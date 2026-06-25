import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5A2B), width: 6)),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, size: 70, color: Colors.white70),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF8B5A2B),
                    child: IconButton(icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white), onPressed: () {}),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Saifullah Ali', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('+62 812-3456-7890', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(15)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS PIKET', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 5),
                  Text('Sedang belajar membuat aplikasi chat estetik pakai Flutter. Harap tidak berisik! 🤫', style: TextStyle(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                ListTile(leading: const Icon(Icons.key_outlined, color: Colors.white70), title: const Text('Akun', style: TextStyle(color: Colors.white))),
                ListTile(leading: const Icon(Icons.notifications_none, color: Colors.white70), title: const Text('Notifikasi', style: TextStyle(color: Colors.white))),
                ListTile(leading: const Icon(Icons.lock_outline, color: Colors.white70), title: const Text('Privasi', style: TextStyle(color: Colors.white))),
                const Divider(color: Colors.white10, height: 30),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Keluar (Pintu Kelas)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
