import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_info_screen.dart';

// === TAMBAHAN IMPORT BARU UNTUK MEDIA ===
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // 1. FUNGSI KIRIM TEKS BIASA (BAWAAN KAMU)
  void _sendMessage() async {
    final user = _auth.currentUser;
    if (_messageController.text.trim().isEmpty || user == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance.collection('chats').add({
      'room': widget.groupName,
      'text': messageText,
      'senderUid': user.uid,
      'senderName': user.displayName ?? user.email ?? 'Anggota Kapur',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'isRead': false,
    });

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // === 2. FUNGSI BARU: PROSES UPLOAD KE FIREBASE STORAGE ===
  Future<void> _uploadAndSendFile(Uint8List fileBytes, String fileName, String type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Notifikasi loading instan agar user tahu proses sedang berjalan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengirim media...'), duration: Duration(seconds: 2)),
      );

      // Membuat folder unik di Firebase Storage
      String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference storageRef = FirebaseStorage.instance.ref().child('chat_files/$uniqueName');

      // Upload data bytes (Aman untuk Android & Web)
      UploadTask uploadTask = storageRef.putData(fileBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Simpan metadata ke Firestore chats
      await FirebaseFirestore.instance.collection('chats').add({
        'room': widget.groupName,
        'text': type == 'image' ? '📷 Foto' : '📎 Dokumen: $fileName',
        'senderUid': user.uid,
        'senderName': user.displayName ?? user.email ?? 'Anggota Kapur',
        'timestamp': FieldValue.serverTimestamp(),
        'type': type, // nilainya nanti 'image' atau 'file'
        'fileUrl': downloadUrl, // Link unduh dari storage
        'isRead': false,
      });

      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint("Gagal mengunggah file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim file: $e")),
      );
    }
  }

  // === 3. FUNGSI BARU: MEMBUKA KAMERA ===
  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (image != null) {
      Uint8List fileBytes = await image.readAsBytes();
      await _uploadAndSendFile(fileBytes, image.name, 'image');
    }
  }

  // === 4. FUNGSI BARU: MEMILIH FILE / DOKUMEN DARI HP ===
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true, // Wajib true agar byte data terbaca sempurna
    );

    if (result != null && result.files.first.bytes != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;
      
      // Validasi ekstensi untuk menentukan jenis tampilan gelembung chat nanti
      String type = (fileName.toLowerCase().endsWith('.jpg') || 
                     fileName.toLowerCase().endsWith('.png') || 
                     fileName.toLowerCase().endsWith('.jpeg') ||
                     fileName.toLowerCase().endsWith('.webp') ||
                     fileName.toLowerCase().endsWith('.gif')) 
          ? 'image' 
          : 'file';

      await _uploadAndSendFile(fileBytes, fileName, type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Latar belakang abu-abu terang premium

      // === APPBAR HITAM CHARCOAL (MATCHING 100%) ===
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2B2A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GroupInfoScreen(groupName: widget.groupName)),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.group_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const Text(
                        'Tap untuk info grup',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupInfoScreen(groupName: widget.groupName)),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // === BODY STREAM CHAT ===
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

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderUid'] == currentUser?.uid;
                    final String senderName = data['senderName'] ?? 'Anonim';
                    final String text = data['text'] ?? '';
                    final bool isRead = data['isRead'] ?? false;
                    
                    // Deteksi tipe pesan dan ambil link file
                    final String messageType = data['type'] ?? 'text';
                    final String? fileUrl = data['fileUrl'];

                    // Format Jam & Menit
                    String timeString = "00:00";
                    if (data['timestamp'] != null) {
                      DateTime dt = (data['timestamp'] as Timestamp).toDate();
                      timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    }

                    // Pembeda Warna & Ekor Balon
                    Color bubbleColor = isMe ? const Color(0xFFE5BE5F) : const Color(0xFFECECE9);
                    Color textColor = const Color(0xFF1E1400);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF533B00),
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],

                            // === LOGIKA BARU UNTUK DISPLAY TIPE GELEMBUNG CHAT ===
                            if (messageType == 'image' && fileUrl != null) ...[
                              // TAMPILAN JIKA PESAN BERUPA GAMBAR
                              GestureDetector(
                                onTap: () async {
                                  final Uri url = Uri.parse(fileUrl);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      fileUrl,
                                      width: 200,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const SizedBox(
                                          width: 200,
                                          height: 180,
                                          child: Center(child: CircularProgressIndicator(color: Color(0xFFAB873A))),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (messageType == 'file' && fileUrl != null) ...[
                              // TAMPILAN JIKA PESAN BERUPA FILE DOKUMEN
                              InkWell(
                                onTap: () async {
                                  final Uri url = Uri.parse(fileUrl);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF533B00), size: 28),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          text.replaceFirst('📎 Dokumen: ', ''),
                                          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ] else ...[
                              // DEFAULT: TAMPILAN JIKA PESAN TEKS BIASA
                              Text(
                                text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.2,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(width: 40),
                                Text(
                                  timeString,
                                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 9),
                                ),
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
                    );
                  },
                );
              },
            ),
          ),

          // === BAR INPUT PESAN MATCHING 100% ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            color: const Color(0xFFF4F5F7),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black26, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFFAB873A), size: 22),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // === AKTIVASI TOMBOL ATTACH FILE ===
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Colors.black54, size: 24),
                    onPressed: _pickFile, // Menyambung ke handler file picker
                  ),
                  
                  // === AKTIVASI TOMBOL KAMERA ===
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54, size: 24),
                    onPressed: _openCamera, // Menyambung ke handler kamera asli HP
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