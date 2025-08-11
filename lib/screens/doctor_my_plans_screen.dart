import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agora_service.dart';
import 'video_call_screen_factory.dart';

class DoctorMyPlansScreen extends StatefulWidget {
  const DoctorMyPlansScreen({super.key});

  @override
  State<DoctorMyPlansScreen> createState() => _DoctorMyPlansScreenState();
}

class _DoctorMyPlansScreenState extends State<DoctorMyPlansScreen> {
  List<Map<String, dynamic>> myConsultations = [];
  bool _isLoading = true;
  String? _currentDoctorId;

  @override
  void initState() {
    super.initState();
    _getCurrentDoctorId();
  }

  Future<void> _getCurrentDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentDoctorId = user.uid;
      });
      _loadMyConsultations();
    }
  }

  Future<void> _loadMyConsultations() async {
    if (_currentDoctorId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Bekleyen ve devam eden konsültasyonları al
      final consultationsSnapshot = await FirebaseFirestore.instance
          .collection('consultations')
          .where('doctorId', isEqualTo: _currentDoctorId)
          .where('status', whereIn: ['waiting', 'in_progress'])
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> consultations = [];

      for (var doc in consultationsSnapshot.docs) {
        Map<String, dynamic> consultationData = doc.data();
        consultationData['id'] = doc.id;

        // Hasta bilgilerini al
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(consultationData['patientId'])
              .get();

          if (patientDoc.exists) {
            consultationData['patientInfo'] = patientDoc.data();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Hasta bilgisi alınamadı: $e');
          }
        }

        // Acil başvuru bilgilerini al
        try {
          final applicationDoc = await FirebaseFirestore.instance
              .collection('emergency_applications')
              .doc(consultationData['applicationId'])
              .get();

          if (applicationDoc.exists) {
            consultationData['applicationInfo'] = applicationDoc.data();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Başvuru bilgisi alınamadı: $e');
          }
        }

        // Triaj sonucu bilgilerini al
        try {
          final triageQuery = await FirebaseFirestore.instance
              .collection('triage_results')
              .where('patientId', isEqualTo: consultationData['patientId'])
              .where(
                'applicationId',
                isEqualTo: consultationData['applicationId'],
              )
              .limit(1)
              .get();

          if (triageQuery.docs.isNotEmpty) {
            consultationData['triageInfo'] = triageQuery.docs.first.data();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Triaj bilgisi alınamadı: $e');
          }
        }

        consultations.add(consultationData);
      }

      setState(() {
        myConsultations = consultations;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('👨‍⚕️ ${consultations.length} konsültasyon yüklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Konsültasyon yükleme hatası: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Hastalarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadMyConsultations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // İstatistikler kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bekleyen Hastalar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${myConsultations.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hasta listesi
                Expanded(
                  child: myConsultations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bekleyen hasta bulunmuyor',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Atanmış hastalar burada görünecek',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: myConsultations.length,
                          itemBuilder: (context, index) {
                            final consultation = myConsultations[index];
                            final patientInfo = consultation['patientInfo'];
                            final applicationInfo =
                                consultation['applicationInfo'];
                            final triageInfo = consultation['triageInfo'];

                            final triageScore =
                                triageInfo?['score']?.toDouble() ?? 0.0;
                            final priorityData = _getPriorityData(triageScore);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: priorityData['color'],
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Hasta başlığı ve öncelik
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: priorityData['color']
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: priorityData['color'],
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
                                                  patientInfo != null
                                                      ? '${patientInfo['firstName']} ${patientInfo['lastName']}'
                                                      : 'İsimsiz Hasta',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (patientInfo?['phone'] !=
                                                    null)
                                                  Text(
                                                    patientInfo['phone'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: priorityData['color'],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              priorityData['text'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Triaj bilgileri
                                      if (triageInfo != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.healing,
                                                    color:
                                                        priorityData['color'],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Triaj Bilgileri',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          priorityData['color'],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Puan: ${triageScore.toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (triageInfo['symptoms'] !=
                                                  null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Şikayetler: ${(triageInfo['symptoms'] as List).join(', ')}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                              if (triageInfo['recommendation'] !=
                                                  null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Öneri: ${triageInfo['recommendation']}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Hastane bilgisi
                                      if (applicationInfo?['hospitalName'] !=
                                          null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              color: Colors.grey.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              applicationInfo['hospitalName'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Başvuru zamanı
                                      if (consultation['createdAt'] !=
                                          null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Colors.grey.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Başvuru: ${_formatDateTime(consultation['createdAt'])}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Video görüşme butonu
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _startVideoConsultation(
                                                consultation,
                                              ),
                                          icon: const Icon(Icons.video_call),
                                          label: const Text(
                                            'Video Konsültasyon Başlat',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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

  Map<String, dynamic> _getPriorityData(double score) {
    if (score >= 80) {
      return {'text': 'KRİTİK', 'color': Colors.red};
    } else if (score >= 60) {
      return {'text': 'ACİL', 'color': Colors.orange};
    } else if (score >= 30) {
      return {'text': 'ORTA', 'color': Colors.green};
    } else {
      return {'text': 'DÜŞÜK', 'color': Colors.blue};
    }
  }

  String _formatDateTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  Future<void> _startVideoConsultation(
    Map<String, dynamic> consultation,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Video görüşme başlatılıyor...'),
            ],
          ),
        ),
      );

      // Konsültasyon durumunu güncelle
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultation['id'])
          .update({
            'status': 'in_progress',
            'startTime': FieldValue.serverTimestamp(),
          });

      // Video call oluştur
      final callId = await AgoraService.createVideoCall(
        doctorId: _currentDoctorId!,
        patientId: consultation['patientId'],
        applicationId: consultation['applicationId'],
        additionalData: {
          'consultationId': consultation['id'],
          'doctorName': consultation['patientInfo'] != null
              ? '${consultation['patientInfo']['firstName']} ${consultation['patientInfo']['lastName']}'
              : 'Doktor',
          'patientName': consultation['patientInfo'] != null
              ? '${consultation['patientInfo']['firstName']} ${consultation['patientInfo']['lastName']}'
              : 'Hasta',
          'triageScore': consultation['triageInfo']?['score'] ?? 0,
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
      }

      if (callId != null && mounted) {
        // Video call ekranına yönlendir
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreenFactory.create(
              channelName: 'call_$callId',
              userId: _currentDoctorId!,
              userType: 'doctor',
              callData: {
                'id': callId,
                'consultationId': consultation['id'],
                'patientId': consultation['patientId'],
                'doctorId': _currentDoctorId!,
                'patientName': consultation['patientInfo'] != null
                    ? '${consultation['patientInfo']['firstName']} ${consultation['patientInfo']['lastName']}'
                    : 'Hasta',
                'doctorName':
                    'Dr. ${FirebaseAuth.instance.currentUser?.displayName ?? 'Doktor'}',
                'applicationId': consultation['applicationId'],
              },
            ),
          ),
        );

        // Call sonrası konsültasyonları yenile
        _loadMyConsultations();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video görüşme başlatılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
      }

      if (kDebugMode) {
        debugPrint('❌ Video konsültasyon hatası: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
