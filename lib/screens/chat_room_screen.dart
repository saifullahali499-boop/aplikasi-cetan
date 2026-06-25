import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

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

  final int _appId = 1301579572; 
  final String _appSign = "fb312780b8fe4320f92e5691be0c3dbb1c5a2c86c425c46214858c0a59c16bcb";

  Widget? _localViewWidget; // Tempat menaruh gambar wajah Anda sendiri
  int? _localViewID;

  @override
  void initState() {
    super.initState();
    _initZegoEngine();
  }

  void _initZegoEngine() async {
    ZegoEngineProfile profile = ZegoEngineProfile(
      _appId,
      ZegoScenario.Default,
      appSign: _appSign,
    );
    await ZegoExpressEngine.createEngineWithProfile(profile);
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
        'sender': currentUser.displayName ?? 'Ali (Anda)',
        'senderUid': currentUser.uid, 
        'timestamp': FieldValue.serverTimestamp(),
        'room': widget.name,
        'isRead': false, 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    }
  }

  // FUNGSI VIDEO CALL DENGAN TAMPILAN KAMERA NYATA
  void _startCall(bool isVideo) async {
    String type = isVideo ? "Video Call" : "Telepon Suara";
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String roomCallId = widget.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    
    // 1. Login ke Room Zego
    ZegoUser user = ZegoUser(currentUser.uid, currentUser.displayName ?? "User");
    await ZegoExpressEngine.instance.loginRoom(roomCallId, user);

    // 2. Jika memilih Video, buat kotak cermin untuk menampilkan kamera depan Chromebook
    if (isVideo) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        setState(() {
          _localViewID = viewID;
          // Membuat tampilan lokal kamera
          ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
          ZegoExpressEngine.instance.startPreview(canvas: canvas);
        });
      }).then((widgetView) {
        setState(() {
          _localViewWidget = widgetView;
        });
      });
    }

    // 3. Mulai siaran ke internet
    String streamId = "${roomCallId}_${currentUser.uid}_stream";
    await ZegoExpressEngine.instance.startPublishingStream(streamId);

    // 4. Tampilkan Pop-up Layar Panggilan beserta Kotak Kamera Anda
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E3F24),
            title: Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // JIKA VIDEO CALL, TAMPILKAN KOTAK KAMERA AKTIF NYATA
                if (isVideo && _localViewWidget != null)
                  Container(
                    width: 220,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _localViewWidget, // GAMBAR KAMERA ANDA MUNCUL DI SINI
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
                const Text('Saluran terhubung & memancar...', style: TextStyle(color: Colors.amber, fontSize: 12)),
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
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String subtitleStatus = 'Terakhir dilihat kemarin jam 18:20';
    if (widget.name.contains('ISTRIKU')) {
      subtitleStatus = 'Terakhir dilihat hari ini jam 21:45';
    } else if (widget.name.contains('Grup')) {
      subtitleStatus = 'Budi, Santi, Anda'; 
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.3, 0.4), 
          radius: 1.5, 
          colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                    backgroundColor: Colors.white12,
                    child: Icon(widget.name.contains('Grup') ? Icons.group_outlined : Icons.person, color: Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          subtitleStatus,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
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
              tooltip: 'Telepon Suara',
              onPressed: () => _startCall(false),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Colors.white70),
              tooltip: 'Video Call',
              onPressed: () => _startCall(true),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .where('room', isEqualTo: widget.name)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white38));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada goresan kapur di sini...',
                        style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(25)),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Goreskan pesan...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, child) {
                      return CircleAvatar(
                        backgroundColor: Colors.white12,
                        child: IconButton(
                          icon: Icon(value.text.trim().isEmpty ? Icons.mic_none : Icons.send, color: Colors.white70, size: 20),
                          onPressed: _sendMessage,
                        ),
                      );
                    },
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
    bool isRead = chat['isRead'] ?? false; 

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF8B5A2B) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 14 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 14),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    chat['sender'] ?? 'Anonim',
                    style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1E3F24),
                    fontSize: 15
                  )
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe ? Colors.white54 : Colors.black38,
                        fontSize: 10
                      )
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isRead 
                              ? const Color(0xFF1E3F24)  
                              : const Color(0xFF5C3A21), 
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          isRead ? 'D' : 'T', 
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
    String phone = name.contains('Grup') ? 'Grup Obrolan (3 Anggota)' : '+62 857-9912-34XX';
    String statusKapur = name.contains('ISTRIKU')
        ? 'Sedang masak di dapur... jangan diganggu 🍳'
        : name.contains('Grup')
            ? 'Tempat berkumpulnya alumni angkatan 1998'
            : 'Fokus belajar Flutter biar pinter! 💻';

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(-0.1, -0.2), radius: 1.5, colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
          title: const Text('Detail Papan Informasi', style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5A2B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(2, 4))],
                  ),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(color: const Color(0xFF1E3F24), borderRadius: BorderRadius.circular(14)),
                    child: Icon(name.contains('Grup') ? Icons.group_outlined : Icons.person_outline, size: 90, color: Colors.white60),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(phone, style: const TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickActionButton(Icons.message_outlined, 'Pesan'),
                  _buildQuickActionButton(Icons.call_outlined, 'Suara'),
                  _buildQuickActionButton(Icons.videocam_outlined, 'Video'),
                ],
              ),
              const SizedBox(height: 35),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CORETAN STATUS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(statusKapur, style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.white.withOpacity(0.02),
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.volume_off_outlined, color: Colors.white60),
                      title: const Text('Bisukan Notifikasi', style: TextStyle(color: Colors.white70)),
                      trailing: Switch(value: false, onChanged: (val) {}),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    const ListTile(
                      leading: Icon(Icons.block, color: Colors.redAccent),
                      title: Text('Blokir Kontak', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.06),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
