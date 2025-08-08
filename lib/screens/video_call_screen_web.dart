import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/agora_service.dart';

/// Web platformu için Agora-free video call simülasyon ekranı
class VideoCallScreenWeb extends StatefulWidget {
  final String channelName;
  final String userId;
  final String userType; // 'doctor' veya 'patient'
  final Map<String, dynamic> callData;

  const VideoCallScreenWeb({
    super.key,
    required this.channelName,
    required this.userId,
    required this.userType,
    required this.callData,
  });

  @override
  State<VideoCallScreenWeb> createState() => _VideoCallScreenWebState();
}

class _VideoCallScreenWebState extends State<VideoCallScreenWeb> {
  bool _localUserJoined = false;
  bool _remoteUserJoined = false;
  bool _muted = false;
  bool _videoEnabled = true;
  bool _speakerEnabled = true;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startWebSimulation();
    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  void _startWebSimulation() async {
    if (kDebugMode) {
      debugPrint("🌐 Web Video Call Simülasyonu Başlatılıyor");
    }

    // Yerel kullanıcı katılımı simülasyonu
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _localUserJoined = true;
    });

    // Uzak kullanıcı katılımı simülasyonu
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _remoteUserJoined = true;
    });

    // Firestore'da call durumunu güncelle
    await AgoraService.updateCallStatus(
      callId: widget.callData['id'] ?? 'web_demo',
      status: 'active',
      userId: widget.userId,
      userType: widget.userType,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    if (kDebugMode) {
      debugPrint("🎤 Mikrofon: ${_muted ? 'Kapalı' : 'Açık'} (Web Simülasyon)");
    }
  }

  void _onToggleVideo() {
    setState(() {
      _videoEnabled = !_videoEnabled;
    });
    if (kDebugMode) {
      debugPrint(
        "📹 Video: ${_videoEnabled ? 'Açık' : 'Kapalı'} (Web Simülasyon)",
      );
    }
  }

  void _onToggleSpeaker() {
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });
    if (kDebugMode) {
      debugPrint(
        "🔊 Hoparlör: ${_speakerEnabled ? 'Açık' : 'Kapalı'} (Web Simülasyon)",
      );
    }
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ana video alanı (uzak kullanıcı)
          Center(child: _buildRemoteVideo()),

          // Üst bilgi çubuğu
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // Alt kontrol çubuğu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // Küçük video alanı (yerel kullanıcı)
          Positioned(top: 100, right: 20, child: _buildLocalVideo()),

          // Bağlantı durumu
          if (!_localUserJoined || !_remoteUserJoined)
            Container(
              color: Colors.black54,
              child: Center(child: _buildConnectionStatus()),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isDoctor = widget.userType == 'doctor';
    final otherUserType = isDoctor ? 'Hasta' : 'Doktor';
    final otherUserName = isDoctor
        ? widget.callData['patientName'] ?? 'Hasta'
        : widget.callData['doctorName'] ?? 'Doktor';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDoctor ? Colors.blue : Colors.green,
              child: Icon(
                isDoctor ? Icons.medical_services : Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    otherUserType,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'WEB DEMO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mikrofon kontrol
            _buildControlButton(
              icon: _muted ? Icons.mic_off : Icons.mic,
              isActive: !_muted,
              onPressed: _onToggleMute,
              color: _muted ? Colors.red : Colors.white,
            ),

            // Video kontrol
            _buildControlButton(
              icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
              isActive: _videoEnabled,
              onPressed: _onToggleVideo,
              color: !_videoEnabled ? Colors.red : Colors.white,
            ),

            // Hoparlör kontrol
            _buildControlButton(
              icon: _speakerEnabled ? Icons.volume_up : Icons.volume_off,
              isActive: _speakerEnabled,
              onPressed: _onToggleSpeaker,
              color: Colors.white,
            ),

            // Aramayı sonlandır
            _buildControlButton(
              icon: Icons.call_end,
              isActive: false,
              onPressed: () => _onCallEnd(context),
              color: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required Color color,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: color,
        iconSize: 28,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _localUserJoined
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _videoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'WEB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteUserJoined) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, color: Colors.white, size: 80),
              SizedBox(height: 16),
              Text(
                'Karşı Taraf',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Web Demo Modunda',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.computer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tarayıcı Simülasyonu',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                color: Colors.white.withValues(alpha: 0.7),
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Karşı taraf bekleniyor...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '(Web Demo Modu - Simülasyon)',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildConnectionStatus() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
        const SizedBox(height: 20),
        Text(
          _localUserJoined
              ? 'Karşı taraf bekleniyor...'
              : 'Web simülasyonu başlatılıyor...',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          _localUserJoined
              ? 'Demo modunda karşı taraf simüle ediliyor'
              : 'Tarayıcı uyumluluğu için simülasyon hazırlanıyor',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                'Gerçek video call için mobil cihaz kullanın',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
