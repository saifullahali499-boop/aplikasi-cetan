import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuListScreen extends StatelessWidget {
  final String kafeId;
  final String namaKafe;

  const MenuListScreen({super.key, required this.kafeId, required this.namaKafe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Warna background senada
      appBar: AppBar(
        title: Text(
          namaKafe, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D2B2A), // Warna AppBar pilihan Anda
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Ikon kembali jadi putih
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('kantin')
            .doc(kafeId)
            .collection('menu')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var menus = snapshot.data!.docs;
          if (menus.isEmpty) {
            return const Center(child: Text("Menu belum tersedia"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              var data = menus[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    data['nama_menu'] ?? 'Menu',
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2B2A), // Teks judul menggunakan warna gelap senada
                    ),
                  ),
                  trailing: Text(
                    "Rp ${data['harga'] ?? '0'}",
                    style: const TextStyle(
                      fontSize: 18, 
                      color: Colors.green, // Warna hijau untuk harga tetap bagus
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}