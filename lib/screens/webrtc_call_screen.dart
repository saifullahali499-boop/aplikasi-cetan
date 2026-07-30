import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCCallScreen extends StatefulWidget {
  final String callId; // ID unik ruangan/percakapan
  final bool isVideoCall;
  final String receiverName;
  final bool isCaller; // True jika user ini yang menelepon, False jika menerima

  const WebRTCCallScreen({
    Key? key,
    required this.callId,
    required this.isVideoCall,
    required this.receiverName,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<WebRTCCallScreen> createState() => _WebRTCCallScreenState();
}

class _WebRTCCallScreenState extends State<WebRTCCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isConnected = false;
  bool _hasSetRemoteDescription = false; // Bendera pengaman remote description

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    // Meminta izin kamera dan mikrofon
    await [Permission.camera, Permission.microphone].request();

    await _startLocalStream();
    await _createPeerConnection();

    if (widget.isCaller) {
      await _createOffer();
    } else {
      await _joinCall();
    }
  }

  Future<void> _startLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': widget.isVideoCall
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      debugPrint("Error getting user media: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // Tambahkan stream lokal ke peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    // Dengarkan saat ada stream remote (lawan bicara) masuk
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
          _isConnected = true;
        });
      }
    };

    // Kirim ICE Candidate ke Firestore agar ditemukan lawan bicara
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate == null) return;
      String targetCollection = widget.isCaller ? 'callerCandidates' : 'calleeCandidates';
      _firestore
          .collection('calls')
          .doc(widget.callId)
          .collection(targetCollection)
          .add(candidate.toMap());
    };
  }

  Future<void> _createOffer() async {
    DocumentReference callRef = _firestore.collection('calls').doc(widget.callId);

    // Buat SDP Offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> callData = {
      'offer': offer.toMap(),
      'callerId': _auth.currentUser?.uid,
      'status': 'calling',
    };

    await callRef.set(callData);

    // Tunggu balasan (Answer) dari Callee (penerima)
    callRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data['answer'] != null && !_hasSetRemoteDescription) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
        setState(() {
          _hasSetRemoteDescription = true;
        });
      }
    });

    // Dengarkan ICE Candidate dari Callee
    callRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  Future<void> _joinCall() async {
    DocumentReference callRef = _firestore.collection('calls').doc(widget.callId);
    var snapshot = await callRef.get();

    if (!snapshot.exists) return;
    var data = snapshot.data() as Map<String, dynamic>;

    var offer = data['offer'];
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // Buat SDP Answer
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await callRef.update({'answer': answer.toMap(), 'status': 'answered'});

    // Dengarkan ICE Candidate dari Caller
    callRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
      setState(() {
        _isMuted = !enabled;
      });
    }
  }

  void _toggleCamera() {
    if (_localStream != null && widget.isVideoCall) {
      bool enabled = _localStream!.getVideoTracks()[0].enabled;
      _localStream!.getVideoTracks()[0].enabled = !enabled;
      setState(() {
        _isCameraOff = !enabled;
      });
    }
  }

  void _switchCamera() {
    if (_localStream != null && widget.isVideoCall) {
      _localStream!.getVideoTracks()[0].switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    }
  }

  Future<void> _endCall() async {
    try {
      // Bersihkan stream lokal & remote
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
      await _peerConnection?.close();

      // Hapus dokumen call dari Firestore
      await _firestore.collection('calls').doc(widget.callId).delete();
    } catch (e) {
      debugPrint("Error ending call: $e");
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. TAMPILAN UTAMA (Video Lawan Bicara / Background Suara)
            if (widget.isVideoCall)
              _isConnected
                  ? SizedBox.expand(child: RTCVideoView(_remoteRenderer))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFFD2B46A)),
                          const SizedBox(height: 16),
                          Text(
                            widget.isCaller
                                ? 'Menghubungkan ke ${widget.receiverName}...'
                                : 'Memuat panggilan dari ${widget.receiverName}...',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF2D2D2D),
                      child: Icon(Icons.person, size: 70, color: Color(0xFFD2B46A)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.receiverName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isConnected ? 'Panggilan Suara Aktif' : 'Memanggil...',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // 2. VIDEO LOKAL KECIL (PiP di pojok kanan atas untuk video call)
            if (widget.isVideoCall)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD2B46A), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                ),
              ),

            // 3. HEADER NAMA
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.receiverName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // 4. TOMBOL KONTROL DI BAWAH
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'mic',
                    backgroundColor: _isMuted ? Colors.red : const Color(0xFF2D2D2D),
                    onPressed: _toggleMute,
                    child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    heroTag: 'end_call',
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  if (widget.isVideoCall) ...[
                    FloatingActionButton(
                      heroTag: 'camera',
                      backgroundColor: _isCameraOff ? Colors.red : const Color(0xFF2D2D2D),
                      onPressed: _toggleCamera,
                      child: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'switch_camera',
                      backgroundColor: const Color(0xFF2D2D2D),
                      onPressed: _switchCamera,
                      child: const Icon(Icons.switch_camera, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}