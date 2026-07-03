import 'dart:async'; // Ditambahkan untuk mengelola sinkronisasi status baca otomatis
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatRoomScreen extends StatefulWidget {
  final String name;
  const ChatRoomScreen({super.key, required this.name});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final int _appId = 1301579572;
  final String _appSign = "fb312780b8fe4320f92e5691be0c3dbb1c5a2c86c425c46214858c0a59c16bcb";

  Widget? _localViewWidget;
  int? _localViewID;
  StreamSubscription<QuerySnapshot>? _chatSubscription; // Untuk memantau pesan unread secara real-time

  @override
  void initState() {
    super.initState();
    _initZegoEngine();
    _listenToMessages(); // Mengaktifkan fitur deteksi buka pesan otomatis
  }

  void _initZegoEngine() async {
    ZegoEngineProfile profile = ZegoEngineProfile(
      _appId,
      ZegoScenario.Default,
      appSign: _appSign,
    );
    await ZegoExpressEngine.createEngineWithProfile(profile);
  }

  // Otomatis mengubah status pesan lawan bicara menjadi 'sudah dibuka/isRead: true' saat kita masuk ruang chat
  void _listenToMessages() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _chatSubscription = _firestore
        .collection('chats')
        .where('room', isEqualTo: widget.name)
        .snapshots()
        .listen((snapshot) {
      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var doc = change.doc;
          // Jika pesan berasal dari orang lain dan statusnya belum dibaca, ubah jadi sudah dibaca
          if (doc['senderUid'] != currentUser.uid && (doc['isRead'] == false || doc['isRead'] == null)) {
            batch.update(doc.reference, {'isRead': true});
            hasUpdates = true;
          }
        }
      }

      if (hasUpdates) {
        batch.commit().catchError((e) {
          print("Gagal memperbarui status baca: $e");
        });
      }
    });
  }

  // Ambil Gambar dari Kamera
  void _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) {
        Uint8List bytes = await image.readAsBytes();
        _uploadMedia(bytes, image.name, 'image');
      }
    } catch (e) {
      _showSnackBar('Gagal membuka kamera: $e');
    }
  }

  // Ambil File / Gambar dari Galeri lewat Klip Kertas
  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.single.bytes != null) {
        PlatformFile file = result.files.single;
        String type = 'file';
      
        // Cek jika file ekstensi berupa gambar
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.extension?.toLowerCase())) {
          type = 'image';
        }
      
        _uploadMedia(file.bytes!, file.name, type);
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file: $e');
    }
  }

  // Proses Upload ke Firebase Storage
  void _uploadMedia(Uint8List bytes, String fileName, String type) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _showSnackBar('Sedang mengunggah file...');

    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('chat_media/${timestamp}_$fileName');
    
      UploadTask uploadTask = ref.putData(bytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('chats').add({
        'text': fileName,
        'url': downloadUrl,
        'type': type,
        'sender': currentUser.displayName ?? 'Ali (Anda)',
        'senderUid': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'room': widget.name,
        'isRead': false,
      });
    } catch (e) {
      _showSnackBar('Gagal mengunggah ke Storage: $e\n(Pastikan Rules Firebase Storage Anda sudah di-set Public)');
    }
  }

  void _sendMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    if (_messageController.text.trim().isEmpty) return;
  
    String messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestore.collection('chats').add({
        'text': messageText,
        'type': 'text',
        'sender': currentUser.displayName ?? 'Ali (Anda)',
        'senderUid': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'room': widget.name,
        'isRead': false,
      });
    } catch (e) {
      _showSnackBar('Gagal mengirim pesan: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startCall(bool isVideo) async {
    String type = isVideo ? "Video Call" : "Telepon Suara";
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String roomCallId = widget.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
  
    ZegoUser user = ZegoUser(currentUser.uid, currentUser.displayName ?? "User");
    await ZegoExpressEngine.instance.loginRoom(roomCallId, user);

    if (isVideo) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        setState(() {
          _localViewID = viewID;
          ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
          ZegoExpressEngine.instance.startPreview(canvas: canvas);
        });
      }).then((widgetView) {
        setState(() {
          _localViewWidget = widgetView;
        });
      });
    }

    String streamId = "${roomCallId}_${currentUser.uid}_stream";
    await ZegoExpressEngine.instance.startPublishingStream(streamId);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVideo && _localViewWidget != null)
                  Container(
                    width: 220,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFAB873A), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _localViewWidget,
                    ),
                  )
                else
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, size: 50, color: Colors.white60),
                  ),
                const SizedBox(height: 16),
                Text('Kamar Aktif: $roomCallId', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 8),
                const Text('Saluran terhubung...', style: TextStyle(color: Color(0xFFD2B46A), fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Tutup', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (isVideo) {
                    await ZegoExpressEngine.instance.stopPreview();
                    if (_localViewID != null) {
                      await ZegoExpressEngine.instance.destroyCanvasView(_localViewID!);
                    }
                  }
                  await ZegoExpressEngine.instance.stopPublishingStream();
                  await ZegoExpressEngine.instance.logoutRoom(roomCallId);
                  Navigator.pop(context);
                },
              )
            ],
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatSubscription?.cancel(); // Menghentikan pendengar data agar ram hemat daya
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String subtitleStatus = 'Transformative Teal';

    return Container(
      color: const Color(0xFFF4F5F7),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D2B2A),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DetailProfilScreen(name: widget.name)));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Icon(widget.name.contains('Grup') ? Icons.group_outlined : Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text(
                          subtitleStatus,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.phone_outlined, color: Colors.white70),
              onPressed: () => _startCall(false),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Colors.white70),
              onPressed: () => _startCall(true),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .where('room', isEqualTo: widget.name)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFAB873A)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada pesan di sini...',
                        style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                    
                      String timeString = "--:--";
                      if (data['timestamp'] != null) {
                        DateTime dt = (data['timestamp'] as Timestamp).toDate();
                        timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                      }

                      return _buildBubble(context, data, timeString);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black38, width: 1.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.black),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: "Message...",
                          hintStyle: const TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFAB873A)),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // BUTTON KLIP KERTAS AKTIF
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.black54),
                    onPressed: _pickFile,
                  ),
                  // BUTTON KAMERA AKTIF
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                    onPressed: _pickImageFromCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, Map<String, dynamic> chat, String time) {
    bool isMe = chat['senderUid'] == _auth.currentUser?.uid;
    String text = chat['text'] ?? '';
    String type = chat['type'] ?? 'text';
    String url = chat['url'] ?? '';
    
    // Status pesan (true = sudah dibuka, false = baru terkirim/belum dibuka)
    bool isRead = chat['isRead'] ?? false;

    Color bubbleColor = isMe ? const Color(0xFFE5BE5F) : const Color(0xFFECECE9);
    Color textColor = const Color(0xFF1E1400);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    chat['sender'] ?? 'Anonim',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF533B00), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                ],
                // LOGIKA TAMPILAN MEDIA PINTAR
                if (type == 'image')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar ⚠️'),
                      ),
                    ),
                  )
                else if (type == 'file')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file, color: Color(0xFF1E1400), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    text,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.2)
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      time,
                      style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 9)
                    ),
                    // LOGIKA BARU: Jika ini pesan kita DAN belum dibuka, tampilkan titik bulat kecil warna abu gela (black54)
                    if (isMe && !isRead) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.black54,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailProfilScreen extends StatelessWidget {
  final String name;
  const DetailProfilScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2B2A),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: const Text('Detail Profil', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFAB873A),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2B2A))),
          ],
        ),
      ),
    );
  }
}