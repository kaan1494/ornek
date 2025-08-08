import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AgoraService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agora App ID - Gerçek projede environment variable'dan alınmalı
  static const String appId = "25ca70bf1f1f466e9669b9e5142ef57c";

  // Geçici token - Production'da token server kullanılmalı
  static const String tempToken =
      ""; // Şimdilik boş, test için token olmadan deneyeceğiz

  /// Video call kanalı oluştur
  static Future<String?> createVideoCall({
    required String doctorId,
    required String patientId,
    required String applicationId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Benzersiz kanal adı oluştur
      final channelName = _generateChannelName(doctorId, patientId);

      // Call verilerini Firestore'a kaydet
      final callDoc = await _firestore.collection('video_calls').add({
        'channelName': channelName,
        'doctorId': doctorId,
        'patientId': patientId,
        'applicationId': applicationId,
        'status': 'pending', // pending, active, ended
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': null,
        'endedAt': null,
        'duration': 0,
        'doctorJoined': false,
        'patientJoined': false,
        'additionalData': additionalData ?? {},
      });

      if (kDebugMode) {
        debugPrint(
          '🎥 Video call oluşturuldu: ${callDoc.id}, kanal: $channelName',
        );
      }

      return callDoc.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video call oluşturma hatası: $e');
      }
      return null;
    }
  }

  /// Kanal adı oluştur
  static String _generateChannelName(String doctorId, String patientId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'call_${doctorId}_${patientId}_${timestamp}_$random';
  }

  /// Video call durumunu güncelle
  static Future<bool> updateCallStatus({
    required String callId,
    required String status,
    String? userId,
    String? userType, // 'doctor' or 'patient'
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Kullanıcı katılım durumunu güncelle
      if (userId != null && userType != null) {
        if (userType == 'doctor') {
          updates['doctorJoined'] = status == 'active';
        } else if (userType == 'patient') {
          updates['patientJoined'] = status == 'active';
        }
      }

      // Call başlatıldıysa başlangıç zamanını kaydet
      if (status == 'active') {
        updates['startedAt'] = FieldValue.serverTimestamp();
      }

      // Call bittiyse bitiş zamanını kaydet
      if (status == 'ended') {
        updates['endedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('video_calls').doc(callId).update(updates);

      if (kDebugMode) {
        debugPrint('🎥 Call durumu güncellendi: $callId -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call durum güncelleme hatası: $e');
      }
      return false;
    }
  }

  /// Video call bilgilerini getir
  static Future<Map<String, dynamic>?> getCallInfo(String callId) async {
    try {
      final doc = await _firestore.collection('video_calls').doc(callId).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call bilgisi getirme hatası: $e');
      }
      return null;
    }
  }

  /// Aktif call'ları dinle
  static Stream<DocumentSnapshot> listenToCall(String callId) {
    return _firestore.collection('video_calls').doc(callId).snapshots();
  }

  /// Call geçmişini getir
  static Future<List<Map<String, dynamic>>> getCallHistory({
    String? doctorId,
    String? patientId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('video_calls');

      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call geçmişi getirme hatası: $e');
      }
      return [];
    }
  }

  /// Call süresini hesapla ve kaydet
  static Future<bool> calculateAndSaveCallDuration(String callId) async {
    try {
      final callDoc = await _firestore
          .collection('video_calls')
          .doc(callId)
          .get();

      if (!callDoc.exists) return false;

      final data = callDoc.data()!;
      final startedAt = data['startedAt'] as Timestamp?;
      final endedAt = data['endedAt'] as Timestamp?;

      if (startedAt != null && endedAt != null) {
        final duration = endedAt.seconds - startedAt.seconds;

        await _firestore.collection('video_calls').doc(callId).update({
          'duration': duration,
        });

        if (kDebugMode) {
          debugPrint('🎥 Call süresi hesaplandı: $duration saniye');
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call süresi hesaplama hatası: $e');
      }
      return false;
    }
  }

  /// Token oluştur (Gelecekte token server ile)
  static Future<String?> generateToken({
    required String channelName,
    required int uid,
    String role = 'publisher',
  }) async {
    try {
      // Şimdilik null döndürüyoruz, token olmadan test edeceğiz
      // Production'da buraya token server API çağrısı gelecek

      if (kDebugMode) {
        debugPrint('🎥 Token oluşturma istendi: $channelName, $uid');
      }

      return null; // Test için token olmadan deneyeceğiz
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token oluşturma hatası: $e');
      }
      return null;
    }
  }

  /// Call kalitesi metrikleri kaydet
  static Future<bool> saveCallQualityMetrics({
    required String callId,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      await _firestore
          .collection('video_calls')
          .doc(callId)
          .collection('quality_metrics')
          .add({...metrics, 'timestamp': FieldValue.serverTimestamp()});

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call kalite metrikleri kaydetme hatası: $e');
      }
      return false;
    }
  }

  /// Call raporunu oluştur
  static Future<Map<String, dynamic>?> generateCallReport(String callId) async {
    try {
      final callDoc = await _firestore
          .collection('video_calls')
          .doc(callId)
          .get();

      if (!callDoc.exists) return null;

      final data = callDoc.data()!;

      // Kalite metrikleri topla
      final metricsSnapshot = await _firestore
          .collection('video_calls')
          .doc(callId)
          .collection('quality_metrics')
          .get();

      final metrics = metricsSnapshot.docs.map((doc) => doc.data()).toList();

      return {
        'callInfo': data,
        'qualityMetrics': metrics,
        'reportGeneratedAt': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Call raporu oluşturma hatası: $e');
      }
      return null;
    }
  }
}
