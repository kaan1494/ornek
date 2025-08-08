import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uygun doktor bulma
  static Future<Map<String, dynamic>?> findAvailableDoctor({
    String? hospitalId,
    required String priority,
  }) async {
    try {
      // Önce belirtilen hastanedeki nöbetçi doktorları ara
      if (hospitalId != null) {
        final hospitalDoctors = await _findDoctorsInHospital(hospitalId);
        if (hospitalDoctors.isNotEmpty) {
          return hospitalDoctors.first;
        }
      }

      // Hastane belirtilmemişse veya o hastanede doktor yoksa genel arama yap
      return await _findAnyAvailableDoctor(priority);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor arama hatası: $e');
      }
      return null;
    }
  }

  /// Belirli hastanedeki uygun doktorları bul
  static Future<List<Map<String, dynamic>>> _findDoctorsInHospital(
    String hospitalId,
  ) async {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;

      // Nöbetçi doktorları sorgula
      final snapshot = await _firestore
          .collection('doctors')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('isActive', isEqualTo: true)
          .where('isOnDuty', isEqualTo: true)
          .where('availableForConsultation', isEqualTo: true)
          .get();

      final availableDoctors = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final shiftStart = data['shiftStartHour'] as int? ?? 8;
        final shiftEnd = data['shiftEndHour'] as int? ?? 17;

        // Nöbet saatleri kontrolü
        bool isInShift = false;
        if (shiftStart <= shiftEnd) {
          // Normal vardiya (örn: 08:00 - 17:00)
          isInShift = currentHour >= shiftStart && currentHour < shiftEnd;
        } else {
          // Gece vardiyası (örn: 22:00 - 06:00)
          isInShift = currentHour >= shiftStart || currentHour < shiftEnd;
        }

        if (isInShift) {
          availableDoctors.add({
            'id': doc.id,
            'name': data['name'],
            'specialty': data['specialty'],
            'hospital': data['hospitalName'],
            'phone': data['phone'],
            'experience': data['experienceYears'],
            'rating': data['rating'] ?? 4.5,
            'isOnline': data['isOnline'] ?? false,
            'lastSeen': data['lastSeen'],
          });
        }
      }

      // Online olan doktorları öncelik ver
      availableDoctors.sort((a, b) {
        if (a['isOnline'] && !b['isOnline']) return -1;
        if (!a['isOnline'] && b['isOnline']) return 1;
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });

      return availableDoctors;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane doktor arama hatası: $e');
      }
      return [];
    }
  }

  /// Genel uygun doktor arama
  static Future<Map<String, dynamic>?> _findAnyAvailableDoctor(
    String priority,
  ) async {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;

      // Acil durum önceliğine göre arama
      final baseQuery = _firestore
          .collection('doctors')
          .where('isActive', isEqualTo: true)
          .where('availableForConsultation', isEqualTo: true);

      QuerySnapshot snapshot;

      if (priority == 'medium') {
        // Sarı alan - uzman doktor tercihi
        snapshot = await baseQuery
            .where('specialty', whereNotIn: ['Genel Pratisyen'])
            .limit(10)
            .get();
      } else {
        // Yeşil alan - genel pratisyen yeterli
        snapshot = await baseQuery.limit(10).get();
      }

      final availableDoctors = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final shiftStart = data['shiftStartHour'] as int? ?? 8;
        final shiftEnd = data['shiftEndHour'] as int? ?? 17;

        // Nöbet saatleri kontrolü
        bool isInShift = false;
        if (shiftStart <= shiftEnd) {
          isInShift = currentHour >= shiftStart && currentHour < shiftEnd;
        } else {
          isInShift = currentHour >= shiftStart || currentHour < shiftEnd;
        }

        if (isInShift) {
          availableDoctors.add({
            'id': doc.id,
            'name': data['name'],
            'specialty': data['specialty'],
            'hospital': data['hospitalName'],
            'phone': data['phone'],
            'experience': data['experienceYears'],
            'rating': data['rating'] ?? 4.5,
            'isOnline': data['isOnline'] ?? false,
            'lastSeen': data['lastSeen'],
          });
        }
      }

      if (availableDoctors.isEmpty) {
        return null;
      }

      // En uygun doktoru seç (online, yüksek rating)
      availableDoctors.sort((a, b) {
        if (a['isOnline'] && !b['isOnline']) return -1;
        if (!a['isOnline'] && b['isOnline']) return 1;
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });

      return availableDoctors.first;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Genel doktor arama hatası: $e');
      }
      return null;
    }
  }

  /// Konsültasyon kaydı oluştur
  static Future<String?> createConsultation({
    required String applicationId,
    required String patientId,
    required String doctorId,
    required String triageScore,
  }) async {
    try {
      final consultationData = {
        'applicationId': applicationId,
        'patientId': patientId,
        'doctorId': doctorId,
        'triageScore': triageScore,
        'status': 'waiting',
        'type': 'video_consultation',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledTime': FieldValue.serverTimestamp(),
        'startTime': null,
        'endTime': null,
        'duration': 0,
        'notes': '',
        'prescription': '',
        'followUpRequired': false,
        'rating': null,
        'feedback': '',
        'channelName': 'consultation_$applicationId',
      };

      final docRef = await _firestore
          .collection('consultations')
          .add(consultationData);

      // Başvuru durumunu güncelle
      await _firestore
          .collection('emergency_applications')
          .doc(applicationId)
          .update({
            'status': 'consultation_scheduled',
            'consultationId': docRef.id,
            'assignedDoctorId': doctorId,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      // Doktora bildirim gönder
      await _createDoctorNotification(
        doctorId: doctorId,
        consultationId: docRef.id,
        patientId: patientId,
        applicationId: applicationId,
      );

      if (kDebugMode) {
        debugPrint('✅ Konsültasyon oluşturuldu: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon oluşturma hatası: $e');
      }
      return null;
    }
  }

  /// Video görüşme başlat
  static Future<bool> initiateVideoCall({
    required String patientId,
    required String doctorId,
    required String applicationId,
  }) async {
    try {
      final consultationId = 'consultation_$applicationId';

      // Konsültasyon durumunu güncelle
      await _firestore
          .collection('consultations')
          .where('applicationId', isEqualTo: applicationId)
          .get()
          .then((snapshot) async {
            if (snapshot.docs.isNotEmpty) {
              await snapshot.docs.first.reference.update({
                'status': 'in_progress',
                'startTime': FieldValue.serverTimestamp(),
                'channelName': consultationId,
              });
            }
          });

      // Doktor durumunu güncelle
      await _firestore.collection('doctors').doc(doctorId).update({
        'currentConsultationId': consultationId,
        'isInConsultation': true,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Video görüşme başlatıldı: $consultationId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video görüşme başlatma hatası: $e');
      }
      return false;
    }
  }

  /// Konsültasyon tamamla
  static Future<bool> completeConsultation({
    required String consultationId,
    required int duration,
    String? notes,
    String? prescription,
    bool followUpRequired = false,
  }) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'duration': duration,
        'notes': notes ?? '',
        'prescription': prescription ?? '',
        'followUpRequired': followUpRequired,
      });

      // İlgili başvuruyu da tamamla
      final consultationDoc = await _firestore
          .collection('consultations')
          .doc(consultationId)
          .get();

      if (consultationDoc.exists) {
        final data = consultationDoc.data()!;
        await _firestore
            .collection('emergency_applications')
            .doc(data['applicationId'])
            .update({
              'status': 'completed',
              'consultationCompleted': true,
              'consultationEndTime': FieldValue.serverTimestamp(),
              'doctorNotes': notes,
              'prescription': prescription,
            });

        // Doktor durumunu güncelle
        await _firestore.collection('doctors').doc(data['doctorId']).update({
          'currentConsultationId': null,
          'isInConsultation': false,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }

      if (kDebugMode) {
        debugPrint('✅ Konsültasyon tamamlandı: $consultationId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon tamamlama hatası: $e');
      }
      return false;
    }
  }

  /// Doktora bildirim gönder
  static Future<void> _createDoctorNotification({
    required String doctorId,
    required String consultationId,
    required String patientId,
    required String applicationId,
  }) async {
    try {
      final notificationData = {
        'doctorId': doctorId,
        'type': 'new_consultation',
        'title': 'Yeni Konsültasyon Talebi',
        'message': 'Online konsültasyon talebi bekliyor.',
        'consultationId': consultationId,
        'patientId': patientId,
        'applicationId': applicationId,
        'status': 'unread',
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      };

      await _firestore.collection('doctor_notifications').add(notificationData);

      if (kDebugMode) {
        debugPrint('✅ Doktor bildirimi gönderildi: $doctorId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor bildirimi hatası: $e');
      }
    }
  }

  /// Konsültasyon geçmişi getir
  static Stream<QuerySnapshot> getConsultationHistory(String patientId) {
    return _firestore
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Doktor için bekleyen konsültasyonları getir
  static Stream<QuerySnapshot> getPendingConsultationsForDoctor(
    String doctorId,
  ) {
    return _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['waiting', 'in_progress'])
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Konsültasyon detayını getir
  static Future<Map<String, dynamic>?> getConsultationDetails(
    String consultationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('consultations')
          .doc(consultationId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon detay hatası: $e');
      }
      return null;
    }
  }

  /// Konsültasyon değerlendirmesi ekle
  static Future<bool> rateConsultation({
    required String consultationId,
    required double rating,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('consultations').doc(consultationId).update({
        'rating': rating,
        'feedback': feedback ?? '',
        'ratedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Konsültasyon değerlendirildi: $consultationId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon değerlendirme hatası: $e');
      }
      return false;
    }
  }
}
