import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Memanggil modul halaman dari folder screens
import 'screens/login_screen.dart';
import 'screens/mading_screen.dart';
import 'screens/panggilan_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/kantin_screen.dart'; // <--- IMPORT BARU DITAMBAHKAN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("Error Firebase: $e");
  }
  runApp(const PapanTulisChatApp());
}

class PapanTulisChatApp extends StatelessWidget {
  const PapanTulisChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cettan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Color(0xFF555555)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 3;
  late PageController _pageController;
  double? _x;
  double? _y;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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

    _x ??= screenSize.width - 72;  
    _y ??= screenSize.height - 120;

    return Container(
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
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [ // 1. Hapus kata 'const' dari sini
                const PembaruanScreen(), // 2. Tambahkan const di sini jika belum ada
                const PanggilanScreen(), // 3. Tambahkan const di sini jika belum ada
                const KantinScreen(),    // 4. Tambahkan const di sini jika belum ada
                const ChatListScreen(),  // 5. Tambahkan const di sini jika belum ada
                ProfileScreen(           // 6. Bagian ini JANGAN diberi const karena ada FirebaseAuth
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Profil Saya',
                ),
              ],
            ),

            Positioned(
              left: _x,
              top: _y,
              child: Draggable(
                feedback: _buildButtonDesign(isDragging: true),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (dragDetails) {
                  setState(() {
                    _x = dragDetails.offset.dx;
                    _y = dragDetails.offset.dy;
                    if (_x! < 16) _x = 16;
                    if (_x! > screenSize.width - 72) _x = screenSize.width - 72;
                    if (_y! < 40) _y = 40;
                    if (_y! > screenSize.height - 100) _y = screenSize.height - 100;
                  });
                },
                child: PopupMenuButton<int>(
                  tooltip: 'Navigasi Menu',
                  onSelected: (index) {
                    setState(() {
                      _currentIndex = index;
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