import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'emergency_application_service.dart';

class TriageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Triaj sorularını döndürür
  static List<Map<String, dynamic>> getTriageQuestions() {
    return [
      {
        'id': 'consciousness',
        'category': 'Bilinç Durumu',
        'question': 'Bilinciniz açık mı?',
        'description': 'Etrafınızı görebiliyor, konuşabiliyor musunuz?',
        'icon': Icons.psychology,
        'yesPoints': 0,
        'noPoints': 100,
        'critical': true,
        'criticalAnswer': false,
      },
      {
        'id': 'breathing',
        'category': 'Solunum',
        'question': 'Nefes darlığı çekiyor musunuz?',
        'description': 'Nefes almakta zorlanıyor musunuz?',
        'icon': Icons.air,
        'yesPoints': 80,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'chest_pain',
        'category': 'Göğüs Ağrısı',
        'question': 'Göğüs ağrınız var mı?',
        'description': 'Göğsünüzde baskı, sıkışma veya ağrı hissi var mı?',
        'icon': Icons.favorite,
        'yesPoints': 50,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'bleeding',
        'category': 'Kanama',
        'question': 'Vücudunuzda kontrolsüz kanama var mı?',
        'description': 'Durdurulamayan aktif kanama var mı?',
        'icon': Icons.bloodtype,
        'yesPoints': 60,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'fever',
        'category': 'Ateş',
        'question': '38°C ve üzerinde ateşiniz var mı?',
        'description': 'Yüksek ateş, titreme veya üşüme var mı?',
        'icon': Icons.thermostat,
        'yesPoints': 30,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'dizziness',
        'category': 'Baş Dönmesi',
        'question': 'Şiddetli baş dönmesi veya baygınlık hissi var mı?',
        'description': 'Ayakta durmakta zorlanıyor musunuz?',
        'icon': Icons.psychology_alt,
        'yesPoints': 10,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'trauma',
        'category': 'Travma',
        'question': 'Yakın zamanda büyük bir travma geçirdiniz mi?',
        'description': 'Ciddi kaza, düşme veya darbe aldınız mı?',
        'icon': Icons.car_crash,
        'yesPoints': 70,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'pregnancy',
        'category': 'Gebelik',
        'question': 'Gebe misiniz ve acil bir şikayetiniz var mı?',
        'description': 'Hamilelik ile ilgili acil durum var mı?',
        'icon': Icons.pregnant_woman,
        'yesPoints': 30,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'speech_paralysis',
        'category': 'Nörolojik',
        'question': 'Konuşmada zorluk veya felç hissediyor musunuz?',
        'description':
            'Konuşamıyor, anlayamıyor veya vücut kontrolünü kaybediyor musunuz?',
        'icon': Icons.record_voice_over,
        'yesPoints': 80,
        'noPoints': 0,
        'critical': false,
      },
      {
        'id': 'urination',
        'category': 'İdrar/Dışkı',
        'question':
            'Son 12 saatte işeme veya dışkılamada büyük değişiklik yaşadınız mı?',
        'description': 'Hiç işeyememe veya kontrolsüz işeme var mı?',
        'icon': Icons.wc,
        'yesPoints': 10,
        'noPoints': 0,
        'critical': false,
      },
    ];
  }

  /// Toplam puana göre triaj seviyesini hesaplar
  static Map<String, dynamic> calculateTriageResult(int totalScore) {
    if (totalScore >= 100) {
      return {
        'level': 'Kırmızı Alan',
        'priority': 'emergency',
        'color': Colors.red.shade600,
        'icon': Icons.emergency,
        'message':
            'HAYATI TEHLİKE!\n\nLütfen hemen en yakın acil servise gidin. Durumunuz acil müdahale gerektiriyor.',
        'action': 'hospital',
        'waitTime': 0,
      };
    } else if (totalScore >= 40) {
      return {
        'level': 'Sarı Alan',
        'priority': 'medium',
        'color': Colors.orange.shade600,
        'icon': Icons.warning,
        'message':
            'ORTA RİSK\n\nDoktor kontrolü gerekiyor. Nöbetçi doktor ile görüşmeniz önerilir.',
        'action': 'doctor_consultation',
        'waitTime': 15,
      };
    } else {
      return {
        'level': 'Yeşil Alan',
        'priority': 'low',
        'color': Colors.green.shade600,
        'icon': Icons.check_circle,
        'message':
            'DÜŞÜK RİSK\n\nUzaktan değerlendirme yeterli. Doktor ile online görüşme yapabilirsiniz.',
        'action': 'video_consultation',
        'waitTime': 30,
      };
    }
  }

  /// Acil başvuru kaydı oluşturur
  static Future<String?> createEmergencyApplication({
    required String patientId,
    required String patientName,
    required int triageScore,
    required Map<int, bool> answers,
    required List<Map<String, dynamic>> questions,
    required String priority,
    String? hospitalId,
    Map<String, dynamic>? selectedHospital,
    String? selectedProvince,
    String? selectedDistrict,
  }) async {
    try {
      // Triaj sonucunu hesapla
      final triageResult = calculateTriageResult(triageScore);

      // Cevapları formatla
      final formattedAnswers = <Map<String, dynamic>>[];
      answers.forEach((questionIndex, answer) {
        if (questionIndex < questions.length) {
          final question = questions[questionIndex];
          final points = answer ? question['yesPoints'] : question['noPoints'];

          formattedAnswers.add({
            'questionId': question['id'],
            'question': question['question'],
            'answer': answer,
            'points': points,
            'category': question['category'],
          });
        }
      });

      // Hasta bilgilerini Firestore'dan al
      String patientPhone = '';
      String patientEmail = '';
      
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(patientId)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          patientPhone = userData['phone'] ?? '';
          patientEmail = userData['email'] ?? '';
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Hasta bilgileri alınamadı, varsayılan değerler kullanılıyor: $e');
        }
      }

      // Hastane bilgilerini düzenle
      final hospitalData = selectedHospital ?? {};
      if (selectedProvince != null) hospitalData['province'] = selectedProvince;
      if (selectedDistrict != null) hospitalData['district'] = selectedDistrict;

      // Yeni servisi kullanarak başvuru oluştur
      final applicationId = await EmergencyApplicationService.createApplication(
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        patientEmail: patientEmail,
        triageScore: triageScore,
        triageLevel: triageResult['level'],
        priority: priority,
        selectedHospital: hospitalData,
        answers: formattedAnswers,
        recommendation: triageResult['message'],
        notes: 'Triaj uygulaması ile oluşturuldu',
      );

      if (kDebugMode) {
        debugPrint('🏥 Acil başvuru oluşturuldu: $applicationId');
        debugPrint('🏥 Triaj seviyesi: ${triageResult['level']}');
        debugPrint('🏥 Toplam puan: $triageScore');
      }

      // Acil durum ise hastane bildirimini de oluştur
      if (priority == 'emergency') {
        await _createHospitalNotification(
          applicationId: applicationId!,
          patientId: patientId,
          patientName: patientName,
          triageScore: triageScore,
          triageLevel: triageResult['level'],
        );
      }

      return applicationId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Acil başvuru oluşturma hatası: $e');
      }
      rethrow;
    }
  }

  /// Hastane bildirimi oluşturur (acil durumlar için)
  static Future<void> _createHospitalNotification({
    required String applicationId,
    required String patientId,
    required String patientName,
    required int triageScore,
    required String triageLevel,
  }) async {
    try {
      final notificationData = {
        'applicationId': applicationId,
        'patientId': patientId,
        'patientName': patientName,
        'triageScore': triageScore,
        'triageLevel': triageLevel,
        'notificationType': 'emergency_arrival',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'acknowledged': false,
        'acknowledgedBy': null,
        'acknowledgedAt': null,
        'priority': 'critical',
        'message':
            '🚨 ACİL HASTA GELİYOR!\n\n'
            'Hasta: $patientName\n'
            'Triaj Seviyesi: $triageLevel\n'
            'Puan: $triageScore\n\n'
            'Hasta acil servise yönlendirildi.',
      };

      await _firestore
          .collection('hospital_notifications')
          .add(notificationData);

      if (kDebugMode) {
        debugPrint('🏥 Hastane bildirimi oluşturuldu: $applicationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane bildirimi oluşturma hatası: $e');
      }
    }
  }

  /// Hasta başvuru geçmişini getir
  static Stream<QuerySnapshot> getPatientApplications(String patientId) {
    return _firestore
        .collection('emergency_applications')
        .where('patientId', isEqualTo: patientId)
        .orderBy('applicationDate', descending: true)
        .snapshots();
  }

  /// Doktor için bekleyen başvuruları getir
  static Stream<QuerySnapshot> getPendingApplicationsForDoctor() {
    return _firestore
        .collection('emergency_applications')
        .where('status', isEqualTo: 'pending')
        .where('priority', whereIn: ['medium', 'low'])
        .orderBy('applicationDate', descending: false)
        .snapshots();
  }

  /// Admin için tüm başvuruları getir
  static Stream<QuerySnapshot> getAllApplicationsForAdmin() {
    return _firestore
        .collection('emergency_applications')
        .orderBy('applicationDate', descending: true)
        .snapshots();
  }

  /// Başvuru durumunu güncelle
  static Future<bool> updateApplicationStatus(
    String applicationId,
    String status, {
    String? doctorId,
    String? doctorName,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (doctorId != null) updateData['doctorId'] = doctorId;
      if (doctorName != null) updateData['doctorName'] = doctorName;
      if (notes != null) updateData['notes'] = notes;

      if (status == 'in_consultation') {
        updateData['consultationStarted'] = true;
        updateData['consultationStartTime'] = FieldValue.serverTimestamp();
      } else if (status == 'completed') {
        updateData['consultationCompleted'] = true;
        updateData['consultationEndTime'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('emergency_applications')
          .doc(applicationId)
          .update(updateData);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Başvuru durumu güncelleme hatası: $e');
      }
      return false;
    }
  }

  /// Hastane bildirimini onaylama
  static Future<bool> acknowledgeHospitalNotification(
    String notificationId,
    String acknowledgedBy,
  ) async {
    try {
      await _firestore
          .collection('hospital_notifications')
          .doc(notificationId)
          .update({
            'acknowledged': true,
            'acknowledgedBy': acknowledgedBy,
            'acknowledgedAt': FieldValue.serverTimestamp(),
            'status': 'acknowledged',
          });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane bildirimi onaylama hatası: $e');
      }
      return false;
    }
  }

  /// Triaj istatistikleri
  static Future<Map<String, int>> getTriageStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('emergency_applications');

      if (startDate != null) {
        query = query.where(
          'applicationDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where('applicationDate', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final stats = {
        'total': 0,
        'red': 0,
        'yellow': 0,
        'green': 0,
        'pending': 0,
        'completed': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = stats['total']! + 1;

        final triageLevel = data['triageLevel'] as String?;
        if (triageLevel?.contains('Kırmızı') == true) {
          stats['red'] = stats['red']! + 1;
        } else if (triageLevel?.contains('Sarı') == true) {
          stats['yellow'] = stats['yellow']! + 1;
        } else if (triageLevel?.contains('Yeşil') == true) {
          stats['green'] = stats['green']! + 1;
        }

        final status = data['status'] as String?;
        if (status == 'pending') {
          stats['pending'] = stats['pending']! + 1;
        } else if (status == 'completed') {
          stats['completed'] = stats['completed']! + 1;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Triaj istatistikleri hatası: $e');
      }
      return {
        'total': 0,
        'red': 0,
        'yellow': 0,
        'green': 0,
        'pending': 0,
        'completed': 0,
      };
    }
  }
}
