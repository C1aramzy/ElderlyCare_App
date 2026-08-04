import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddMedicationPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? medication;

  const AddMedicationPage({
    super.key,
    required this.userId,
    this.medication,
  });

  bool get isEditMode => medication != null;

  @override
  State<AddMedicationPage> createState() =>
      _AddMedicationPageState();
}

class _AddMedicationPageState
    extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController medicineNameController =
      TextEditingController();

  final TextEditingController dosageController =
      TextEditingController();

  final TextEditingController instructionsController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  final TextEditingController lowStockController =
      TextEditingController(text: '5');

  final String addMedicationUrl =
      'http://elderlym.atspace.cc/Medication/add_medication.php';

  final String updateMedicationUrl =
      'http://elderlym.atspace.cc/Medication/update_medication.php';

  XFile? selectedImage;

  DateTime startDate = DateTime.now();
  DateTime? endDate;

  List<TimeOfDay> reminderTimes = [
    const TimeOfDay(hour: 8, minute: 0),
  ];

  String repeatType = 'daily';

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Set<String> selectedDays = {};

  bool isSaving = false;

  bool get isEditMode => widget.medication != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      _fillExistingMedication();
    }
  }

  void _fillExistingMedication() {
    final medication = widget.medication!;

    medicineNameController.text =
        medication['medicine_name']?.toString() ?? '';
    dosageController.text =
        medication['dosage']?.toString() ?? '';
    instructionsController.text =
        medication['instructions']?.toString() ?? '';
    quantityController.text =
        medication['remaining_quantity']?.toString() ?? '';
    lowStockController.text =
        medication['low_stock_threshold']?.toString() ?? '5';

    final parsedStartDate = DateTime.tryParse(
      medication['start_date']?.toString() ?? '',
    );

    if (parsedStartDate != null) {
      startDate = parsedStartDate;
    }

    final endDateText =
        medication['end_date']?.toString() ?? '';

    if (endDateText.isNotEmpty) {
      endDate = DateTime.tryParse(endDateText);
    }

    final schedules = medication['schedules'];

    if (schedules is List && schedules.isNotEmpty) {
      final loadedTimes = <TimeOfDay>[];

      for (final schedule in schedules) {
        if (schedule is! Map<String, dynamic>) continue;

        final timeText =
            schedule['reminder_time']?.toString() ?? '';

        final parts = timeText.split(':');

        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);

          if (hour != null && minute != null) {
            loadedTimes.add(
              TimeOfDay(hour: hour, minute: minute),
            );
          }
        }
      }

      if (loadedTimes.isNotEmpty) {
        reminderTimes = loadedTimes;
      }

      final firstSchedule = schedules.first;

      if (firstSchedule is Map<String, dynamic>) {
        repeatType =
            firstSchedule['repeat_type']?.toString() ?? 'daily';

        final repeatDaysText =
            firstSchedule['repeat_days']?.toString() ?? '';

        if (repeatDaysText.isNotEmpty) {
          selectedDays.addAll(
            repeatDaysText
                .split(',')
                .map((day) => day.trim())
                .where((day) => day.isNotEmpty),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    medicineNameController.dispose();
    dosageController.dispose();
    instructionsController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    super.dispose();
  }

  String formatDateForServer(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String formatTimeForServer(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String getTimeLabel(TimeOfDay time) {
    if (time.hour < 12) {
      return 'Morning';
    }

    if (time.hour < 17) {
      return 'Afternoon';
    }

    if (time.hour < 21) {
      return 'Evening';
    }

    return 'Night';
  }

  Future<void> showImageOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  selectImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  selectImage(ImageSource.gallery);
                },
              ),
              if (selectedImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    setState(() {
                      selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> selectImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        selectedImage = image;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select image: $e'),
        ),
      );
    }
  }

  Future<void> addReminderTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 20,
        minute: 0,
      ),
    );

    if (selectedTime == null) {
      return;
    }

    final duplicateExists = reminderTimes.any(
      (time) =>
          time.hour == selectedTime.hour &&
          time.minute == selectedTime.minute,
    );

    if (duplicateExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This reminder time has already been added.',
          ),
        ),
      );

      return;
    }

    setState(() {
      reminderTimes.add(selectedTime);

      reminderTimes.sort(
        (first, second) {
          final firstMinutes =
              first.hour * 60 + first.minute;

          final secondMinutes =
              second.hour * 60 + second.minute;

          return firstMinutes.compareTo(secondMinutes);
        },
      );
    });
  }

  Future<void> editReminderTime(int index) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: reminderTimes[index],
    );

    if (selectedTime == null) {
      return;
    }

    final duplicateExists = reminderTimes.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.hour == selectedTime.hour &&
          entry.value.minute == selectedTime.minute,
    );

    if (duplicateExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This reminder time has already been added.',
          ),
        ),
      );

      return;
    }

    setState(() {
      reminderTimes[index] = selectedTime;

      reminderTimes.sort(
        (first, second) {
          final firstMinutes =
              first.hour * 60 + first.minute;

          final secondMinutes =
              second.hour * 60 + second.minute;

          return firstMinutes.compareTo(secondMinutes);
        },
      );
    });
  }

  Future<void> selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      startDate = selectedDate;

      if (endDate != null &&
          endDate!.isBefore(startDate)) {
        endDate = null;
      }
    });
  }

  Future<void> selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      endDate = selectedDate;
    });
  }

  Future<void> saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one reminder time.',
          ),
        ),
      );

      return;
    }

    if (repeatType == 'selected_days' &&
        selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one repeat day.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          isEditMode
              ? updateMedicationUrl
              : addMedicationUrl,
        ),
      );

      final schedules = reminderTimes.map((time) {
        return {
          'reminder_time': formatTimeForServer(time),
          'time_label': getTimeLabel(time),
          'repeat_type': repeatType,
          'repeat_days':
              repeatType == 'selected_days'
                  ? weekDays
                      .where(selectedDays.contains)
                      .join(',')
                  : '',
          'early_window_minutes': 30,
          'late_window_minutes': 60,
        };
      }).toList();

      request.fields.addAll({
        if (isEditMode)
          'medication_id':
              widget.medication!['medication_id'].toString(),
        'elderly_user_id': widget.userId.toString(),
        'medicine_name':
            medicineNameController.text.trim(),
        'dosage': dosageController.text.trim(),
        'instructions':
            instructionsController.text.trim(),
        'start_date':
            formatDateForServer(startDate),
        'end_date': endDate == null
            ? ''
            : formatDateForServer(endDate!),
        'remaining_quantity':
            quantityController.text.trim(),
        'low_stock_threshold':
            lowStockController.text.trim(),
        'schedules': jsonEncode(schedules),
      });

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'medicine_image',
            selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      final dynamic decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded['message'] ??
                  (isEditMode
                      ? 'Medication updated successfully.'
                      : 'Medication added successfully.'),
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        final message =
            decoded is Map<String, dynamic>
                ? decoded['message']?.toString()
                : null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ??
                  (isEditMode
                      ? 'Unable to update medication.'
                      : 'Unable to add medication.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Error updating medication: $e'
                : 'Error adding medication: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: showImageOptions,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(10),
                              color: Colors.black.withValues(
                                alpha: 0.55,
                              ),
                              child: const Text(
                                'Tap to change photo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 52,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add Medicine Photo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Take a photo or choose from gallery',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            sectionTitle('Medicine Details'),

            TextFormField(
              controller: medicineNameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: fieldDecoration(
                label: 'Medicine Name',
                icon: Icons.medication,
                hint: 'Example: Amlodipine',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter the medicine name.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: dosageController,
              decoration: fieldDecoration(
                label: 'Dosage',
                icon: Icons.local_pharmacy,
                hint: 'Example: 1 tablet',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter the dosage.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: instructionsController,
              maxLines: 3,
              decoration: fieldDecoration(
                label: 'Instructions',
                icon: Icons.notes,
                hint: 'Example: Take after breakfast',
              ),
            ),

            sectionTitle('Reminder Times'),

            ...reminderTimes.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final time = entry.value;

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading:
                        const Icon(Icons.access_time),
                    title: Text(
                      time.format(context),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      getTimeLabel(time),
                    ),
                    onTap: () {
                      editReminderTime(index);
                    },
                    trailing: reminderTimes.length > 1
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                reminderTimes.removeAt(
                                  index,
                                );
                              });
                            },
                          )
                        : const Icon(Icons.edit),
                  ),
                );
              },
            ),

            OutlinedButton.icon(
              onPressed: addReminderTime,
              icon: const Icon(Icons.add_alarm),
              label:
                  const Text('Add Another Reminder'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),

            sectionTitle('Repeat'),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'daily',
                  label: Text('Every Day'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: 'selected_days',
                  label: Text('Selected Days'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {repeatType},
              onSelectionChanged: (selection) {
                setState(() {
                  repeatType = selection.first;
                });
              },
            ),

            if (repeatType == 'selected_days') ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weekDays.map((day) {
                  final selected =
                      selectedDays.contains(day);

                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            sectionTitle('Medication Dates'),

            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(
                  formatDateForServer(startDate),
                ),
                trailing: const Icon(Icons.edit),
                onTap: selectStartDate,
              ),
            ),

            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.event_available),
                title: const Text('End Date'),
                subtitle: Text(
                  endDate == null
                      ? 'No end date'
                      : formatDateForServer(endDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (endDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            endDate = null;
                          });
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      ),
                    const Icon(Icons.edit),
                  ],
                ),
                onTap: selectEndDate,
              ),
            ),

            sectionTitle('Medicine Stock'),

            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration(
                label: 'Remaining Quantity',
                icon: Icons.inventory_2_outlined,
                hint: 'Example: 30 tablets',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return null;
                }

                final quantity =
                    int.tryParse(value.trim());

                if (quantity == null ||
                    quantity < 0) {
                  return 'Enter a valid quantity.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: lowStockController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration(
                label: 'Low Stock Warning',
                icon: Icons.warning_amber,
                hint: 'Example: 5',
              ),
              validator: (value) {
                final threshold =
                    int.tryParse(value?.trim() ?? '');

                if (threshold == null ||
                    threshold < 0) {
                  return 'Enter a valid warning quantity.';
                }

                return null;
              },
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isSaving ? null : saveMedication,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : isEditMode
                          ? 'Save Changes'
                          : 'Add Medicine',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}