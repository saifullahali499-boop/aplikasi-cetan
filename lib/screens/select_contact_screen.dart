import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_screen.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  // Fungsi dialog untuk input grup atau kontak baru
  void _showInputDialog({required String title, required String hint, required bool isGroup}) {
    final TextEditingController inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title, style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 18, fontWeight: FontWeight.bold)),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F4),
              border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: inputController,
              style: const TextStyle(color: Color(0xFF2C2C2C)),
              autofocus: true,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38),
                border: InputBorder.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                final text = inputController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFD49A3B),
                      content: Text('${isGroup ? 'Grup' : 'Kontak'} "$text" berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('SIMPAN', style: TextStyle(color: Color(0xFFD49A3B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.3,
          colors: [Color(0xFFFDFDFD), Color(0xFFF6F6F4), Color(0xFFEAEAEA)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C), // Warna Charcoal sesuai permintaan
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pilih Kontak Baru',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            // Tombol Buat Kelompok / Grup Baru
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2C2C2C)), color: Colors.white),
                child: const Icon(Icons.group_add_outlined, color: Color(0xFF2C2C2C)),
              ),
              title: const Text('Buat Kelompok Baru (Grup)', style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold)),
              onTap: () => _showInputDialog(
                title: 'Tulis Nama Grup Baru',
                hint: 'Misal: Tim Piket Jumat, Squad Kopi...',
                isGroup: true,
              ),
            ),
            // Tombol Tambah Kontak Kapur
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2C2C2C)), color: Colors.white),
                child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2C2C2C)),
              ),
              title: const Text('Tambah Kontak Kapur', style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold)),
              onTap: () => _showInputDialog(
                title: 'Tambah Nama Kontak',
                hint: 'Tulis nama teman...',
                isGroup: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SEMUA KONTAK',
                  style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
            // Daftar Kontak Asli dari Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada kontak tersedia di database.'));
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final String receiverUid = users[index].id;
                      final String name = userData['name'] ?? 'Tanpa Nama';
                      final String status = userData['status'] ?? 'Tersedia';

                      // Sembunyikan akun sendiri dari daftar kontak
                      if (currentUser != null && receiverUid == currentUser.uid) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2C2C2C)), color: Colors.white),
                              child: const Icon(Icons.person_outline, color: Color(0xFF2C2C2C)),
                            ),
                            title: Text(name, style: const TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.w600)),
                            subtitle: Text(status, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatRoomScreen(
                                    name: name,
                                    chatId: name,
                                    receiverUid: receiverUid,
                                  ),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 72.0),
                            child: Divider(color: const Color(0xFF2C2C2C).withOpacity(0.08), height: 1),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}