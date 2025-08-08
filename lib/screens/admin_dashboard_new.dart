import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/hospital_service.dart';
import 'admin_schedule_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            Container(
              color: Colors.green.shade50,
              child: const TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
                  Tab(icon: Icon(Icons.medical_services), text: 'Doktorlar'),
                  Tab(icon: Icon(Icons.local_hospital), text: 'Hastaneler'),
                  Tab(icon: Icon(Icons.assignment), text: 'Triyaj Başvuruları'),
                  Tab(icon: Icon(Icons.schedule), text: 'Nöbet Programı'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUsersTab(),
                  _buildDoctorsTab(),
                  _buildHospitalsTab(),
                  _buildTriageApplicationsTab(),
                  _buildScheduleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Henüz kullanıcı bulunmuyor'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final userData = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(userData['role']),
                  child: Icon(
                    _getRoleIcon(userData['role']),
                    color: Colors.white,
                  ),
                ),
                title: Text('${userData['firstName']} ${userData['lastName']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${userData['email']}'),
                    Text('TC: ${userData['tcNo']}'),
                    Text('Rol: ${_getRoleDisplayName(userData['role'])}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    _changeUserRole(doc.id, value, userData);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'patient',
                      child: Text('Hasta Yap'),
                    ),
                    const PopupMenuItem(
                      value: 'doctor',
                      child: Text('Doktor Yap'),
                    ),
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Admin Yap'),
                    ),
                    const PopupMenuItem(
                      value: 'proAdmin',
                      child: Text('Pro Admin Yap'),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text('Henüz doktor bulunmuyor'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addSampleDoctor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Örnek Doktor Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Doktorlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSampleDoctor,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Doktor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final userData = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Dr. ${userData['firstName']} ${userData['lastName']}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${userData['email']}'),
                          Text(
                            'Uzmanlık: ${userData['specialization'] ?? 'Belirtilmemiş'}',
                          ),
                          Text(
                            'Durum: ${_getDoctorStatus(userData['status'])}',
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: userData['isActive'] ?? true,
                        onChanged: (bool value) {
                          _toggleDoctorStatus(doc.id, value);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHospitalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('hospitals').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_hospital, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz hastane bulunmuyor'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addSampleHospitals(),
                  icon: const Icon(Icons.add),
                  label: const Text('Örnek Hastaneler Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hastaneler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addNewHospital,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Hastane'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final hospitalData = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: hospitalData['isActive']
                            ? Colors.green
                            : Colors.red,
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(hospitalData['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hospitalData['district']}, ${hospitalData['city']}',
                          ),
                          Text(
                            'Tel: ${hospitalData['phone'] ?? 'Belirtilmemiş'}',
                          ),
                          if (hospitalData['emergencyCapacity'] != null)
                            Text(
                              'Kapasite: ${hospitalData['currentPatients'] ?? 0}/${hospitalData['emergencyCapacity']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: hospitalData['isActive'] ?? true,
                            onChanged: (bool value) {
                              _toggleHospitalStatus(doc.id, value);
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              if (value == 'edit') {
                                _editHospital(doc.id, hospitalData);
                              } else if (value == 'delete') {
                                _deleteHospital(doc.id, hospitalData['name']);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Düzenle'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Sil'),
                              ),
                            ],
                            child: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTriageApplicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('triage_applications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz triyaj başvurusu bulunmuyor'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final applicationData = doc.data() as Map<String, dynamic>;

            Color priorityColor;
            IconData priorityIcon;

            switch (applicationData['triageResult']) {
              case 'RED':
                priorityColor = Colors.red;
                priorityIcon = Icons.emergency;
                break;
              case 'YELLOW':
                priorityColor = Colors.orange;
                priorityIcon = Icons.warning;
                break;
              case 'GREEN':
                priorityColor = Colors.green;
                priorityIcon = Icons.check_circle;
                break;
              default:
                priorityColor = Colors.grey;
                priorityIcon = Icons.help;
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: priorityColor,
                  child: Icon(priorityIcon, color: Colors.white),
                ),
                title: Text(
                  applicationData['hospitalName'] ?? 'Bilinmeyen Hastane',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puan: ${applicationData['totalScore']}'),
                    Text(
                      'Durum: ${_getTriageResultText(applicationData['triageResult'])}',
                    ),
                    if (applicationData['timestamp'] != null)
                      Text(
                        'Tarih: ${_formatTimestamp(applicationData['timestamp'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showTriageDetails(applicationData),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'assign_doctor') {
                          _assignDoctor(doc.id);
                        } else if (value == 'complete') {
                          _completeApplication(doc.id);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'assign_doctor',
                          child: Text('Doktor Ata'),
                        ),
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Tamamla'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getTriageResultText(String? result) {
    switch (result) {
      case 'RED':
        return 'Acil - Kırmızı';
      case 'YELLOW':
        return 'Orta Risk - Sarı';
      case 'GREEN':
        return 'Düşük Risk - Yeşil';
      default:
        return 'Bilinmiyor';
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTriageDetails(Map<String, dynamic> applicationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Triyaj Detayları'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hastane: ${applicationData['hospitalName']}'),
                Text('Toplam Puan: ${applicationData['totalScore']}'),
                Text(
                  'Sonuç: ${_getTriageResultText(applicationData['triageResult'])}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verilen Cevaplar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (applicationData['answers'] != null)
                  ...List.generate(applicationData['answers'].length, (index) {
                    final answer = applicationData['answers'][index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              answer['question'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              answer['answer'] ? 'EVET' : 'HAYIR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: answer['answer']
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                          Text(
                            '${answer['score']}p',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _assignDoctor(String applicationId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doktor atama özelliği yakında eklenecek'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeApplication(String applicationId) async {
    try {
      await _firestore
          .collection('triage_applications')
          .doc(applicationId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          const SnackBar(
            content: Text('Başvuru tamamlandı olarak işaretlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildScheduleTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Nöbet Yönetimi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Doktor nöbet atama ve yönetimi için\ngelişmiş arayüzü kullanın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScheduleManagement(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Nöbet Yönetimine Git'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/doctor-schedule'),
                icon: const Icon(Icons.schedule),
                label: const Text('Hızlı Nöbet Planla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'patient':
        return Colors.red;
      case 'doctor':
        return Colors.blue;
      case 'admin':
        return Colors.green;
      case 'proAdmin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'patient':
        return Icons.person;
      case 'doctor':
        return Icons.medical_services;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'proAdmin':
        return Icons.supervisor_account;
      default:
        return Icons.help;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'patient':
        return 'Hasta';
      case 'doctor':
        return 'Doktor';
      case 'admin':
        return 'Admin';
      case 'proAdmin':
        return 'Pro Admin';
      default:
        return 'Bilinmiyor';
    }
  }

  String _getDoctorStatus(String? status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı';
      case 'pending':
        return 'Beklemede';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Belirtilmemiş';
    }
  }

  Future<void> _changeUserRole(
    String userId,
    String newRole,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text(
              '${userData['firstName']} ${userData['lastName']} kullanıcısının rolü ${_getRoleDisplayName(newRole)} olarak değiştirildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Rol değiştirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDoctorStatus(String doctorId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Doktor aktifleştirildi'
                  : 'Doktor devre dışı bırakıldı',
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Durum değiştirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewHospital() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emergencyCapacityController = TextEditingController();
    final currentPatientsController = TextEditingController(text: '0');

    String selectedCity = 'İstanbul';
    String selectedDistrict = 'Kadıköy';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Hastane Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hastane Adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'İl',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCity,
                            items:
                                [
                                  'İstanbul',
                                  'Ankara',
                                  'İzmir',
                                  'Bursa',
                                  'Antalya',
                                ].map((String city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCity = newValue!;
                                // İl değişince uygun ilçeyi seç
                                switch (selectedCity) {
                                  case 'İstanbul':
                                    selectedDistrict = 'Kadıköy';
                                    break;
                                  case 'Ankara':
                                    selectedDistrict = 'Çankaya';
                                    break;
                                  case 'İzmir':
                                    selectedDistrict = 'Konak';
                                    break;
                                  case 'Bursa':
                                    selectedDistrict = 'Nilüfer';
                                    break;
                                  case 'Antalya':
                                    selectedDistrict = 'Muratpaşa';
                                    break;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'İlçe',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedDistrict,
                            items: _getDistrictsForCity(selectedCity).map((
                              String district,
                            ) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedDistrict = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emergencyCapacityController,
                            decoration: const InputDecoration(
                              labelText: 'Acil Kapasite',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: currentPatientsController,
                            decoration: const InputDecoration(
                              labelText: 'Mevcut Hasta',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        addressController.text.isEmpty ||
                        phoneController.text.isEmpty ||
                        emergencyCapacityController.text.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen tüm alanları doldurun'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    // Context'i await'tan önce sakla
                    final navigator = Navigator.of(context);
                    if (context.mounted) {
                      navigator.pop();
                    }

                    await _createNewHospital({
                      'name': nameController.text,
                      'city': selectedCity,
                      'district': selectedDistrict,
                      'address': addressController.text,
                      'phone': phoneController.text,
                      'emergencyCapacity':
                          int.tryParse(emergencyCapacityController.text) ?? 0,
                      'currentPatients':
                          int.tryParse(currentPatientsController.text) ?? 0,
                      'isActive': true,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewHospital(Map<String, dynamic> hospitalData) async {
    try {
      final hospitalId = await HospitalService.addHospital(hospitalData);
      if (hospitalId != null && mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          const SnackBar(
            content: Text('Yeni hastane başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Hastane ekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSampleHospitals() async {
    try {
      await HospitalService.initializeHospitals();
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          const SnackBar(
            content: Text('Örnek hastaneler başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Hastane ekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleHospitalStatus(String hospitalId, bool isActive) async {
    try {
      await HospitalService.updateHospitalStatus(hospitalId, isActive);
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Hastane aktifleştirildi'
                  : 'Hastane devre dışı bırakıldı',
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Durum değiştirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editHospital(String hospitalId, Map<String, dynamic> hospitalData) {
    final nameController = TextEditingController(text: hospitalData['name']);
    final addressController = TextEditingController(
      text: hospitalData['address'],
    );
    final phoneController = TextEditingController(text: hospitalData['phone']);
    final emergencyCapacityController = TextEditingController(
      text: hospitalData['emergencyCapacity']?.toString() ?? '',
    );
    final currentPatientsController = TextEditingController(
      text: hospitalData['currentPatients']?.toString() ?? '',
    );

    String selectedCity = hospitalData['city'] ?? 'İstanbul';
    String selectedDistrict = hospitalData['district'] ?? 'Kadıköy';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Hastane Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hastane Adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'İl',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedCity,
                            items:
                                [
                                  'İstanbul',
                                  'Ankara',
                                  'İzmir',
                                  'Bursa',
                                  'Antalya',
                                ].map((String city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCity = newValue!;
                                // İl değişince uygun ilçeyi seç
                                switch (selectedCity) {
                                  case 'İstanbul':
                                    selectedDistrict = 'Kadıköy';
                                    break;
                                  case 'Ankara':
                                    selectedDistrict = 'Çankaya';
                                    break;
                                  case 'İzmir':
                                    selectedDistrict = 'Konak';
                                    break;
                                  case 'Bursa':
                                    selectedDistrict = 'Nilüfer';
                                    break;
                                  case 'Antalya':
                                    selectedDistrict = 'Muratpaşa';
                                    break;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'İlçe',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedDistrict,
                            items: _getDistrictsForCity(selectedCity).map((
                              String district,
                            ) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedDistrict = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emergencyCapacityController,
                            decoration: const InputDecoration(
                              labelText: 'Acil Kapasite',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: currentPatientsController,
                            decoration: const InputDecoration(
                              labelText: 'Mevcut Hasta',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Context'i await'tan önce sakla
                    final navigator = Navigator.of(context);
                    if (context.mounted) {
                      navigator.pop();
                    }

                    await _updateHospital(hospitalId, {
                      'name': nameController.text,
                      'city': selectedCity,
                      'district': selectedDistrict,
                      'address': addressController.text,
                      'phone': phoneController.text,
                      'emergencyCapacity':
                          int.tryParse(emergencyCapacityController.text) ?? 0,
                      'currentPatients':
                          int.tryParse(currentPatientsController.text) ?? 0,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _getDistrictsForCity(String city) {
    switch (city) {
      case 'İstanbul':
        return ['Kadıköy', 'Üsküdar', 'Beşiktaş', 'Şişli', 'Fatih', 'Beyoğlu'];
      case 'Ankara':
        return ['Çankaya', 'Keçiören', 'Yenimahalle', 'Mamak', 'Sincan'];
      case 'İzmir':
        return ['Konak', 'Bornova', 'Karşıyaka', 'Buca', 'Bayraklı'];
      case 'Bursa':
        return ['Nilüfer', 'Osmangazi', 'Yıldırım', 'Mudanya'];
      case 'Antalya':
        return ['Muratpaşa', 'Kepez', 'Konyaaltı', 'Aksu'];
      default:
        return [];
    }
  }

  Future<void> _updateHospital(
    String hospitalId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('hospitals').doc(hospitalId).update(updates);
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          const SnackBar(
            content: Text('Hastane başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteHospital(String hospitalId, String hospitalName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hastane Sil'),
          content: Text(
            '$hospitalName hastanesini silmek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Context'i await'tan önce sakla
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (context.mounted) {
                  navigator.pop();
                }

                try {
                  await _firestore
                      .collection('hospitals')
                      .doc(hospitalId)
                      .delete();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Hastane başarıyla silindi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Silme hatası: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSampleDoctor() async {
    try {
      final sampleDoctors = [
        {
          'firstName': 'Ahmet',
          'lastName': 'Yılmaz',
          'email': 'ahmet.yilmaz@hastane.com',
          'tcNo': '12345678901',
          'phone': '05551234567',
          'role': 'doctor',
          'specialization': 'Acil Tıp',
          'isActive': true,
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'firstName': 'Fatma',
          'lastName': 'Demir',
          'email': 'fatma.demir@hastane.com',
          'tcNo': '12345678902',
          'phone': '05551234568',
          'role': 'doctor',
          'specialization': 'Dahiliye',
          'isActive': true,
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'firstName': 'Mehmet',
          'lastName': 'Kaya',
          'email': 'mehmet.kaya@hastane.com',
          'tcNo': '12345678903',
          'phone': '05551234569',
          'role': 'doctor',
          'specialization': 'Kardiyoloji',
          'isActive': true,
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final doctor in sampleDoctors) {
        await _firestore.collection('users').add(doctor);
      }

      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          const SnackBar(
            content: Text('Örnek doktorlar başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = ScaffoldMessenger.of(context);
        messengerContext.showSnackBar(
          SnackBar(
            content: Text('Doktor ekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
