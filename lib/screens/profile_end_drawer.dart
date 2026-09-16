import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ChatRoomScreen extends StatelessWidget {
  final String chatId, chatName;
  final String? receiverUid;
  ChatRoomScreen({super.key, required this.chatId, required this.chatName, this.receiverUid});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(chatName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
      body: const Center(child: Text('Area Percakapan Chat', style: TextStyle(color: Colors.white54))),
      endDrawer: ProfileEndDrawer(name: chatName, chatId: chatId, receiverUid: receiverUid),
    );
  }
}

class ProfileEndDrawer extends StatefulWidget {
  final String name, chatId;
  final String? receiverUid;
  const ProfileEndDrawer({super.key, required this.name, required this.chatId, this.receiverUid});

  @override
  State<ProfileEndDrawer> createState() => _ProfileEndDrawerState();
}

class _ProfileEndDrawerState extends State<ProfileEndDrawer> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isFavorite = false;
  bool _isHiddenStatus = false;
  bool _isLoadingStatus = true; // Indikator pemuatan status
  late String _numericId;
  String? _resolvedTargetUid;

  @override
  void initState() {
    super.initState();
    _numericId = widget.receiverUid?.isNotEmpty == true ? widget.receiverUid! : widget.chatId;
    _resolvedTargetUid = widget.receiverUid;
    _loadInitialData();
    _fetchContactNumericId();
  }

  void _loadInitialData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Jika receiverUid kosong, cari targetUid dari koleksi chats terlebih dahulu
      if (_resolvedTargetUid == null || _resolvedTargetUid!.isEmpty) {
        final chat = await _firestore.collection('chats')
            .where('room', isEqualTo: widget.chatId)
            .where('senderUid', isNotEqualTo: user.uid)
            .limit(1)
            .get();
        if (chat.docs.isNotEmpty) {
          _resolvedTargetUid = chat.docs.first.data()['senderUid'];
        }
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        List favorites = data['favoriteRooms'] ?? [];
        List hiddenList = data['hiddenStatusUsers'] ?? [];

        setState(() {
          _isFavorite = favorites.contains(widget.chatId);
          if (_resolvedTargetUid != null) {
            _isHiddenStatus = hiddenList.contains(_resolvedTargetUid);
          }
          _isLoadingStatus = false; // Data selesai dimuat
        });
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  void _fetchContactNumericId() async {
    final user = _auth.currentUser;
    try {
      if (widget.receiverUid?.isNotEmpty == true) {
        final doc = await _firestore.collection('users').where('uid', isEqualTo: widget.receiverUid).limit(1).get();
        if (doc.docs.isNotEmpty && mounted) {
          setState(() => _numericId = doc.docs.first.data()['numericId'] ?? doc.docs.first.id);
          return;
        }
      }
      if (user != null) {
        final contact = await _firestore.collection('users').doc(user.uid).collection('contacts').where('name', isEqualTo: widget.name).limit(1).get();
        if (contact.docs.isNotEmpty && mounted) {
          setState(() => _numericId = contact.docs.first.data()['numericId'] ?? contact.docs.first.id);
        }
      }
    } catch (e) {
      debugPrint("Error fetching ID: $e");
    }
  }

  void _toggleHideStatus(bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final targetUid = _resolvedTargetUid ?? widget.receiverUid ?? widget.chatId;

    // 🔥 Optimistic Update: Ubah state lokal seketika agar tombol langsung merespons
    setState(() => _isHiddenStatus = value);

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'hiddenStatusUsers': value ? FieldValue.arrayUnion([targetUid]) : FieldValue.arrayRemove([targetUid])
      }, SetOptions(merge: true));
      
      _showSnackBar(value ? 'Status disembunyikan dari kontak ini' : 'Status ditampilkan kembali');
    } catch (e) {
      // Rollback jika gagal menyimpan ke Firestore
      setState(() => _isHiddenStatus = !value);
      _showSnackBar('Gagal memperbarui status');
    }
  }

  void _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isFavorite = !_isFavorite);
    await _firestore.collection('users').doc(user.uid).set({
      'favoriteRooms': _isFavorite ? FieldValue.arrayUnion([widget.chatId]) : FieldValue.arrayRemove([widget.chatId])
    }, SetOptions(merge: true));
    _showSnackBar(_isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit');
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('QR ID: ${widget.name}', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                width: 200, height: 200,
                child: QrImageView(data: _numericId, version: QrVersions.auto, size: 200.0),
              ),
            ),
            const SizedBox(height: 16),
            Text('ID Angka: $_numericId', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup', style: TextStyle(color: Color(0xFFD49A3B))))],
      ),
    );
  }

  void _executeAction(String type) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final chat = await _firestore.collection('chats').where('room', isEqualTo: widget.chatId).limit(1).get();
    final docId = chat.docs.isNotEmpty ? chat.docs.first.id : null;

    if (type == 'KELUAR' && docId != null) {
      await _firestore.collection('chats').doc(docId).update({'members': FieldValue.arrayRemove([user.uid])});
    } else if (type == 'BLOKIR' && widget.receiverUid != null) {
      await _firestore.collection('users').doc(user.uid).set({'blockedUsers': FieldValue.arrayUnion([widget.receiverUid])}, SetOptions(merge: true));
    }
    _showSnackBar('Aksi berhasil diproses');
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
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  const Text('Info Kontak', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 35, backgroundColor: Colors.white10, child: Icon(isGroup ? Icons.group : Icons.person, size: 35, color: Colors.white70)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(widget.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                if (!isGroup)
                                  InkWell(
                                    onTap: () => _showQrDialog(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.qr_code_2, color: Color(0xFFD49A3B), size: 26)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(isGroup ? 'Grup Aktif' : 'ID Angka: $_numericId', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCard([
                    _buildTile(Icons.image_outlined, 'Media, tautan, & dokumen', () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaLinksDocsScreen(roomName: widget.chatId)))),
                    _buildTile(Icons.star_outline, 'Pesan berbintang', () => Navigator.push(context, MaterialPageRoute(builder: (_) => StarredMessagesScreen(roomName: widget.chatId)))),
                  ]),
                  _buildCard([
                    _buildTile(_isFavorite ? Icons.favorite : Icons.favorite_border, _isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit', _toggleFavorite),
                    _buildTile(Icons.share_outlined, 'Bagikan kontak', () => {Clipboard.setData(ClipboardData(text: "ID: $_numericId")), _showSnackBar('Disalin!')}),
                    _buildTile(
                      Icons.visibility_off_outlined, 
                      'Sembunyikan Status', 
                      null, 
                      subTitle: 'Orang ini tidak bisa melihat status Anda',
                      trailing: _isLoadingStatus
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD49A3B)))
                          : Switch(
                              value: _isHiddenStatus,
                              activeColor: const Color(0xFFD49A3B),
                              onChanged: _toggleHideStatus,
                            ),
                    ),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('DANGEROUS ACTIONS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                  _buildCard([
                    _buildTile(Icons.block, isGroup ? 'Keluar dari grup' : 'Blokir Kontak', () => _showConfirm(isGroup ? 'KELUAR' : 'BLOKIR'), iconColor: Colors.redAccent),
                    _buildTile(Icons.thumb_down_outlined, 'Laporkan Kontak', () => _showConfirm('LAPORKAN'), iconColor: Colors.redAccent),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: Column(children: children));
  
  Widget _buildTile(IconData icon, String title, VoidCallback? onTap, {Color iconColor = const Color(0xFFD49A3B), String? subTitle, Widget? trailing}) => 
    ListTile(
      leading: Icon(icon, color: iconColor), 
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), 
      subtitle: subTitle != null ? Text(subTitle, style: const TextStyle(color: Colors.white54, fontSize: 11)) : null, 
      trailing: trailing,
      onTap: onTap,
    );

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF2D2D2D)));
  
  void _showConfirm(String action) => showDialog(context: context, useRootNavigator: true, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: Text('Konfirmasi $action', style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('BATAL')), TextButton(onPressed: () { Navigator.pop(c); _executeAction(action); }, child: const Text('YA'))]));
}

class MediaLinksDocsScreen extends StatelessWidget {
  final String roomName;
  const MediaLinksDocsScreen({super.key, required this.roomName});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF121212), appBar: AppBar(title: const Text('Media & Dokumen', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF1E1E1E), iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: Text('Room: $roomName', style: const TextStyle(color: Colors.white54))));
}

class StarredMessagesScreen extends StatelessWidget {
  final String roomName;
  const StarredMessagesScreen({super.key, required this.roomName});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').where('room', isEqualTo: roomName).where('isStarred', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(title: const Text('Pesan Berbintang', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF1E1E1E), iconTheme: const IconThemeData(color: Colors.white)),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator(color: Colors.white70))
              : snapshot.data!.docs.isEmpty
                  ? const Center(child: Text('Belum ada pesan berbintang', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (_, i) {
                        final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber), 
                          title: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white)), 
                          subtitle: Text(data['sender'] ?? '', style: const TextStyle(color: Colors.white38)),
                        );
                      },
                    ),
        );
      },
    );
  }
}