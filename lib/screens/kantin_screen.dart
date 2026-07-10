import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_list_screen.dart'; 

class KantinScreen extends StatelessWidget {
  const KantinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Memberikan latar belakang abu-abu terang agar Card putih terlihat menonjol
      backgroundColor: const Color(0xFFF5F5F5), 
      
      appBar: AppBar(
        title: const Text(
          "Daftar Kantin", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Menggunakan warna pilihan Anda
        backgroundColor: const Color(0xFF2D2B2A), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('kantin').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var kantinList = snapshot.data!.docs;

          return ListView.builder(
            // Padding disesuaikan karena sudah ada AppBar
            padding: const EdgeInsets.only(top: 10, bottom: 100),
            itemCount: kantinList.length,
            itemBuilder: (context, index) {
              var data = kantinList[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: ListTile(
                  // Ikon menggunakan warna pilihan Anda agar serasi
                  leading: const Icon(Icons.storefront, color: Color(0xFF2D2B2A)),
                  title: Text(
                    data['nama_kantin'] ?? 'Tanpa Nama', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text("Lokasi: ${data['lokasi'] ?? '-'}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2D2B2A)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuListScreen(
                          kafeId: kantinList[index].id, 
                          namaKafe: data['nama_kantin'] ?? 'Menu Kafe',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}