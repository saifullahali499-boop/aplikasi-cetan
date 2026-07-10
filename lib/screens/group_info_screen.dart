import 'package:flutter/material.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupName;

  const GroupInfoScreen({super.key, required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  // Data contoh dummy anggota grup (Nanti bisa ditarik dari Firebase koleksi 'groups')
  final List<Map<String, dynamic>> _groupMembers = [
    {"name": "Anak Lanang", "role": "Admin", "status": "Sedang belajar Flutter 🚀"},
    {"name": "ISTRIKU ❤️", "role": "Anggota", "status": "Jangan lupa titipan belanjaan ya"},
    {"name": "Sobat Ngopi", "role": "Anggota", "status": "Ngopi yuk! ☕"},
    {"name": "Anda", "role": "Admin", "status": "Online"},
  ];

  // Fungsi pura-pura kick anggota (Fitur Admin)
  void _kickMember(int index, String name) {
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
            onPressed: () {
              setState(() {
                _groupMembers.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: const Color(0xFF2D2B2A), content: Text('"$name" telah dikeluarkan.')),
              );
            },
            child: const Text('KELUARKAN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Info Kelompok', style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold, fontSize: 18)),
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
            
            // Nama Grup
            Text(
              widget.groupName.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 4),
            Text(
              'Grup Kapur • ${_groupMembers.length} Anggota',
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
                  letterSpacing: 1.2
                ),
              ),
            ),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groupMembers.length,
              itemBuilder: (context, index) {
                final member = _groupMembers[index];
                final bool isAdmin = member['role'] == 'Admin';
                final bool isMe = member['name'] == 'Anda';

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
                            
                            // Fitur Akses Admin: Bisa kick orang lain (bukan diri sendiri)
                            if (!isMe) 
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.black45),
                                onSelected: (value) {
                                  if (value == 'kick') {
                                    _kickMember(index, member['name']);
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

            // === TOMBOL KELUAR GRUP ===
            const SizedBox(height: 20),
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                title: const Text('Tinggalkan Kelompok', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  // Tambahkan logika keluar grup di sini nanti
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}