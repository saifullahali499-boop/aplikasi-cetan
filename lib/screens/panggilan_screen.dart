import 'package:flutter/material.dart';

class PanggilanScreen extends StatelessWidget {
  const PanggilanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RIWAYAT KAPUR', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Container(height: 1.5, width: 120, color: Colors.white38, margin: const EdgeInsets.only(top: 5, bottom: 25)),
            Card(
              color: Colors.white.withOpacity(0.03),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
              child: const ListTile(
                leading: CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.phone_missed, color: Colors.redAccent)),
                title: Text('ISTRIKU ❤️ (2)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Hari ini, 13:15', style: TextStyle(color: Colors.white38)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
