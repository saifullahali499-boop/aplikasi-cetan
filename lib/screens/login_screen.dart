import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    // Dipanggil untuk mencegah Memory Leak
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 1. FUNGSI UNTUK MEMINTA SMS OTP
  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nomor HP Anda! (Gunakan format +62)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (kIsWeb) {
      try {
        ConfirmationResult confirmationResult = await _auth.signInWithPhoneNumber(phone);
        if (mounted) {
          setState(() {
            _isOtpSent = true;
            _verificationId = confirmationResult.verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kode OTP berhasil dikirim via SMS (Web)!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim SMS Web: ${e.toString().split(']').last}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              UserCredential userCredential = await _auth.signInWithCredential(credential);
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                await userCredential.user?.updateDisplayName(name);
              }
             
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainTabController()),
                  );
                });
              }
            } catch (e) {
              debugPrint("Error auto verification: $e");
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mengirim SMS Android: ${e.message}')),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (mounted) {
              setState(() {
                _isOtpSent = true;
                _verificationId = verificationId;
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode OTP berhasil dikirim via SMS!')),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan sistem: $e')),
          );
        }
      }
    }
  }

  // 2. FUNGSI UNTUK VERIFIKASI KODE OTP
  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    final name = _nameController.text.trim();

    if (otp.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi Nama dan Kode OTP Anda!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId ?? '',
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await userCredential.user?.updateDisplayName(name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabController()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode OTP salah atau kedaluwarsa: ${e.toString().split(']').last}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color accentColor = Color(0xFF8B5A2B);
    const Color backgroundColor = Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: accentColor,
                    child: Icon(Icons.phone_android_outlined, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MASUK VIA NOMOR HP',
                    style: TextStyle(
                      color: darkTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                
                  // --- TAHAP 1: INPUT NOMOR TELEPON ---
                  if (!_isOtpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: 'Nomor HP (Contoh: +62812345678)',
                        labelStyle: const TextStyle(color: Colors.black45),
                        prefixIcon: const Icon(Icons.phone, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator(color: accentColor)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _sendOtp,
                              child: const Text(
                                'Kirim SMS OTP',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ],

                  // --- TAHAP 2: INPUT NAMA DAN KODE OTP ---
                  if (_isOtpSent) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: 'Nama Tampilan Anda',
                        labelStyle: const TextStyle(color: Colors.black45),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: '6 Digit Kode OTP SMS',
                        labelStyle: const TextStyle(color: Colors.black45),
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator(color: accentColor)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _verifyOtp,
                              child: const Text(
                                'Verifikasi & Masuk',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      child: const Text('Ganti Nomor HP', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                    )
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}