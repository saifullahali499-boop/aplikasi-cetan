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

  // Master data daftar obrolan utama
  final List<Map<String, dynamic>> _masterChatList = [
    {"name": "ISTRIKU ❤️", "message": "Say, jangan lupa ya?", "time": "10:05", "isGroup": false, "isUnread": true},
    {"name": "Grup Alumni '98", "message": "Reuni jadi nggak nih???", "time": "Yesterday", "isGroup": true, "isUnread": false},
    {"name": "Anak Lanang", "message": "Ma, pinjam HP sebentar ya?", "time": "Yesterday", "isGroup": false, "isUnread": true},
    {"name": "Pak Eko Guru", "message": "Tugas seni dikumpulkan besok.", "time": "2 days ago", "isGroup": false, "isUnread": false},
    {"name": "Grup Ronda RT 03", "message": "Jadwal siskamling malam ini aman.", "time": "3 days ago", "isGroup": true, "isUnread": false},
  ];

  @override
  Widget build(BuildContext context) {
    // Proses penyaringan (filtering) data berdasarkan tab yang dipilih
    List<Map<String, dynamic>> filteredChatList = [];
    if (_selectedTabFilter == 0) {
      filteredChatList = _masterChatList; // Semua chat ditampilkan
    } else if (_selectedTabFilter == 1) {
      filteredChatList = _masterChatList.where((chat) => chat['isUnread'] == true).toList(); // Hanya yang belum dibaca
    } else if (_selectedTabFilter == 2) {
      filteredChatList = _masterChatList.where((chat) => chat['isGroup'] == true).toList(); // Hanya grup
    }

    // Hitung berapa total chat yang belum dibaca secara dinamis
    int unreadCount = _masterChatList.where((chat) => chat['isUnread'] == true).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAPANTULIS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('CHAT', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 30), 
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactListScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(height: 2, width: 100, color: Colors.white38),
            const SizedBox(height: 25),
            
            // --- BAGIAN NAVIGASI TAB YANG SEKARANG BISA DIPENCET ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWoodTabButton("SEMUA", indexTarget: 0),
                  _buildWoodTabButton("BELUM DIBACA ($unreadCount)", indexTarget: 1),
                  _buildWoodTabButton("GRUP", indexTarget: 2),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            // --- DAFTAR CHAT HASIL FILTERING ---
            Expanded(
              child: filteredChatList.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada obrolan di kategori ini.',
                        style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredChatList.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChatList[index];
                        return InkWell(
                          onTap: () {
                            // Simulasi: begitu chat dibuka, tandai sudah dibaca secara lokal
                            setState(() {
                              chat['isUnread'] = false;
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: chat['name'])));
                          },
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.white12,
                                      child: Icon(chat['name'].contains('Grup') ? Icons.group_outlined : Icons.person_outline, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(chat['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                  if (chat['isUnread'] == true) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(color: Color(0xFF8B5A2B), shape: BoxShape.circle),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                              Text(chat['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            chat['message'], 
                                            style: TextStyle(
                                              color: chat['isUnread'] == true ? Colors.white : Colors.white70, 
                                              fontSize: 14,
                                              fontWeight: chat['isUnread'] == true ? FontWeight.bold : FontWeight.normal,
                                            ), 
                                            maxLines: 1, 
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 1, thickness: 1),
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

  // Desain tombol kayu yang dibungkus dengan GestureDetector agar bisa menerima respon sentuhan
  Widget _buildWoodTabButton(String text, {required int indexTarget}) {
    bool isSelected = _selectedTabFilter == indexTarget;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabFilter = indexTarget; // Ubah filter sesuai tab yang ditekan
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(4), 
        decoration: BoxDecoration(
          color: const Color(0xFF8B5A2B), 
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(1, 2))],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E5B35) : const Color(0xFF152E19),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// === SCREEN PILIH KONTAK BARU ===
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
          backgroundColor: const Color(0xFF1E3F24),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF8B5A2B), width: 3),
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: inputController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL', style: TextStyle(color: Colors.white38)),
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
                      backgroundColor: const Color(0xFF8B5A2B),
                      content: Text('${isGroup ? 'Grup' : 'Kontak'} "$text" berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        gradient: RadialGradient(center: Alignment(-0.2, -0.3), radius: 1.5, colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)]),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Kontak Baru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${_contacts.length} Kontak Tersedia', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        body: Column(
          children: [
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.group_add_outlined, color: Colors.white70)),
              title: const Text('Buat Kelompok Baru (Grup)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => _showInputDialog(
                title: 'Tulis Nama Grup Baru',
                hint: 'Misal: Tim Piket Jumat, Squad Kopi...',
                isGroup: true,
              ),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.person_add_alt_1_outlined, color: Colors.white70)),
              title: const Text('Tambah Kontak Kapur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => _showInputDialog(
                title: 'Tambah Nama Kontak',
                hint: 'Tulis nama teman sekelas...',
                isGroup: false,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('SEMUA KONTAK', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                        leading: CircleAvatar(
                          backgroundColor: Colors.white12, 
                          child: Icon(contact['name']!.contains('Grup') ? Icons.group_outlined : Icons.person_outline, color: Colors.white70),
                        ),
                        title: Text(contact['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text(contact['status']!, style: const TextStyle(color: Colors.white38, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: contact['name']!)));
                        },
                      ),
                      const Padding(padding: EdgeInsets.only(left: 70.0), child: Divider(color: Colors.white10, height: 1)),
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
