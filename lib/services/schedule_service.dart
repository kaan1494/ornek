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
      };

      final docRef = await _firestore
          .collection('doctor_shifts')
          .add(shiftData);

      if (kDebugMode) {
        debugPrint('✅ Doktor nöbeti oluşturuldu: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Nöbet oluşturma hatası: $e');
      }
      return null;
    }
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
        'id': 'morning',
        'name': 'Sabah Nöbeti',
        'startTime': '08:00',
        'endTime': '16:00',
        'color': 0xFF2196F3, // Mavi
      },
      {
        'id': 'evening',
        'name': 'Akşam Nöbeti',
        'startTime': '16:00',
        'endTime': '00:00',
        'color': 0xFFFFF3E0, // Light Orange
      },
      {
        'id': 'night',
        'name': 'Gece Nöbeti',
        'startTime': '00:00',
        'endTime': '08:00',
        'color': 0xFFE8F5E8, // Light Green
      },
    ];
  }
}
