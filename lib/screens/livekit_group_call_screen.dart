import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveKitGroupCallScreen extends StatefulWidget {
  final String roomName;
  final String participantName;
  final String liveKitUrl; // Contoh: "wss://your-livekit-server.com"
  final String token;      // JWT Token yang digenerate oleh server backend Anda

  const LiveKitGroupCallScreen({
    Key? key,
    required this.roomName,
    required this.participantName,
    required this.liveKitUrl,
    required this.token,
  }) : super(key: key);

  @override
  State<LiveKitGroupCallScreen> createState() => _LiveKitGroupCallScreenState();
}

class _LiveKitGroupCallScreenState extends State<LiveKitGroupCallScreen> {
  Room? _room;
  bool _isConnecting = true;
  bool _isMuted = false;
  bool _isCameraOff = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    // 1. Minta izin Kamera & Mikrofon
    await [Permission.camera, Permission.microphone].request();

    try {
      // 2. Inisialisasi Room LiveKit
      _room = Room();

      // Tambahkan listener untuk mendeteksi perubahan state ruangan (peserta masuk/keluar)
      _room!.addListener(_onRoomChanged);

      // 3. Hubungkan ke server LiveKit
      await _room!.connect(
        widget.liveKitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // 4. Aktifkan kamera dan mikrofon secara default
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      await _room!.localParticipant?.setCameraEnabled(true);

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = "Gagal terhubung ke server LiveKit: $e";
      });
    }
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  void _toggleMute() async {
    if (_room?.localParticipant != null) {
      bool newMutedState = !_isMuted;
      await _room!.localParticipant!.setMicrophoneEnabled(!newMutedState);
      setState(() {
        _isMuted = newMutedState;
      });
    }
  }

  void _toggleCamera() async {
    if (_room?.localParticipant != null) {
      bool newCameraOffState = !_isCameraOff;
      await _room!.localParticipant!.setCameraEnabled(!newCameraOffState);
      setState(() {
        _isCameraOff = newCameraOffState;
      });
    }
  }

  Future<void> _disconnect() async {
    await _room?.disconnect();
    _room?.dispose();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _room?.removeListener(_onRoomChanged);
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          "Panggilan Grup: ${widget.roomName}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFAB873A)),
                  SizedBox(height: 16),
                  Text(
                    "Menghubungkan ke ruang panggilan...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Grid Peserta Rapat/Panggilan
                    Expanded(
                      child: _buildParticipantsGrid(),
                    ),
                    // Kontrol Panggilan (Mute, Akhiri, Kamera)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: const Color(0xFF2D2D2D),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'lk_mic',
                            backgroundColor: _isMuted ? Colors.red : const Color(0xFF3D3D3D),
                            onPressed: _toggleMute,
                            child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            heroTag: 'lk_end',
                            backgroundColor: Colors.red,
                            onPressed: _disconnect,
                            child: const Icon(Icons.call_end, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            heroTag: 'lk_cam',
                            backgroundColor: _isCameraOff ? Colors.red : const Color(0xFF3D3D3D),
                            onPressed: _toggleCamera,
                            child: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildParticipantsGrid() {
    if (_room == null) return const SizedBox.shrink();

    // Gabungkan local participant dan remote participants
    List<Participant> participants = [];
    if (_room!.localParticipant != null) {
      participants.add(_room!.localParticipant!);
    }
    participants.addAll(_room!.remoteParticipants.values);

    if (participants.isEmpty) {
      return const Center(
        child: Text("Belum ada peserta lain di ruangan.", style: TextStyle(color: Colors.white54)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: participants.length > 2 ? 2 : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return _buildParticipantTile(participants[index]);
      },
    );
  }

  Widget _buildParticipantTile(Participant participant) {
    // Cari video track aktif dari peserta
    VideoTrack? videoTrack;
    for (var pub in participant.videoTrackPublications) {
      if (pub.track != null && !pub.muted) {
        videoTrack = pub.track as VideoTrack?;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFAB873A), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (videoTrack != null)
            SizedBox.expand(
              child: VideoTrackRenderer(videoTrack),
            )
          else
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF3D3D3D),
                child: Text(
                  participant.identity.isNotEmpty ? participant.identity[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          // Label Nama Peserta di pojok kiri bawah
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                participant.identity,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}