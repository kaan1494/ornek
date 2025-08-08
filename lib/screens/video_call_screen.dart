import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userId;
  final String userType; // 'doctor' veya 'patient'
  final Map<String, dynamic> callData;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userId,
    required this.userType,
    required this.callData,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoEnabled = true;
  bool _speakerEnabled = true;
  late RtcEngine _engine;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    initAgora();
    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> initAgora() async {
    // Web platformunda Agora çalışmıyor, simülasyon yap
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint("🌐 Web platformu - Video call simülasyonu başlatılıyor");
      }

      // Web için simülasyon
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _localUserJoined = true;
        _remoteUid = 12345; // Simülasyon için sahte remote ID
      });

      // Call durumunu güncelle
      await AgoraService.updateCallStatus(
        callId: widget.callData['id'],
        status: 'active',
        userId: widget.userId,
        userType: widget.userType,
      );

      return;
    }

    // Mobil/Desktop platformlar için gerçek Agora
    // İzin kontrolü
    await [Permission.microphone, Permission.camera].request();

    // Agora Engine oluştur
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: AgoraService.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (kDebugMode) {
            debugPrint("🎥 Kanala başarıyla katıldı: ${connection.channelId}");
          }
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (kDebugMode) {
            debugPrint("🎥 Uzak kullanıcı katıldı: $remoteUid");
          }
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              if (kDebugMode) {
                debugPrint("🎥 Uzak kullanıcı ayrıldı: $remoteUid");
              }
              setState(() {
                _remoteUid = null;
              });
            },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          if (kDebugMode) {
            debugPrint("🎥 Token yenilenecek");
          }
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // Kanala katıl
    await _engine.joinChannel(
      token: AgoraService.tempToken,
      channelId: widget.channelName,
      uid: int.parse(widget.userId),
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    _callTimer?.cancel();

    if (!kIsWeb) {
      await _engine.leaveChannel();
      await _engine.release();
    }
  }

  // Mikrofonmu aç/kapat
  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });

    if (!kIsWeb) {
      _engine.muteLocalAudioStream(_muted);
    }
  }

  // Kamerayı aç/kapat
  void _onToggleVideo() {
    setState(() {
      _videoEnabled = !_videoEnabled;
    });

    if (!kIsWeb) {
      _engine.muteLocalVideoStream(!_videoEnabled);
    }
  }

  // Hoparlörü aç/kapat
  void _onToggleSpeaker() {
    setState(() {
      _speakerEnabled = !_speakerEnabled;
    });

    if (!kIsWeb) {
      _engine.setEnableSpeakerphone(_speakerEnabled);
    }
  }

  // Aramayı sonlandır
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
          Center(child: _remoteVideo()),

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
          if (!_localUserJoined || _remoteUid == null)
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
            ? kIsWeb
                  ? Container(
                      color: Colors.blue.shade300,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam, color: Colors.white, size: 30),
                            SizedBox(height: 4),
                            Text(
                              'Sen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
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

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return kIsWeb
          ? Container(
              color: Colors.green.shade300,
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
                  ],
                ),
              ),
            )
          : AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
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
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '(Web Demo Modu)',
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          _localUserJoined ? 'Karşı taraf bekleniyor...' : 'Bağlanıyor...',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          _localUserJoined
              ? 'Doktor/hasta bağlanmayı bekliyor'
              : 'Video çağrısı başlatılıyor',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
