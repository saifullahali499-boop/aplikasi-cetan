import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'select_contact_screen.dart';
import 'chat_room_screen.dart';
import 'group_chat_screen.dart';
import '../services/wifi_service.dart';
import 'chat_options_sheet.dart'; // Sesuaikan jika filenya berada di dalam folder lain, misal: import '../widgets/chat_options_sheet.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  int _selectedTabFilter = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  final WifiStatusService _wifiService = WifiStatusService();

  List<String> _lockedChats = [];
  String _appPin = "1234";

final Set<String> _hiddenChats = {};
  final Map<String, String> _chatCategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wifiService.checkAndUpdatetWifiStatus();
    _wifiService.listenToConnectivityChanges();
    _loadLockedChats();
    _loadHiddenChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  // Fungsi simpan kategori chat berdasarkan ID unik chat (chatId)
Future<void> _simpanKategoriKeFirestore(String chatId, String kategoriBaru) async {
  try {
    // Langsung update dokumen berdasarkan ID uniknya
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      'categoryId': kategoriBaru,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kategori "$kategoriBaru" berhasil disimpan!')),
    );
  } catch (e) {
    print("Gagal menyimpan kategori: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menyimpan kategori: $e')),
    );
  }
}
Future<void> _showCategoryDialog(BuildContext context, String roomName) async {
  // 1. Controller untuk mengambil teks yang diketik pengguna
  TextEditingController categoryController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D), // Warna latar belakang gelap khas tema
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Atur Kategori Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: categoryController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Masukkan kategori (cth: Keluarga)',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFAB873A)), // Garis bawah warna Amber
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFAB873A), width: 2), // Garis bawah fokus Amber
            ),
          ),
        ),
        actions: [
          // Tombol Batal
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          
          // Tombol Simpan
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAB873A), // Tombol Simpan warna Amber
              foregroundColor: Colors.black, // Teks gelap agar kontras
            ),
            onPressed: () {
              String kategoriBaru = categoryController.text.trim();
              if (kategoriBaru.isNotEmpty) {
                // Memanggil fungsi simpan ke Firestore
                _simpanKategoriKeFirestore(roomName, kategoriBaru);
                Navigator.pop(context); // Tutup dialog
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

// ⬇️ TARUH FUNGSI _hapusKategori DI SINI (SEJAJAR DENGAN FUNGSI LAINNYA)
Future<void> _hapusKategori(String categoryName) async {
  bool? confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D), // Menyesuaikan tema gelap
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Hapus Kategori',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Yakin ingin menghapus kategori "$categoryName"?',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() {
      _selectedTabFilter = 0; // 🔴 Reset tab filter
    });
    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('categoryId', isEqualTo: categoryName)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        'categoryId': FieldValue.delete(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kategori "$categoryName" berhasil dihapus')),
    );
  }
}
  // Fungsi untuk mengambil data chat yang disembunyikan dari memori HP
  Future<void> _loadHiddenChats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList('hidden_chats_key');
    if (savedList != null) {
      setState(() {
        _hiddenChats.clear();
        _hiddenChats.addAll(savedList);
      });
    }
  }

  // Fungsi untuk menyimpan data setiap kali ada chat yang disembunyikan/ditampilkan
  Future<void> _saveHiddenChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_chats_key', _hiddenChats.toList());
  }

  Future<void> _loadLockedChats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockedChats = prefs.getStringList('locked_chats') ?? [];
      _appPin = prefs.getString('app_pin') ?? "1234";
    });
  }

  Future<void> _toggleLockChat(String roomName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_lockedChats.contains(roomName)) {
        _lockedChats.remove(roomName);
      } else {
        _lockedChats.add(roomName);
      }
    });
    await prefs.setStringList('locked_chats', _lockedChats);
  }

  // Fungsi untuk menandai pesan di chat ini sudah dibaca menggunakan nama room
  Future<void> _markChatAsRead(String roomName) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('room', isEqualTo: roomName) // 🟢 Sesuaikan dengan field di database (room)
          .get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['senderUid'] != currentUserId && (data['isRead'] == false || data['isRead'] == null)) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      print("Error marking chat as read: $e");
    }
  }

  // Dialog untuk memasukkan PIN saat membuka chat yang dikunci
  void _showPinDialog(BuildContext context, String roomName, bool isGroup
  , String? receiverUid) {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFD49A3B)),
              SizedBox(width: 8),
              Text('Chat Terkunci', style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masukkan PIN untuk membuka obrolan dengan "$roomName":', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F4),
                  border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Color(0xFF2C2C2C), letterSpacing: 8, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.black38, letterSpacing: 8),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                if (pinController.text == _appPin) {
                  Navigator.pop(context);
                  _markChatAsRead(roomName);
                  if (isGroup) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(groupName: roomName)));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: roomName,chatId: roomName, 
                    receiverUid: receiverUid,)));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.red, content: Text('PIN Salah! Coba lagi.')),
                  );
                }
              },
              child: const Text('BUKA', style: TextStyle(color: Color(0xFFD49A3B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk memasukkan PIN saat ingin MEMBUKA KUNCI obrolan
  void _showUnlockPinDialog(BuildContext context, String roomName) {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: Color(0xFFD49A3B)),
              SizedBox(width: 8),
              Text('Buka Kunci Obrolan', style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masukkan PIN untuk menghapus kunci dari obrolan "$roomName":', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F4),
                  border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Color(0xFF2C2C2C), letterSpacing: 8, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.black38, letterSpacing: 8),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                if (pinController.text == _appPin) {
                  Navigator.pop(context);
                  _toggleLockChat(roomName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFD49A3B),
                      content: Text('Obrolan berhasil dibuka kuncinya 🔓'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.red, content: Text('PIN Salah! Coba lagi.')),
                  );
                }
              },
              child: const Text('BUKA', style: TextStyle(color: Color(0xFFD49A3B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  // Jendela Modal untuk Fitur Lihat Chat / Incognito Peek
  void _showIncognitoPeekModal(BuildContext context, String roomName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility_off, color: Color(0xFFD49A3B)),
                      const SizedBox(width: 8),
                      Text(
                        'INTIP: ${roomName.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C2C2C)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF2C2C2C)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                '🛡️ Mode Baca Aman Aktif (Status dibaca & online tidak berubah)',
                style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 20),
              
            ],
          ),
        );
      },
    );
  }

