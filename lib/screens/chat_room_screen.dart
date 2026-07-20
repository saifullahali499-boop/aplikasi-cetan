import 'profile_end_drawer.dart'; 
import 'dart:async';
import 'dart:typed_data';
import 'dart:io' as io; // Untuk memproses file di HP
import 'package:flutter/foundation.dart' show kIsWeb; // Cek apakah mode web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart'; // Library Rekam suara
import 'package:audioplayers/audioplayers.dart'; // Library Putar suara
import 'package:http/http.dart' as http; // Pendukung pembaca audio di Web

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
 StreamSubscription<QuerySnapshot>? _chatSubscription;

 Map<String, dynamic>? _replyingMessage;
 Map<String, dynamic>? _editingMessage;
 String? _editingMessageId;

 // 🟢 BARU: State kontrol untuk Voice Note
 bool _isRecording = false;
 final AudioRecorder _audioRecorder = AudioRecorder();

 late Stream<QuerySnapshot> _chatsStream;

 @override
 void initState() {
   super.initState();
   _initZegoEngine();
   _listenToMessages();

   _chatsStream = _firestore
       .collection('chats')
       .where('room', isEqualTo: widget.name)
       .orderBy('timestamp', descending: true)
       .snapshots();
 }

 void _initZegoEngine() async {
   ZegoEngineProfile profile = ZegoEngineProfile(
     _appId,
     ZegoScenario.Default,
     appSign: _appSign,
   );
   await ZegoExpressEngine.createEngineWithProfile(profile);
 }

 void _listenToMessages() {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;

   _chatSubscription = _firestore
       .collection('chats')
       .where('room', isEqualTo: widget.name)
       .where('isRead', isEqualTo: false)
       .snapshots()
       .listen((snapshot) {
     if (snapshot.docs.isEmpty) return;

     final batch = _firestore.batch();
     bool hasUpdates = false;

     for (var doc in snapshot.docs) {
       var data = doc.data() as Map<String, dynamic>;
       if (data['senderUid'] != currentUser.uid) {
         batch.update(doc.reference, {'isRead': true});
         hasUpdates = true;
       }
     }

     if (hasUpdates) {
       batch.commit().catchError((e) {
         print("Gagal memperbarui status baca: $e");
       });
     }
   });
 }

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

 void _pickFile() async {
   try {
     FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
     if (result != null && result.files.single.bytes != null) {
       PlatformFile file = result.files.single;
       String type = 'file';
       if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.extension?.toLowerCase())) {
         type = 'image';
       }
       _uploadMedia(file.bytes!, file.name, type);
     }
   } catch (e) {
     _showSnackBar('Gagal memilih file: $e');
   }
 }

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

     String? replyText = _replyingMessage != null ? _replyingMessage!['text'] : null;
     String? replySender = _replyingMessage != null ? _replyingMessage!['sender'] : null;

     await _firestore.collection('chats').add({
       'text': fileName,
       'url': downloadUrl,
       'type': type,
       'sender': currentUser.displayName ?? 'Ali (Anda)',
       'senderUid': currentUser.uid,
       'timestamp': FieldValue.serverTimestamp(),
       'room': widget.name,
       'isRead': false,
       'isStarred': false,
       'replyToText': replyText,
       'replyToSender': replySender,
     });

     setState(() { _replyingMessage = null; });
   } catch (e) {
     _showSnackBar('Gagal mengunggah: $e');
   }
 }

 // 🟢 BARU: Fungsi On/Off saklar Perekam Suara (Voice Note)
 void _toggleRecording() async {
   if (_isRecording) {
     // 1. Berhentikan rekaman
     final path = await _audioRecorder.stop();
     setState(() { _isRecording = false; });

     if (path != null) {
       _showSnackBar('Memproses rekaman suara...');
       try {
         Uint8List audioBytes;
         // Cek jenis perangkat (Web punya struktur penanganan Blob URL yang berbeda dengan HP biasa)
         if (kIsWeb) {
           final response = await http.get(Uri.parse(path));
           audioBytes = response.bodyBytes;
         } else {
           audioBytes = await io.File(path).readAsBytes();
         }
         
         // Kirim pecahan bytes ke Firebase Storage
         _uploadAudio(audioBytes);
       } catch (e) {
         _showSnackBar('Gagal memproses audio: $e');
       }
     }
   } else {
     // 2. Mulai rekaman baru (Minta izin Mic dulu)
     if (await _audioRecorder.hasPermission()) {
       await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: '');
       setState(() { _isRecording = true; });
     } else {
       _showSnackBar('Izin mikrofon ditolak oleh perangkat');
     }
   }
 }

 // 🟢 BARU: Fungsi unggah Voice Note ke Firebase Storage & Firestore
 void _uploadAudio(Uint8List bytes) async {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;
   _showSnackBar('Mengirim voice note...');

   try {
     String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
     Reference ref = FirebaseStorage.instance.ref().child('chat_audio/${timestamp}_vn.m4a');
     UploadTask uploadTask = ref.putData(bytes);
     TaskSnapshot snapshot = await uploadTask;
     String downloadUrl = await snapshot.ref.getDownloadURL();

     await _firestore.collection('chats').add({
       'text': '🎤 Voice Note',
       'url': downloadUrl,
       'type': 'audio', // Mengunci tipe data sebagai audio player
       'sender': currentUser.displayName ?? 'Ali (Anda)',
       'senderUid': currentUser.uid,
       'timestamp': FieldValue.serverTimestamp(),
       'room': widget.name,
       'isRead': false,
       'isStarred': false,
     });
   } catch (e) {
     _showSnackBar('Gagal mengirim Voice Note: $e');
   }
 }

 void _sendMessage() async {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;
   if (_messageController.text.trim().isEmpty) return;
   String messageText = _messageController.text.trim();

   if (_editingMessageId != null) {
     _updateMessage(messageText);
     return;
   }

   _messageController.clear();

   String? replyText = _replyingMessage != null ? _replyingMessage!['text'] : null;
   String? replySender = _replyingMessage != null ? _replyingMessage!['sender'] : null;

   try {
     await _firestore.collection('chats').add({
       'text': messageText,
       'type': 'text',
       'sender': currentUser.displayName ?? 'Ali (Anda)',
       'senderUid': currentUser.uid,
       'timestamp': FieldValue.serverTimestamp(),
       'room': widget.name,
       'isRead': false,
       'isStarred': false,
       'replyToText': replyText,
       'replyToSender': replySender,
     });

     setState(() { _replyingMessage = null; });
   } catch (e) {
     _showSnackBar('Gagal mengirim pesan: $e');
   }
 }

 void _updateMessage(String newText) async {
   if (_editingMessageId == null) return;
   _messageController.clear();

   try {
     await _firestore.collection('chats').doc(_editingMessageId).update({
       'text': newText,
     });

     setState(() {
       _editingMessage = null;
       _editingMessageId = null;
     });
     _showSnackBar('Pesan berhasil diperbarui');
   } catch (e) {
     _showSnackBar('Gagal memperbarui pesan: $e');
   }
 }

 void _showSchedulePicker() async {
   if (_messageController.text.trim().isEmpty) {
     _showSnackBar('Tulis pesan terlebih dahulu sebelum dijadwalkan!');
     return;
   }

   DateTime? pickedDate = await showDatePicker(
     context: context,
     initialDate: DateTime.now(),
     firstDate: DateTime.now(),
     lastDate: DateTime.now().add(const Duration(days: 365)),
     builder: (context, child) {
       return Theme(
         data: Theme.of(context).copyWith(
           colorScheme: const ColorScheme.light(primary: Color(0xFFAB873A)),
         ),
         child: child!,
       );
     },
   );

   if (pickedDate == null) return;

   if (!mounted) return;
   TimeOfDay? pickedTime = await showTimePicker(
     context: context,
     initialTime: TimeOfDay.now(),
   );

   if (pickedTime == null) return;

   DateTime scheduledDateTime = DateTime(
     pickedDate.year,
     pickedDate.month,
     pickedDate.day,
     pickedTime.hour,
     pickedTime.minute,
   );

   if (scheduledDateTime.isBefore(DateTime.now())) {
     _showSnackBar('Waktu yang dipilih sudah lewat!');
     return;
   }

   _sendScheduledMessage(scheduledDateTime);
 }

 void _sendScheduledMessage(DateTime sendAt) async {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;
   String messageText = _messageController.text.trim();
   _messageController.clear();
   setState(() {});

   try {
     await _firestore.collection('scheduled_chats').add({
       'text': messageText,
       'type': 'text',
       'sender': currentUser.displayName ?? 'Ali (Anda)',
       'senderUid': currentUser.uid,
       'timestamp': FieldValue.serverTimestamp(),
       'sendAt': Timestamp.fromDate(sendAt), 
       'room': widget.name,
       'isRead': false,
       'isStarred': false,
     });

     _showSnackBar('Pesan dijadwalkan untuk tanggal ${sendAt.day}/${sendAt.month} jam ${sendAt.hour.toString().padLeft(2, '0')}:${sendAt.minute.toString().padLeft(2, '0')}');
   } catch (e) {
     _showSnackBar('Gagal menjadwalkan pesan: $e');
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

 void _showChatMenu(BuildContext context, Map<String, dynamic> chat, String messageId, String time) {
   showModalBottomSheet(
     context: context,
     backgroundColor: const Color(0xFF2D2D2D),
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
     ),
     builder: (context) {
       bool isStarred = chat['isStarred'] ?? false;
       String text = chat['text'] ?? '';
       bool isMe = chat['senderUid'] == _auth.currentUser?.uid;
       String type = chat['type'] ?? 'text';

       return SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const SizedBox(height: 8),
             ListTile(
               leading: const Icon(Icons.reply, color: Colors.white70),
               title: const Text('Balas', style: TextStyle(color: Colors.white)),
               onTap: () {
                 Navigator.pop(context);
                 setState(() { _replyingMessage = chat; });
               },
             ),
             if (isMe && type == 'text')
               ListTile(
                 leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                 title: const Text('Edit Pesan', style: TextStyle(color: Colors.white)),
                 onTap: () {
                   Navigator.pop(context);
                   setState(() {
                     _editingMessage = chat;
                     _editingMessageId = messageId;
                     _messageController.text = text; 
                     _replyingMessage = null; 
                   });
                 },
               ),
             ListTile(
               leading: const Icon(Icons.forward, color: Colors.white70),
               title: const Text('Teruskan', style: TextStyle(color: Colors.white)),
               onTap: () {
                 Navigator.pop(context);
                 _showForwardDialog(context, chat);
               },
             ),
             ListTile(
               leading: const Icon(Icons.copy, color: Colors.white70),
               title: const Text('Salin', style: TextStyle(color: Colors.white)),
               onTap: () async {
                 Navigator.pop(context);
                 await Clipboard.setData(ClipboardData(text: text));
                 _showSnackBar('Pesan berhasil disalin!');
               },
             ),
             ListTile(
               leading: Icon(isStarred ? Icons.star : Icons.star_border, color: Colors.amber),
               title: Text(isStarred ? 'Hapus Bintang' : 'Beri Bintang', style: const TextStyle(color: Colors.white)),
               onTap: () async {
                 Navigator.pop(context);
                 await _firestore.collection('chats').doc(messageId).update({'isStarred': !isStarred});
                 _showSnackBar(isStarred ? 'Bintang dihapus' : 'Pesan telah dibintangi');
               },
             ),
             ListTile(
               leading: const Icon(Icons.info_outline, color: Colors.white70),
               title: const Text('Info', style: TextStyle(color: Colors.white)),
               onTap: () {
                 Navigator.pop(context);
                 _showInfoDialog(context, chat, time);
               },
             ),
             ListTile(
               leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
               title: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
               onTap: () {
                 Navigator.pop(context);
                 _showDeleteDialog(context, messageId);
               },
             ),
             const SizedBox(height: 8),
           ],
         ),
       );
     },
   );
 }

 void _showForwardDialog(BuildContext context, Map<String, dynamic> originalChat) {
   showDialog(
     context: context,
     builder: (context) {
       List<String> targetRooms = ['Grup Utama', 'Ali', 'Budi', 'Jessica', 'Manajer'];

       return AlertDialog(
         backgroundColor: const Color(0xFF2D2D2D),
         title: const Text('Teruskan pesan ke...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
         content: SizedBox(
           width: double.maxFinite,
           child: ListView.builder(
             shrinkWrap: true,
             itemCount: targetRooms.length,
             itemBuilder: (context, index) {
               String roomName = targetRooms[index];
               return ListTile(
                 leading: const Icon(Icons.forum_outlined, color: Color(0xFFAB873A)),
                 title: Text(roomName, style: const TextStyle(color: Colors.white)),
                 onTap: () async {
                   Navigator.pop(context);
                   final currentUser = _auth.currentUser;
                   if (currentUser == null) return;

                   try {
                     await _firestore.collection('chats').add({
                       'text': originalChat['text'],
                       'type': originalChat['type'] ?? 'text',
                       'url': originalChat['url'] ?? '',
                       'sender': currentUser.displayName ?? 'Ali (Anda)',
                       'senderUid': currentUser.uid,
                       'timestamp': FieldValue.serverTimestamp(),
                       'room': roomName,
                       'isRead': false,
                       'isStarred': false,
                     });
                     _showSnackBar('Pesan berhasil diteruskan ke $roomName!');
                   } catch (e) {
                     _showSnackBar('Gagal meneruskan: $e');
                   }
                 },
               );
             },
           ),
         ),
       );
     },
   );
 }

 void _showInfoDialog(BuildContext context, Map<String, dynamic> chat, String time) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       backgroundColor: const Color(0xFF2D2D2D),
       title: const Text("Info Pesan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text("Pengirim: ${chat['sender'] ?? 'Anonim'}", style: const TextStyle(color: Colors.white70)),
           const SizedBox(height: 8),
           Text("Waktu: Jam $time", style: const TextStyle(color: Colors.white70)),
           const SizedBox(height: 8),
           Text("Status: ${chat['isRead'] == true ? 'Sudah dibaca oleh lawan bicara' : 'Belum dibaca'}", style: const TextStyle(color: Colors.white70)),
         ],
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text("Tutup", style: TextStyle(color: Color(0xFFAB873A))),
         )
       ],
     ),
   );
 }

 void _showDeleteDialog(BuildContext context, String messageId) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       backgroundColor: const Color(0xFF2D2D2D),
       title: const Text("Hapus Pesan?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
       content: const Text("Apakah kamu yakin ingin menghapus pesan ini?", style: TextStyle(color: Colors.white70)),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text("Batal", style: TextStyle(color: Colors.white60)),
         ),
         TextButton(
           onPressed: () async {
             Navigator.pop(context);
             try {
               await _firestore.collection('chats').doc(messageId).delete();
             } catch (e) {
               _showSnackBar('Gagal menghapus pesan: $e');
             }
           },
           child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
         ),
       ],
     ),
   );
 }

 @override
 void dispose() {
   _messageController.dispose();
   _chatSubscription?.cancel();
   _audioRecorder.dispose(); // Matikan sensor mic saat keluar room
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
       endDrawer: ProfileEndDrawer(name: widget.name,chatId: widget.name,), 
       appBar: AppBar(
         backgroundColor: const Color(0xFF2D2B2A),
         elevation: 2,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back, color: Colors.white70),
           onPressed: () => Navigator.pop(context),
         ),
         title: Builder(
           builder: (innerContext) {
             return InkWell(
               onTap: () {
                 Scaffold.of(innerContext).openEndDrawer();
               },
               borderRadius: BorderRadius.circular(8),
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                 child: Row(
                   children: [
                     CircleAvatar(
                       radius: 18,
                       backgroundColor: Colors.white24,
                       child: Icon(
                         widget.name.contains('Grup') ? Icons.group_outlined : Icons.person,
                         color: Colors.white,
                         size: 20,
                       ),
                     ),
                     const SizedBox(width: 10),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             widget.name.toUpperCase(),
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                               letterSpacing: 0.5
                             ),
                           ),
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
             );
           },
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
               stream: _chatsStream,
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                     String messageId = docs[index].id;

                     String timeString = "--:--";
                     if (data['timestamp'] != null) {
                       DateTime dt = (data['timestamp'] as Timestamp).toDate();
                       timeString = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                     }

                     return KeyedSubtree(
                       key: ValueKey(messageId),
                       child: _buildBubble(context, data, timeString, messageId),
                     );
                   },
                 );
               },
             ),
           ),
           if (_replyingMessage != null)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               color: Colors.grey.shade200,
               child: Row(
                 children: [
                   const Icon(Icons.reply, color: Color(0xFFAB873A), size: 18),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           "Membalas ${_replyingMessage!['sender']}",
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF533B00)),
                         ),
                         Text(
                           _replyingMessage!['text'] ?? '',
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(fontSize: 13, color: Colors.black87),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                     onPressed: () {
                       setState(() { _replyingMessage = null; });
                     },
                   )
                 ],
               ),
             ),
           
           if (_editingMessage != null)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               color: Colors.blue.withOpacity(0.1),
               child: Row(
                 children: [
                   const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text(
                           "Edit Pesan",
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                         ),
                         Text(
                           _editingMessage!['text'] ?? '',
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(fontSize: 13, color: Colors.black87),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                     onPressed: () {
                       setState(() { 
                         _editingMessage = null; 
                         _editingMessageId = null;
                         _messageController.clear(); 
                       });
                     },
                   )
                 ],
               ),
             ),

           Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: const BoxDecoration(color: Colors.transparent),
  child: Row(
    children: [
      // 1. Kotak Pesan Utama (Mengambil ruang sisa)
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black38, width: 1.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: _isRecording
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    "🔴 Sedang merekam suara...",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              : TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.black),
                  onChanged: (text) {
                    setState(() {}); // Biar tombol mic/kirim berubah real-time
                  },
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Message...",
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
        ),
      ),
      const SizedBox(width: 8),

      // 2. Tombol Aksi Utama: Kirim atau Mic (Gantian otomatis)
      if (_isRecording)
        IconButton(
          icon: const Icon(Icons.stop_circle, color: Colors.red, size: 30),
          onPressed: _toggleRecording,
        )
      else if (_messageController.text.trim().isEmpty && _editingMessageId == null)
        IconButton(
          icon: const Icon(Icons.mic_none, color: Colors.black54, size: 28),
          onPressed: _toggleRecording,
        )
      else
        IconButton(
          icon: Icon(
            _editingMessageId != null ? Icons.check_circle : Icons.send,
            color: const Color(0xFFAB873A),
            size: 28,
          ),
          onPressed: _sendMessage,
        ),

      // 3. Tombol Titik Tiga (Menu Melompat Ke Atas)
      if (_editingMessageId == null && !_isRecording)
        // 3. Tombol Titik Tiga (Menu Melompat Ke Atas dengan Lingkaran Abu-abu Gelap)
