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
      // Doktor arama işlemi
      final doctor = await ConsultationService.findAvailableDoctor(
        hospitalId: widget.selectedHospital?['id'],
        priority: widget.triageResult['priority'],
      );

      if (doctor != null) {
        setState(() {
          _assignedDoctor = doctor;
          _consultationStatus = 'doctor_found';
        });

        // Konsültasyon kaydı oluştur
        await ConsultationService.createConsultation(
          applicationId: widget.applicationId,
          patientId: widget.patientId,
          doctorId: doctor['id'],
          triageScore: widget.triageResult['priority'],
        );
      } else {
        setState(() {
          _consultationStatus = 'no_doctor_available';
        });
      }
    } catch (e) {
      setState(() {
        _consultationStatus = 'error';
      });
      if (kDebugMode) {
        debugPrint('❌ Doktor arama hatası: $e');
      }
    } finally {
      // _isSearchingDoctor kaldırıldı
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Triaj sonucu özeti
              _buildTriageResultSummary(),
              const SizedBox(height: 24),

              // Konsültasyon durumu
              Expanded(child: _buildConsultationContent()),

              // Alt butonlar
              _buildBottomButtons(),
            ],
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
                      ),
                      Text(
                        'Hasta: ${widget.patientName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
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
          // Doktor avatarı
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.blue.shade300, width: 3),
            ),
            child: Icon(Icons.person, size: 60, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Doktor Bulundu!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),

          // Doktor bilgileri
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _assignedDoctor?['name'] ?? 'Doktor',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _assignedDoctor?['specialty'] ?? 'Genel Pratisyen',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _assignedDoctor?['hospital'] ??
                        widget.selectedHospital?['name'] ??
                        'Hastane',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Görüşme başlat butonu
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
                    : 'Video Görüşme Başlat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
          Icon(Icons.person_off, size: 80, color: Colors.orange.shade400),
          const SizedBox(height: 24),
          const Text(
            'Şu Anda Uygun Doktor Yok',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Maalesef şu anda online konsültasyon verebilecek doktor bulunmuyor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startDoctorSearch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Hastaneye yönlendir
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Hastaneye Git'),
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
