import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_room_screen.dart';
import 'group_chat_screen.dart';
import '../services/wifi_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  int _selectedTabFilter = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  // Fungsi untuk menandai pesan di room ini sudah dibaca
  Future<void> _markChatAsRead(String roomName) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('room', isEqualTo: roomName)
          .get();

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        if (data['senderUid'] != currentUserId && (data['isRead'] == false || data['isRead'] == null)) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      print("Error marking chat as read: $e");
    }
  }

  // Dialog untuk memasukkan PIN saat membuka chat yang dikunci
  void _showPinDialog(BuildContext context, String roomName, bool isGroup) {
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: roomName)));
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('room', isEqualTo: roomName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFAB873A)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Belum ada pesan di obrolan ini.', style: TextStyle(color: Colors.black38)));
                    }

                    var docs = snapshot.data!.docs;
                    docs.sort((a, b) {
                      var tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      var tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (tA == null || tB == null) return 0;
                      return tA.compareTo(tB);
                    });

                    if (docs.length > 15) {
                      docs = docs.sublist(docs.length - 15);
                    }

                    final currentUserId = _auth.currentUser?.uid;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        bool isMe = data['senderUid'] == currentUserId;
                        String text = data['type'] == 'image' ? '📸 [Gambar]' : (data['type'] == 'file' ? '📁 [File]' : (data['text'] ?? ''));

                        String timeString = "--:--";
                        if (data['timestamp'] != null) {
                          DateTime dt = (data['timestamp'] as Timestamp).toDate();
                          timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                        }

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFD49A3B).withOpacity(0.15) : const Color(0xFFF6F6F4),
                              border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isMe ? 'Anda' : (data['senderName'] ?? 'Seseorang'),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(width: 20),
                                    Text(
                                      timeString,
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  text,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Opsi Bottom Sheet saat Long Press pada Chat Item
  void _showChatOptionsSheet(BuildContext context, String roomName) {
    bool isLocked = _lockedChats.contains(roomName);
    bool isHidden = _hiddenChats.contains(roomName);
    String? currentCategory = _chatCategories[roomName];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(roomName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C))),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300),
              
              // FITUR LIHAT CHAT: Hanya muncul jika chat TIDAK terkunci (!isLocked)
              if (!isLocked) ...[
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined, color: Color(0xFFD49A3B)),
                  title: const Text('Lihat Chat (Mode Baca Aman)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Baca tanpa ketahuan / tanpa centang biru', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  onTap: () {
                    Navigator.pop(context);
                    _showIncognitoPeekModal(context, roomName);
                  },
                ),
                const SizedBox(height: 4),
              ],
              
              // FITUR KUNCI / BUKA KUNCI OBROLAN
              ListTile(
                leading: Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: const Color(0xFFD49A3B)),
                title: Text(isLocked ? 'Buka Kunci Obrolan' : 'Kunci Obrolan Ini', style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  if (isLocked) {
                    // Wajib masukkan PIN jika ingin membuka kunci
                    _showUnlockPinDialog(context, roomName);
                  } else {
                    // Langsung kunci jika sebelumnya belum terkunci
                    _toggleLockChat(roomName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFFD49A3B),
                        content: Text('Obrolan berhasil dikunci 🔒'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 4),

              // FITUR TAMBAHKAN KATEGORI CHAT
              ListTile(
                leading: const Icon(Icons.label_outline_rounded, color: Color(0xFFD49A3B)),
                title: const Text('Tambahkan Kategori Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  currentCategory != null ? 'Kategori: $currentCategory' : 'Belum ada kategori',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryDialog(context, roomName);
                },
              ),
              const SizedBox(height: 4),

              // FITUR SEMBUNYIKAN / BATALKAN SEMBUNYI CHAT
              ListTile(
                leading: Icon(isHidden ? Icons.visibility_outlined : Icons.visibility_off_rounded, color: const Color(0xFFD49A3B)),
                title: Text(isHidden ? 'Batalkan Sembunyikan' : 'Sembunyikan Chat', style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (isHidden) {
                      _hiddenChats.remove(roomName);
                    } else {
                      _hiddenChats.add(roomName);
                    }
                  });

                  _saveHiddenChats();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFD49A3B),
                      content: Text(isHidden ? 'Obrolan dimunculkan kembali 👁️' : 'Obrolan berhasil disembunyikan 🙈'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  void _showCategoryDialog(BuildContext context, String roomName) {
    final TextEditingController categoryController = TextEditingController(
      text: _chatCategories[roomName] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Atur Kategori Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'Contoh: Penting, Tugas, Keluarga',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  if (categoryController.text.trim().isEmpty) {
                    _chatCategories.remove(roomName);
                  } else {
                    _chatCategories[roomName] = categoryController.text.trim();
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFD49A3B),
                    content: Text('Kategori obrolan berhasil diperbarui 🏷️'),
                  ),
                );
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'status': 'Offline',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else if (state == AppLifecycleState.resumed) {
      _wifiService.checkAndUpdatetWifiStatus();
      FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactListScreen()));
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

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String roomName = data['room'] ?? 'Tanpa Nama';

              if (!roomsMap.containsKey(roomName)) {
                String timeString = "--:--";
                if (data['timestamp'] != null) {
                  DateTime dt = (data['timestamp'] as Timestamp).toDate();
                  timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                }

                roomsMap[roomName] = {
                  "name": roomName,
                  "message": data['type'] == 'image' ? '📸 Gambar' : (data['type'] == 'file' ? '📁 File' : (data['text'] ?? '')),
                  "time": timeString,
                  "isGroup": roomName.toLowerCase().contains('grup'),
                  "isUnread": (data['isRead'] == false || data['isRead'] == null) && data['senderUid'] != currentUser?.uid,
                };
              } else {
                if ((data['isRead'] == false || data['isRead'] == null) && data['senderUid'] != currentUser?.uid) {
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
      return const SizedBox.shrink(); // Lewati dan jangan tampilkan
    }
                            final bool isLocked = _lockedChats.contains(roomName);

                            return InkWell(
                              onTap: () {
                                if (isLocked) {
                                  _showPinDialog(context, roomName, chat['isGroup']);
                                } else {
                                  _markChatAsRead(roomName);
                                  if (chat['isGroup'] == true) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(groupName: roomName)));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(name: roomName)));
                                  }
                                }
                              },
                              onLongPress: () {
                                _showChatOptionsSheet(context, roomName);
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
                                            border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                            ]
                                          ),
                                          child: Icon(
                                            chat['isGroup'] ? Icons.group_outlined : Icons.person_outline_rounded,
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
        },
      ),
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

// === SCREEN PILIH KONTAK BARU ===
class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListViewState();
}

class _ContactListViewState extends State<ContactListScreen> {
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
                      "status": isGroup ? "Baru saja dibuat oleh Anda" : "Halo! Salat menggunakan CETAN.",
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
              Text('${_contacts.length} Kontak Tersedia', style: TextStyle(color: Color(0xFF2C2C2C).withOpacity(0.5), fontSize: 12)),
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
                hint: 'Tulis nama teman...',
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
                          if (contact['name']!.contains('Grup')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GroupChatScreen(groupName: contact['name']!))
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChatRoomScreen(name: contact['name']!))
                            );
                          }
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
