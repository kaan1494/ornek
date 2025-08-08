import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/triage_service.dart';
import '../services/hospital_service.dart';
import 'doctor_consultation_screen.dart';

class EmergencyTriageScreen extends StatefulWidget {
  const EmergencyTriageScreen({super.key});

  @override
  State<EmergencyTriageScreen> createState() => _EmergencyTriageScreenState();
}

class _EmergencyTriageScreenState extends State<EmergencyTriageScreen> {
  final PageController _pageController = PageController();
  int _currentStep =
      0; // 0: İl seçimi, 1: İlçe seçimi, 2: Hastane seçimi, 3+: Sorular
  double _totalScore = 0;
  bool _isSubmitting = false;

  // Hasta bilgileri
  String? _patientName;
  String? _patientId;

  // Hastane seçimi
  String? _selectedProvince;
  String? _selectedDistrict;
  Map<String, dynamic>? _selectedHospital;

  // Sorular ve cevaplar
  List<Map<String, dynamic>> _questions = [];
  final Map<int, bool> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    // Soruları başlangıçta yükleme, hastane seçiminden sonra yükleyeceğiz
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _patientName = '${userData['firstName']} ${userData['lastName']}';
            _patientId = user.uid;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Hasta bilgileri yüklenirken hata: $e');
        }
      }
    }
  }

  void _loadTriageQuestions() {
    _questions = TriageService.getTriageQuestions();
    if (kDebugMode) {
      debugPrint('🏥 Triaj soruları yüklendi: ${_questions.length} soru');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentStep > 0) {
          _previousStep();
        } else {
          if (!mounted) return;
          final navigator = Navigator.of(context);
          final shouldExit = await _showExitDialog();
          if (shouldExit && mounted) {
            navigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                final shouldExit = await _showExitDialog();
                if (shouldExit && mounted) {
                  navigator.pop();
                }
              }
            },
          ),
        ),
        body: Column(
          children: [
            // İlerleme göstergesi
            _buildProgressIndicator(),

            // Ana içerik
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getTotalSteps(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildProvinceSelectionPage();
                  } else if (index == 1) {
                    return _buildDistrictSelectionPage();
                  } else if (index == 2) {
                    return _buildHospitalSelectionPage();
                  } else if (index >= 3 && index < 3 + _questions.length) {
                    return _buildQuestionPage(_questions[index - 3], index - 3);
                  } else {
                    return _buildResultPage();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'İl Seçimi';
      case 1:
        return 'İlçe Seçimi';
      case 2:
        return 'Hastane Seçimi';
      default:
        if (_currentStep >= 3 && _currentStep < 3 + _questions.length) {
          return 'Acil Durum Değerlendirmesi';
        } else {
          return 'Değerlendirme Sonucu';
        }
    }
  }

  int _getTotalSteps() {
    return 3 + _questions.length + 1; // İl + İlçe + Hastane + Sorular + Sonuç
  }

  Widget _buildProgressIndicator() {
    final totalSteps = _getTotalSteps() - 1; // Sonuç sayfası hariç
    final progress = _currentStep / totalSteps;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getProgressText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              if (_patientName != null)
                Text(
                  _patientName!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.red.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  String _getProgressText() {
    switch (_currentStep) {
      case 0:
        return 'Adım 1/4: İl Seçimi';
      case 1:
        return 'Adım 2/4: İlçe Seçimi';
      case 2:
        return 'Adım 3/4: Hastane Seçimi';
      default:
        if (_currentStep >= 3 && _currentStep < 3 + _questions.length) {
          final questionIndex = _currentStep - 3;
          return 'Soru ${questionIndex + 1} / ${_questions.length}';
        } else {
          return 'Değerlendirme Tamamlandı';
        }
    }
  }

  // İl seçimi sayfası
  Widget _buildProvinceSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.red.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_city,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Hastane Konumu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hangi ilde acil servis hizmeti almak istiyorsunuz?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Size en yakın hastaneleri gösterebilmek için önce ilinizi seçin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: HospitalService.getProvinces().length,
              itemBuilder: (context, index) {
                final province = HospitalService.getProvinces()[index];
                final isSelected = _selectedProvince == province;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.red.shade600
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        province,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.red.shade700
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.red.shade600)
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectProvince(province),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // İlçe seçimi sayfası
  Widget _buildDistrictSelectionPage() {
    final districts = HospitalService.getDistricts()[_selectedProvince] ?? [];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.red.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedProvince ?? 'İlçe Seçimi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_selectedProvince ilinde hangi ilçede acil servis hizmeti almak istiyorsunuz?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (districts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bu il için henüz ilçe bilgisi bulunmuyor.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _nextStep(),
                      child: const Text('Devam Et'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final district = districts[index];
                  final isSelected = _selectedDistrict == district;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.red.shade600
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? Colors.red.shade600
                              : Colors.grey.shade600,
                        ),
                        title: Text(
                          district,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.red.shade600,
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectDistrict(district),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Hastane seçimi sayfası
  Widget _buildHospitalSelectionPage() {
    final hospitals = _selectedProvince != null && _selectedDistrict != null
        ? HospitalService.getHospitalsByLocation(
            _selectedProvince!,
            _selectedDistrict!,
          )
        : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.red.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '$_selectedDistrict, $_selectedProvince',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hangi hastanede acil servis hizmeti almak istiyorsunuz?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bekleme süresi ve kapasite bilgilerini göz önünde bulundurarak seçim yapabilirsiniz.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (hospitals.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bu bölgede henüz acil servis hizmeti veren hastane bilgisi bulunmuyor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _previousStep(),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: hospitals.length,
                itemBuilder: (context, index) {
                  final hospital = hospitals[index];
                  final isSelected = _selectedHospital?['id'] == hospital['id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: isSelected ? 8 : 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.red.shade600
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _selectHospital(hospital),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.red.shade600
                                          : Colors.grey.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      hospital['type'] == 'Özel'
                                          ? Icons.business
                                          : Icons.account_balance,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hospital['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.red.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hospital['type'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? Colors.red.shade600
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.red.shade600,
                                      size: 28,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Bekleme: ~${hospital['waitingTime']} dk',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kapasite: %${hospital['capacity']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hospital['address'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> question, int index) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru kartı
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.red.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Soru başlığı
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          question['icon'] ?? Icons.help,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          question['category'] ?? 'Sağlık Değerlendirmesi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Soru metni
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Açıklama varsa
                  if (question['description'] != null)
                    Text(
                      question['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Cevap butonları
          Expanded(
            child: Column(
              children: [
                // EVET butonu
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(index, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answers[index] == true
                          ? Colors.green.shade600
                          : Colors.white,
                      foregroundColor: _answers[index] == true
                          ? Colors.white
                          : Colors.green.shade600,
                      elevation: _answers[index] == true ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.green.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 32),
                        const SizedBox(width: 16),
                        const Text(
                          'EVET',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // HAYIR butonu
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(index, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answers[index] == false
                          ? Colors.blue.shade600
                          : Colors.white,
                      foregroundColor: _answers[index] == false
                          ? Colors.white
                          : Colors.blue.shade600,
                      elevation: _answers[index] == false ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, size: 32),
                        const SizedBox(width: 16),
                        const Text(
                          'HAYIR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Navigasyon butonları
                if (_currentStep > 3)
                  TextButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Önceki Soru'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPage() {
    final triageResult = TriageService.calculateTriageResult(
      _totalScore.toInt(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sonuç kartı
          Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    triageResult['color'],
                    triageResult['color'].withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(triageResult['icon'], size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    triageResult['level'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toplam Puan: ${_totalScore.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      triageResult['message'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seçilen hastane bilgisi
          if (_selectedHospital != null) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_hospital, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Seçilen Hastane',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedHospital!['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedHospital!['address']}\n$_selectedDistrict, $_selectedProvince',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Telefon: ${_selectedHospital!['phone']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Cevaplar özeti
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Verilen Cevaplar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._buildAnswersSummary(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Aksiyon butonları
          if (triageResult['level'] == 'Kırmızı Alan')
            _buildEmergencyActionButton()
          else
            _buildDoctorConsultationButton(),

          const SizedBox(height: 16),

          // Ana sayfaya dön butonu
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Ana Sayfaya Dön',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildAnswersSummary() {
    final List<Widget> widgets = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final answer = _answers[i];
      final points = answer != null
          ? (answer ? question['yesPoints'] : question['noPoints'])
          : 0;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soru ${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                question['question'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: answer == true
                          ? Colors.green.withValues(alpha: 0.1)
                          : answer == false
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: answer == true
                            ? Colors.green
                            : answer == false
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    child: Text(
                      answer == true
                          ? 'EVET'
                          : answer == false
                          ? 'HAYIR'
                          : 'Cevapsız',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: answer == true
                            ? Colors.green.shade700
                            : answer == false
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    '+$points puan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: points > 50
                          ? Colors.red.shade600
                          : points > 20
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildEmergencyActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleEmergencyCase,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.local_hospital, size: 28),
        label: Text(
          _isSubmitting ? 'Hastane Bildiriliyor...' : 'Acil Servise Git',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorConsultationButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleDoctorConsultation,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.video_call, size: 28),
        label: Text(
          _isSubmitting ? 'Doktor Bağlanıyor...' : 'Doktor ile Görüş',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _answerQuestion(int questionIndex, bool answer) {
    setState(() {
      _answers[questionIndex] = answer;
    });

    // Puanı hesapla
    final question = _questions[questionIndex];
    final points = answer ? question['yesPoints'] : question['noPoints'];

    if (kDebugMode) {
      debugPrint('🏥 Soru $questionIndex: $answer -> $points puan');
    }

    // Toplam puanı güncelle
    _totalScore += points;

    // Kritik durum kontrolü (bilinç kapalı, nefes durmuş vs.)
    if (question['critical'] == true && answer == question['criticalAnswer']) {
      if (kDebugMode) {
        debugPrint('🚨 KRİTİK DURUM TESPİT EDİLDİ!');
      }
      _totalScore = 200; // Kritik durumda maksimum puan ver
      _goToResultPage();
      return;
    }

    // Sonraki soruya geç
    _nextQuestion();
  }

  void _selectProvince(String province) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null; // İl değiştiğinde ilçeyi sıfırla
      _selectedHospital = null; // Hastaneyi de sıfırla
    });
    _nextStep();
  }

  void _selectDistrict(String district) {
    setState(() {
      _selectedDistrict = district;
      _selectedHospital = null; // İlçe değiştiğinde hastaneyi sıfırla
    });
    _nextStep();
  }

  void _selectHospital(Map<String, dynamic> hospital) {
    setState(() {
      _selectedHospital = hospital;
    });
    _nextStep();
  }

  void _nextStep() {
    if (_currentStep == 2 && _questions.isEmpty) {
      // Hastane seçiminden sonra soruları yükle
      _loadTriageQuestions();
    }

    setState(() {
      _currentStep++;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Eğer soru aşamasındayken geri dönüyorsak puanları güncelle
      if (_currentStep >= 3 && _currentStep < 3 + _questions.length) {
        final questionIndex = _currentStep - 3;
        if (questionIndex >= 0) {
          final question = _questions[questionIndex];
          final answer = _answers[questionIndex];
          if (answer != null) {
            final points = answer
                ? question['yesPoints']
                : question['noPoints'];
            _totalScore -= points;
          }
        }
      }

      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextQuestion() {
    final questionIndex = _currentStep - 3;
    if (questionIndex < _questions.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToResultPage();
    }
  }

  void _previousQuestion() {
    if (_currentStep > 3) {
      // Önceki sorunun puanını çıkar
      final questionIndex = _currentStep - 3 - 1;
      if (questionIndex >= 0) {
        final previousQuestion = _questions[questionIndex];
        final previousAnswer = _answers[questionIndex];
        if (previousAnswer != null) {
          final points = previousAnswer
              ? previousQuestion['yesPoints']
              : previousQuestion['noPoints'];
          _totalScore -= points;
        }
      }

      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToResultPage() {
    setState(() {
      _currentStep = _getTotalSteps() - 1; // Son sayfa
    });
    _pageController.animateToPage(
      _getTotalSteps() - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleEmergencyCase() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Acil başvuru kaydı oluştur
      final applicationId = await TriageService.createEmergencyApplication(
        patientId: _patientId!,
        patientName: _patientName!,
        triageScore: _totalScore.toInt(),
        answers: _answers,
        questions: _questions,
        priority: 'emergency',
        selectedHospital: _selectedHospital,
        selectedProvince: _selectedProvince,
        selectedDistrict: _selectedDistrict,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🚨 Acil başvurunuz hastaneye iletildi! Lütfen en yakın acil servise gidin.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('🏥 Acil başvuru oluşturuldu: $applicationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Başvuru kaydı oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleDoctorConsultation() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Normal başvuru kaydı oluştur
      final applicationId = await TriageService.createEmergencyApplication(
        patientId: _patientId!,
        patientName: _patientName!,
        triageScore: _totalScore.toInt(),
        answers: _answers,
        questions: _questions,
        priority: _totalScore >= 40 ? 'medium' : 'low',
        selectedHospital: _selectedHospital,
        selectedProvince: _selectedProvince,
        selectedDistrict: _selectedDistrict,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '👨‍⚕️ Başvurunuz kaydedildi! Doktor konsültasyon ekranına yönlendiriliyorsunuz...',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Doktor konsültasyon ekranına yönlendir
        if (applicationId != null) {
          final triageResult = TriageService.calculateTriageResult(
            _totalScore.toInt(),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorConsultationScreen(
                applicationId: applicationId,
                patientId: _patientId!,
                patientName: _patientName!,
                triageResult: triageResult,
                selectedHospital: _selectedHospital,
              ),
            ),
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '🏥 Doktor konsültasyon başvurusu oluşturuldu: $applicationId',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Başvuru kaydı oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Değerlendirmeden Çık'),
            content: const Text(
              'Değerlendirme henüz tamamlanmadı. Çıkmak istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Çık'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
