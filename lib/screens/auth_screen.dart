import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Mengambil MainTabController dari main.dart

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP salah atau kedaluwarsa: ${e.toString().split(']').last}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color backgroundColor = Color(0xFFF4F5F7);
    const Color accentColor = Color(0xFF8B5A2B);

    return Scaffold(
      backgroundColor: backgroundColor, // Mengganti background gradien hijau dengan abu terang
      // 1. PENAMBAHAN: AppBar atas berwarna hitam pekat serasi dengan screen lain
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'OTENTIKASI MASUK',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white, // Card diubah menjadi putih bersih solid
            elevation: 3, // Efek bayangan halus kartu
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black12), // Border abu-abu tipis
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
                    style: TextStyle(color: darkTextColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_isOtpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: darkTextColor), // Teks ketikan berwarna charcoal
                      decoration: InputDecoration(
                        labelText: 'Nomor HP (Contoh: +62812345678)',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.phone, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black26), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accentColor, width: 2), borderRadius: BorderRadius.circular(12)),
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
                              child: const Text('Kirim SMS OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                  ],

                  if (_isOtpSent) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: 'Nama Tampilan Anda',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black26), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accentColor, width: 2), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: '6 Digit Kode OTP SMS',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black26), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: accentColor, width: 2), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.green)
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
                      child: const Text('Ganti Nomor HP', style: TextStyle(color: Color(0xFFC67C24), fontWeight: FontWeight.bold)),
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