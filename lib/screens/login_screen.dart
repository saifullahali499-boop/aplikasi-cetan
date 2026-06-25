import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Mengambil MainTabController dari main.dart

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
  
  bool _isOtpSent = false; // Status apakah SMS OTP sudah dikirim
  bool _isLoading = false;
  String? _verificationId;

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

    try {
      ConfirmationResult confirmationResult = await _auth.signInWithPhoneNumber(phone);
      setState(() {
        _isOtpSent = true;
        _verificationId = confirmationResult.verificationId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP berhasil dikirim via SMS!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim SMS: ${e.toString().split(']').last}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
      
      // Menyimpan nama pengguna ke profil Firebase Auth mereka
      await userCredential.user?.updateDisplayName(name);

      if (mounted) {
        // Jika sukses, lempar pengguna ke menu utama (MainTabController)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabController()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP salah atau kedaluwarsa: ${e.toString().split(']').last}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.3, 0.4), 
          radius: 1.5, 
          colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF8B5A2B),
                      child: Icon(Icons.phone_android_outlined, size: 45, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MASUK VIA NOMOR HP',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 24),
                    
                    // --- TAHAP 1: INPUT NOMOR TELEPON ---
                    if (!_isOtpSent) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nomor HP (Contoh: +62812345678)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.phone, color: Colors.white60),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5A2B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _sendOtp,
                                child: const Text('Kirim SMS OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                    ],

                    // --- TAHAP 2: INPUT NAMA DAN KODE OTP ---
                    if (_isOtpSent) ...[
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nama Tampilan Anda',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.white60),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '6 Digit Kode OTP SMS',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.white60),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _verifyOtp,
                                child: const Text('Verifikasi & Masuk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _isOtpSent = false),
                        child: const Text('Ganti Nomor HP', style: TextStyle(color: Colors.amber)),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
