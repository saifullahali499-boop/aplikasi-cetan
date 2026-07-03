import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna tema gelap/charcoal untuk teks utama agar mudah dibaca
    const Color darkTextColor = Color(0xFF2D2B2A);
    // Warna cokelat estetis untuk aksen status dan border
    const Color accentColor = Color(0xFF8B5A2B);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: accentColor, width: 6),
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.black12, // PERBAIKAN: Diubah menjadi black12 yang valid di Flutter
                    child: Icon(Icons.person, size: 70, color: darkTextColor),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: accentColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white), 
                      onPressed: () {},
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Saifullah Ali', 
            style: TextStyle(color: darkTextColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            '+62 812-3456-7890', 
            style: TextStyle(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS PIKET', 
                    style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Sedang belajar membuat aplikasi chat estetik pakai Flutter. Harap tidak berisik! 🤫', 
                    style: TextStyle(color: darkTextColor, fontSize: 15, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                const ListTile(
                  leading: Icon(Icons.key_outlined, color: Colors.black54),
                  title: Text('Akun', style: TextStyle(color: darkTextColor)),
                ),
                const ListTile(
                  leading: Icon(Icons.notifications_none, color: Colors.black54), 
                  title: Text('Notifikasi', style: TextStyle(color: darkTextColor)),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline, color: Colors.black54), 
                  title: Text('Privasi', style: TextStyle(color: darkTextColor)),
                ),
                const Divider(color: Colors.black12, height: 30),
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