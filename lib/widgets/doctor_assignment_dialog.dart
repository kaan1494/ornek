import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/schedule_service.dart';
import '../services/hospital_service.dart';

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
  String _selectedShiftType = 'daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 8));
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _hospitalSearchController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _allStaticHospitals = [];
  List<Map<String, dynamic>> _filteredHospitals = [];

  @override
  void initState() {
    super.initState();
    if (widget.hospitalId != null) {
      _selectedHospitalId = widget.hospitalId;
      _selectedHospitalName = widget.hospitalName;
    }
    _loadAllStaticHospitals();
    _updateEndDate();
  }

  // Tüm statik hastaneleri yükle
  Future<void> _loadAllStaticHospitals() async {
    final List<Map<String, dynamic>> allHospitals = [];
    
    // HospitalService'den tüm il ve ilçeler için hastaneleri al
    final provinces = HospitalService.getProvinces();
    final districts = HospitalService.getDistricts();
    
    for (String province in provinces) {
      final provinceDistricts = districts[province] ?? ['Merkez'];
      for (String district in provinceDistricts) {
        final hospitalsForLocation = HospitalService.getHospitalsByLocation(
          province,
          district,
        );
        
        // Her hastaneye benzersiz ID ekle
        for (var hospital in hospitalsForLocation) {
          hospital['searchText'] = '${hospital['name']} ${hospital['province']} ${hospital['district']}'.toLowerCase();
          allHospitals.add(hospital);
        }
      }
    }
    
    setState(() {
      _allStaticHospitals = allHospitals;
      _filteredHospitals = allHospitals;
    });
    
    if (kDebugMode) {
      debugPrint('🏥 Toplam ${allHospitals.length} statik hastane yüklendi');
    }
  }

  // Hastane arama/filtreleme
  void _filterHospitals(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHospitals = _allStaticHospitals;
      } else {
        _filteredHospitals = _allStaticHospitals.where((hospital) {
          return hospital['searchText'].contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _updateEndDate() {
    switch (_selectedShiftType) {
      case 'daily':
        // 24 saatlik nöbet: 08:00 - 08:00 (ertesi gün)
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
          _startDate.day + 1,
          8,
          0,
        );
        break;
      case 'half_day':
        // 12 saatlik gündüz nöbet: 08:00 - 20:00
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
          20,
          0,
        );
        break;
      case 'night':
        // 12 saatlik gece nöbet: 20:00 - 08:00 (ertesi gün)
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          20,
          0,
        );
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day + 1,
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Dr. ${data['firstName']} ${data['lastName']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (data['specialization'] != null)
                                Text(
                                  data['specialization'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
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
                
                // Hastane arama kutusu
                TextField(
                  controller: _hospitalSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Hastane Ara',
                    hintText: 'Hastane adı, il veya ilçe yazın...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _filterHospitals,
                ),
                const SizedBox(height: 12),
                
                // Hastane seçimi dropdown'u
                if (_allStaticHospitals.isNotEmpty)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: DropdownButtonFormField<String>(
                      value: _selectedHospitalId,
                      decoration: const InputDecoration(
                        labelText: 'Hastane Seçin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_hospital),
                        helperText: 'Doktor atanacak hastaneyi seçin',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 300,
                      items: _filteredHospitals.map<DropdownMenuItem<String>>((hospital) {
                        return DropdownMenuItem<String>(
                          value: hospital['id'],
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hospital['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${hospital['province']} - ${hospital['district']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      Icon(
                                        hospital['type'] == 'Özel' 
                                          ? Icons.business 
                                          : Icons.account_balance,
                                        size: 12,
                                        color: hospital['type'] == 'Özel' 
                                          ? Colors.blue.shade600 
                                          : Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${hospital['type']} Hastane',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: hospital['type'] == 'Özel' 
                                              ? Colors.blue.shade600 
                                              : Colors.green.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Bekleme: ${hospital['waitingTime'] ?? 30} dk',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedHospital = _filteredHospitals.firstWhere(
                          (hospital) => hospital['id'] == value,
                        );

                        setState(() {
                          _selectedHospitalId = value;
                          _selectedHospitalName = selectedHospital['name'];
                          // Arama kutusunu temizle
                          _hospitalSearchController.clear();
                          _filteredHospitals = _allStaticHospitals;
                        });

                        if (kDebugMode) {
                          debugPrint('🏥 Seçilen hastane: ${selectedHospital['name']} (${selectedHospital['province']}/${selectedHospital['district']})');
                        }
                      },
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Hastaneler yükleniyor...'),
                        ],
                      ),
                    ),
                  ),
                
                // Seçilen hastane bilgisi
                if (_selectedHospitalName != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seçilen Hastane:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _selectedHospitalName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedHospitalId = null;
                                _selectedHospitalName = null;
                                _hospitalSearchController.clear();
                                _filteredHospitals = _allStaticHospitals;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Hastane sayısı bilgisi
                if (_allStaticHospitals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Toplam ${_allStaticHospitals.length} hastane - Filtrelenen: ${_filteredHospitals.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
              ],

              // Nöbet Türü Seçimi
              _buildSectionTitle('⏰ Nöbet Türü'),
              _buildShiftTypeSelector(),
              const SizedBox(height: 16),

              // Tarih Seçimi
              _buildSectionTitle('📅 Tarih ve Saat'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateTime(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 16, color: Colors.green.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Başlangıç',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateTime(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule_outlined, size: 16, color: Colors.red.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bitiş',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
        return Card(
          elevation: _selectedShiftType == type['id'] ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            value: type['id'],
            groupValue: _selectedShiftType,
            onChanged: (value) {
              setState(() {
                _selectedShiftType = value!;
                _updateEndDate();
              });
            },
            title: Text(
              type['name'],
              style: TextStyle(
                fontWeight: _selectedShiftType == type['id'] 
                  ? FontWeight.bold 
                  : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type['startTime']} - ${type['endTime']}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (type['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      type['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (type['duration'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(type['color']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${type['duration']} saat nöbet',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(type['color']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeColor: Color(type['color']),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
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
                ? '✅ Dr. $_selectedDoctorName $_selectedHospitalName hastanesine nöbete atandı!\n📋 Nöbet ID: $shiftId'
                : '❌ Nöbet atama başarısız - Lütfen tekrar deneyin',
          ),
          backgroundColor: shiftId != null ? Colors.green : Colors.red,
          duration: Duration(seconds: shiftId != null ? 4 : 3),
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
    _hospitalSearchController.dispose();
    super.dispose();
  }
}
