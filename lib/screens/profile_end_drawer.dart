import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// CONTOH HALAMAN CHAT (Pastikan mengirim receiverUid saat membuka halaman ini)
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? receiverUid;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.receiverUid,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.chatName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Area Percakapan Chat',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      endDrawer: ProfileEndDrawer(
        name: widget.chatName,
        chatId: widget.chatId,
        receiverUid: widget.receiverUid,
      ),
    );
  }
}

// KELAS DRAWER UTAMA
class ProfileEndDrawer extends StatefulWidget {
  final String name;
  final String chatId;
  final String? receiverUid;

  const ProfileEndDrawer({
    super.key,
    required this.name,
    required this.chatId,
    this.receiverUid,
  });

  @override
  State<ProfileEndDrawer> createState() => _ProfileEndDrawerState();
}

class _ProfileEndDrawerState extends State<ProfileEndDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        List<dynamic> favorites = userDoc.data()?['favoriteRooms'] ?? [];
        if (mounted) setState(() => _isFavorite = favorites.contains(widget.chatId));
      }
    } catch (e) {
      debugPrint("Gagal: $e");
    }
  }

  void _toggleFavorite() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() => _isFavorite = !_isFavorite);

    try {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'favoriteRooms': _isFavorite 
            ? FieldValue.arrayUnion([widget.chatId]) 
            : FieldValue.arrayRemove([widget.chatId])
      }, SetOptions(merge: true));
      if (mounted) _showSnackBar(_isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit');
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      if (mounted) _showSnackBar('Gagal memperbarui favorit');
    }
  }

  void _hideStatusFromContact() async {
  final currentUser = _auth.currentUser;
  
  if (currentUser == null) {
    if (mounted) _showSnackBar('Gagal: Anda belum login');
    return;
  }

  // Coba cari receiverUid secara otomatis dari database berdasarkan chatId (room)
  String? targetReceiverUid = widget.receiverUid;

  if (targetReceiverUid == null || targetReceiverUid.isEmpty) {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('room', isEqualTo: widget.chatId)
          .where('senderUid', isNotEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        targetReceiverUid = querySnapshot.docs.first.data()['senderUid'] as String?;
      }
    } catch (e) {
      debugPrint("Gagal mendeteksi receiverUid otomatis: $e");
    }
  }

  // Validasi akhir jika tetap tidak ketemu
  if (targetReceiverUid == null || targetReceiverUid.isEmpty) {
    if (mounted) _showSnackBar('Gagal: Tidak dapat menemukan UID kontak.');
    return;
  }

  // Simpan ke Firestore
  try {
    await _firestore.collection('users').doc(currentUser.uid).set({
      'hiddenStatusUsers': FieldValue.arrayUnion([targetReceiverUid])
    }, SetOptions(merge: true));
    
    if (mounted) _showSnackBar('Status berhasil disembunyikan dari kontak ini');
  } catch (e) {
    debugPrint("Firestore Error: $e");
    if (mounted) _showSnackBar('Gagal menyembunyikan status');
  }
}
  void _shareContact() {
    Clipboard.setData(ClipboardData(text: "Kontak: ${widget.name}\nID: ${widget.chatId}"));
    _showSnackBar('Info kontak disalin!');
  }

  void _executeAction(String type) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final chatQuery = await _firestore.collection('chats').where('room', isEqualTo: widget.chatId).limit(1).get();
      String? actualDocId = chatQuery.docs.isNotEmpty ? chatQuery.docs.first.id : null;

      if (type == 'KELUAR') {
        await _firestore.collection('chats').doc(actualDocId).update({'members': FieldValue.arrayRemove([currentUser.uid])});
        if (mounted) _showSnackBar('Anda telah keluar');
      } else if (type == 'BLOKIR' && widget.receiverUid != null) {
        await _firestore.collection('users').doc(currentUser.uid).set({'blockedUsers': FieldValue.arrayUnion([widget.receiverUid])}, SetOptions(merge: true));
        if (mounted) _showSnackBar('Kontak berhasil diblokir');
      } else if (type == 'LAPORKAN') {
        await _firestore.collection('reports').add({'reportedChatId': actualDocId, 'reportedBy': currentUser.uid, 'timestamp': FieldValue.serverTimestamp()});
        if (mounted) _showSnackBar('Laporan dikirim');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.name.contains('Grup');
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70), 
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Info Kontak', 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35, 
                        backgroundColor: Colors.white10, 
                        child: Icon(isGroup ? Icons.group : Icons.person, size: 35, color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name.toUpperCase(), 
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGroup ? 'Grup Aktif' : 'Kontak Personal', 
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildGroupContainer([
                    _buildListTile(
                      Icons.image_outlined, 
                      'Media, tautan, & dokumen', 
                      () => Navigator.push(context, MaterialPageRoute(builder: (c) => MediaLinksDocsScreen(roomName: widget.chatId))),
                    ),
                    _buildListTile(
                      Icons.star_outline, 
                      'Pesan berbintang', 
                      () => Navigator.push(context, MaterialPageRoute(builder: (c) => StarredMessagesScreen(roomName: widget.chatId))),
                    ),
                  ]),

                  _buildGroupContainer([
                    _buildListTile(
                      _isFavorite ? Icons.favorite : Icons.favorite_border, 
                      _isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit', 
                      _toggleFavorite, 
                    ),
                    _buildListTile(
                      Icons.share_outlined, 
                      'Bagikan kontak', 
                      _shareContact,
                    ),
                    _buildListTile(
                      Icons.visibility_off_outlined, 
                      'Sembunyikan Status dari ini', 
                      _hideStatusFromContact, 
                      subTitle: 'Orang ini tidak bisa melihat status Anda',
                    ),
                  ]),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), 
                    child: Text('DANGEROUS ACTIONS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  _buildGroupContainer([
                    _buildListTile(
                      Icons.block, 
                      isGroup ? 'Keluar dari grup' : 'Blokir Kontak', 
                      () => _showActionDialog(context, isGroup ? 'Keluar?' : 'Blokir?', isGroup ? 'KELUAR' : 'BLOKIR'), 
                      iconColor: Colors.redAccent,
                    ),
                    _buildListTile(
                      Icons.thumb_down_outlined, 
                      'Laporkan Kontak', 
                      () => _showActionDialog(context, 'Laporkan Kontak?', 'LAPORKAN'), 
                      iconColor: Colors.redAccent,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap, {Color iconColor = const Color(0xFFD49A3B), String? subTitle}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subTitle != null ? Text(subTitle, style: const TextStyle(color: Colors.white54, fontSize: 11)) : null,
      onTap: onTap,
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF2D2D2D)),
    );
  }

  void _showActionDialog(BuildContext context, String title, String actionKey) {
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), 
        title: Text(title, style: const TextStyle(color: Colors.white)), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('BATAL')), 
          TextButton(onPressed: () { Navigator.pop(c); _executeAction(actionKey); }, child: const Text('YA')),
        ],
      ),
    );
  }
}

// KELAS PENDUKUNG MEDIA
class MediaLinksDocsScreen extends StatelessWidget {
  final String roomName;
  const MediaLinksDocsScreen({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Media, Tautan & Dokumen', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          'Belum ada media di room: $roomName',
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

// KELAS PENDUKUNG PESAN BERBINTANG
class StarredMessagesScreen extends StatelessWidget {
  final String roomName;
  const StarredMessagesScreen({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Pesan Berbintang', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('chats')
            .where('room', isEqualTo: roomName)      
            .where('isStarred', isEqualTo: true)     
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white70));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Belum ada pesan berbintang di room: $roomName',
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final starredMessages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: starredMessages.length,
            itemBuilder: (context, index) {
              final msgData = starredMessages[index].data() as Map<String, dynamic>;
              final messageText = msgData['text'] ?? '(Pesan tanpa teks)';
              final senderName = msgData['sender'] ?? 'Pengirim';

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(messageText, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(senderName, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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