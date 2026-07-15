import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    

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
       if (mounted) {
         setState(() {
           _isFavorite = favorites.contains(widget.chatId);
         });
       }
     }
   } catch (e) {
     print("Gagal mengambil data favorit: $e");
   }
 }

 // 🟢 PERBAIKAN 1: Mengubah .update() menjadi .set(..., SetOptions(merge: true))
 void _toggleFavorite() async {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;

   setState(() {
     _isFavorite = !_isFavorite; 
   });

   try {
     if (_isFavorite) {
       // Menggunakan .set otomatis membuat dokumen baru jika belum ada di DB
       await _firestore.collection('users').doc(currentUser.uid).set({
         'favoriteRooms': FieldValue.arrayUnion([widget.chatId])
       }, SetOptions(merge: true));
       if (mounted) _showSnackBar(context, 'Ditambahkan ke favorit');
     } else {
       await _firestore.collection('users').doc(currentUser.uid).set({
         'favoriteRooms': FieldValue.arrayRemove([widget.chatId])
       }, SetOptions(merge: true));
       if (mounted) _showSnackBar(context, 'Dihapus dari favorit');
     }
   } catch (e) {
     setState(() {
       _isFavorite = !_isFavorite; 
     });
     if (mounted) _showSnackBar(context, 'Gagal memperbarui favorit: $e');
   }
 }

 void _shareContact() {
   String infoKontak = "Kontak App Chat\nNama: ${widget.name}\nRoom: ${widget.chatId}";
   Clipboard.setData(ClipboardData(text: infoKontak)); 
   _showSnackBar(context, 'Info kontak untuk ${widget.name} disalin ke papan klip!');
 }

 void _executeAction(String type) async {
   final currentUser = _auth.currentUser;
   if (currentUser == null) return;

   try {
     final chatQuery = await _firestore
         .collection('chats')
         .where('room', isEqualTo: widget.chatId)
         .limit(1)
         .get();

     if (chatQuery.docs.isEmpty && (type == 'KELUAR' || type == 'LAPORKAN')) {
       if (mounted) _showSnackBar(context, 'Grup/Chat tidak ditemukan di database.');
       return;
     }

     String? actualDocId;
     if (chatQuery.docs.isNotEmpty) {
       actualDocId = chatQuery.docs.first.id;
     }

     if (type == 'KELUAR') {
       await _firestore.collection('chats').doc(actualDocId).update({
         'members': FieldValue.arrayRemove([currentUser.uid])
       });
       if (mounted) _showSnackBar(context, 'Anda telah keluar dari grup');
     }
     // 🟢 PERBAIKAN 2: Mengubah .update() blokir menjadi .set(..., SetOptions(merge: true))
     else if (type == 'BLOKIR') {
       if (widget.receiverUid == null) return;
       await _firestore.collection('users').doc(currentUser.uid).set({
         'blockedUsers': FieldValue.arrayUnion([widget.receiverUid])
       }, SetOptions(merge: true));
       if (mounted) _showSnackBar(context, '${widget.name} berhasil diblokir');
     }
     else if (type == 'LAPORKAN') {
       await _firestore.collection('reports').add({
         'reportedChatId': actualDocId,
         'reportedRoomName': widget.chatId,
         'reportedBy': currentUser.uid,
         'timestamp': FieldValue.serverTimestamp(),
       });
       if (mounted) _showSnackBar(context, 'Laporan Anda telah dikirim');
     }
   } catch (e) {
     if (mounted) _showSnackBar(context, 'Gagal memproses aksi: $e');
   }
 }

 @override
 Widget build(BuildContext context) {
   final isGroup = widget.name.contains('Grup');
   final double panelWidth = MediaQuery.of(context).size.width * 0.8;

   return Drawer(
     width: panelWidth,
     backgroundColor: const Color(0xFF1E1E1E),
     shape: const RoundedRectangleBorder(
       borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
     ),
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
                   style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                 ),
               ],
             ),
           ),
         
           Expanded(
             child: ListView(
               padding: const EdgeInsets.symmetric(horizontal: 8),
               children: [
                 Center(
                   child: Column(
                     children: [
                       const SizedBox(height: 10),
                       CircleAvatar(
                         radius: 45,
                         backgroundColor: Colors.white10,
                         child: Icon(
                           isGroup ? Icons.group_outlined : Icons.person,
                           size: 50,
                           color: Colors.white70,
                         ),
                       ),
                       const SizedBox(height: 16),
                       Text(
                         widget.name.toUpperCase(),
                         style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 4),
                       Text(
                         isGroup ? 'Grup Obrolan Aktif' : 'Kontak Personal',
                         style: const TextStyle(color: Colors.white60, fontSize: 12),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20),
                 const Divider(color: Colors.white12, thickness: 1),

                 ListTile(
                   leading: const Icon(Icons.image_outlined, color: Colors.white70),
                   title: const Text('Media, tautan, & dokumen', style: TextStyle(color: Colors.white, fontSize: 14)),
                   trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
                   onTap: () {
                     Navigator.pop(context); 
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => MediaLinksDocsScreen(roomName: widget.chatId)),
                     );
                   },
                 ),
                 ListTile(
                   leading: const Icon(Icons.star_outline, color: Colors.white70),
                   title: const Text('Pesan berbintang', style: TextStyle(color: Colors.white, fontSize: 14)),
                   trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
                   onTap: () {
                     Navigator.pop(context); 
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => StarredMessagesScreen(roomName: widget.chatId)),
                     );
                   },
                 ),
                 const Divider(color: Colors.white12, thickness: 1),

                 ListTile(
                   leading: Icon(
                     _isFavorite ? Icons.favorite : Icons.favorite_border,
                     color: _isFavorite ? Colors.redAccent : Colors.white70
                   ),
                   title: Text(
                     _isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
                     style: const TextStyle(color: Colors.white, fontSize: 14)
                   ),
                   onTap: _toggleFavorite, 
                 ),
                 ListTile(
                   leading: const Icon(Icons.share_outlined, color: Colors.white70),
                   title: const Text('Bagikan kontak', style: TextStyle(color: Colors.white, fontSize: 14)),
                   onTap: _shareContact, 
                 ),
                 const Divider(color: Colors.white12, thickness: 1),

                 ListTile(
                   leading: Icon(Icons.block, color: Colors.redAccent.shade200),
                   title: Text(isGroup ? 'Keluar dari grup' : 'Blokir Kontak', style: TextStyle(color: Colors.redAccent.shade200, fontSize: 14)),
                   onTap: () {
                     _showActionDialog(context, isGroup ? 'Keluar dari grup?' : 'Blokir Kontak?', isGroup ? 'KELUAR' : 'BLOKIR');
                   },
                 ),
                 ListTile(
                   leading: Icon(Icons.thumb_down_alt_outlined, color: Colors.redAccent.shade200),
                   title: Text(isGroup ? 'Laporkan grup' : 'Laporkan Kontak', style: TextStyle(color: Colors.redAccent.shade200, fontSize: 14)),
                   onTap: () {
                     _showActionDialog(context, 'Laporkan Kontak?', 'LAPORKAN');
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

 void _showSnackBar(BuildContext context, String msg) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text(msg), duration: const Duration(seconds: 2), backgroundColor: const Color(0xFF2D2D2D)),
   );
 }

 void _showActionDialog(BuildContext context, String title, String actionKey) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       backgroundColor: const Color(0xFF2D2D2D),
       title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
       content: const Text('Apakah Anda yakin ingin melanjutkan aksi ini?', style: TextStyle(color: Colors.white70, fontSize: 14)),
       actions: [
         TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL', style: TextStyle(color: Colors.white38))),
         TextButton(
           onPressed: () {
             Navigator.pop(context);
             _executeAction(actionKey);
           },
           child: Text(actionKey, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
         ),
       ],
     ),
   );
 }
}

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
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.star_outline, size: 48, color: Colors.white24),
                   const SizedBox(height: 12),
                   Text(
                     'Belum ada pesan berbintang di room: $roomName',
                     style: const TextStyle(color: Colors.white54),
                     textAlign: TextAlign.center,
                   ),
                 ],
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
                 title: Text(
                   messageText,
                   style: const TextStyle(color: Colors.white, fontSize: 14),
                 ),
                 subtitle: Padding(
                   padding: const EdgeInsets.only(top: 4.0),
                   child: Text(
                     senderName,
                     style: const TextStyle(color: Colors.white38, fontSize: 11),
                   ),
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