import 'package:flutter/material.dart';

class PopupChatButton extends StatelessWidget {
  final VoidCallback onPickFile;
  final VoidCallback onPickCamera;
  final VoidCallback onShowSchedule;
  final VoidCallback onShowAutoDestruct;

  const PopupChatButton({
    super.key,
    required this.onPickFile,
    required this.onPickCamera,
    required this.onShowSchedule,
    required this.onShowAutoDestruct,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF2A2E33), // Warna latar belakang charcoal
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF37333B), 
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert,
          color: Colors.white,
          size: 20,
        ),
      ),
      offset: const Offset(0, -210),
      onSelected: (value) {
        if (value == 'file') onPickFile();
        if (value == 'camera') onPickCamera();
        if (value == 'schedule') onShowSchedule();
        if (value == 'auto_destruct') onShowAutoDestruct();
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'file',
          child: Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, color: Color(0xFFAB873A), size: 20),
              SizedBox(width: 12),
              Text('Kirim File', style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: Color(0xFFAB873A), size: 20),
              SizedBox(width: 12),
              Text('Kamera', style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'schedule',
          child: Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFFAB873A), size: 20),
              SizedBox(width: 12),
              Text('Jadwalkan Pesan', style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'auto_destruct',
          child: Row(
            children: [
              Icon(Icons.timer_off_outlined, color: Color(0xFFAB873A), size: 20),
              SizedBox(width: 12),
              Text('Pesan Media Sementara', style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}