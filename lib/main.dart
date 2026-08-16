import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics

// Import halaman dari folder screens
import 'package:papantulis_chat/screens/mading_screen.dart';
import 'package:papantulis_chat/screens/auth_screen.dart';
import 'package:papantulis_chat/screens/panggilan_screen.dart';
import 'package:papantulis_chat/screens/chat_list_screen.dart';
import 'package:papantulis_chat/screens/profile_screen.dart';
import 'package:papantulis_chat/screens/kantin_screen.dart';

void main() async {
  // Wajib dipanggil sebelum menginisialisasi plugin native/Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Menangkap error global agar aplikasi TIDAK KELUAR SENDIRI jika ada crash UI
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error Caught: ${details.exception}");
  };

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
    debugPrint("Firebase Berhasil Dimuat!");
  } catch (e, stackTrace) {
    debugPrint("Error Inisialisasi Firebase: $e");
    debugPrint("StackTrace: $stackTrace");
  }

  // === DUA BARIS KODE FIREBASE CRASHLYTICS ===
  // Mengirim laporan crash otomatis dari HP ke Firebase Console
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
      // Pengecekan Sesi Login Otomatis dengan Penanganan Error Anti-Crash
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Saat loading status autentikasi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFFDFDFD),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5A2B)),
              ),
            );
          }

          // 2. Jika ada error jaringan/Firebase
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFFFDFDFD),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Gagal memuat sesi: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }

          // 3. Jika user sudah login
          if (snapshot.hasData && snapshot.data != null) {
            return const MainTabController();
          }

          // 4. Jika belum login
          return AuthScreen();
        },
      ),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 3; // Halaman default (ChatListScreen)
  late PageController _pageController;

  double? _x;
  double? _y;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Inisialisasi posisi tombol floating secara aman setelah layout dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        if (screenSize.width > 0 && screenSize.height > 0) {
          setState(() {
            _x = screenSize.width - 72;
            _y = screenSize.height - 120;
          });
        }
      }
    });
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

    // Proteksi batas posisi floating button
    final currentX = _x ?? (screenSize.width > 0 ? screenSize.width - 72 : 200.0);
    final currentY = _y ?? (screenSize.height > 0 ? screenSize.height - 120 : 500.0);

    final currentUser = FirebaseAuth.instance.currentUser;

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
            // Area Konten Utama
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disarankan agar swipe tab tidak mengganggu gesture chat
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                const PembaruanScreen(),
                const PanggilanScreen(),
                const KantinScreen(),
                const ChatListScreen(),
                ProfileScreen(
                  userId: currentUser?.uid ?? '',
                  userName: currentUser?.displayName ?? currentUser?.email ?? 'Profil Saya',
                ),
              ],
            ),

            // Tombol Navigasi Melayang (Draggable)
            Positioned(
              left: currentX,
              top: currentY,
              child: Draggable(
                feedback: _buildButtonDesign(isDragging: true),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (dragDetails) {
                  setState(() {
                    double newX = dragDetails.offset.dx;
                    double newY = dragDetails.offset.dy;

                    // Batasi gerakan agar tidak keluar dari area layar HP
                    if (newX < 16) newX = 16;
                    if (newX > screenSize.width - 72) newX = screenSize.width - 72;
                    if (newY < 40) newY = 40;
                    if (newY > screenSize.height - 100) newY = screenSize.height - 100;

                    _x = newX;
                    _y = newY;
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
              color: isDragging ? Colors.black45 : Colors.black26, // Disesuaikan agar aman dari deprecated/crash
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
    return PopupMenuItem<int>(
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