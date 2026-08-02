import 'dart5:async';
import 'package:flutter/foundation.dart'; // Untuk mendeteksi apakah di Web atau HP
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiStatusService {
  static final WifiStatusService _instance = WifiStatusService._internal();
  factory WifiStatusService() => _instance;
  WifiStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NetworkInfo _networkInfo = NetworkInfo();

  bool _isListening = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Memeriksa koneksi & memperbarui status WiFi user ke Firestore
  Future<void> checkAndUpdatetWifiStatus() async {
    try {
      String newStatus = "Online";

      // Jika dijalankan di HP (Android/iOS)
      if (!kIsWeb) {
        // 1. Cek & minta izin lokasi (wajib di Android untuk baca SSID WiFi)
        var status = await Permission.location.status;
        if (status.isDenied) {
          status = await Permission.location.request();
        }

        // 2. Cek koneksi internet
        final List<ConnectivityResult> connectivityResult = 
            await Connectivity().checkConnectivity();

        // Jika terhubung via WiFi DAN izin lokasi diberikan
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          if (status.isGranted) {
            String? ssid = await _networkInfo.getWifiName();
            
            if (ssid != null && ssid.isNotEmpty && ssid != "<unknown ssid>") {
              // Bersihkan tanda petik bawaan dari SSID
              String cleanSsid = ssid.replaceAll('"', '').trim();
              if (cleanSsid.isNotEmpty) {
                newStatus = cleanSsid;
              }
            } else {
              newStatus = "Wi-Fi";
            }
          } else {
            // Jika izin ditolak, fallback ke label generic Wi-Fi
            newStatus = "Wi-Fi";
          }
        } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
          newStatus = "Mobile Data";
        } else if (connectivityResult.contains(ConnectivityResult.none)) {
          newStatus = "Offline";
        }
      } else {
        // Jika sedang diuji di Web
        newStatus = "Online (Web)";
      }

      // 3. Update status ke Firebase Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'status': newStatus,
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("[WifiStatusService] Status diperbarui: $newStatus");
      }
    } catch (e) {
      debugPrint("[WifiStatusService] Error saat memperbarui status: $e");
    }
  }

  /// Mendengarkan perubahan jaringan secara real-time
  void listenToConnectivityChanges() {
    if (_isListening) return;

    _isListening = true;
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      checkAndUpdatetWifiStatus();
    });
  }

  /// Menghentikan listener saat tidak digunakan
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }
}