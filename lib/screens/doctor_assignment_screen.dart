import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/hospital_service.dart';

class DoctorAssignmentScreen extends StatefulWidget {
  const DoctorAssignmentScreen({super.key});

  @override
  State<DoctorAssignmentScreen> createState() => _DoctorAssignmentScreenState();
}

class _DoctorAssignmentScreenState extends State<DoctorAssignmentScreen> {
  List<Map<String, dynamic>> hospitals = [];
  List<Map<String, dynamic>> doctors = [];
  Map<String, String> hospitalDoctorAssignments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadHospitals(), _loadDoctors(), _loadAssignments()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadHospitals() async {
    try {
      // Acil hastaneleri al (tüm şehirlerden)
      List<Map<String, dynamic>> allHospitals = [];

      // İstanbul hastaneleri
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('İstanbul', 'Kadıköy'),
      );
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('İstanbul', 'Beşiktaş'),
      );
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('İstanbul', 'Şişli'),
      );

      // Ankara hastaneleri
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('Ankara', 'Çankaya'),
      );
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('Ankara', 'Keçiören'),
      );

      // İzmir hastaneleri
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('İzmir', 'Konak'),
      );
      allHospitals.addAll(
        HospitalService.getHospitalsByLocation('İzmir', 'Bornova'),
      );

      // Duplicates'i kaldır
      final uniqueHospitals = <String, Map<String, dynamic>>{};
      for (var hospital in allHospitals) {
        uniqueHospitals[hospital['id']] = hospital;
      }

      setState(() {
        hospitals = uniqueHospitals.values.toList();
      });

      if (kDebugMode) {
        debugPrint('🏥 ${hospitals.length} hastane yüklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane yükleme hatası: $e');
      }
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      setState(() {
        doctors = querySnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });

      if (kDebugMode) {
        debugPrint('👨‍⚕️ ${doctors.length} doktor yüklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor yükleme hatası: $e');
      }
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('hospital_doctor_assignments')
          .get();

      Map<String, String> assignments = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        assignments[data['hospitalId']] = data['doctorId'];
      }

      setState(() {
        hospitalDoctorAssignments = assignments;
      });

      if (kDebugMode) {
        debugPrint('🔗 ${assignments.length} atama yüklendi');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Atama yükleme hatası: $e');
      }
    }
  }

  Future<void> _assignDoctor(String hospitalId, String doctorId) async {
    try {
      // Mevcut atamanın var olup olmadığını kontrol et
      final existingQuery = await FirebaseFirestore.instance
          .collection('hospital_doctor_assignments')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Güncelle
        await existingQuery.docs.first.reference.update({
          'doctorId': doctorId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Yeni oluştur
        await FirebaseFirestore.instance
            .collection('hospital_doctor_assignments')
            .add({
              'hospitalId': hospitalId,
              'doctorId': doctorId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      setState(() {
        hospitalDoctorAssignments[hospitalId] = doctorId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Doktor başarıyla atandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Doktor atama hatası: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Doktor atama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDoctorName(String doctorId) {
    final doctor = doctors.firstWhere(
      (d) => d['id'] == doctorId,
      orElse: () => {},
    );
    if (doctor.isNotEmpty) {
      return '${doctor['firstName']} ${doctor['lastName']}';
    }
    return 'Doktor bulunamadı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text(
          'Doktor Ata',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acil Hastanelere Doktor Atama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acil başvuru yapabilen hastanelere nöbetçi doktor atayabilirsiniz',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
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
                                '${hospitals.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Toplam Hastane',
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
                                '${doctors.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                'Toplam Doktor',
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
                                '${hospitalDoctorAssignments.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                'Atanmış',
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

                // Hastane listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: hospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = hospitals[index];
                      final hospitalId = hospital['id'];
                      final assignedDoctorId =
                          hospitalDoctorAssignments[hospitalId];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_hospital,
                                    color: Colors.red.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hospital['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${hospital['province']} - ${hospital['district']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: assignedDoctorId != null
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      assignedDoctorId != null
                                          ? 'Atanmış'
                                          : 'Boş',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: assignedDoctorId != null
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (assignedDoctorId != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.green.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Atanmış Doktor: ${_getDoctorName(assignedDoctorId)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showDoctorSelectionDialog(hospitalId),
                                  icon: Icon(
                                    assignedDoctorId != null
                                        ? Icons.edit
                                        : Icons.person_add,
                                  ),
                                  label: Text(
                                    assignedDoctorId != null
                                        ? 'Doktoru Değiştir'
                                        : 'Doktor Ata',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: assignedDoctorId != null
                                        ? Colors.orange.shade600
                                        : Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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

  void _showDoctorSelectionDialog(String hospitalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doktor Seçin'),
        content: SizedBox(
          width: double.maxFinite,
          child: doctors.isEmpty
              ? const Text('Henüz doktor kaydı bulunmuyor.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, color: Colors.blue.shade600),
                      ),
                      title: Text(
                        '${doctor['firstName']} ${doctor['lastName']}',
                      ),
                      subtitle: Text(doctor['email']),
                      onTap: () {
                        Navigator.pop(context);
                        _assignDoctor(hospitalId, doctor['id']);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}
