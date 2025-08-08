import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  // Admin giriş kontrolü
  Future<bool> signInAdmin(String email, String password) async {
    try {
      // Özel admin girişi kontrolü
      if (email == 'admin@hastane-acil.com' &&
          password == 'HastaneAdmin2025!') {
        // Admin hesabını Firestore'dan kontrol et
        final adminQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();

        if (adminQuery.docs.isNotEmpty) {
          if (kDebugMode) {
            print('✅ Admin girişi başarılı');
          }
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Admin giriş hatası: $e');
      }
      return false;
    }
  }

  // Normal kullanıcı girişi
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Giriş hatası: $e');
      }
      rethrow;
    }
  }

  // Kullanıcı kaydı
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Kayıt hatası: $e');
      }
      rethrow;
    }
  }

  // Çıkış
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
      if (kDebugMode) {
        print('✅ Çıkış başarılı');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Çıkış hatası: $e');
      }
      rethrow;
    }
  }

  // Kullanıcı verilerini al
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Kullanıcı verisi alma hatası: $e');
      }
      return null;
    }
  }

  // Kullanıcı verilerini güncelle
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Kullanıcı verisi güncellendi');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Kullanıcı verisi güncelleme hatası: $e');
      }
      return false;
    }
  }

  // Admin kontrolü
  Future<bool> isAdmin() async {
    try {
      if (_auth.currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Admin kontrol hatası: $e');
      }
      return false;
    }
  }

  // Doktor kontrolü
  Future<bool> isDoctor() async {
    try {
      if (_auth.currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'doctor';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Doktor kontrol hatası: $e');
      }
      return false;
    }
  }
}
