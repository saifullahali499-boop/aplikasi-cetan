import 'dart:async';
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

  Future<void> checkAndUpdatetWifiStatus() async {
    try {
      String newStatus = "Online"; 

      // Jika dijalankan di HP (Android/iOS), cek izin dan nama Wi-Fi
      if (!kIsWeb) {
        var status = await Permission.location.status;
        if (!status.isGranted) {
          await Permission.location.request();
        }

        final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          String? ssid = await _networkInfo.getWifiName();
          
          if (ssid != null && ssid.isNotEmpty) {
            String cleanSsid = ssid.replaceAll('"', '');
            newStatus = cleanSsid; 
          }
        }
      } else {
        // Jika sedang diuji di Web, status otomatis terbaca "Online (Web)"
        newStatus = "Online (Web)";
      }

      User? user = _auth.currentUser;
      if (user != null) {
        // Menggunakan set dengan merge: true agar field otomatis dibuat jika belum ada
        await _firestore.collection('users').doc(user.uid).set({
          'status': newStatus,
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print("✅ Status Wi-Fi berhasil diperbarui ke Firebase: $newStatus");
      }
    } catch (e) {
      print("❌ Error saat memperbarui status Wi-Fi: $e");
    }
  }

  void listenToConnectivityChanges() {
    if (_isListening) return; 

    _isListening = true;
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      checkAndUpdatetWifiStatus();
    });
  }

  void dispose() {
    _subscription?.cancel();
    _isListening = false;
  }
}