void _showDeleteChatRoomDialog(BuildContext context, String docId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: const Text(
        'Hapus Obrolan', 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Apakah Anda yakin ingin menghapus obrolan ini secara permanen?', 
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            if (docId.isNotEmpty) {
              await FirebaseFirestore.instance.collection('chats').doc(docId).delete();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Obrolan berhasil dihapus')),
              );
            }
          },
          child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void _showChatOptionsSheet(BuildContext context, Map<String, dynamic> chatData) {
  final String roomName = chatData['name'] ?? '';
  final String docId = chatData["id"] ?? "";
  bool isLocked = _lockedChats.contains(roomName);
  bool isHidden = _hiddenChats.contains(roomName);

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2B2B2B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return ChatOptionsSheet(
        chatData: chatData,
        isLocked: isLocked,
        isHidden: isHidden,
        currentCategory: _chatCategories[roomName],
        onUnlockPin: () => _showUnlockPinDialog(context, roomName),
        onToggleLock: () {
          _toggleLockChat(roomName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Color(0xFFD49A3B), content: Text('Obrolan berhasil dikunci 🔒')),
          );
        },
        onShowCategory: () => _showCategoryDialog(context, roomName),
        onToggleHide: () {
          setState(() {
            if (isHidden) {
              _hiddenChats.remove(roomName);
            } else {
              _hiddenChats.add(roomName);
            }
          });
          _saveHiddenChats();
        },
        onDeleteChat: () => _showDeleteChatRoomDialog(context, docId),
        onIncognitoPeek: (ctx) => _showIncognitoPeekModal(ctx, roomName),
      );
    },
  );
}


 @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    // Ambil ID Angka yang tersimpan di SharedPreferences saat login/pendaftaran
    final prefs = await SharedPreferences.getInstance();
    final numericId = prefs.getString('user_numeric_id'); // Sesuaikan key jika di aplikasi Anda menggunakan nama lain
    
    if (numericId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      await FirebaseFirestore.instance.collection('users').doc(numericId).set({
        'status': 'Offline',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else if (state == AppLifecycleState.resumed) {
      _wifiService.checkAndUpdatetWifiStatus();
      await FirebaseFirestore.instance.collection('users').doc(numericId).set({
        'status': 'Online',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2B2A),
        elevation: 2,
        automaticallyImplyLeading: false,
        title: const Text(
          'PESAN',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        actions: [
          IconButton(
  icon: const Icon(Icons.edit_note_outlined, color: Colors.white70, size: 28),
  onPressed: () {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const SelectContactScreen()),
    );
  },
),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('chats')
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
   if (snapshot.connectionState == ConnectionState.waiting) {
     return const Center(child: CircularProgressIndicator(color: Color(0xFFAB873A)));
   }

   Map<String, Map<String, dynamic>> roomsMap = {};
   Set<String> roomsWithMyActivity = {}; // Pass 1: Mencatat ruangan yang melibatkan user ini

   if (snapshot.hasData) {
     // Pass 1: Identifikasi room apa saja yang pernah diinteraksi oleh user yang sedang login
     for (var doc in snapshot.data!.docs) {
       var data = doc.data() as Map<String, dynamic>;
       String roomName = data['room'] ?? 'Tanpa Nama';
       String? senderUid = data['senderUid'];
       String? receiverUid = data['receiverUid'];

       if (senderUid == currentUser?.uid || receiverUid == currentUser?.uid) {
         roomsWithMyActivity.add(roomName);
       }
     }

     // Pass 2: Masukkan ke roomsMap HANYA jika user memiliki akses/aktivitas di room tersebut
     for (var doc in snapshot.data!.docs) {
       var data = doc.data() as Map<String, dynamic>;
       String roomName = data['room'] ?? 'Tanpa Nama';
       bool isGroup = roomName.toLowerCase().contains('grup') || (data['isGroup'] == true);
       String? senderUid = data['senderUid'];
       String? receiverUid = data['receiverUid'];

       // Aturan Ketat:
       // 1. Jika chat pribadi, wajib melibatkan user yang login.
       // 2. Jika grup, user yang login harus sudah pernah nimbrung/berinteraksi di grup tersebut.
       if (!isGroup) {
         if (senderUid != currentUser?.uid && receiverUid != currentUser?.uid) {
           continue;
         }
       } else {
         if (!roomsWithMyActivity.contains(roomName)) {
           continue;
         }
       }

       if (!roomsMap.containsKey(roomName)) {
         String timeString = "--:--";
         if (data['timestamp'] != null) {
           DateTime dt = (data['timestamp'] as Timestamp).toDate();
           timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
         }

         roomsMap[roomName] = {
           "id": doc.id,
           "name": roomName,
           "message": data['type'] == 'image' ? '📸 Gambar' : (data['type'] == 'file' ? '📁 File' : (data['text'] ?? '')),
           "time": timeString,
           "isGroup": isGroup,
           "isUnread": (data['isRead'] == false || data['isRead'] == null) && senderUid != currentUser?.uid,
           "categoryId": data['categoryId'],
           "isFavorite": data['isFavorite'] ?? false,
           "receiverUid": receiverUid,
         };
       } else {
         if ((data['isRead'] == false || data['isRead'] == null) && senderUid != currentUser?.uid) {
           roomsMap[roomName]!['isUnread'] = true;
         }
       }
     }
   }

   List<Map<String, dynamic>> masterChatList = roomsMap.values.toList();

   List<Map<String, dynamic>> filteredChatList = [];
   if (_selectedTabFilter == 0) {
     filteredChatList = masterChatList;
   } else if (_selectedTabFilter == 1) {
     filteredChatList = masterChatList.where((chat) => chat['isUnread'] == true).toList();
   } else if (_selectedTabFilter == 2) {
     filteredChatList = masterChatList.where((chat) => chat['isGroup'] == true).toList();
   } else if (_selectedTabFilter == 3) {
     filteredChatList = masterChatList.where((chat) => chat['isFavorite'] == true).toList();
   } else {
     List<String> categoryList = masterChatList
         .map((chat) => chat['categoryId']?.toString())
         .where((id) => id != null && id.isNotEmpty)
         .cast<String>()
         .toSet()
         .toList();

     if (_selectedTabFilter - 4 >= categoryList.length) {
       _selectedTabFilter = 0;
       filteredChatList = masterChatList;
     } else {
       String selectedCategoryName = categoryList[_selectedTabFilter - 4];
       filteredChatList = masterChatList.where((chat) => chat['categoryId'] == selectedCategoryName).toList();
     }
   }

   int unreadCount = masterChatList.where((chat) => chat['isUnread'] == true).length;

   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 16.0),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const SizedBox(height: 15),
         SingleChildScrollView(
           scrollDirection: Axis.horizontal,
           child: Row(
             children: [
               _buildSketchTabButton("SEMUA", indexTarget: 0),
               _buildSketchTabButton("BELUM DIBACA ($unreadCount)", indexTarget: 1),
               _buildSketchTabButton("GRUP", indexTarget: 2),
               _buildSketchTabButton("FAVORIT", indexTarget: 3),
               ...(() {
                 final Set<String> customCategories = {};
                 if (snapshot.hasData) {
                   for (var doc in snapshot.data!.docs) {
                     final data = doc.data() as Map<String, dynamic>;
                     if (data['categoryId'] != null && data['categoryId'].toString().isNotEmpty) {
                       customCategories.add(data['categoryId'].toString());
                     }
                   }
                 }

                 int currentIndex = 4;
                 return customCategories.map((catName) {
                   final int target = currentIndex++;
                   return Padding(
                     padding: const EdgeInsets.only(left: 8.0),
                     child: GestureDetector(
                       onLongPress: () => _hapusKategori(catName),
                       child: Tooltip(
                         message: "Tekan lama untuk menghapus kategori ini",
                         child: _buildSketchTabButton(catName, indexTarget: target),
                       ),
                     ),
                   );
                 }).toList();
               }()),
             ],
           ),
         ),
         const SizedBox(height: 15),
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
                     final String roomName = chat['name'];
                     if (_hiddenChats.contains(roomName)) {
                       return const SizedBox.shrink();
                     }
                     final bool isLocked = _lockedChats.contains(roomName);

                     return InkWell(
                       onTap: () {
                         if (isLocked) {
                           _showPinDialog(context, roomName, chat['isGroup'], chat['receiverUid']);
                         } else {
                           _markChatAsRead(roomName);
                           if (chat['isGroup'] == true) {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(groupName: roomName)));
                           } else {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(
                               name: roomName,
                               chatId: roomName,
                               receiverUid: chat['receiverUid'],
                             )));
                           }
                         }
                       },
                       onLongPress: () {
                         _showChatOptionsSheet(context, chat);
                       },
                       child: Column(
                         children: [
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 12.0),
                             child: Row(
                               children: [
                                 Container(
                                   width: 48,
                                   height: 48,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     color: Colors.white,
                                     border: Border.all(color: const Color(0xFFAB873A), width: 1.5),
                                     boxShadow: [
                                       BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                     ]
                                   ),
                                   child: Icon(
                                     chat['isGroup'] ? Icons.group_outlined : Icons.person_outline_rounded,
                                     color: const Color(0xFFAB873A),
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
                                           Row(
                                             children: [
                                               Text(
                                                 roomName.toUpperCase(),
                                                 style: const TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold, fontSize: 15),
                                               ),
                                               if (isLocked) ...[
                                                 const SizedBox(width: 6),
                                                 const Icon(Icons.lock, size: 14, color: Color(0xFFD49A3B)),
                                               ]
                                             ],
                                           ),
                                           Text(
                                             chat['time'],
                                             style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.4), fontSize: 11),
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 6),
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Expanded(
                                             child: Text(
                                               isLocked ? '🔒 Obrolan ini dikunci' : chat['message'],
                                               style: TextStyle(
                                                 color: isLocked
                                                     ? Colors.black38
                                                     : (chat['isUnread'] == true ? const Color(0xFF2C2C2C) : Colors.black54),
                                                 fontSize: 13,
                                                 fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
                                                 fontWeight: chat['isUnread'] == true ? FontWeight.bold : FontWeight.normal,
                                               ),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           if (chat['isUnread'] == true && !isLocked)
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
   );
 }
)
    );
  }

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
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
