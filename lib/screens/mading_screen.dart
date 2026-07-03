import 'package:flutter/material.dart';

class PembaruanScreen extends StatefulWidget {
  const PembaruanScreen({super.key});

  @override
  State<PembaruanScreen> createState() => _PembaruanScreenState();
}

class _PembaruanScreenState extends State<PembaruanScreen> {
  // PERBAIKAN: Kode emoji yang eror unicode sudah diperbaiki menjadi normal kembali
  final List<Map<String, String>> _statusMading = [
    {"name": "ISTRIKU ❤️", "time": "Baru saja", "content": "Jemur pakaian jangan lupa diangkat klo mendung ya pa... ☁️"},
    {"name": "Pak Eko Guru", "time": "2 jam lalu", "content": "Pengumuman: Besok pagi harap membawa kapur warna-warni untuk kelas seni."},
  ];

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color accentColor = Color(0xFF8B5A2B);
    const Color backgroundColor = Color(0xFFF4F5F7); // Warna dasar screen terang agar konsisten

    return Scaffold(
      backgroundColor: backgroundColor,
      // 1. PENAMBAHAN: AppBar Atas Berwarna Hitam sesuai Chat List Screen
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'MADING STATUS', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _statusMading.length,
                  itemBuilder: (context, index) {
                    final status = _statusMading[index];
                    return Card(
                      color: Colors.white, // Diubah menjadi putih bersih agar tulisan kontras
                      elevation: 2, // Memberikan sedikit bayangan halus
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black12), // Border abu-abu tipis
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  status['name']!, 
                                  style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  status['time']!, 
                                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              status['content']!, 
                              style: const TextStyle(color: darkTextColor, fontSize: 15, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor, // Menggunakan warna cokelat aksen estetis
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TulisStatusScreen()));
          if (result != null && result is String && result.trim().isNotEmpty) {
            setState(() {
              _statusMading.insert(0, {"name": "Anda", "time": "Baru saja", "content": result});
            });
          }
        },
      ),
    );
  }
}

class TulisStatusScreen extends StatefulWidget {
  const TulisStatusScreen({super.key});

  @override
  State<TulisStatusScreen> createState() => _TulisStatusScreenState();
}

class _TulisStatusScreenState extends State<TulisStatusScreen> {
  final TextEditingController _statusController = TextEditingController();

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color backgroundColor = Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor, // Menghilangkan RadialGradient hijau lama
      // 2. PERBAIKAN: AppBar Tulis Status juga disamakan Berwarna Hitam pekat
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Goreskan Cerita Baru', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _statusController.text),
            child: const Text('TEMPEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _statusController,
                maxLines: null,
                style: const TextStyle(color: darkTextColor, fontSize: 20, fontStyle: FontStyle.italic), // Teks input menjadi charcoal gelap
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Tulis apa yang kamu pikirkan di mading kelas...",
                  hintStyle: TextStyle(color: Colors.black38), // Hint text menjadi abu-abu gelap transparan
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}