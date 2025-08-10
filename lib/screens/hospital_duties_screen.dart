import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/hospital_service.dart';

class HospitalDutiesScreen extends StatefulWidget {
  const HospitalDutiesScreen({super.key});

  @override
  State<HospitalDutiesScreen> createState() => _HospitalDutiesScreenState();
}

class _HospitalDutiesScreenState extends State<HospitalDutiesScreen> {
  List<Map<String, dynamic>> hospitalsWithDoctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalDuties();
  }

  Future<void> _loadHospitalDuties() async {
    try {
      // Acil hastaneleri al
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

      List<Map<String, dynamic>> hospitals = uniqueHospitals.values.toList();

      // Doktor atamalarını al
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('hospital_doctor_assignments')
          .get();

      Map<String, String> hospitalDoctorMap = {};
      for (var doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        hospitalDoctorMap[data['hospitalId']] = data['doctorId'];
      }

      // Doktorları al
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      Map<String, Map<String, dynamic>> doctorMap = {};
      for (var doc in doctorsSnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        doctorMap[doc.id] = data;
      }

      // Hastaneleri doktor bilgileriyle birleştir
      List<Map<String, dynamic>> result = [];
      for (var hospital in hospitals) {
        final hospitalId = hospital['id'];
        final doctorId = hospitalDoctorMap[hospitalId];

        Map<String, dynamic> hospitalWithDoctor = Map.from(hospital);
        if (doctorId != null && doctorMap[doctorId] != null) {
          hospitalWithDoctor['assignedDoctor'] = doctorMap[doctorId];
        }

        result.add(hospitalWithDoctor);
      }

      // Önce doktor atanmış hastaneler, sonra boş olanlar
      result.sort((a, b) {
        if (a['assignedDoctor'] != null && b['assignedDoctor'] == null) {
          return -1;
        }
        if (a['assignedDoctor'] == null && b['assignedDoctor'] != null) {
          return 1;
        }
        return a['name'].compareTo(b['name']);
      });

      setState(() {
        hospitalsWithDoctors = result;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('🏥 ${result.length} hastane nöbet bilgisi yüklendi');
        final withDoctor = result
            .where((h) => h['assignedDoctor'] != null)
            .length;
        debugPrint('👨‍⚕️ $withDoctor hastanede nöbetçi doktor var');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hastane nöbet bilgileri yükleme hatası: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text(
          'Hastane Nöbetleri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadHospitalDuties,
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
                      colors: [Colors.green.shade100, Colors.green.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: Colors.green.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acil Hastane Nöbetleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acil başvuru yapabilen hastanelerdeki nöbetçi doktorları görüntüleyin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
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
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${hospitalsWithDoctors.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                'Toplam Hastane',
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
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${hospitalsWithDoctors.where((h) => h['assignedDoctor'] != null).length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Nöbetçi Var',
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
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${hospitalsWithDoctors.where((h) => h['assignedDoctor'] == null).length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                'Nöbetçi Yok',
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
                    itemCount: hospitalsWithDoctors.length,
                    itemBuilder: (context, index) {
                      final hospital = hospitalsWithDoctors[index];
                      final assignedDoctor = hospital['assignedDoctor'];
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
                                : null,
                          ),
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
                                        color: hasDoctor
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.local_hospital,
                                        color: hasDoctor
                                            ? Colors.green.shade600
                                            : Colors.orange.shade600,
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
                                            hospital['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${hospital['province']} - ${hospital['district']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (hospital['address'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              hospital['address'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasDoctor
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasDoctor
                                                ? Icons.check_circle
                                                : Icons.warning,
                                            color: hasDoctor
                                                ? Colors.green.shade600
                                                : Colors.orange.shade600,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasDoctor
                                                ? 'Nöbetçi Var'
                                                : 'Nöbetçi Yok',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: hasDoctor
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                if (hasDoctor) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
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
                                              color: Colors.green.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nöbetçi Doktor',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${assignedDoctor['firstName']} ${assignedDoctor['lastName']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (assignedDoctor['email'] !=
                                            null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            assignedDoctor['email'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        if (assignedDoctor['phone'] !=
                                            null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tel: ${assignedDoctor['phone']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Bu hastaneye henüz nöbetçi doktor atanmamış',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
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
