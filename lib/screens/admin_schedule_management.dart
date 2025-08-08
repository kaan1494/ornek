import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/schedule_service.dart';
import '../widgets/doctor_assignment_dialog.dart';
import 'doctor_schedule_screen.dart';

class AdminScheduleManagement extends StatefulWidget {
  const AdminScheduleManagement({super.key});

  @override
  State<AdminScheduleManagement> createState() =>
      _AdminScheduleManagementState();
}

class _AdminScheduleManagementState extends State<AdminScheduleManagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbet Yönetimi'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showDoctorAssignmentDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Nöbet Ata',
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst İstatistik Kartları
          _buildScheduleStatistics(),
          const SizedBox(height: 16),

          // Aksiyon Butonları
          _buildScheduleActions(),
          const SizedBox(height: 16),

          // Aktif Nöbetler Listesi
          Expanded(child: _buildActiveShiftsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDoctorAssignmentDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildScheduleStatistics() {
    return FutureBuilder<Map<String, int>>(
      future: ScheduleService.getShiftStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'current': 0, 'today': 0, 'total': 0};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🟢 Şu Anda Aktif',
                  stats['current'].toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '📅 Bugün Başlayan',
                  stats['today'].toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '📊 Toplam Nöbet',
                  stats['total'].toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showDoctorAssignmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Doktor Ata'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showHospitalShiftsOverview(),
              icon: const Icon(Icons.local_hospital),
              label: const Text('Hastane Nöbetleri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorScheduleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Planlama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: ScheduleService.getActiveShifts(),
      builder: (context, snapshot) {
        // Debug information
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Veri yükleme hatası:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Widget'ı yeniden oluştur
                  },
                  child: Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Nöbet verileri yükleniyor...'),
              ],
            ),
          );
        }

        // Veri kontrolleri
        final hasData = snapshot.hasData;
        final allDocs = snapshot.data?.docs ?? [];

        // Client-side filtering for active shifts
        final activeDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'active';
        }).toList();

        final docCount = activeDocs.length;

        if (kDebugMode) {
          print('🔍 Shifts data: total=${allDocs.length}, active=$docCount');
        }

        if (!hasData || activeDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Henüz aktif nöbet yok',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Toplam veri: ${allDocs.length}, Aktif: $docCount',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  'Doktor atamak için yukarıdaki "Doktor Ata" butonunu kullanın',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: activeDocs.length,
          itemBuilder: (context, index) {
            final doc = activeDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final shiftTypes = ScheduleService.getShiftTypes();
            final shiftInfo = shiftTypes.firstWhere(
              (type) => type['id'] == data['shiftType'],
              orElse: () => shiftTypes.first,
            );

            final startDate = (data['startDate'] as Timestamp).toDate();
            final endDate = (data['endDate'] as Timestamp).toDate();
            final now = DateTime.now();

            final isCurrentlyActive =
                startDate.isBefore(now) && endDate.isAfter(now);

            return Card(
              elevation: isCurrentlyActive ? 6 : 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: isCurrentlyActive
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(shiftInfo['color']),
                          width: 3,
                        ),
                      )
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(shiftInfo['color']),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['doctorName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentlyActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AKTİF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_hospital,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['hospitalName'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${shiftInfo['name']} (${shiftInfo['startTime']} - ${shiftInfo['endTime']})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (data['notes'] != null &&
                          data['notes'].isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.note,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['notes'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'remove') {
                        await _removeFromShift(doc.id, data['doctorName']);
                      } else if (value == 'view_hospital') {
                        await _viewHospitalShifts(
                          data['hospitalId'],
                          data['hospitalName'],
                        );
                      } else if (value == 'edit') {
                        await _editShift(doc.id, data);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_hospital',
                        child: Row(
                          children: [
                            Icon(Icons.local_hospital, size: 16),
                            SizedBox(width: 8),
                            Text('Hastane Nöbetleri'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Nöbetten Çıkar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDoctorAssignmentDialog() async {
    // Context'i await'tan önce sakla
    final dialogContext = context;

    if (kDebugMode) {
      print('🔍 Doktor atama dialog\'u açılıyor...');
    }

    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => const DoctorAssignmentDialog(),
    );

    if (kDebugMode) {
      print('🔍 Dialog sonucu: $result');
    }

    if (result == true && mounted) {
      if (kDebugMode) {
        print('✅ Nöbet başarıyla atandı, UI güncelleniyor...');
      }

      // Context'i await'tan önce sakla
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Doktor nöbete başarıyla atandı'),
          backgroundColor: Colors.green,
        ),
      );

      // Widget'ı yeniden oluşturmaya zorla
      if (mounted) {
        setState(() {
          // Bu, StreamBuilder'ın yeniden dinlenmesini sağlar
        });
      }
    } else if (result == false) {
      if (kDebugMode) {
        print('❌ Nöbet atama başarısız');
      }
    } else {
      if (kDebugMode) {
        print('❌ Dialog iptal edildi veya sonuç null');
      }
    }
  }

  Future<void> _removeFromShift(String shiftId, String doctorName) async {
    // Context'i await'tan önce sakla
    final dialogContext = context;

    final confirm = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Nöbetten Çıkar'),
        content: Text(
          '$doctorName isimli doktoru nöbetten çıkarmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ScheduleService.removeFromShift(shiftId);

      if (mounted) {
        // Context'i await'tan sonra kullan
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success ? '✅ Doktor nöbetten çıkarıldı' : '❌ İşlem başarısız',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewHospitalShifts(
    String hospitalId,
    String hospitalName,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('$hospitalName Nöbetleri')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: ScheduleService.getHospitalActiveShifts(hospitalId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Bu hastanede aktif nöbet yok'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final shiftTypes = ScheduleService.getShiftTypes();
                  final shiftInfo = shiftTypes.firstWhere(
                    (type) => type['id'] == data['shiftType'],
                    orElse: () => shiftTypes.first,
                  );

                  final startDate = (data['startDate'] as Timestamp).toDate();
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  final now = DateTime.now();
                  final isActive =
                      startDate.isBefore(now) && endDate.isAfter(now);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(shiftInfo['color']),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(data['doctorName'])),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AKTİF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${shiftInfo['name']} - ${shiftInfo['startTime']} / ${shiftInfo['endTime']}',
                          ),
                          Text(
                            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDoctorAssignmentDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yeni Doktor Ata'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHospitalShiftsOverview() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.green),
            SizedBox(width: 8),
            Text('Tüm Hastane Nöbetleri'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hospitals')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, hospitalSnapshot) {
              if (!hospitalSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: hospitalSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final hospitalDoc = hospitalSnapshot.data!.docs[index];
                  final hospitalData =
                      hospitalDoc.data() as Map<String, dynamic>;

                  return Card(
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.local_hospital,
                        color: Colors.green,
                      ),
                      title: Text(hospitalData['name']),
                      subtitle: Text(
                        '${hospitalData['city']} - ${hospitalData['district']}',
                      ),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: ScheduleService.getCurrentHospitalDoctors(
                            hospitalDoc.id,
                          ),
                          builder: (context, shiftSnapshot) {
                            if (!shiftSnapshot.hasData ||
                                shiftSnapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Şu anda nöbetçi doktor yok'),
                              );
                            }

                            return Column(
                              children: shiftSnapshot.data!.docs.map((
                                shiftDoc,
                              ) {
                                final shiftData =
                                    shiftDoc.data() as Map<String, dynamic>;
                                final shiftTypes =
                                    ScheduleService.getShiftTypes();
                                final shiftInfo = shiftTypes.firstWhere(
                                  (type) =>
                                      type['id'] == shiftData['shiftType'],
                                  orElse: () => shiftTypes.first,
                                );

                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(shiftInfo['color']),
                                    child: const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(shiftData['doctorName']),
                                  subtitle: Text(shiftInfo['name']),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _editShift(String shiftId, Map<String, dynamic> data) async {
    // Basit düzenleme için not güncellemesi
    final notesController = TextEditingController(text: data['notes'] ?? '');

    // Context'i await'tan önce sakla
    final dialogContext = context;

    final result = await showDialog<String>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text('${data['doctorName']} Nöbet Notları'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Nöbet Notları',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('doctor_shifts')
            .doc(shiftId)
            .update({
              'notes': result,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          // Context'i await'tan sonra kullan
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Nöbet notları güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // Context'i await'tan sonra kullan
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('❌ Güncelleme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
