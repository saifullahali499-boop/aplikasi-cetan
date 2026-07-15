import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupName;

  const GroupInfoScreen({super.key, required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // === 1. FUNGSI NYATA: MENGELUARKAN ANGGOTA (KICK) ===
  void _kickMember(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Keluarkan Anggota', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
        content: Text('Apakah Anda yakin ingin mengeluarkan "$name" dari grup ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.black45)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dialog
              
              // Logika: Menghapus log chat user tersebut di room ini agar namanya terhapus dari daftar aktif
              final chatDocs = await FirebaseFirestore.instance
                  .collection('chats')
                  .where('room', isEqualTo: widget.groupName)
                  .where('senderUid', isEqualTo: uid)
                  .get();

              for (var doc in chatDocs.docs) {
                await doc.reference.delete();
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: const Color(0xFF2D2B2A), content: Text('"$name" telah dikeluarkan.')),
                );
              }
            },
            child: const Text('KELUARKAN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // === 2. FUNGSI NYATA: TINGGALKAN KELOMPOK ===
  void _leaveGroup() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Tinggalkan Kelompok', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
        content: const Text('Apakah Anda yakin ingin keluar? Riwayat chat Anda di kelompok ini akan dibersihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.black45)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup Dialog
              
              // Back beruntun sampai ke halaman Dashboard utama aplikasi
              Navigator.of(context).pop(); 
              Navigator.of(context).pop();

              // Bersihkan data chat kita di room ini
              final chatDocs = await FirebaseFirestore.instance
                  .collection('chats')
                  .where('room', isEqualTo: widget.groupName)
                  .where('senderUid', isEqualTo: currentUser.uid)
                  .get();

              for (var doc in chatDocs.docs) {
                await doc.reference.delete();
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: Color(0xFF2D2B2A), content: Text('Anda telah meninggalkan kelompok.')),
              );
            },
            child: const Text('KELUAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    // === 3. SEPROSES REAL-TIME STREAM DATA KELOMPOK ===
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('room', isEqualTo: widget.groupName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F5F7),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2C2C2C))),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        Map<String, Map<String, dynamic>> membersMap = {};

        // Inisialisasi Akun Sendiri ("Anda") agar selalu muncul paling atas walaupun grup baru
        if (currentUser != null) {
          membersMap[currentUser.uid] = {
            'uid': currentUser.uid,
            'name': 'Anda',
            'role': 'Admin',
            'status': 'Online 🚀',
          };
        }

        // Ambil data anggota lain secara unik dari riwayat chat room ini
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String uid = data['senderUid'] ?? '';
          final String name = data['senderName'] ?? 'Anggota Kelompok';

          if (uid.isNotEmpty && uid != currentUser?.uid) {
            if (!membersMap.containsKey(uid)) {
              membersMap[uid] = {
                'uid': uid,
                'name': name,
                'role': 'Anggota',
                'status': 'Aktif di kelompok ini • ☕',
              };
            }
          }
        }

        final List<Map<String, dynamic>> activeMembers = membersMap.values.toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          
          // === APPBAR TRANSPARAN SESUAI DESIGN ASLI ===
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C2C2C)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Info Kelompok',
              style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // === AVATAR GRUP BESAR STIL SKETSA ===
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF2C2C2C), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Icon(Icons.group_outlined, size: 50, color: Color(0xFF2C2C2C)),
                  ),
                ),
                const SizedBox(height: 14),

                // Nama Grup Dinamis
                Text(
                  widget.groupName.toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                ),
                const SizedBox(height: 4),
                
                // Indikator Jumlah Anggota Dinamis
                Text(
                  'Grup Kapur • ${activeMembers.length} Anggota',
                  style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.5), fontSize: 13),
                ),

                const SizedBox(height: 30),

                // === STRUKTUR DAFTAR ANGGOTA ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Text(
                    'ANGGOTA KELOMPOK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C2C2C).withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // LIST ANGGOTA REAL-TIME
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeMembers.length,
                  itemBuilder: (context, index) {
                    final member = activeMembers[index];
                    final bool isAdmin = member['role'] == 'Admin';
                    final bool isMe = member['uid'] == currentUser?.uid;

                    return Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2C2C2C)),
                                color: const Color(0xFFF6F6F4),
                              ),
                              child: const Icon(Icons.person_outline, color: Color(0xFF2C2C2C)),
                            ),
                            title: Text(
                              member['name'],
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C)),
                            ),
                            subtitle: Text(
                              member['status'],
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge Penanda Admin
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFD49A3B)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Admin',
                                      style: TextStyle(color: Color(0xFFD49A3B), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                // Tombol Kelola hanya muncul di baris orang lain (bukan diri sendiri)
                                if (!isMe)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.black45),
                                    color: Colors.white,
                                    onSelected: (value) {
                                      if (value == 'kick') {
                                        _kickMember(member['uid'], member['name']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'kick',
                                        child: Text('Keluarkan dari Grup', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 70.0),
                            child: Divider(color: const Color(0xFF2C2C2C).withOpacity(0.06), height: 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // === TOMBOL KELUAR GRUP AKTIF ===
                const SizedBox(height: 20),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                    title: const Text('Tinggalkan Kelompok', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: _leaveGroup,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}