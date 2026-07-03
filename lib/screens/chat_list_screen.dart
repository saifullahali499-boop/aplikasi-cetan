import 'package:flutter/material.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Status tab yang sedang aktif (0: SEMUA, 1: BELUM DIBACA, 2: GRUP)
  int _selectedTabFilter = 0;

  // Master data daftar obrolan utama (Emoji dibersihkan agar rapi)
  final List<Map<String, dynamic>> _masterChatList = [
    {"name": "ISTRIKU ❤️", "message": "Say, jangan lupa ya?", "time": "10:05", "isGroup": false, "isUnread": true},
    {"name": "Grup Alumni '98", "message": "Reuni jadi nggak nih???", "time": "Yesterday", "isGroup": true, "isUnread": false},
    {"name": "Anak Lanang", "message": "Ma, pinjam HP sebentar ya?", "time": "Yesterday", "isGroup": false, "isUnread": true},
    {"name": "Pak Eko Guru", "message": "Tugas seni dikumpulkan besok.", "time": "2 days ago", "isGroup": false, "isUnread": false},
    {"name": "Grup Ronda RT 03", "message": "Jadwal siskamling malam ini aman.", "time": "3 days ago", "isGroup": true, "isUnread": false},
  ];

  @override
  Widget build(BuildContext context) {
    // Proses penyaringan (filtering) data tetap berjalan normal sesuai logika asli Anda
    List<Map<String, dynamic>> filteredChatList = [];
    if (_selectedTabFilter == 0) {
      filteredChatList = _masterChatList;
    } else if (_selectedTabFilter == 1) {
      filteredChatList = _masterChatList.where((chat) => chat['isUnread'] == true).toList();
    } else if (_selectedTabFilter == 2) {
      filteredChatList = _masterChatList.where((chat) => chat['isGroup'] == true).toList();
    }

    int unreadCount = _masterChatList.where((chat) => chat['isUnread'] == true).length;

    return Scaffold(
      backgroundColor: Colors.transparent, // Tetap transparan agar gradasi luar terlihat mewah
      
      // === APPBAR HITAM CHARCOAL SESUAI DI ROOM CHAT ===
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2B2A), // Warna hitam arang premium
        elevation: 2,
        automaticallyImplyLeading: false, // Menghilangkan tombol back otomatis jika tidak sengaja muncul
        title: const Text(
          'PESAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          // Tombol Edit (Tulis Pesan) dipindah ke pojok kanan atas AppBar
          IconButton(
            icon: const Icon(Icons.edit_note_outlined, color: Colors.white70, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactListScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15), // Jarak tipis setelah AppBar agar proporsional
            
            // --- BAGIAN NAVIGASI TAB GAYA SKETSA CERAH ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSketchTabButton("SEMUA", indexTarget: 0),
                  _buildSketchTabButton("BELUM DIBACA ($unreadCount)", indexTarget: 1),
                  _buildSketchTabButton("GRUP", indexTarget: 2),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            // --- DAFTAR CHAT HASIL FILTERING ---
            Expanded(
              child: filteredChatList.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada obrolan di kategori ini.',
                        style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.4), fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredChatList.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChatList[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              chat['isUnread'] = false;
                            });
                            // Tetap mengarah ke chat room pembawa parameter name asli Anda
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: chat['name'])));
                          },
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    // Lingkaran Profil Bergaya Sketsa Pensil
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                        ]
                                      ),
                                      child: Icon(
                                        chat['name'].contains('Grup') ? Icons.group_outlined : Icons.person_outline_rounded,
                                        color: const Color(0xFF2C2C2C),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                chat['name'],
                                                style: const TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                chat['time'],
                                                style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.4), fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  chat['message'],
                                                  style: TextStyle(
                                                    color: chat['isUnread'] == true ? const Color(0xFF2C2C2C) : Colors.black54,
                                                    fontSize: 14,
                                                    fontWeight: chat['isUnread'] == true ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Badge Bulat Indikator Pesan Belum Dibaca Warna Amber Menyala
                                              if (chat['isUnread'] == true)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  margin: const EdgeInsets.only(left: 8),
                                                  decoration: const BoxDecoration(color: Color(0xFFD49A3B), shape: BoxShape.circle),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: const Color(0xFF2C2C2C).withOpacity(0.1), height: 1, thickness: 1),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain tombol navigasi tab filter bertema sketsa pensil & aksen Amber
  Widget _buildSketchTabButton(String text, {required int indexTarget}) {
    bool isSelected = _selectedTabFilter == indexTarget;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabFilter = indexTarget;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD49A3B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD49A3B) : const Color(0xFF2C2C2C).withOpacity(0.2),
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
            fontSize: 12,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}

// === SCREEN PILIH KONTAK BARU (Baju Baru Bertema Kertas Sketsa) ===
class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final List<Map<String, String>> _contacts = [
    {"name": "Anak Lanang", "status": "Sedang belajar Flutter 🚀"},
    {"name": "Bapak Ketua RT", "status": "Ada rapat warga nanti malam"},
    {"name": "ISTRIKU ❤️", "status": "Jangan lupa titipan belanjaan ya"},
    {"name": "Mas Agus (Montir)", "status": "Bengkel buka sampai jam 5 sore"},
    {"name": "Pak Eko Guru", "status": "Sedang piket di sekolah... Harap tenang"},
    {"name": "Sobat Ngopi", "status": "Ngopi yuk! ☕"},
  ];

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
                  setState(() {
                    _contacts.insert(0, {
                      "name": isGroup ? "Grup $text" : text,
                      "status": isGroup ? "Baru saja dibuat oleh Anda" : "Halo! Saya menggunakan PapanTulis.",
                    });
                  });
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
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.3,
          colors: [Color(0xFFFDFDFD), Color(0xFFF6F6F4), Color(0xFFEAEAEA)]
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C2C2C)), onPressed: () => Navigator.pop(context)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Kontak Baru', style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${_contacts.length} Kontak Tersedia', style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ),
        body: Column(
          children: [
            Divider(color: const Color(0xFF2C2C2C).withOpacity(0.12), height: 1),
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
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2C2C2C)), color: Colors.white),
                child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2C2C2C)),
              ),
              title: const Text('Tambah Kontak Kapur', style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold)),
              onTap: () => _showInputDialog(
                title: 'Tambah Nama Kontak',
                hint: 'Tulis nama teman sekelas...',
                isGroup: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('SEMUA KONTAK', style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2C2C2C)), color: Colors.white),
                          child: Icon(contact['name']!.contains('Grup') ? Icons.group_outlined : Icons.person_outline, color: const Color(0xFF2C2C2C)),
                        ),
                        title: Text(contact['name']!, style: const TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.w600)),
                        subtitle: Text(contact['status']!, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: contact['name']!)));
                        },
                      ),
                      Padding(padding: const EdgeInsets.only(left: 72.0), child: Divider(color: const Color(0xFF2C2C2C).withOpacity(0.08), height: 1)),
                    ],
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