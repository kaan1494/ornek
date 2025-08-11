import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/consultation_service.dart';
import '../services/agora_service.dart';
import 'video_call_screen_factory.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final String applicationId;
  final String patientId;
  final String patientName;
  final Map<String, dynamic> triageResult;
  final Map<String, dynamic>? selectedHospital;

  const DoctorConsultationScreen({
    super.key,
    required this.applicationId,
    required this.patientId,
    required this.patientName,
    required this.triageResult,
    this.selectedHospital,
  });

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  bool _isCallStarted = false;
  Map<String, dynamic>? _assignedDoctor;
  String _consultationStatus = 'searching';

  @override
  void initState() {
    super.initState();
    _startDoctorSearch();
  }

  Future<void> _startDoctorSearch() async {
    setState(() {
      _consultationStatus = 'searching';
    });

    try {
      if (kDebugMode) {
        debugPrint('🔍===========================================');
        debugPrint('🔍 NÖBET DOKTORu ARAMA BAŞLATIYOR...');
        debugPrint('🔍===========================================');
        debugPrint('🏥 Hastane ID: ${widget.selectedHospital?['id']}');
        debugPrint('🏥 Hastane Adı: ${widget.selectedHospital?['name']}');
        debugPrint('📊 Triaj Önceliği: ${widget.triageResult['priority']}');
        debugPrint('👤 Patient ID: ${widget.patientId}');
        debugPrint('📋 Application ID: ${widget.applicationId}');
        debugPrint('🔍===========================================');
      }

      // Admin panelinden atanmış nöbetçi doktor ara
      final doctor = await ConsultationService.findAssignedDoctor(
        hospitalId: widget.selectedHospital?['id'] ?? '',
        patientId: widget.patientId,
        applicationId: widget.applicationId,
      );

      if (doctor != null) {
        if (kDebugMode) {
          debugPrint('✅===========================================');
          debugPrint('✅ NÖBETÇİ DOKTOR BULUNDU!');
          debugPrint('✅===========================================');
          debugPrint('👨‍⚕️ Doktor: Dr. ${doctor['doctorName']}');
          debugPrint('🆔 Doktor ID: ${doctor['doctorId']}');
          debugPrint('🏥 Hastane: ${doctor['hospitalName']}');
          debugPrint('🆔 Hastane ID: ${doctor['hospitalId']}');
          debugPrint('🕐 Nöbet Türü: ${doctor['shiftType']}');
          debugPrint('📅 Nöbet Başlangıç: ${doctor['startDate']}');
          debugPrint('⏰ Nöbet Bitiş: ${doctor['endDate']}');
          debugPrint('🚨 Acil için Müsait: ${doctor['availableForEmergency']}');
          debugPrint('📊 Hasta Kapasitesi: ${doctor['currentPatientCount']}/${doctor['maxPatientCapacity']}');
          debugPrint('✅===========================================');
        }

        setState(() {
          _assignedDoctor = {
            'id': doctor['doctorId'],
            'name': doctor['doctorName'],
            'specialty': 'Acil Tıp', // Default specialty
            'hospital': doctor['hospitalName'],
            'hospitalId': doctor['hospitalId'],
            'shiftType': doctor['shiftType'],
            'isOnline': true,
            'avatarUrl': null,
            'shiftId': doctor['id'], // Nöbet kaydının ID'si
            'startDate': doctor['startDate'],
            'endDate': doctor['endDate'],
            'patientCapacity': doctor['maxPatientCapacity'],
            'currentPatients': doctor['currentPatientCount'],
          };
          _consultationStatus = 'doctor_found';
        });

        // Hasta sayısını artır
        await ConsultationService.incrementPatientCount(doctor['id']);
        
        if (kDebugMode) {
          debugPrint('📊 Doktor hasta sayısı güncellendi');
        }

      } else {
        if (kDebugMode) {
          debugPrint('❌===========================================');
          debugPrint('❌ NÖBETÇİ DOKTOR BULUNAMADI!');
          debugPrint('❌===========================================');
          debugPrint('🏥 Aranan Hastane: ${widget.selectedHospital?['name']}');
          debugPrint('🆔 Hastane ID: ${widget.selectedHospital?['id']}');
          debugPrint('⚠️ Bu hastaneye admin panelinden doktor atanmamış olabilir');
          debugPrint('❌===========================================');
        }
        
        setState(() {
          _consultationStatus = 'no_doctor_available';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌===========================================');
        debugPrint('❌ DOKTOR ARAMA HATASI!');
        debugPrint('❌===========================================');
        debugPrint('💥 Hata: $e');
        debugPrint('🏥 Hastane: ${widget.selectedHospital?['name']}');
        debugPrint('❌===========================================');
      }
      
      setState(() {
        _consultationStatus = 'error';
      });
    }
  }

  Future<void> _startVideoCall() async {
    setState(() {
      _isCallStarted = true;
      _consultationStatus = 'starting_call';
    });

    try {
      // Video call oluştur
      final callId = await AgoraService.createVideoCall(
        doctorId: _assignedDoctor!['id'],
        patientId: widget.patientId,
        applicationId: widget.applicationId,
        additionalData: {
          'patientName': widget.patientName,
          'doctorName': _assignedDoctor!['name'],
          'triageResult': widget.triageResult,
          'hospitalId': widget.selectedHospital?['id'],
        },
      );

      if (callId != null && mounted) {
        // Video call ekranına yönlendir
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreenFactory.create(
              channelName: 'call_$callId',
              userId: widget.patientId,
              userType: 'patient',
              callData: {
                'id': callId,
                'patientName': widget.patientName,
                'doctorName': _assignedDoctor!['name'],
                'doctorId': _assignedDoctor!['id'],
                'applicationId': widget.applicationId,
              },
            ),
          ),
        );

        // Call sonrası durum güncelle
        if (mounted) {
          setState(() {
            _consultationStatus = 'call_ended';
            _isCallStarted = false;
          });

          // Call bilgilerini güncelle
          await AgoraService.updateCallStatus(
            callId: callId,
            status: 'ended',
            userId: widget.patientId,
            userType: 'patient',
          );
        }
      } else {
        throw Exception('Video call oluşturulamadı');
      }
    } catch (e) {
      setState(() {
        _consultationStatus = 'call_error';
        _isCallStarted = false;
      });

      if (kDebugMode) {
        debugPrint('❌ Video call başlatma hatası: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video görüşme başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Online Doktor Konsültasyonu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 
                         AppBar().preferredSize.height - 32,
            ),
            child: Column(
              children: [
                // Triaj sonucu özeti
                _buildTriageResultSummary(),
                const SizedBox(height: 20),

                // Konsültasyon durumu - flex yerine normal widget
                _buildConsultationContent(),
                const SizedBox(height: 20),

                // Alt butonlar
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriageResultSummary() {
    final triageResult = widget.triageResult;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, triageResult['color'].withOpacity(0.1)],
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
                    color: triageResult['color'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    triageResult['icon'],
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        triageResult['level'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: triageResult['color'],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Hasta: ${widget.patientName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              triageResult['message'],
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationContent() {
    switch (_consultationStatus) {
      case 'searching':
        return _buildSearchingDoctor();
      case 'doctor_found':
        return _buildDoctorFound();
      case 'no_doctor_available':
        return _buildNoDoctorAvailable();
      case 'in_call':
        return _buildInCall();
      case 'call_error':
        return _buildCallError();
      case 'error':
        return _buildError();
      default:
        return _buildSearchingDoctor();
    }
  }

  Widget _buildSearchingDoctor() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Uygun Doktor Aranıyor...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Size en uygun doktoru buluyoruz.\nLütfen bekleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Başarı ikonu
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.green.shade300, width: 3),
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Nöbetçi Doktor Bulundu!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),

          // Doktor detay kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Doktor avatarı
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Doktor adı
                Text(
                  'Dr. ${_assignedDoctor?['name'] ?? 'Doktor'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Uzmanlık alanı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _assignedDoctor?['specialty'] ?? 'Acil Tıp Uzmanı',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hastane bilgisi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _assignedDoctor?['hospital'] ?? widget.selectedHospital?['name'] ?? 'Hastane',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nöbet bilgisi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_assignedDoctor?['shiftType'] == 'daily' ? '24 Saatlik' : '12 Saatlik'} Nöbet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Online durum
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Şu anda müsait',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Video görüşme başlat butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isCallStarted ? null : _startVideoCall,
              icon: _isCallStarted
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
                _isCallStarted
                    ? 'Görüşme Başlatılıyor...'
                    : '📹 Doktor ile Görüntülü Görüş',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDoctorAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Uyarı ikonu
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.orange.shade300, width: 3),
            ),
            child: Icon(
              Icons.person_off,
              size: 50,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Şu Anda Uygun Doktor Yok',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Açıklama kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Maalesef ${widget.selectedHospital?['name'] ?? 'seçilen hastane'}de şu anda online konsültasyon verebilecek nöbetçi doktor bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu durumun nedenleri:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Hastaneye henüz doktor atanmamış\n'
                  '• Nöbetçi doktorların kapasitesi dolu\n'
                  '• Vardiya saatleri dışında',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startDoctorSearch,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Tekrar Dene',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.local_hospital, size: 20),
                  label: const Text(
                    'Acil Servise Git',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInCall() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.video_call,
              size: 60,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Görüşme Devam Ediyor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Doktor ile görüşmeniz devam ediyor.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCallError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          const Text(
            'Bağlantı Hatası',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Görüşme başlatılırken bir hata oluştu. Lütfen tekrar deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          const Text(
            'Bir Hata Oluştu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Sistem hatası oluştu. Lütfen tekrar deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startDoctorSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_consultationStatus == 'doctor_found' ||
        _consultationStatus == 'in_call') {
      return Container();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
