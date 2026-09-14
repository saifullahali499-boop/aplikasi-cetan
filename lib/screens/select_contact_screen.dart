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
  // Fungsi dialog dengan gaya seperti popup "Edit Pesan"
  void _showInputDialog({required String title, required String hint, required bool isGroup}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input Nama Kontak
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD49A3B)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD49A3B), width: 2),
                    ),
                  ),
                ),
               
                // Jika bukan grup, tampilkan input ID Angka Unik
                if (!isGroup) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: idController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ID Angka Unik Teman',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Contoh: 1234',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD49A3B)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD49A3B), width: 2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal', 
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A3B),
                foregroundColor: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final targetId = idController.text.trim();

                if (isGroup && name.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFD49A3B),
                      content: Text('Grup "$name" berhasil dibuat!'),
                    ),
                  );
                } else if (!isGroup && name.isNotEmpty && targetId.isNotEmpty && currentUser != null) {
                  try {
                    // Karena ID Angka Unik dijadikan Document ID di koleksi 'users',
                    // kita bisa langsung mencarinya dengan cepat via .doc(targetId)
                    var targetDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetId)
                        .get();

                    if (targetDoc.exists) {
                      var targetData = targetDoc.data()!;
                      String targetUid = targetData['uid'] ?? '';
                      String targetName = targetData['name'] ?? name;

                      // Simpan ke subkoleksi 'contacts' milik user yang sedang login
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('contacts')
                          .doc(targetId)
                          .set({
                            'uid': targetUid,
                            'numericId': targetId,
                            'name': targetName,
                            'status': 'Tersedia',
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Kontak "$targetName" berhasil ditambahkan!'),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text('ID Angka tersebut tidak ditemukan di aplikasi.'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Terjadi kesalahan: $e'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text(
                'Simpan', 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
          backgroundColor: const Color(0xFF2C2C2C),
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
                title: 'Tambah Kontak Kapur',
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
            // Daftar Kontak yang diambil dari subkoleksi 'contacts' milik user aktif
            Expanded(
              child: currentUser == null
                  ? const Center(child: Text('Silakan login terlebih dahulu.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('contacts')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Belum ada kontak yang ditambahkan.\nGunakan "Tambah Kontak Kapur" di atas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        final contacts = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contactData = contacts[index].data() as Map<String, dynamic>;
                            final String receiverUid = contactData['uid'] ?? '';
                            final String name = contactData['name'] ?? 'Tanpa Nama';
                            final String status = contactData['status'] ?? 'Tersedia';

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