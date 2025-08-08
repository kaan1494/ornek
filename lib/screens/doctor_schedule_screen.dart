import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/schedule_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _hospitals = [];

  String? _selectedDoctorId;
  String? _selectedHospitalId;
  String? _selectedShiftType;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Doktorları yükle
      final doctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .get();

      // Hastaneleri yükle
      final hospitalsQuery = await _firestore
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _doctors = doctorsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': '${data['firstName']} ${data['lastName']}',
            'email': data['email'],
            'specialization': data['specialization'] ?? 'Genel Pratisyen',
          };
        }).toList();

        _hospitals = hospitalsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'city': data['city'],
            'district': data['district'],
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Doktor Nöbet Planlaması'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mevcut Nöbetler Kartı
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.green.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mevcut Aktif Nöbetler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActiveShiftsList(),
                  ],
                ),
              ),
            ),

            // Yeni Nöbet Ekleme Kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Yeni Nöbet Planla',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildNewShiftForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShiftsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: ScheduleService.getActiveShifts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Henüz planlanmış nöbet yok\nAşağıdaki formdan yeni nöbet ekleyebilirsiniz',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Client-side filtering for active shifts
        final allDocs = snapshot.data!.docs;
        final activeDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'active';
        }).toList();

        if (activeDocs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Henüz planlanmış nöbet yok\nAşağıdaki formdan yeni nöbet ekleyebilirsiniz',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.3, // Ekranın %30'u max
            minHeight: 60, // En az 60 pixel
          ),
          child: ListView.builder(
            shrinkWrap: true, // İçeriğe göre boyutlan
            physics: const BouncingScrollPhysics(),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              final doc = activeDocs[index];
              final shiftData = doc.data() as Map<String, dynamic>;

              final startDate = (shiftData['startDate'] as Timestamp).toDate();
              final endDate = (shiftData['endDate'] as Timestamp).toDate();
              final shiftTypes = ScheduleService.getShiftTypes();
              final shiftType = shiftTypes.firstWhere(
                (type) => type['id'] == shiftData['shiftType'],
                orElse: () => shiftTypes.first,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Color(shiftType['color']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(shiftType['color']).withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(shiftType['color']),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    shiftData['doctorName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(shiftData['hospitalName']),
                      Text(
                        '${shiftType['name']} - ${_formatDate(startDate)} / ${_formatDate(endDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNewShiftForm() {
    return Column(
      children: [
        // Doktor Seçimi
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Doktor Seçin',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
          ),
          value: _selectedDoctorId,
          items: _doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(doctor['name'], overflow: TextOverflow.ellipsis),
                  Text(
                    doctor['specialization'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDoctorId = value);
          },
        ),
        const SizedBox(height: 16),

        // Hastane Seçimi
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Hastane Seçin',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_hospital),
          ),
          value: _selectedHospitalId,
          items: _hospitals.map((hospital) {
            return DropdownMenuItem<String>(
              value: hospital['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hospital['name'], overflow: TextOverflow.ellipsis),
                  Text(
                    '${hospital['district']}, ${hospital['city']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedHospitalId = value);
          },
        ),
        const SizedBox(height: 16),

        // Nöbet Türü Seçimi
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Nöbet Türü',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.access_time),
          ),
          value: _selectedShiftType,
          items: ScheduleService.getShiftTypes().map((shiftType) {
            return DropdownMenuItem<String>(
              value: shiftType['id'],
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(shiftType['color']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shiftType['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${shiftType['startTime']} - ${shiftType['endTime']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedShiftType = value);
          },
        ),
        const SizedBox(height: 16),

        // Tarih Seçimi
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç Tarihi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedStartDate != null
                        ? _formatDate(_selectedStartDate!)
                        : 'Tarih seçin',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bitiş Tarihi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedEndDate != null
                        ? _formatDate(_selectedEndDate!)
                        : 'Tarih seçin',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Notlar
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notlar (Opsiyonel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),

        // Nöbet Oluştur Butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createShift,
            icon: const Icon(Icons.add),
            label: const Text(
              'Nöbet Oluştur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedStartDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedEndDate = date);
    }
  }

  Future<void> _createShift() async {
    if (_selectedDoctorId == null ||
        _selectedHospitalId == null ||
        _selectedShiftType == null ||
        _selectedStartDate == null ||
        _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doctor = _doctors.firstWhere((d) => d['id'] == _selectedDoctorId);
    final hospital = _hospitals.firstWhere(
      (h) => h['id'] == _selectedHospitalId,
    );

    final shiftId = await ScheduleService.createDoctorShift(
      doctorId: _selectedDoctorId!,
      doctorName: doctor['name'],
      hospitalId: _selectedHospitalId!,
      hospitalName: hospital['name'],
      startDate: _selectedStartDate!,
      endDate: _selectedEndDate!,
      shiftType: _selectedShiftType!,
      notes: _notesController.text,
    );

    if (shiftId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nöbet başarıyla oluşturuldu'),
          backgroundColor: Colors.green,
        ),
      );

      // Form'u temizle
      setState(() {
        _selectedDoctorId = null;
        _selectedHospitalId = null;
        _selectedShiftType = null;
        _selectedStartDate = null;
        _selectedEndDate = null;
        _notesController.clear();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nöbet oluşturma hatası'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
