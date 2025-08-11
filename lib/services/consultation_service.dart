import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test fonksiyonu - Hacettepe hastanesi için doktor var mı kontrol et
  static Future<void> testHacettepeDoctor() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪===========================================');
        debugPrint('🧪 HACETTEPE HASTANESİ TEST BAŞLIYOR...');
        debugPrint('🧪===========================================');
      }
      
      final hospitalId = 'ank_altindag_1'; // Hacettepe ID'si
      final now = DateTime.now();
      
      if (kDebugMode) {
        debugPrint('🕒 Şu anki zaman: $now');
        debugPrint('🏥 Aranan hastane ID: $hospitalId');
      }
      
      // 1. Collection'ın var olup olmadığını kontrol et
      final collections = ['doctor_shifts', 'users', 'emergency_applications'];
      for (final collectionName in collections) {
        try {
          final testQuery = await _firestore.collection(collectionName).limit(1).get();
          if (kDebugMode) {
            debugPrint('📊 $collectionName collection: ${testQuery.docs.isNotEmpty ? 'VAR' : 'BOŞ'}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ $collectionName collection erişim hatası: $e');
          }
        }
      }
      
      // 2. Tüm nöbet kayıtlarını al
      final allShifts = await _firestore
          .collection('doctor_shifts')
          .get();
          
      if (kDebugMode) {
        debugPrint('📊 Toplam nöbet kaydı: ${allShifts.docs.length}');
        
        if (allShifts.docs.isEmpty) {
          debugPrint('⚠️ HİÇ NÖBET KAYDI BULUNAMADI!');
          debugPrint('   Admin panelinden doktor atanmış mı?');
          debugPrint('   Firestore bağlantısı çalışıyor mu?');
        }
        
        for (int i = 0; i < allShifts.docs.length; i++) {
          final doc = allShifts.docs[i];
          final data = doc.data();
          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          final isActive = startDate != null && endDate != null && 
                          startDate.isBefore(now) && endDate.isAfter(now);
          
          debugPrint('   📋 Nöbet Kaydı #${i + 1}:');
          debugPrint('      Doc ID: ${doc.id}');
          debugPrint('      Hastane: ${data['hospitalId']} (${data['hospitalName']})');
          debugPrint('      Doktor: ${data['doctorName']} (ID: ${data['doctorId']})');
          debugPrint('      Durum: ${data['status']}');
          debugPrint('      Nöbet Türü: ${data['shiftType']}');
          debugPrint('      Başlangıç: $startDate');
          debugPrint('      Bitiş: $endDate');
          debugPrint('      Şu an aktif: $isActive');
          debugPrint('      Acil müdahale: ${data['availableForEmergency']}');
          debugPrint('      --------------------------------');
        }
      }
      
      // 3. Hacettepe için özel kontrol
      final hacettepeShifts = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();
          
      if (kDebugMode) {
        debugPrint('🏥 Hacettepe ($hospitalId) için ${hacettepeShifts.docs.length} nöbet kaydı bulundu');
        
        if (hacettepeShifts.docs.isEmpty) {
          debugPrint('❌ HACETTEPE HASTANESİ İÇİN HİÇ NÖBET KAYDI YOK!');
          debugPrint('   Bu hastane ID\'si doğru mu: $hospitalId');
          debugPrint('   Admin panelinden bu hastaneye doktor atanması gerekiyor.');
          
          // Diğer hastane ID'lerini göster
          debugPrint('   Mevcut hastane ID\'leri:');
          for (final doc in allShifts.docs) {
            final data = doc.data();
            debugPrint('     - ${data['hospitalId']} (${data['hospitalName']})');
          }
        } else {
          for (final doc in hacettepeShifts.docs) {
            final data = doc.data();
            debugPrint('   ✅ Hacettepe Nöbeti:');
            debugPrint('      Doktor: ${data['doctorName']}');
            debugPrint('      Durum: ${data['status']}');
            debugPrint('      Nöbet Türü: ${data['shiftType']}');
          }
        }
      }
      
      // 4. Aktif nöbetleri kontrol et
      final activeShifts = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .get();
          
      if (kDebugMode) {
        debugPrint('⏰ Şu anda aktif nöbet sayısı: ${activeShifts.docs.length}');
        
        if (activeShifts.docs.isEmpty) {
          debugPrint('❌ ŞU ANDA AKTİF NÖBET YOK!');
          debugPrint('   Sebepleri:');
          debugPrint('   1. Nöbet zamanları geçmiş olabilir');
          debugPrint('   2. Nöbet durumu \'active\' değil');
          debugPrint('   3. Tarih filtreleri eşleşmiyor');
        }
        
        for (final doc in activeShifts.docs) {
          final data = doc.data();
          debugPrint('   ✅ Aktif Nöbet:');
          debugPrint('      Doktor: ${data['doctorName']}');
          debugPrint('      Nöbet Türü: ${data['shiftType']}');
          debugPrint('      Başlangıç: ${(data['startDate'] as Timestamp).toDate()}');
          debugPrint('      Bitiş: ${(data['endDate'] as Timestamp).toDate()}');
        }
        
        debugPrint('🧪===========================================');
        debugPrint('🧪 TEST TAMAMLANDI');
        debugPrint('🧪===========================================');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Test hatası: $e');
        debugPrint('   Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Uygun doktor bulma
  static Future<Map<String, dynamic>?> findAvailableDoctor({
    String? hospitalId,
    required String priority,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Doktor arama başlatılıyor...');
        debugPrint('   Hastane ID: $hospitalId');
        debugPrint('   Öncelik: $priority');
      }

      // Önce belirtilen hastanedeki nöbetçi doktorları ara
      if (hospitalId != null) {
        final hospitalDoctors = await _findDoctorsInHospital(hospitalId);
        if (hospitalDoctors.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Hastane $hospitalId için ${hospitalDoctors.length} doktor bulundu');
          }
          return hospitalDoctors.first;
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Hastane $hospitalId için doktor bulunamadı, genel aramaya geçiliyor...');
          }
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
      
      if (kDebugMode) {
        debugPrint('🏥 Hastane $hospitalId için doktor aranıyor...');
        debugPrint('   Şu anki zaman: $now');
      }
      
      // Önce aktif nöbetlerdeki doktorları kontrol et
      final shiftSnapshot = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .get();

      if (kDebugMode) {
        debugPrint('📋 Firestore sorgusu tamamlandı: ${shiftSnapshot.docs.length} nöbet kaydı bulundu');
      }

      final availableDoctors = <Map<String, dynamic>>[];

      for (final shiftDoc in shiftSnapshot.docs) {
        final shiftData = shiftDoc.data();
        final doctorId = shiftData['doctorId'] as String;
        
        if (kDebugMode) {
          debugPrint('   🔍 Nöbet kaydı kontrol ediliyor:');
          debugPrint('      Doktor ID: $doctorId');
          debugPrint('      Doktor Adı: ${shiftData['doctorName']}');
          debugPrint('      Hastane: ${shiftData['hospitalName']}');
          debugPrint('      Başlangıç: ${shiftData['startDate']?.toDate()}');
          debugPrint('      Bitiş: ${shiftData['endDate']?.toDate()}');
          debugPrint('      Durum: ${shiftData['status']}');
          debugPrint('      Acil Müdahale: ${shiftData['availableForEmergency']}');
        }
        
        try {
          // Doktor bilgilerini al
          final doctorDoc = await _firestore
              .collection('users')
              .doc(doctorId)
              .get();
              
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            
            if (kDebugMode) {
              debugPrint('      Doktor bilgileri bulundu:');
              debugPrint('         Aktif: ${doctorData['isActive']}');
              debugPrint('         Rol: ${doctorData['role']}');
              debugPrint('         Ad: ${doctorData['firstName']} ${doctorData['lastName']}');
              debugPrint('         Uzmanlık: ${doctorData['specialization']}');
            }
            
            // Doktorun aktif ve müsait olup olmadığını kontrol et
            if (doctorData['isActive'] == true && 
                doctorData['role'] == 'doctor') {
              
              availableDoctors.add({
                'id': doctorId,
                'name': '${doctorData['firstName']} ${doctorData['lastName']}',
                'specialty': doctorData['specialization'] ?? 'Genel Pratisyen',
                'hospital': shiftData['hospitalName'],
                'hospitalId': hospitalId,
                'phone': doctorData['phone'] ?? '',
                'experience': doctorData['experienceYears'] ?? 5,
                'rating': doctorData['rating'] ?? 4.5,
                'isOnline': doctorData['isOnline'] ?? false,
                'lastSeen': doctorData['lastSeen'],
                'shiftType': shiftData['shiftType'],
                'shiftStart': shiftData['startDate'],
                'shiftEnd': shiftData['endDate'],
                'availableForEmergency': shiftData['availableForEmergency'] ?? true,
              });
              
              if (kDebugMode) {
                debugPrint('         ✅ Doktor uygun listesine eklendi');
              }
            } else {
              if (kDebugMode) {
                debugPrint('         ❌ Doktor aktif değil veya doctor rolünde değil');
              }
            }
          } else {
            if (kDebugMode) {
              debugPrint('         ❌ Doktor bilgileri bulunamadı');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Doktor bilgileri alınırken hata: $e');
          }
        }
      }

      // Online olan ve acil müdahaleye uygun doktorları öncelik ver
      availableDoctors.sort((a, b) {
        // Önce acil müdahaleye uygun olanlar
        if (a['availableForEmergency'] && !b['availableForEmergency']) return -1;
        if (!a['availableForEmergency'] && b['availableForEmergency']) return 1;
        
        // Sonra online olanlar
        if (a['isOnline'] && !b['isOnline']) return -1;
        if (!a['isOnline'] && b['isOnline']) return 1;
        
        // Son olarak rating'e göre
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });

      if (kDebugMode) {
        debugPrint('🏥 Hastane $hospitalId için toplam ${availableDoctors.length} uygun doktor bulundu');
        for (final doctor in availableDoctors) {
          debugPrint('   - Dr. ${doctor['name']} (${doctor['specialty']}) - ${doctor['shiftType']} nöbeti');
        }
      }

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
      
      if (kDebugMode) {
        debugPrint('🔍 Genel doktor arama başlatılıyor (tüm hastaneler)...');
      }
      
      // Tüm aktif nöbetleri kontrol et
      final shiftSnapshot = await _firestore
          .collection('doctor_shifts')
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .where('availableForEmergency', isEqualTo: true)
          .get();

      final availableDoctors = <Map<String, dynamic>>[];

      for (final shiftDoc in shiftSnapshot.docs) {
        final shiftData = shiftDoc.data();
        final doctorId = shiftData['doctorId'] as String;
        
        try {
          // Doktor bilgilerini al
          final doctorDoc = await _firestore
              .collection('users')
              .doc(doctorId)
              .get();
              
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            
            // Doktorun aktif olup olmadığını kontrol et
            if (doctorData['isActive'] == true && 
                doctorData['role'] == 'doctor') {
              
              final specialty = doctorData['specialization'] ?? 'Genel Pratisyen';
              
              // Öncelik durumuna göre filtrele
              bool isEligible = true;
              if (priority == 'medium') {
                // Sarı alan - uzman doktor tercihi (ama genel pratisyeni de kabul et)
                isEligible = true; // Tüm doktorları kabul et, öncelik sıralamasında ayır
              }
              
              if (isEligible) {
                availableDoctors.add({
                  'id': doctorId,
                  'name': '${doctorData['firstName']} ${doctorData['lastName']}',
                  'specialty': specialty,
                  'hospital': shiftData['hospitalName'],
                  'hospitalId': shiftData['hospitalId'],
                  'phone': doctorData['phone'] ?? '',
                  'experience': doctorData['experienceYears'] ?? 5,
                  'rating': doctorData['rating'] ?? 4.5,
                  'isOnline': doctorData['isOnline'] ?? false,
                  'lastSeen': doctorData['lastSeen'],
                  'shiftType': shiftData['shiftType'],
                  'shiftStart': shiftData['startDate'],
                  'shiftEnd': shiftData['endDate'],
                  'availableForEmergency': shiftData['availableForEmergency'] ?? true,
                  'isSpecialist': specialty != 'Genel Pratisyen',
                });
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Doktor bilgileri alınırken hata: $e');
          }
        }
      }

      if (availableDoctors.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ Hiç uygun doktor bulunamadı');
        }
        return null;
      }

      // Öncelik sıralaması
      availableDoctors.sort((a, b) {
        // Önce acil müdahaleye uygun olanlar
        if (a['availableForEmergency'] && !b['availableForEmergency']) return -1;
        if (!a['availableForEmergency'] && b['availableForEmergency']) return 1;
        
        // Orta öncelik için uzman doktor tercihi
        if (priority == 'medium') {
          if (a['isSpecialist'] && !b['isSpecialist']) return -1;
          if (!a['isSpecialist'] && b['isSpecialist']) return 1;
        }
        
        // Online olanlar öncelik
        if (a['isOnline'] && !b['isOnline']) return -1;
        if (!a['isOnline'] && b['isOnline']) return 1;
        
        // Rating'e göre
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });

      if (kDebugMode) {
        debugPrint('🔍 Genel arama sonucu: ${availableDoctors.length} doktor bulundu');
        for (final doctor in availableDoctors.take(3)) {
          debugPrint('   - Dr. ${doctor['name']} (${doctor['specialty']}) - ${doctor['hospital']}');
        }
      }

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

  /// Admin panelinden atanmış nöbetçi doktoru bul
  static Future<Map<String, dynamic>?> findAssignedDoctor({
    required String hospitalId,
    required String patientId,
    required String applicationId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Admin panelinden atanmış doktor aranıyor...');
        debugPrint('   Hastane ID: $hospitalId');
        debugPrint('   Patient ID: $patientId');
        debugPrint('   Application ID: $applicationId');
      }

      final now = DateTime.now();
      
      // Hastanedeki aktif nöbetleri sorgula
      final shiftsQuery = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'active')
          .where('isAvailable', isEqualTo: true)
          .where('availableForEmergency', isEqualTo: true)
          .get();

      if (kDebugMode) {
        debugPrint('📊 Bulunan nöbet sayısı: ${shiftsQuery.docs.length}');
      }

      for (var shiftDoc in shiftsQuery.docs) {
        final shiftData = shiftDoc.data();
        final startDate = (shiftData['startDate'] as Timestamp).toDate();
        final endDate = (shiftData['endDate'] as Timestamp).toDate();
        
        // Şu anda aktif nöbet mi?
        if (now.isAfter(startDate) && now.isBefore(endDate)) {
          // Hasta kapasitesi kontrolü
          final currentPatientCount = shiftData['currentPatientCount'] ?? 0;
          final maxPatientCapacity = shiftData['maxPatientCapacity'] ?? 10;
          
          if (currentPatientCount < maxPatientCapacity) {
            if (kDebugMode) {
              debugPrint('✅ Uygun nöbetçi doktor bulundu!');
              debugPrint('   Shift ID: ${shiftDoc.id}');
              debugPrint('   Doktor: ${shiftData['doctorName']}');
              debugPrint('   Hasta Kapasitesi: $currentPatientCount/$maxPatientCapacity');
            }
            
            // Nöbet verisini döndür
            final result = Map<String, dynamic>.from(shiftData);
            result['id'] = shiftDoc.id;
            return result;
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ Doktor kapasitesi dolu: ${shiftData['doctorName']} ($currentPatientCount/$maxPatientCapacity)');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Nöbet şu anda aktif değil: ${shiftData['doctorName']}');
            debugPrint('   Başlangıç: $startDate');
            debugPrint('   Bitiş: $endDate');
            debugPrint('   Şu an: $now');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('❌ Hastanede uygun nöbetçi doktor bulunamadı');
        debugPrint('   Toplam kontrol edilen nöbet: ${shiftsQuery.docs.length}');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbetçi doktor arama hatası: $e');
      }
      return null;
    }
  }

  /// Doktorun hasta sayısını artır
  static Future<bool> incrementPatientCount(String shiftId) async {
    try {
      await _firestore.collection('doctor_shifts').doc(shiftId).update({
        'currentPatientCount': FieldValue.increment(1),
        'lastPatientAssignedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Doktor hasta sayısı artırıldı: $shiftId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hasta sayısı artırma hatası: $e');
      }
      return false;
    }
  }

  /// Doktorun hasta sayısını azalt
  static Future<bool> decrementPatientCount(String shiftId) async {
    try {
      await _firestore.collection('doctor_shifts').doc(shiftId).update({
        'currentPatientCount': FieldValue.increment(-1),
        'lastPatientReleasedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Doktor hasta sayısı azaltıldı: $shiftId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hasta sayısı azaltma hatası: $e');
      }
      return false;
    }
  }
}
