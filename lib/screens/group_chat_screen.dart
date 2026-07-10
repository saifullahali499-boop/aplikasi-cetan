import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;

  const GroupChatScreen({super.key, required this.groupName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final user = _auth.currentUser;
    if (_messageController.text.trim().isEmpty || user == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Kirim ke koleksi 'chats' sesuai struktur database kamu
    await FirebaseFirestore.instance.collection('chats').add({
      'room': widget.groupName,
      'text': messageText,
      'senderUid': user.uid,
      'senderName': user.displayName ?? user.email ?? 'Anggota Kapur', // Nama pengirim
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'isRead': false,
    });

    // Otomatis scroll ke bawah
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Latar kertas sketsa
      
      // === APPBAR GAYA SKETSA CHARCOAL ===
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2B2A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ketuk di sini untuk info grup',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoScreen(groupName: widget.groupName),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // === BODY: STREAM CHAT GRUP ===
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('room', isEqualTo: widget.groupName)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFAB873A)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada kapur coretan di grup ini.\nMulai obrolan sekarang!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.4), fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Biar chat baru muncul dari bawah
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderUid'] == currentUser?.uid;
                    final String senderName = data['senderName'] ?? 'Anonim';
                    final String text = data['text'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Tampilkan nama orang lain di atas bubble chat
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  senderName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ),
                            
                            // Bubble Chat Gaya Sketsa Kertas
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF2D2B2A) : Colors.white,
                                borderRadius: BorderRadius.circular(14).copyWith(
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(14),
                                  topLeft: isMe ? const Radius.circular(14) : const Radius.circular(0),
                                ),
                                border: Border.all(
                                  color: isMe ? const Color(0xFF2D2B2A) : const Color(0xFF2C2C2C).withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : const Color(0xFF2C2C2C),
                                  fontSize: 14,
                                ),
                              ),
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

          // === BAGIAN BAWAH: INPUT TEKS ===
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.15)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan grup...',
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD49A3B), // Tombol Emas Sketsa
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}