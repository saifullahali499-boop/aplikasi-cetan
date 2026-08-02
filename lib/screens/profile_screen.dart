import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State lokal untuk tombol saklar status jaringan
  bool _isStatusVisible = true;

  // 1. Fungsi untuk mengubah Status Piket di Firestore
  void _editStatusDialog(String currentStatus) {
    TextEditingController statusController = TextEditingController(text: currentStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Status Piket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: statusController,
          decoration: const InputDecoration(
            hintText: "Masukkan status baru...",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5A2B))),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5A2B)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                'statusPiket': statusController.text.trim(),
              }, SetOptions(merge: true));

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. Fungsi untuk menampilkan Detail Akun & Ubah Nama
  void _showAccountDetailsDialog(String currentName) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${currentUser?.email ?? "Tidak tersedia"}', style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pengguna',
                labelStyle: TextStyle(color: Color(0xFF8B5A2B)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5A2B))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5A2B)),
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await currentUser?.updateDisplayName(newName);
                await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                  'name': newName,
                }, SetOptions(merge: true));

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama akun berhasil diperbarui!')),
                  );
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. Fungsi Pengaturan Privasi (Simpan ke Firestore)
  void _showPrivacyDialog(String currentPrivacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setelan Privasi Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Semua Orang', 'Hanya Kontak', 'Privat'].map((opsi) {
            return RadioListTile<String>(
              title: Text(opsi),
              value: opsi,
              groupValue: currentPrivacy,
              activeColor: const Color(0xFF8B5A2B),
              onChanged: (value) async {
                if (value != null) {
                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                    'privasiStatus': value,
                  }, SetOptions(merge: true));
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privasi status diubah ke: $value')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // 4. Jendela Pesan Berbintang
  void _showStarredMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Pesan Berbintang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Icon(Icons.star_border_rounded, size: 60, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'Belum ada pesan berbintang',
              style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            Text(
              'Tekan dan tahan pesan penting di ruang chat lalu ketuk ikon bintang untuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF8B5A2B))),
          ),
        ],
      ),
    );
  }

  // 5. Pop-up dialog Ubah PIN
  void _showChangePinDialog(BuildContext context) {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFFD49A3B)),
              SizedBox(width: 8),
              Text('Ubah PIN Keamanan', style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PIN Lama:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F4),
                  border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Color(0xFF2C2C2C), letterSpacing: 8, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.black38, letterSpacing: 8),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('PIN Baru (4 Digit):', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F4),
                  border: Border.all(color: const Color(0xFF2C2C2C).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Color(0xFF2C2C2C), letterSpacing: 8, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.black38, letterSpacing: 8),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('BATAL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                String savedPin = prefs.getString('app_pin') ?? "1234";

                if (!dialogContext.mounted) return;

                if (oldPinController.text != savedPin) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(backgroundColor: Colors.red, content: Text('PIN Lama yang dimasukkan salah!')),
                  );
                  return;
                }
                if (newPinController.text.length != 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(backgroundColor: Colors.red, content: Text('PIN Baru harus tepat 4 digit!')),
                  );
                  return;
                }

                await prefs.setString('app_pin', newPinController.text);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Color(0xFFD49A3B), content: Text('PIN Keamanan berhasil diubah!')),
                );
              },
              child: const Text('SIMPAN', style: TextStyle(color: Color(0xFFD49A3B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isMe = widget.userId == currentUid;

    const Color darkTextColor = Color(0xFF2D2B2A);
    const Color accentColor = Color(0xFF8B5A2B);

    String defaultStatus = isMe
        ? 'Sedang belajar membuat aplikasi chat estetik pakai Flutter. Harap tidak berisik! 🤫'
        : 'Anggota aktif di aplikasi Cettan. Mari saling menyapa! ☕';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            String liveName = widget.userName;
            String liveStatus = defaultStatus;
            String livePrivacy = 'Semua Orang';
            bool liveShowStatus = true;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              liveName = data['name'] ?? widget.userName;
              liveStatus = data['statusPiket'] ?? defaultStatus;
              livePrivacy = data['privasiStatus'] ?? 'Semua Orang';
              liveShowStatus = data['showStatus'] ?? true;
              _isStatusVisible = liveShowStatus;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // === JUDUL HALAMAN ===
                  Text(
                    isMe ? 'PROFIL SAYA' : 'PROFIL ANGGOTA',
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),

                  const SizedBox(height: 25),

                  // === FOTO PROFIL BULAT ===
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 6),
                          ),
                          child: const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person, size: 70, color: darkTextColor),
                          ),
                        ),
                        if (isMe)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: accentColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                                onPressed: () {
                                  // Nanti dihubungkan dengan image_picker
                                },
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nama User
                  Text(
                    isMe ? '$liveName (Anda)' : liveName,
                    style: const TextStyle(color: darkTextColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  // ID Unik User
                  Text(
                    'ID: ${widget.userId.length > 12 ? widget.userId.substring(0, 12) : widget.userId}...',
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                  const SizedBox(height: 30),

                  // === KOTAK STATUS PIKET ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InkWell(
                      onTap: isMe ? () => _editStatusDialog(liveStatus) : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'STATUS PIKET',
                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                if (isMe) const Icon(Icons.edit_outlined, size: 14, color: accentColor),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              liveStatus,
                              style: const TextStyle(color: darkTextColor, fontSize: 15, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // === MENU MANAGEMENT (HANYA MUNCUL JIKA PROFIL SAYA) ===
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          // Menu Akun
                          ListTile(
                            leading: const Icon(Icons.key_outlined, color: Colors.black54),
                            title: const Text('Akun', style: TextStyle(color: darkTextColor)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black38),
                            onTap: () => _showAccountDetailsDialog(liveName),
                          ),

                          // Menu Ubah PIN Keamanan
                          ListTile(
                            leading: const Icon(Icons.lock_reset, color: Color(0xFFD49A3B)),
                            title: const Text('Ubah PIN Keamanan', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Ganti PIN untuk membuka kunci obrolan', style: TextStyle(fontSize: 11, color: Colors.black54)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black38),
                            onTap: () {
                              _showChangePinDialog(context);
                            },
                          ),

                          // Menu Tampilkan Status Jaringan (Switch)
                          SwitchListTile(
                            secondary: const Icon(Icons.wifi_outlined, color: Colors.black54),
                            title: const Text('Tampilkan Status Jaringan', style: TextStyle(color: darkTextColor)),
                            subtitle: const Text('Sembunyikan atau tampilkan status koneksi Anda di chat', style: TextStyle(fontSize: 11, color: Colors.black45)),
                            activeColor: accentColor,
                            value: _isStatusVisible,
                            onChanged: (bool value) async {
                              setState(() {
                                _isStatusVisible = value;
                              });

                              // Simpan ke Firestore
                              await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                                'showStatus': value,
                              }, SetOptions(merge: true));

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? 'Status jaringan ditampilkan' : 'Status jaringan disembunyikan'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),

                          // Menu Pesan Berbintang
                          ListTile(
                            leading: const Icon(Icons.star_border, color: Colors.black54),
                            title: const Text('Pesan Berbintang', style: TextStyle(color: darkTextColor)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black38),
                            onTap: _showStarredMessagesDialog,
                          ),

                          // Menu Privasi
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: Colors.black54),
                            title: const Text('Privasi', style: TextStyle(color: darkTextColor)),
                            trailing: Text(livePrivacy, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                            onTap: () => _showPrivacyDialog(livePrivacy),
                          ),

                          const Divider(color: Colors.black12, height: 30),

                          // Tombol Keluar
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.redAccent),
                            title: const Text('Keluar (Pintu Kelas)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}