if (_editingMessageId == null && !_isRecording)
  PopupMenuButton<String>(
    icon: Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        // 🟢 DI SINI PERUBAHANNYA: Menggunakan warna arang tua (#37333B)
        color: Color(0xFF37333B), 
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.more_vert,
        color: Colors.white, // Ikon tetap putih agar kontras
        size: 20,
      ),
    ),
    offset: const Offset(0, -160),
    onSelected: (value) {
      if (value == 'file') _pickFile();
      if (value == 'camera') _pickImageFromCamera();
      if (value == 'schedule') _showSchedulePicker();
    },
    itemBuilder: (BuildContext context) => [
      const PopupMenuItem<String>(
        value: 'file',
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_outlined, color: Color(0xFFAB873A), size: 20),
            SizedBox(width: 12),
            Text('Kirim File', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'camera',
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: Color(0xFFAB873A), size: 20),
            SizedBox(width: 12),
            Text('Kamera', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'schedule',
        child: Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFFAB873A), size: 20),
            SizedBox(width: 12),
            Text('Jadwalkan Pesan', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ],
  ),
    ],
  ),
),
         ],
       ),
     ),
   );
 }

 Widget _buildBubble(BuildContext context, Map<String, dynamic> chat, String time, String messageId) {
   bool isMe = chat['senderUid'] == _auth.currentUser?.uid;
   String text = chat['text'] ?? '';
   String type = chat['type'] ?? 'text';
   String url = chat['url'] ?? '';
   bool isRead = chat['isRead'] ?? false;
   bool isStarred = chat['isStarred'] ?? false;

   String? replyToSender = chat['replyToSender'];
   String? replyToText = chat['replyToText'];

   Color bubbleColor = isMe ? const Color(0xFFE5BE5F) : const Color(0xFFECECE9);
   Color textColor = const Color(0xFF1E1400);

   return Align(
     alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
     child: Column(
       crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
       children: [
         GestureDetector(
           onLongPress: () {
             _showChatMenu(context, chat, messageId, time);
           },
           child: Container(
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
                 if (replyToSender != null && replyToText != null) ...[
                   Container(
                     width: double.infinity,
                     margin: const EdgeInsets.only(bottom: 6),
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.black.withOpacity(0.06),
                       borderRadius: BorderRadius.circular(8),
                       border: const Border(left: BorderSide(color: Color(0xFFAB873A), width: 3)),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           replyToSender,
                           style: const TextStyle(fontSize: 11, color: Color(0xFF533B00), fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 2),
                         Text(
                           replyToText,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(fontSize: 12, color: Colors.black54),
                         ),
                       ],
                     ),
                   ),
                 ],
                 if (type == 'image') ...[
                   ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: Image.network(
                       url,
                       fit: BoxFit.cover,
                       errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                     ),
                   ),
                 ] else if (type == 'file') ...[
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.insert_drive_file, size: 20, color: Colors.black54),
                       const SizedBox(width: 6),
                       Expanded(
                         child: Text(
                           text,
                           style: TextStyle(color: textColor, decoration: TextDecoration.underline),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ],
                   ),
                 ] else if (type == 'audio') ...[
                   // 🟢 BARU: Jika bertipe audio, panggil player khusus Voice Note
                   VoiceNotePlayer(url: url, textColor: textColor),
                 ] else ...[
                   Text(
                     text,
                     style: TextStyle(color: textColor, fontSize: 14.5),
                   ),
                 ],
                 const SizedBox(height: 6),
                 Row(
                   mainAxisSize: MainAxisSize.min,
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     if (isStarred) ...[
                       const Icon(Icons.star, size: 12, color: Colors.black54),
                       const SizedBox(width: 4),
                     ],
                     Text(
                       time,
                       style: const TextStyle(fontSize: 10, color: Colors.black38),
                     ),
                     if (isMe) ...[
                       const SizedBox(width: 4),
                       isRead
                           ? const SizedBox.shrink() 
                           : const Icon(
                               Icons.fiber_manual_record, 
                               size: 7,
                               color: Colors.black54, 
                             ),
                     ],
                   ],
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

// 🟢 BARU: Sub-Widget Mandiri khusus pengendali tombol Play/Pause tiap gelembung Voice Note
class VoiceNotePlayer extends StatefulWidget {
  final String url;
  final Color textColor;
  const VoiceNotePlayer({super.key, required this.url, required this.textColor});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan status pemutar audio
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() { _isPlaying = state == PlayerState.playing; });
      }
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() { _duration = newDuration; });
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() { _position = newPosition; });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Hapus memori player saat bubble dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 32, color: widget.textColor.withOpacity(0.8)),
          onPressed: () async {
            if (_isPlaying) {
              await _audioPlayer.pause();
            } else {
              await _audioPlayer.play(UrlSource(widget.url));
            }
          },
        ),
        const SizedBox(width: 4),
        Text(
          "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
          style: TextStyle(color: widget.textColor, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}