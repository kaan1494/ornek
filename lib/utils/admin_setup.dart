import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Admin hesabını Firestore'da oluşturur (eğer yoksa)
  static Future<void> createAdminIfNotExists() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Admin hesabı kontrol ediliyor...');
      }

      // Admin hesabını kontrol et
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@hastane-acil.com')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔧 Admin hesabı bulunamadı, oluşturuluyor...');
        }

        // Admin hesabını oluştur
        await _firestore.collection('users').add({
          'email': 'admin@hastane-acil.com',
          'firstName': 'Sistem',
          'lastName': 'Yöneticisi',
          'role': 'admin',
          'tcNo': '00000000000',
          'phone': '+90 555 000 0000',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'permissions': [
            'users_manage',
            'doctors_manage',
            'hospitals_manage',
            'triage_manage',
            'reports_view',
          ],
        });

        if (kDebugMode) {
          debugPrint('✅ Admin hesabı başarıyla oluşturuldu');
        }
      } else {
        if (kDebugMode) {
          debugPrint('✅ Admin hesabı zaten mevcut');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Admin hesabı oluşturma hatası: $e');
      }
    }
  }
}
