import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Doktor nöbet planı oluşturur
  static Future<String?> createDoctorShift({
    required String doctorId,
    required String doctorName,
    required String hospitalId,
    required String hospitalName,
    required DateTime startDate,
    required DateTime endDate,
    required String shiftType, // 'morning', 'evening', 'night'
    String? notes,
  }) async {
    try {
      final shiftData = {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'shiftType': shiftType,
        'notes': notes ?? '',
        'status': 'active', // active, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'availableForEmergency': true,
        // Hasta eşleştirme için ek alanlar
        'isAvailable': true,
        'currentPatientCount': 0,
        'maxPatientCapacity': 10, // Maksimum hasta kapasitesi
        'shiftDate': Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day)),
        'assignedBy': 'admin', // Admin tarafından atandı
        'assignmentTimestamp': FieldValue.serverTimestamp(),
        // Lokasyon bilgileri (consultation service için)
        'province': _extractProvinceFromHospitalId(hospitalId),
        'district': _extractDistrictFromHospitalId(hospitalId),
      };

      if (kDebugMode) {
        debugPrint('🔄===========================================');
        debugPrint('🔄 YENİ NÖBET ATAMASı BAŞLATIYOR...');
        debugPrint('🔄===========================================');
        debugPrint('👨‍⚕️ Doktor: $doctorName');
        debugPrint('🆔 Doktor ID: $doctorId');
        debugPrint('🏥 Hastane: $hospitalName');
        debugPrint('🆔 Hastane ID: $hospitalId');
        debugPrint('📅 Başlangıç: ${startDate.toString()}');
        debugPrint('⏰ Bitiş: ${endDate.toString()}');
        debugPrint('🕐 Vardiya Tipi: $shiftType');
        debugPrint('📝 Notlar: ${notes ?? 'Yok'}');
        debugPrint('📊 Hasta Kapasitesi: ${shiftData['maxPatientCapacity']}');
        debugPrint('🔄===========================================');
      }

      final docRef = await _firestore
          .collection('doctor_shifts')
          .add(shiftData);

      if (kDebugMode) {
        debugPrint('✅===========================================');
        debugPrint('✅ NÖBET BAŞARIYLA OLUŞTURULDU!');
        debugPrint('✅===========================================');
        debugPrint('🆔 Shift ID: ${docRef.id}');
        debugPrint('📦 Collection: doctor_shifts');
        debugPrint('📋 Kaydedilen Data:');
        shiftData.forEach((key, value) {
          if (key != 'createdAt' && key != 'assignmentTimestamp') {
            debugPrint('   $key: $value');
          }
        });
        debugPrint('✅===========================================');
        
        // Doğrulama sorgusu - kaydın gerçekten oluştuğunu kontrol et
        debugPrint('🔍 Kayıt doğrulanıyor...');
        try {
          final verificationDoc = await _firestore
              .collection('doctor_shifts')
              .doc(docRef.id)
              .get();
          
          if (verificationDoc.exists) {
            final savedData = verificationDoc.data();
            debugPrint('✅ Kayıt doğrulandı! Firestore\'da mevcut.');
            debugPrint('🔍 Kaydedilmiş hospitalId: ${savedData?['hospitalId']}');
            debugPrint('🔍 Kaydedilmiş doctorId: ${savedData?['doctorId']}');
            debugPrint('🔍 Kaydedilmiş isAvailable: ${savedData?['isAvailable']}');
          } else {
            debugPrint('❌ UYARI: Kayıt doğrulanamadı!');
          }
        } catch (verificationError) {
          debugPrint('❌ Doğrulama hatası: $verificationError');
        }
        
        // Bu hastanedeki toplam nöbet sayısını kontrol et
        try {
          final hospitalShiftsQuery = await _firestore
              .collection('doctor_shifts')
              .where('hospitalId', isEqualTo: hospitalId)
              .where('status', isEqualTo: 'active')
              .get();
          
          debugPrint('📊 $hospitalName hastanesinde toplam ${hospitalShiftsQuery.docs.length} aktif nöbet var');
        } catch (countError) {
          debugPrint('❌ Hastane nöbet sayısı alınamadı: $countError');
        }
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌===========================================');
        debugPrint('❌ NÖBET OLUŞTURMA HATASI!');
        debugPrint('❌===========================================');
        debugPrint('💥 Hata: $e');
        debugPrint('👨‍⚕️ Doktor: $doctorName ($doctorId)');
        debugPrint('🏥 Hastane: $hospitalName ($hospitalId)');
        debugPrint('❌===========================================');
      }
      return null;
    }
  }

  /// Hastane ID'sinden il bilgisini çıkarır
  static String _extractProvinceFromHospitalId(String hospitalId) {
    // hospitalId formatı: 'ank_altindag_1' -> 'Ankara'
    if (hospitalId.startsWith('ank_')) return 'Ankara';
    if (hospitalId.startsWith('ist_')) return 'İstanbul';
    if (hospitalId.startsWith('izm_')) return 'İzmir';
    // Diğer iller için genişletilir
    return 'Bilinmiyor';
  }

  /// Hastane ID'sinden ilçe bilgisini çıkarır
  static String _extractDistrictFromHospitalId(String hospitalId) {
    // hospitalId formatı: 'ank_altindag_1' -> 'Altındağ'
    final parts = hospitalId.split('_');
    if (parts.length >= 2) {
      switch (parts[1]) {
        case 'altindag': return 'Altındağ';
        case 'cankaya': return 'Çankaya';
        case 'kecioren': return 'Keçiören';
        case 'mamak': return 'Mamak';
        case 'sincan': return 'Sincan';
        case 'etimesgut': return 'Etimesgut';
        case 'golbasi': return 'Gölbaşı';
        case 'pursaklar': return 'Pursaklar';
        case 'yenimahalle': return 'Yenimahalle';
        // İstanbul ilçeleri
        case 'besiktas': return 'Beşiktaş';
        case 'kadikoy': return 'Kadıköy';
        case 'uskudar': return 'Üsküdar';
        // Diğer ilçeler için genişletilir
        default: return parts[1];
      }
    }
    return 'Bilinmiyor';
  }

  /// Belirtilen tarih aralığında nöbetçi doktorları getirir
  static Stream<QuerySnapshot> getActiveShifts({
    String? hospitalId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Active shifts query başlatılıyor...');
      }

      // En basit sorgu - sadece collection'daki tüm dokümanları getir
      return _firestore.collection('doctor_shifts').snapshots();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Active shifts query hatası: $e');
      }
      // Hata durumunda boş stream döndür
      return Stream.empty();
    }
  }

  /// Doktorun mevcut nöbetlerini getirir
  static Stream<QuerySnapshot> getDoctorShifts(String doctorId) {
    return _firestore
        .collection('doctor_shifts')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'active')
        .orderBy('startDate', descending: false)
        .snapshots();
  }

  /// Nöbet güncelleme
  static Future<bool> updateShift(
    String shiftId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('doctor_shifts').doc(shiftId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbet güncelleme hatası: $e');
      }
      return false;
    }
  }

  /// Nöbet silme/iptal etme
  static Future<bool> cancelShift(String shiftId) async {
    try {
      await _firestore.collection('doctor_shifts').doc(shiftId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbet iptal hatası: $e');
      }
      return false;
    }
  }

  /// Hastane bazında nöbet istatistikleri
  static Future<Map<String, int>> getHospitalShiftStats(
    String hospitalId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final shifts = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .where(
            'startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'startDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .get();

      int totalShifts = shifts.docs.length;
      int activeShifts = shifts.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      int completedShifts = shifts.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'total': totalShifts,
        'active': activeShifts,
        'completed': completedShifts,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ İstatistik alma hatası: $e');
      }
      return {'total': 0, 'active': 0, 'completed': 0};
    }
  }

  /// Admin paneli için hastaneye doktor atama (çakışma kontrolü ile)
  static Future<bool> assignDoctorToHospital({
    required String doctorId,
    required String doctorName,
    required String hospitalId,
    required String hospitalName,
    required DateTime startDate,
    required DateTime endDate,
    required String shiftType,
    String? notes,
    String? assignedBy,
  }) async {
    try {
      // Çakışan nöbet kontrolü
      final conflictCheck = await _firestore
          .collection('doctor_shifts')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where(
            'endDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      if (conflictCheck.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('❌ Doktor bu tarih aralığında başka bir nöbette');
        }
        return false;
      }

      // Doktor aktif mi kontrolü
      final doctorDoc = await _firestore
          .collection('users')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists || doctorDoc.data()!['isActive'] != true) {
        if (kDebugMode) {
          debugPrint('❌ Doktor aktif değil');
        }
        return false;
      }

      // Nöbet oluştur
      await _firestore.collection('doctor_shifts').add({
        'doctorId': doctorId,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'shiftType': shiftType,
        'notes': notes ?? '',
        'status': 'active',
        'availableForEmergency': true,
        'assignedBy': assignedBy ?? 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'patientCount': 0,
        'emergencyCount': 0,
      });

      if (kDebugMode) {
        debugPrint(
          '✅ Admin tarafından doktor nöbete atandı: $doctorName → $hospitalName',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Admin nöbet atama hatası: $e');
      }
      return false;
    }
  }

  /// Hastanedeki aktif nöbetleri getir
  static Stream<QuerySnapshot> getHospitalActiveShifts(String hospitalId) {
    return _firestore
        .collection('doctor_shifts')
        .where('hospitalId', isEqualTo: hospitalId)
        .where('status', isEqualTo: 'active')
        .where('endDate', isGreaterThan: Timestamp.now())
        .orderBy('endDate')
        .orderBy('startDate')
        .snapshots();
  }

  /// Hastanedeki şu anda nöbetçi doktorları getir
  static Stream<QuerySnapshot> getCurrentHospitalDoctors(String hospitalId) {
    final now = Timestamp.now();
    return _firestore
        .collection('doctor_shifts')
        .where('hospitalId', isEqualTo: hospitalId)
        .where('status', isEqualTo: 'active')
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThan: now)
        .orderBy('startDate')
        .orderBy('endDate')
        .snapshots();
  }

  /// Doktoru nöbetten çıkar
  static Future<bool> removeFromShift(String shiftId) async {
    try {
      await _firestore.collection('doctor_shifts').doc(shiftId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Doktor nöbetten çıkarıldı: $shiftId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbetten çıkarma hatası: $e');
      }
      return false;
    }
  }

  /// Nöbet istatistikleri (admin panel için)
  static Future<Map<String, int>> getShiftStatistics() async {
    try {
      final activeShifts = await _firestore
          .collection('doctor_shifts')
          .where('status', isEqualTo: 'active')
          .get();

      final now = DateTime.now();
      int currentShifts = 0;
      int todayShifts = 0;
      int totalShifts = activeShifts.docs.length;

      for (var doc in activeShifts.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();

        // Şu anda aktif
        if (startDate.isBefore(now) && endDate.isAfter(now)) {
          currentShifts++;
        }

        // Bugün başlayan
        if (startDate.day == now.day &&
            startDate.month == now.month &&
            startDate.year == now.year) {
          todayShifts++;
        }
      }

      return {
        'current': currentShifts,
        'today': todayShifts,
        'total': totalShifts,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbet istatistik hatası: $e');
      }
      return {'current': 0, 'today': 0, 'total': 0};
    }
  }

  /// Nöbet türleri
  static List<Map<String, dynamic>> getShiftTypes() {
    return [
      {
        'id': 'daily',
        'name': '24 Saatlik Günlük Nöbet',
        'startTime': '08:00',
        'endTime': '08:00 (Ertesi Gün)',
        'color': 0xFF4CAF50, // Yeşil
        'duration': 24,
        'description': 'Sabah 08:00\'dan ertesi gün 08:00\'a kadar 24 saatlik nöbet',
      },
      {
        'id': 'half_day',
        'name': '12 Saatlik Nöbet',
        'startTime': '08:00',
        'endTime': '20:00',
        'color': 0xFF2196F3, // Mavi
        'duration': 12,
        'description': 'Sabah 08:00\'dan akşam 20:00\'a kadar 12 saatlik nöbet',
      },
      {
        'id': 'night',
        'name': '12 Saatlik Gece Nöbeti',
        'startTime': '20:00',
        'endTime': '08:00 (Ertesi Gün)',
        'color': 0xFF9C27B0, // Mor
        'duration': 12,
        'description': 'Akşam 20:00\'dan ertesi sabah 08:00\'a kadar gece nöbeti',
      },
    ];
  }

  /// Belirli bir hastanedeki aktif nöbetleri getir
  static Future<List<Map<String, dynamic>>> getActiveShiftsByHospital(String hospitalId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 $hospitalId hastanesi için aktif nöbetler aranıyor...');
      }

      final query = await _firestore
          .collection('doctor_shifts')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: false)
          .get();

      final shifts = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('✅ $hospitalId hastanesi için ${shifts.length} aktif nöbet bulundu');
        for (var shift in shifts) {
          debugPrint('   👨‍⚕️ ${shift['doctorName']} - ${shift['shiftType']} - ${shift['startDate']}');
        }
      }

      return shifts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane nöbetleri alınamadı: $e');
      }
      return [];
    }
  }

  /// Belirli bir doktorun aktif nöbetlerini getir
  static Future<List<Map<String, dynamic>>> getActiveShiftsByDoctor(String doctorId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 $doctorId doktoru için aktif nöbetler aranıyor...');
      }

      final query = await _firestore
          .collection('doctor_shifts')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: false)
          .get();

      final shifts = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('✅ $doctorId doktoru için ${shifts.length} aktif nöbet bulundu');
      }

      return shifts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor nöbetleri alınamadı: $e');
      }
      return [];
    }
  }

  /// Tüm aktif nöbetleri getir (admin paneli için)
  static Future<List<Map<String, dynamic>>> getAllActiveShifts() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Tüm aktif nöbetler getiriliyor...');
      }

      final query = await _firestore
          .collection('doctor_shifts')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(100) // Son 100 nöbet
          .get();

      final shifts = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('✅ Toplam ${shifts.length} aktif nöbet bulundu');
        
        // Hastane bazlı gruplandırma
        final Map<String, int> hospitalCounts = {};
        for (var shift in shifts) {
          final hospitalName = shift['hospitalName'] ?? 'Bilinmiyor';
          hospitalCounts[hospitalName] = (hospitalCounts[hospitalName] ?? 0) + 1;
        }
        
        debugPrint('📊 Hastane bazlı nöbet dağılımı:');
        hospitalCounts.forEach((hospital, shiftCount) {
          debugPrint('   🏥 $hospital: $shiftCount nöbet');
        });
      }

      return shifts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Aktif nöbetler alınamadı: $e');
      }
      return [];
    }
  }

  /// Test fonksiyonu - belirli hastane için nöbet var mı kontrol et
  static Future<void> testHospitalShifts(String hospitalId) async {
    if (kDebugMode) {
      debugPrint('🧪===========================================');
      debugPrint('🧪 HASTANE NÖBETLERİ TEST EDILIYOR...');
      debugPrint('🧪===========================================');
      debugPrint('🏥 Test edilen hastane ID: $hospitalId');
    }

    try {
      final shifts = await getActiveShiftsByHospital(hospitalId);
      
      if (kDebugMode) {
        if (shifts.isNotEmpty) {
          debugPrint('✅ TEST BAŞARILI: $hospitalId hastanesi için ${shifts.length} aktif nöbet bulundu');
          for (var shift in shifts) {
            debugPrint('   📋 Nöbet ID: ${shift['id']}');
            debugPrint('   👨‍⚕️ Doktor: ${shift['doctorName']} (${shift['doctorId']})');
            debugPrint('   📅 Tarih: ${shift['startDate']} - ${shift['endDate']}');
            debugPrint('   🚨 Acil için müsait: ${shift['availableForEmergency']}');
            debugPrint('   📊 Hasta kapasitesi: ${shift['currentPatientCount']}/${shift['maxPatientCapacity']}');
            debugPrint('   ---');
          }
        } else {
          debugPrint('⚠️ TEST SONUCU: $hospitalId hastanesi için aktif nöbet bulunamadı');
        }
        debugPrint('🧪===========================================');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TEST HATASI: $e');
        debugPrint('🧪===========================================');
      }
    }
  }
}
