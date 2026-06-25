import 'package:flutter/material.dart';

class PembaruanScreen extends StatefulWidget {
  const PembaruanScreen({super.key});

  @override
  State<PembaruanScreen> createState() => _PembaruanScreenState();
}

class _PembaruanScreenState extends State<PembaruanScreen> {
  final List<Map<String, String>> _statusMading = [
    {"name": "ISTRIKU ❤️", "time": "Baru saja", "content": "Jemur pakaian jangan lupa diangkat klo mendung ya pa... ☁️"},
    {"name": "Pak Eko Guru", "time": "2 jam lalu", "content": "Pengumuman: Besok pagi harap membawa kapur warna-warni untuk kelas seni."},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MADING STATUS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(height: 1.5, width: 120, color: Colors.white38, margin: const EdgeInsets.only(top: 5, bottom: 20)),
              Expanded(
                child: ListView.builder(
                  itemCount: _statusMading.length,
                  itemBuilder: (context, index) {
                    final status = _statusMading[index];
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white24),
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
                                Text(status['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(status['time']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(status['content']!, style: const TextStyle(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic)),
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
        backgroundColor: const Color(0xFF8B5A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xAFA0522D), width: 2)),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(-0.2, -0.3), radius: 1.5, colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)]),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
          title: const Text('Goreskan Cerita Baru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: _statusController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white70, fontSize: 20, fontStyle: FontStyle.italic),
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Tulis apa yang kamu pikirkan di mading kelas...",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
