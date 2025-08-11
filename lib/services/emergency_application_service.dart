import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Acil başvuru kayıtlarını yöneten servis
class EmergencyApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'emergency_applications';

  /// Acil başvuru oluştur ve kaydet
  static Future<String?> createApplication({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String patientEmail,
    required int triageScore,
    required String triageLevel,
    required String priority,
    required Map<String, dynamic> selectedHospital,
    required List<Map<String, dynamic>> answers,
    required String recommendation,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      
      final applicationData = {
        // Hasta bilgileri
        'patientId': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'patientEmail': patientEmail,
        
        // Başvuru bilgileri
        'applicationDate': Timestamp.fromDate(now),
        'applicationNumber': _generateApplicationNumber(),
        'status': 'waiting', // waiting, in_progress, completed, cancelled
        
        // Triaj bilgileri
        'triageScore': triageScore,
        'triageLevel': triageLevel, // critical, urgent, moderate, low
        'priority': priority, // emergency, medium, low
        'answers': answers,
        'recommendation': recommendation,
        
        // Hastane bilgileri
        'hospitalId': selectedHospital['id'],
        'hospitalName': selectedHospital['name'],
        'hospitalAddress': selectedHospital['address'],
        'hospitalPhone': selectedHospital['phone'],
        'hospitalType': selectedHospital['type'],
        'province': selectedHospital['province'],
        'district': selectedHospital['district'],
        
        // Doktor atama bilgileri
        'assignedDoctorId': null,
        'assignedDoctorName': null,
        'doctorAssignedAt': null,
        'consultationStarted': false,
        'consultationStartedAt': null,
        'consultationCompleted': false,
        'consultationCompletedAt': null,
        
        // Tedavi bilgileri
        'diagnosis': null,
        'prescription': null,
        'treatmentNotes': null,
        'followUpRequired': false,
        'followUpDate': null,
        
        // Sistem bilgileri
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': notes ?? '',
        
        // Bekleme süresi tahmini
        'estimatedWaitTime': _calculateEstimatedWaitTime(priority, triageLevel),
        'queuePosition': await _getQueuePosition(selectedHospital['id'], priority),
      };

      final docRef = await _firestore
          .collection(_collectionName)
          .add(applicationData);

      if (kDebugMode) {
        debugPrint('✅ Acil başvuru oluşturuldu: ${docRef.id}');
        debugPrint('   Hasta: $patientName ($patientId)');
        debugPrint('   Hastane: ${selectedHospital['name']}');
        debugPrint('   Triaj: $triageLevel (Puan: $triageScore)');
        debugPrint('   Öncelik: $priority');
        debugPrint('   Başvuru No: ${applicationData['applicationNumber']}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Acil başvuru oluşturulamadı: $e');
      }
      return null;
    }
  }

  /// Hastanedeki bekleyen başvuruları getir
  static Future<List<Map<String, dynamic>>> getWaitingApplications({
    required String hospitalId,
    String? priority,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('applicationDate', descending: false);

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority);
      }

      final snapshot = await query.get();
      
      final applications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('📋 $hospitalId hastanesinde ${applications.length} bekleyen başvuru bulundu');
      }

      return applications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Bekleyen başvurular getirilemedi: $e');
      }
      return [];
    }
  }

  /// Başvuruya doktor ata
  static Future<bool> assignDoctor({
    required String applicationId,
    required String doctorId,
    required String doctorName,
  }) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .update({
        'assignedDoctorId': doctorId,
        'assignedDoctorName': doctorName,
        'doctorAssignedAt': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Başvuruya doktor atandı: $applicationId -> Dr. $doctorName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor atanamadı: $e');
      }
      return false;
    }
  }

  /// Konsültasyonu başlat
  static Future<bool> startConsultation(String applicationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .update({
        'consultationStarted': true,
        'consultationStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Konsültasyon başlatıldı: $applicationId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon başlatılamadı: $e');
      }
      return false;
    }
  }

  /// Konsültasyonu tamamla
  static Future<bool> completeConsultation({
    required String applicationId,
    String? diagnosis,
    String? prescription,
    String? treatmentNotes,
    bool followUpRequired = false,
    DateTime? followUpDate,
  }) async {
    try {
      final updateData = {
        'consultationCompleted': true,
        'consultationCompletedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (prescription != null) updateData['prescription'] = prescription;
      if (treatmentNotes != null) updateData['treatmentNotes'] = treatmentNotes;
      updateData['followUpRequired'] = followUpRequired;
      if (followUpDate != null) {
        updateData['followUpDate'] = Timestamp.fromDate(followUpDate);
      }

      await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .update(updateData);

      if (kDebugMode) {
        debugPrint('✅ Konsültasyon tamamlandı: $applicationId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon tamamlanamadı: $e');
      }
      return false;
    }
  }

  /// Başvuru durumunu güncelle
  static Future<bool> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) updateData['notes'] = notes;

      await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .update(updateData);

      if (kDebugMode) {
        debugPrint('✅ Başvuru durumu güncellendi: $applicationId -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Başvuru durumu güncellenemedi: $e');
      }
      return false;
    }
  }

  /// Hastanın aktif başvurularını getir
  static Future<List<Map<String, dynamic>>> getPatientApplications({
    required String patientId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('patientId', isEqualTo: patientId)
          .orderBy('applicationDate', descending: true)
          .limit(limit)
          .get();

      final applications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('📋 Hasta $patientId için ${applications.length} başvuru bulundu');
      }

      return applications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hasta başvuruları getirilemedi: $e');
      }
      return [];
    }
  }

  /// Başvuru detaylarını getir
  static Future<Map<String, dynamic>?> getApplicationDetails(String applicationId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Başvuru detayları getirilemedi: $e');
      }
      return null;
    }
  }

  /// Doktorun atanmış başvurularını getir
  static Future<List<Map<String, dynamic>>> getDoctorApplications({
    required String doctorId,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('assignedDoctorId', isEqualTo: doctorId)
          .orderBy('applicationDate', descending: false);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      
      final applications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('👨‍⚕️ Dr. $doctorId için ${applications.length} başvuru bulundu');
      }

      return applications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor başvuruları getirilemedi: $e');
      }
      return [];
    }
  }

  /// Başvuru numarası oluştur
  static String _generateApplicationNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'ACL$dateStr$timeStr';
  }

  /// Tahmini bekleme süresi hesapla (dakika cinsinden)
  static int _calculateEstimatedWaitTime(String priority, String triageLevel) {
    // Acil durumlarda 0 dakika
    if (priority == 'emergency' || triageLevel == 'critical') {
      return 0;
    }
    
    // Yüksek öncelik 15 dakika
    if (priority == 'high' || triageLevel == 'urgent') {
      return 15;
    }
    
    // Orta öncelik 45 dakika
    if (priority == 'medium' || triageLevel == 'moderate') {
      return 45;
    }
    
    // Düşük öncelik 90 dakika
    return 90;
  }

  /// Hastanedeki sıra pozisyonunu hesapla
  static Future<int> _getQueuePosition(String hospitalId, String priority) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('status', isEqualTo: 'waiting')
          .where('priority', isEqualTo: priority)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sıra pozisyonu hesaplanamadı: $e');
      }
      return 1;
    }
  }

  /// Günlük istatistikleri getir
  static Future<Map<String, dynamic>> getDailyStats({
    String? hospitalId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection(_collectionName)
          .where('applicationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('applicationDate', isLessThan: Timestamp.fromDate(endOfDay));

      if (hospitalId != null) {
        query = query.where('hospitalId', isEqualTo: hospitalId);
      }

      final snapshot = await query.get();
      
      final applications = snapshot.docs
          .map((doc) => doc.data())
          .whereType<Map<String, dynamic>>()
          .toList();
      
      final stats = {
        'totalApplications': applications.length,
        'emergencyCount': applications.where((app) => app['priority'] == 'emergency').length,
        'completedCount': applications.where((app) => app['status'] == 'completed').length,
        'waitingCount': applications.where((app) => app['status'] == 'waiting').length,
        'inProgressCount': applications.where((app) => app['status'] == 'in_progress').length,
        'byTriageLevel': {
          'critical': applications.where((app) => app['triageLevel'] == 'critical').length,
          'urgent': applications.where((app) => app['triageLevel'] == 'urgent').length,
          'moderate': applications.where((app) => app['triageLevel'] == 'moderate').length,
          'low': applications.where((app) => app['triageLevel'] == 'low').length,
        },
        'date': targetDate.toIso8601String(),
        'hospitalId': hospitalId,
      };

      if (kDebugMode) {
        debugPrint('📊 Günlük istatistikler: ${stats['totalApplications']} başvuru');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Günlük istatistikler getirilemedi: $e');
      }
      return {};
    }
  }
}
