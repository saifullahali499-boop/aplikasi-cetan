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
  
  // === JARING PENGAMAN TRY-CATCH DIMULAI DI SINI ===
  try {
    if (kIsWeb) {
      // Menghubungkan Firebase menggunakan data asli dari Firebase Console Anda saat di mode Web Browser
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
    // Jika Firebase error/gagal konek, ditangkap di sini agar aplikasi Android tidak force close
    print("Waduh, Firebase gagal inisialisasi tapi aplikasi selamat dari crash: $e");
  }
  // === JARING PENGAMAN TRY-CATCH SELESAI ===
  
  runApp(const PapanTulisChatApp());
}

class PapanTulisChatApp extends StatelessWidget {
  const PapanTulisChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent, 
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// === KONTROLLER NAVIGASI UTAMA (TAB CONTROLLER) ===
class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 2; 
  late PageController _pageController;

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
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 1.5,
          colors: [Color(0xFF2E5B35), Color(0xFF1E3F24), Color(0xFF152E19)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            PembaruanScreen(), 
            PanggilanScreen(), 
            ChatListScreen(), 
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5A2B),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, -2))],
                border: const Border(
                  top: BorderSide(color: Color(0xAFA0522D), width: 1.5),
                  bottom: BorderSide(color: Color(0xFF5C3A21), width: 1.5),
                ),
              ),
            ),
            Container(
              color: const Color(0xFF1E3F24),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white38,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.blur_circular), label: 'Pembaruan'),
                  BottomNavigationBarItem(icon: Icon(Icons.call_outlined), label: 'Panggilan'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                  BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Anda'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
