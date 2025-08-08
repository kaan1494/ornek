import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/schedule_service.dart';

class DoctorAssignmentDialog extends StatefulWidget {
  final String? hospitalId;
  final String? hospitalName;

  const DoctorAssignmentDialog({super.key, this.hospitalId, this.hospitalName});

  @override
  State<DoctorAssignmentDialog> createState() => _DoctorAssignmentDialogState();
}

class _DoctorAssignmentDialogState extends State<DoctorAssignmentDialog> {
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  String _selectedShiftType = 'morning';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 8));
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.hospitalId != null) {
      _selectedHospitalId = widget.hospitalId;
      _selectedHospitalName = widget.hospitalName;
    }
    _updateEndDate();
  }

  void _updateEndDate() {
    switch (_selectedShiftType) {
      case 'morning':
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          8,
          0,
        );
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          16,
          0,
        );
        break;
      case 'evening':
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          16,
          0,
        );
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day + 1,
          0,
          0,
        );
        break;
      case 'night':
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          0,
          0,
        );
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          8,
          0,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  const Icon(Icons.assignment_ind, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Doktor Nöbet Ataması',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Doktor Seçimi
              _buildSectionTitle('👨‍⚕️ Doktor Seçimi'),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'doctor')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              'Doktor yükleme hatası: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(height: 8),
                            Text(
                              'Henüz aktif doktor bulunamadı',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedDoctorId,
                    decoration: const InputDecoration(
                      labelText: 'Doktor Seçin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dr. ${data['firstName']} ${data['lastName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data['specialization'] != null)
                              Text(
                                data['specialization'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final selectedDoc = snapshot.data!.docs.firstWhere(
                        (doc) => doc.id == value,
                      );
                      final data = selectedDoc.data() as Map<String, dynamic>;

                      setState(() {
                        _selectedDoctorId = value;
                        _selectedDoctorName =
                            'Dr. ${data['firstName']} ${data['lastName']}';
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Hastane Seçimi (eğer önceden seçilmediyse)
              if (widget.hospitalId == null) ...[
                _buildSectionTitle('🏥 Hastane Seçimi'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hospitals')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(height: 8),
                              Text(
                                'Hastane yükleme hatası: ${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(height: 8),
                              Text(
                                'Henüz aktif hastane bulunamadı',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/admin-new');
                                },
                                child: Text('Hastane Ekle'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedHospitalId,
                      decoration: const InputDecoration(
                        labelText: 'Hastane Seçin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                      items: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${data['city']} - ${data['district']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedDoc = snapshot.data!.docs.firstWhere(
                          (doc) => doc.id == value,
                        );
                        final data = selectedDoc.data() as Map<String, dynamic>;

                        setState(() {
                          _selectedHospitalId = value;
                          _selectedHospitalName = data['name'];
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Nöbet Türü Seçimi
              _buildSectionTitle('⏰ Nöbet Türü'),
              _buildShiftTypeSelector(),
              const SizedBox(height: 16),

              // Tarih Seçimi
              _buildSectionTitle('📅 Tarih ve Saat'),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Başlangıç'),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_startDate.hour}:${_startDate.minute.toString().padLeft(2, '0')}',
                      ),
                      leading: const Icon(Icons.schedule),
                      onTap: () => _selectDateTime(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Bitiş'),
                      subtitle: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year} ${_endDate.hour}:${_endDate.minute.toString().padLeft(2, '0')}',
                      ),
                      leading: const Icon(Icons.schedule_outlined),
                      onTap: () => _selectDateTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notlar
              _buildSectionTitle('📝 Notlar (İsteğe Bağlı)'),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Özel notlar ekleyebilirsiniz...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _assignDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Nöbete Ata',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildShiftTypeSelector() {
    final shiftTypes = ScheduleService.getShiftTypes();

    return Column(
      children: shiftTypes.map((type) {
        return RadioListTile<String>(
          value: type['id'],
          groupValue: _selectedShiftType,
          onChanged: (value) {
            setState(() {
              _selectedShiftType = value!;
              _updateEndDate();
            });
          },
          title: Text(type['name']),
          subtitle: Text('${type['startTime']} - ${type['endTime']}'),
          activeColor: Color(type['color']),
        );
      }).toList(),
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      );

      if (time != null && mounted) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (isStart) {
            _startDate = newDateTime;
            _updateEndDate();
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _assignDoctor() async {
    if (_selectedDoctorId == null || _selectedHospitalId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen doktor ve hastane seçin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final shiftId = await ScheduleService.createDoctorShift(
      doctorId: _selectedDoctorId!,
      doctorName: _selectedDoctorName!,
      hospitalId: _selectedHospitalId!,
      hospitalName: _selectedHospitalName!,
      startDate: _startDate,
      endDate: _endDate,
      shiftType: _selectedShiftType,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shiftId != null
                ? '✅ Doktor başarıyla nöbete atandı'
                : '❌ Nöbet atama başarısız',
          ),
          backgroundColor: shiftId != null ? Colors.green : Colors.red,
        ),
      );

      if (shiftId != null) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
