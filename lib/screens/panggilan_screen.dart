import 'package:flutter/material.dart';

class PanggilanScreen extends StatelessWidget {
  const PanggilanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi warna agar serasi dengan screen lainnya
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color backgroundColor = Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      // 1. PENAMBAHAN: AppBar atas berwarna hitam pekat
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'RIWAYAT PANGGILAN', 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. PERBAIKAN: Card diubah menjadi putih bersih dengan teks charcoal gelap
            Card(
              color: Colors.white,
              elevation: 2, // Efek bayangan halus
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black12), // Border abu-abu tipis
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: backgroundColor, // Latar belakang icon abu-abu terang
                  child: Icon(Icons.phone_missed, color: Colors.redAccent),
                ),
                // PERBAIKAN: Emoji teks rusak 'â¤ï¸' sudah diperbaiki menjadi objek emoji asli
                title: Text(
                  'ISTRIKU ❤️ (2)', 
                  style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Hari ini, 13:15', 
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}