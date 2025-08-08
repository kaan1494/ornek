import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class CreateDoctorScreen extends StatefulWidget {
  const CreateDoctorScreen({super.key});

  @override
  State<CreateDoctorScreen> createState() => _CreateDoctorScreenState();
}

class _CreateDoctorScreenState extends State<CreateDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _tcController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _diplomaNoController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLoading = false;
  String _selectedHospital = '';
  List<Map<String, dynamic>> _hospitals = [];

  // Doktor uzmanlık alanları
  final List<String> _specialties = [
    'Acil Tıp',
    'İç Hastalıkları',
    'Genel Cerrahi',
    'Kardiyoloji',
    'Nöroloji',
    'Ortopedi',
    'Pediatri',
    'Kadın Doğum',
    'Anestezi',
    'Göğüs Hastalıkları',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hospitals')
          .get();

      setState(() {
        _hospitals = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        if (_hospitals.isNotEmpty) {
          _selectedHospital = _hospitals.first['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hastaneler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tcController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _diplomaNoController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _createDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Doktor kimlik bilgilerini users koleksiyonuna ekle
        final doctorRef = FirebaseFirestore.instance.collection('users').doc();

        await doctorRef.set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'tcKimlik': _tcController.text.trim(),
          'password':
              _passwordController.text, // Gerçek uygulamada hash'lenmeli
          'phone': _phoneController.text.trim(),
          'role': 'doctor',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'admin', // Hangi admin oluşturdu
        });

        // Doktor profesyonel bilgilerini doctors koleksiyonuna ekle
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorRef.id)
            .set({
              'userId': doctorRef.id,
              'specialty': _specialtyController.text.trim(),
              'diplomaNumber': _diplomaNoController.text.trim(),
              'experienceYears':
                  int.tryParse(_experienceController.text.trim()) ?? 0,
              'hospitalId': _selectedHospital,
              'isAvailable': true,
              'currentShift': null,
              'totalPatients': 0,
              'rating': 0.0,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Doktor başarıyla oluşturuldu!\nTC: ${_tcController.text}\nŞifre: ${_passwordController.text}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Formu temizle
          _formKey.currentState!.reset();
          _firstNameController.clear();
          _lastNameController.clear();
          _tcController.clear();
          _passwordController.clear();
          _phoneController.clear();
          _specialtyController.clear();
          _diplomaNoController.clear();
          _experienceController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Doktor oluşturulurken hata: $e'),
              backgroundColor: Colors.red,
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

  String _generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(
          (chars.length * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)
                  .floor() %
              chars.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Yeni Doktor Oluştur'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık kartı
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 48,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Yeni Doktor Hesabı',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Doktor için giriş bilgileri ve uzmanlık bilgileri',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kişisel bilgiler
              Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'Ad',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Soyad',
                        prefixIcon: const Icon(Icons.person_outline),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'TC Kimlik Numarası',
                  hintText: '12345678901',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'TC kimlik numarası gerekli';
                  }
                  if (value.length != 11) {
                    return 'TC kimlik numarası 11 haneli olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        hintText: 'Doktor giriş şifresi',
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
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _passwordController.text = _generateRandomPassword();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rastgele'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '05551234567',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası gerekli';
                  }
                  if (value.length != 11 || !value.startsWith('05')) {
                    return 'Geçerli telefon numarası girin (05xxxxxxxxx)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Profesyonel bilgiler
              Text(
                'Profesyonel Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _specialtyController.text.isEmpty
                    ? null
                    : _specialtyController.text,
                decoration: InputDecoration(
                  labelText: 'Uzmanlık Alanı',
                  prefixIcon: const Icon(Icons.medical_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _specialtyController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Uzmanlık alanı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diplomaNoController,
                      decoration: InputDecoration(
                        labelText: 'Diploma Numarası',
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Diploma numarası gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Tecrübe (Yıl)',
                        prefixIcon: const Icon(Icons.timeline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tecrübe yılı gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hastane seçimi
              if (_hospitals.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedHospital.isEmpty ? null : _selectedHospital,
                  decoration: InputDecoration(
                    labelText: 'Hastane',
                    prefixIcon: const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _hospitals.map<DropdownMenuItem<String>>((hospital) {
                    return DropdownMenuItem<String>(
                      value: hospital['id'],
                      child: Text(hospital['name'] ?? 'Hastane Adı'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHospital = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hastane seçin';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),

              // Oluştur butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _createDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Doktor Hesabı Oluştur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Bilgi notu
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Doktor oluşturulduktan sonra TC ve şifre ile giriş yapabilir. Bu bilgileri doktora iletmeyi unutmayın.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
