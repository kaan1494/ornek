import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Web için Agora-free import
import 'video_call_screen_web.dart';
// Mobil için Agora'lı import (koşullu)
import 'video_call_screen.dart' as mobile;

/// Platform'a göre uygun video call ekranını döndüren factory
class VideoCallScreenFactory {
  static Widget create({
    required String channelName,
    required String userId,
    required String userType,
    required Map<String, dynamic> callData,
  }) {
    if (kIsWeb) {
      // Web için Agora-free version
      return VideoCallScreenWeb(
        channelName: channelName,
        userId: userId,
        userType: userType,
        callData: callData,
      );
    } else {
      // Mobil/Desktop için Agora version
      return mobile.VideoCallScreen(
        channelName: channelName,
        userId: userId,
        userType: userType,
        callData: callData,
      );
    }
  }
}
