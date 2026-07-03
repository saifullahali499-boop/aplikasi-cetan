import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk cek mode web

// Memanggil modul kamar halaman dari folder screens
import 'screens/login_screen.dart';
import 'screens/mading_screen.dart';
import 'screens/panggilan_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // === JARING PENGAMAN TRY-CATCH ASLI ANDA TETAP TERJAGA ===
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBt7AcWYEIeLmoVkC2sThS0kEgDz_4tnDc",
          authDomain: "cetan-b0613.firebaseapp.com",
          projectId: "cetan-b0613",
          storageBucket: "cetan-b0613.firebasestorage.app",
          messagingSenderId: "919685453324",
          appId: "1:919685453324:web:7665ce0fd1656182c04029",
        ),
      );
      print("Firebase Web Berhasil Konek!");
    } else {
      await Firebase.initializeApp();
      print("Firebase Android Berhasil Konek!");
    }
  } catch (e) {
    print("Waduh, Firebase gagal inisialisasi tapi aplikasi selamat dari crash: $e");
  }
  runApp(const PapanTulisChatApp());
}

class PapanTulisChatApp extends StatelessWidget {
  const PapanTulisChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CetTan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        // GLOBAL THEME BERUBAH MENJADI TEKS GELAP SKETSA PENSIL
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Color(0xFF555555)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// === KONTROLLER NAVIGASI UTAMA (TOMBOL MULUS DIGESER + PERPINDAHAN INSTAN) ===
class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 3; // Default langsung membuka halaman Chat Obrolan
  late PageController _pageController;

  // Variabel penyimpan koordinat tombol (X dan Y)
  double? _x;
  double? _y;

  @override
  void initSetting() {
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void initState() {
    super.initState();
    initSetting();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkTextColor = Color(0xFF2D2B2A);
    final screenSize = MediaQuery.of(context).size;

    // Mengatur posisi awal tombol di pojok kanan bawah saat pertama kali dibuka
    _x ??= screenSize.width - 72;   
    _y ??= screenSize.height - 120; 

    return Container(
      // LATAR BELAKANG GRADASI KERTAS SKETSA TERANG
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.3,
          colors: [Color(0xFFFDFDFD), Color(0xFFF6F6F4), Color(0xFFEAEAEA)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        
        // Stack utama agar tombol bisa melayang dan digeser mulus di atas halaman
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: const [
                PembaruanScreen(),
                PanggilanScreen(),
                KantinScreen(),
                ChatListScreen(),
                ProfileScreen(),
              ],
            ),

            // 🛠️ TOMBOL NAVIGASI YANG BISA DIGESER DENGAN MULUS
            Positioned(
              left: _x,
              top: _y,
              child: Draggable(
                // feedback: Wujud tombol saat digeser (ditambah Material agar bayangan & transisi mulus)
                feedback: _buildButtonDesign(isDragging: true),
                // childWhenDragging: Membuat tombol asli tidak berbayang ganda di tempat lama saat ditarik
                childWhenDragging: const SizedBox.shrink(),
                // onDragEnd: Mengunci posisi baru tombol dengan mulus tepat saat jari dilepas
                onDragEnd: (dragDetails) {
                  setState(() {
                    _x = dragDetails.offset.dx;
                    _y = dragDetails.offset.dy;

                    // JARING PENGAMAN: Menjaga tombol tidak keluar dari batas layar HP Anda
                    if (_x! < 16) _x = 16; 
                    if (_x! > screenSize.width - 72) _x = screenSize.width - 72; 
                    if (_y! < 40) _y = 40; 
                    if (_y! > screenSize.height - 100) _y = screenSize.height - 100; 
                  });
                },
                
                // Saat diklik biasa (bukan digeser), menu popup akan muncul otomatis mengikuti posisi tombol
                child: PopupMenuButton<int>(
                  tooltip: 'Navigasi Menu',
                  onSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                      
                      // ⚡ PERPINDAHAN INSTAN: Menggunakan jumpToPage tanpa animasi geser layar
                      _pageController.jumpToPage(index); 
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: _buildButtonDesign(isDragging: false),
                  itemBuilder: (context) => [
                    _buildPopupItem(0, Icons.blur_circular, 'Mading Status', darkTextColor),
                    _buildPopupItem(1, Icons.call_outlined, 'Riwayat Kapur', darkTextColor),
                    _buildPopupItem(2, Icons.storefront_outlined, 'Kantin Lokal', darkTextColor),
                    _buildPopupItem(3, Icons.chat_bubble_outline, 'Chat Obrolan', darkTextColor),
                    _buildPopupItem(4, Icons.account_circle_outlined, 'Profil Anda', darkTextColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi desain lingkaran boks tombol hitam kustom
  Widget _buildButtonDesign({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2A32),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.4 : 0.26),
              blurRadius: isDragging ? 14 : 6,
              offset: Offset(0, isDragging ? 8 : 3),
            ),
          ],
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 28),
      ),
    );
  }

  // Helper untuk merapikan layout baris item popup menu
  PopupMenuItem<int> _buildPopupItem(int value, IconData icon, String text, Color textColor) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// === TEMPAT PENAMPUNG HALAMAN KANTIN ===
class KantinScreen extends StatelessWidget {
  const KantinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
              ),
              child: const Icon(Icons.storefront_outlined, size: 60, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 20),
            const Text(
              'MENU KANTIN LOKAL',
              style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur kemitraan kafe sedang dipersiapkan.',
              style: TextStyle(color: const Color(0xFF2C2C2C).withOpacity(0.6), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}