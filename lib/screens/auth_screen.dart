import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _numericIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoginMode = true; // true = Masuk, false = Daftar
  bool _isLoading = false;

  @override
  void dispose() {
    _numericIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 1. FUNGSI TRANSFORMASI EMAIL VIRTUAL DI BALIK LAYAR
  String _getVirtualEmail(String numericId) {
    return '$numericId@papantulis.anonymous';
  }

  // 2. FUNGSI UTAMA PENDAFTARAN & MASUK
  void _submitAuth() async {
    final numericId = _numericIdController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Validasi input kosong
    if (numericId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Angka dan Kata Sandi wajib diisi!')),
      );
      return;
    }

    // Validasi panjang ID Angka (4-12 digit)
    if (numericId.length < 4 || numericId.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Angka harus terdiri dari 4 hingga 12 digit!')),
      );
      return;
    }

    // Validasi panjang password (minimal 6 karakter)
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata Sandi minimal harus 6 karakter!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final virtualEmail = _getVirtualEmail(numericId);
      final docRef = FirebaseFirestore.instance.collection('users').doc(numericId);

      if (!_isLoginMode) {
        // --- LOGIKA PENDAFTARAN (REGISTRASI) ---
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          throw 'ID Angka sudah digunakan oleh pengguna lain. Silakan pilih ID lain.';
        }

        // Buat akun di Firebase Authentication menggunakan email virtual & password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: virtualEmail,
          password: password,
        );

        // Simpan data profil ke Firestore menggunakan ID Angka sebagai Document ID
        await docRef.set({
          'numericId': numericId,
          'uid': userCredential.user?.uid,
          'name': name.isNotEmpty ? name : 'Pengguna $numericId',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update Display Name jika diisi
        if (name.isNotEmpty) {
          await userCredential.user?.updateDisplayName(name);
        }
      } else {
        // --- LOGIKA MASUK (LOGIN) ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: virtualEmail,
          password: password,
        );
      }

      // --- SIMPAN ID ANGKA KE SHARED PREFERENCES ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_numeric_id', numericId);

    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${errorMessage.split(']').last.trim()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color backgroundColor = Color(0xFFF4F5F7);
    const Color accentColor = Color(0xFF8B5A2B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _isLoginMode ? 'MASUK AKUN' : 'PENDAFTARAN AKUN',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
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
                    child: Icon(Icons.lock_person_outlined, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoginMode ? 'MASUK DENGAN ID & SANDI' : 'BUAT ID & KATA SANDI',
                    style: const TextStyle(color: darkTextColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 24),

                  // INPUT NAMA (Hanya muncul saat mode Daftar)
                  if (!_isLoginMode) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: darkTextColor),
                      decoration: InputDecoration(
                        labelText: 'Nama Tampilan (Opsional)',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black45),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // INPUT ID ANGKA
                  TextField(
                    controller: _numericIdController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: darkTextColor),
                    decoration: InputDecoration(
                      labelText: 'ID Angka (4–12 digit)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.badge_outlined, color: Colors.black45),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: accentColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INPUT KATA SANDI
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: darkTextColor),
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi (Min. 6 karakter)',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: accentColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TOMBOL AKSI UTAMA
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
                            onPressed: _submitAuth,
                            child: Text(
                              _isLoginMode ? 'Masuk' : 'Daftar Sekarang',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),

                  // TOMBOL BERALIH ANTARA MASUK DAN DAFTAR
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? 'Belum punya ID? Daftar di sini'
                          : 'Sudah punya ID? Masuk di sini',
                      style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}