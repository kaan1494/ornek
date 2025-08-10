import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_consultation_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  List<Map<String, dynamic>> greenAreaPatients = [];
  Map<String, Map<String, dynamic>> hospitalDoctorMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGreenAreaPatients();
  }

  Future<void> _loadGreenAreaPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Yeşil alan hastalarını al (score 30-50 arası)
      final triageQuery = await FirebaseFirestore.instance
          .collection('triage_results')
          .where('score', isGreaterThanOrEqualTo: 30)
          .where('score', isLessThanOrEqualTo: 50)
          .orderBy('score')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> patients = [];

      for (var doc in triageQuery.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        // Hasta bilgilerini al
        if (data['patientId'] != null) {
          try {
            final patientDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(data['patientId'])
                .get();

            if (patientDoc.exists) {
              data['patientInfo'] = patientDoc.data();
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Hasta bilgisi alınamadı: $e');
            }
          }
        }

        // Hastane bilgilerini al
        if (data['hospitalId'] != null) {
          try {
            final hospitalDoc = await FirebaseFirestore.instance
                .collection('hospitals')
                .doc(data['hospitalId'])
                .get();

            if (hospitalDoc.exists) {
              data['hospitalInfo'] = hospitalDoc.data();
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Hastane bilgisi alınamadı: $e');
            }
          }
        }

        patients.add(data);
      }

      // Hastane-doktor eşleşmelerini al
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('hospital_doctor_assignments')
          .get();

      Map<String, String> hospitalDoctorAssignments = {};
      for (var doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        hospitalDoctorAssignments[data['hospitalId']] = data['doctorId'];
      }

      // Doktor bilgilerini al
      Map<String, Map<String, dynamic>> doctorInfoMap = {};
      for (String doctorId in hospitalDoctorAssignments.values) {
        try {
          final doctorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(doctorId)
              .get();

          if (doctorDoc.exists) {
            doctorInfoMap[doctorId] = doctorDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Doktor bilgisi alınamadı: $e');
          }
        }
      }

      // Hastane-doktor eşleşmelerini tam bilgiyle hazırla
      Map<String, Map<String, dynamic>> hospitalDoctorFullMap = {};
      hospitalDoctorAssignments.forEach((hospitalId, doctorId) {
        if (doctorInfoMap[doctorId] != null) {
          hospitalDoctorFullMap[hospitalId] = doctorInfoMap[doctorId]!;
        }
      });

      setState(() {
        greenAreaPatients = patients;
        hospitalDoctorMap = hospitalDoctorFullMap;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('🟢 ${patients.length} yeşil alan hastası yüklendi');
        debugPrint(
          '👨‍⚕️ ${hospitalDoctorFullMap.length} hastane-doktor eşleşmesi',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Yeşil alan hastaları yükleme hatası: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(double score) {
    if (score >= 40) {
      return Colors.yellow.shade600; // Yüksek öncelik
    } else if (score >= 35) {
      return Colors.green.shade600; // Orta öncelik
    } else {
      return Colors.green.shade400; // Düşük öncelik
    }
  }

  String _getPriorityText(double score) {
    if (score >= 40) {
      return 'Yüksek Öncelik';
    } else if (score >= 35) {
      return 'Orta Öncelik';
    } else {
      return 'Düşük Öncelik';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text(
          'Planlarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGreenAreaPatients,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bilgi kartı
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade100, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note,
                        color: Colors.purple.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yeşil Alan Doktor Görüşmeleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yeşil alana atanan hastaların nöbetçi doktorlarla görüşme planları',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // İstatistikler
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${greenAreaPatients.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Yeşil Alan Hastası',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${greenAreaPatients.where((p) => hospitalDoctorMap[p['hospitalId']] != null).length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                'Doktor Atanmış',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${greenAreaPatients.where((p) => hospitalDoctorMap[p['hospitalId']] == null).length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                'Doktor Bekleyen',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hasta listesi
                Expanded(
                  child: greenAreaPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz yeşil alan hastası bulunmuyor',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Triaj skoru 30-50 arasındaki hastalar burada görünecek',
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
                          itemCount: greenAreaPatients.length,
                          itemBuilder: (context, index) {
                            final patient = greenAreaPatients[index];
                            final patientInfo = patient['patientInfo'];
                            final hospitalInfo = patient['hospitalInfo'];
                            final score = (patient['score'] as num).toDouble();
                            final assignedDoctor =
                                hospitalDoctorMap[patient['hospitalId']];
                            final hasDoctor = assignedDoctor != null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: hasDoctor ? 3 : 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: hasDoctor
                                      ? Border.all(
                                          color: Colors.green.shade300,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: Colors.orange.shade300,
                                          width: 1,
                                        ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Hasta bilgileri
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                score,
                                              ).withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: _getPriorityColor(score),
                                              size: 24,
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
                                                      : patient['patientName'] ??
                                                            'İsimsiz Hasta',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.score,
                                                      size: 16,
                                                      color: _getPriorityColor(
                                                        score,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Triaj Skoru: ${score.toInt()}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            _getPriorityColor(
                                                              score,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
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
                                              color: _getPriorityColor(
                                                score,
                                              ).withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _getPriorityText(score),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _getPriorityColor(score),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Hastane bilgileri
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              color: Colors.blue.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Atanan Hastane',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.blue.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    hospitalInfo?['name'] ??
                                                        patient['hospitalName'] ??
                                                        'Bilinmeyen Hastane',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Doktor bilgileri
                                      if (hasDoctor) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    color:
                                                        Colors.green.shade600,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Nöbetçi Doktor',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.green.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${assignedDoctor['firstName']} ${assignedDoctor['lastName']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (assignedDoctor['email'] !=
                                                  null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  assignedDoctor['email'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => DoctorConsultationScreen(
                                                    applicationId:
                                                        'demo-app', // Placeholder
                                                    patientId:
                                                        patient['patientId'] ??
                                                        '',
                                                    patientName:
                                                        patientInfo != null
                                                        ? '${patientInfo['firstName']} ${patientInfo['lastName']}'
                                                        : patient['patientName'] ??
                                                              'İsimsiz Hasta',
                                                    triageResult: {
                                                      'score': score,
                                                      'priority':
                                                          _getPriorityText(
                                                            score,
                                                          ),
                                                      'symptoms':
                                                          patient['symptoms'] ??
                                                          [],
                                                    },
                                                    selectedHospital: {
                                                      'id':
                                                          patient['hospitalId'],
                                                      'name':
                                                          hospitalInfo?['name'] ??
                                                          patient['hospitalName'] ??
                                                          'Bilinmeyen Hastane',
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.video_call),
                                            label: const Text(
                                              'Doktor Görüşmesi Başlat',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber,
                                                color: Colors.orange.shade600,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Bu hastaneye henüz nöbetçi doktor atanmamış. Doktor görüşmesi yapılamaz.',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      // Başvuru tarihi
                                      if (patient['createdAt'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Başvuru: ${(patient['createdAt'] as Timestamp).toDate().toString().substring(0, 16)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
}
