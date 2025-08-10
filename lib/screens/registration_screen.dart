import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _tcController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tcController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.red.shade600,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ve başlık - klavye açıldığında küçülsün
              Icon(
                Icons.person_add,
                size: MediaQuery.of(context).viewInsets.bottom > 0 ? 60 : 80,
                color: Colors.red.shade600,
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
              ),
              Text(
                'Yeni Hesap Oluştur',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 20
                      : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 32,
              ),

              // Kayıt formu
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'Ad',
                              hintText: 'Adınız',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Soyad',
                              hintText: 'Soyadınız',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tcController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      decoration: InputDecoration(
                        labelText: 'TC Kimlik No',
                        hintText: '12345678901',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'TC Kimlik No gerekli';
                        }
                        if (value.length != 11) {
                          return 'TC Kimlik No 11 haneli olmalı';
                        }
                        // Sadece rakam kontrolü
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'TC Kimlik No sadece rakam içermeli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        hintText: '05XX XXX XX XX',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefon numarası gerekli';
                        }
                        // Türkiye telefon formatı kontrolü
                        if (!RegExp(
                          r'^0[5][0-9]{9}$',
                        ).hasMatch(value.replaceAll(' ', ''))) {
                          return 'Geçerli bir telefon numarası girin (05XXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'ornek@email.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta adresi gerekli';
                        }
                        // E-posta formatı kontrolü
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        hintText: 'En az 6 karakter',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Şifre Tekrar',
                        hintText: 'Şifrenizi tekrar girin',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre tekrarı gerekli';
                        }
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kayıt ol butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 8),

              // Test butonu
              if (kDebugMode)
                ElevatedButton(
                  onPressed: _testFirebaseConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Test Firebase Bağlantısı'),
                ),
              const SizedBox(height: 16),

              // Giriş yap linki
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Zaten hesabınız var mı? Giriş yapın',
                  style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (kDebugMode) {
          print('🚀 Kayıt işlemi başlatılıyor...');
          print(
            '✅ Form validasyonu geçti, Firebase Auth ile kullanıcı oluşturuluyor...',
          );
        }

        // Direkt Firebase Auth ile kullanıcı oluştur
        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (kDebugMode) {
          print(
            '✅ Firebase Auth kullanıcısı oluşturuldu: ${userCredential.user!.uid}',
          );
          print('📝 Firestore\'a hasta bilgileri kaydediliyor...');
        }

        // Firestore'a hasta bilgilerini kaydet (users koleksiyonuna)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'tcNo': _tcController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'role': 'patient',
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
              // Hasta özel alanları
              'medicalHistory': [],
              'allergies': [],
              'currentMedications': [],
              'bloodType': '', // Kullanıcı daha sonra dolduracak
              'height': 0, // Kullanıcı daha sonra dolduracak
              'weight': 0, // Kullanıcı daha sonra dolduracak
              'emergencyContact': {'name': '', 'phone': '', 'relation': ''},
              'address': {'city': '', 'district': '', 'full': ''},
              // Hasta için ek alanlar
              'birthDate': '', // Kullanıcı daha sonra dolduracak
              'gender': '', // Kullanıcı daha sonra dolduracak
              'chronicDiseases': [],
              'lastApplicationDate': null,
              'totalApplications': 0,
              'profilePicture': '',
            });

        if (kDebugMode) {
          print('✅ Firestore\'a hasta bilgileri başarıyla kaydedildi');
        }

        if (mounted) {
          // Başarılı kayıt mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz...',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          if (kDebugMode) {
            print(
              '🎉 Kayıt işlemi tamamlandı, giriş sayfasına yönlendiriliyor...',
            );
          }

          // 2 saniye bekle ve login sayfasına yönlendir
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print('❌ Firebase Auth Hatası: ${e.code} - ${e.message}');
        }

        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Şifre çok zayıf';
            break;
          case 'email-already-in-use':
            errorMessage = 'Bu e-posta adresi zaten kullanılıyor';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz e-posta adresi';
            break;
          default:
            errorMessage = 'Kayıt sırasında bir hata oluştu: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Beklenmeyen Hata: $e');
          print('❌ Hata tipi: ${e.runtimeType}');
          if (e is FirebaseException) {
            print('❌ Firebase Hata Kodu: ${e.code}');
            print('❌ Firebase Hata Mesajı: ${e.message}');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Beklenmeyen hata: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _testFirebaseConnection() async {
    if (kDebugMode) {
      print('🧪 Firebase bağlantısı test ediliyor...');
    }

    try {
      // Sadece Firebase Auth durumunu kontrol et
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (kDebugMode) {
        print('👤 Mevcut kullanıcı: ${currentUser?.email ?? 'Yok'}');
        print('🔧 Firebase App kontrol ediliyor...');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Firebase Auth hazır (API key test edilecek)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase test hatası: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firebase hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
