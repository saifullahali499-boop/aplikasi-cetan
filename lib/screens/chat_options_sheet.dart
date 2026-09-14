import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final bool isLocked;
  final bool isHidden;
  final String? currentCategory;
  final VoidCallback onUnlockPin;
  final VoidCallback onToggleLock;
  final VoidCallback onShowCategory;
  final VoidCallback onToggleHide;
  final VoidCallback onDeleteChat;
  final Function(BuildContext) onIncognitoPeek;

  const ChatOptionsSheet({
    Key? key,
    required this.chatData,
    required this.isLocked,
    required this.isHidden,
    required this.currentCategory,
    required this.onUnlockPin,
    required this.onToggleLock,
    required this.onShowCategory,
    required this.onToggleHide,
    required this.onDeleteChat,
    required this.onIncognitoPeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String roomName = chatData['name'] ?? '';
    final String docId = chatData["id"] ?? "";
    final bool currentFavorite = chatData["isFavorite"] ?? false;

    // Dibungkus SingleChildScrollView agar bisa di-scroll dan bebas overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roomName.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),

            // Menu Favorit
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(
                currentFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (docId.isNotEmpty) {
                  await FirebaseFirestore.instance.collection("chats").doc(docId).update({
                    "isFavorite": !currentFavorite,
                  });
                }
              },
            ),
            const SizedBox(height: 4),

            // Lihat Chat (Mode Baca Aman)
            if (!isLocked) ...[
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Color(0xFFD49A3B)),
                title: const Text('Lihat Chat (Mode Baca Aman)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: const Text('Baca tanpa ketahuan / tanpa centang biru', style: TextStyle(fontSize: 11, color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  onIncognitoPeek(context);
                },
              ),
              const SizedBox(height: 4),
            ],

            // Kunci Obrolan
            ListTile(
              leading: Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: const Color(0xFFD49A3B)),
              title: Text(isLocked ? 'Buka Kunci Obrolan' : 'Kunci Obrolan Ini', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (isLocked) {
                  onUnlockPin();
                } else {
                  onToggleLock();
                }
              },
            ),
            const SizedBox(height: 4),

            // Kategori Chat
            if (!roomName.toLowerCase().contains('grup')) ...[
              ListTile(
                leading: const Icon(Icons.label_outline_rounded, color: Color(0xFFD49A3B)),
                title: const Text('Tambahkan Kategori Chat', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text(
                  currentCategory != null ? 'Kategori: $currentCategory' : 'Belum ada kategori',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onShowCategory();
                },
              ),
              const SizedBox(height: 4),
            ],

            // Sembunyikan Chat
            ListTile(
              leading: Icon(isHidden ? Icons.visibility_outlined : Icons.visibility_off_rounded, color: const Color(0xFFD49A3B)),
              title: Text(isHidden ? 'Batalkan Sembunyikan' : 'Sembunyikan Chat', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onToggleHide();
              },
            ),
            const SizedBox(height: 4),

            // Hapus Obrolan
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Hapus Obrolan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onDeleteChat();
              },
            ),
          ],
        ),
      ),
    );
  }
}