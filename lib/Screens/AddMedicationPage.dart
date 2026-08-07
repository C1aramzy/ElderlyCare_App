import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../Services/notifiService.dart';

class AddMedicationPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? medication;

  const AddMedicationPage({
    super.key,
    required this.userId,
    this.medication,
  });

  @override
  State<AddMedicationPage> createState() =>
      _AddMedicationPageState();
}

class _AddMedicationPageState
    extends State<AddMedicationPage> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final ImagePicker _imagePicker =
      ImagePicker();

  // ==================================================
  // Controllers
  // ==================================================

  final TextEditingController
      medicineNameController =
      TextEditingController(
    text: 'Prescribed Medication',
  );

  final TextEditingController
      customInstructionController =
      TextEditingController();

  final TextEditingController
      quantityController =
      TextEditingController();

  final TextEditingController
      lowStockController =
      TextEditingController(
    text: '5',
  );

  // ==================================================
  // PHP URLs
  // ==================================================

  static const String addMedicationUrl =
      'http://elderlym.atspace.cc/Medication/add_medication.php';

  static const String updateMedicationUrl =
      'http://elderlym.atspace.cc/Medication/update_medication.php';

  // ==================================================
  // Medicine photo
  // ==================================================

  XFile? selectedImage;

  // ==================================================
  // Dosage
  // ==================================================

  int dosageQuantity = 1;

  // ==================================================
  // Instructions
  // ==================================================

  String selectedInstruction =
      'After Food';

  // ==================================================
  // Medication type
  //
  // long_term = Chronic
  // short_term = Acute
  // ==================================================

  String medicationType =
      'long_term';

  // ==================================================
  // Reminder settings
  // ==================================================

  bool amReminderEnabled = true;
  bool pmReminderEnabled = false;

  TimeOfDay amReminderTime =
      const TimeOfDay(
    hour: 8,
    minute: 0,
  );

  TimeOfDay pmReminderTime =
      const TimeOfDay(
    hour: 20,
    minute: 0,
  );

  // ==================================================
  // Dates
  // ==================================================

  DateTime startDate =
      DateTime.now();

  DateTime? endDate;

  // ==================================================
  // Repeat settings
  // ==================================================

  String repeatType =
      'daily';

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

  // ==================================================
  // Saving state
  // ==================================================

  bool isSaving = false;

  // ==================================================
  // Edit mode
  // ==================================================

  bool get isEditMode =>
      widget.medication != null;

  // ==================================================
  // Dosage text
  // ==================================================

  String get dosageText {
    if (dosageQuantity == 1) {
      return '1 tablet';
    }

    return '$dosageQuantity tablets';
  }

  // ==================================================
  // Final instruction value
  // ==================================================

  String get finalInstruction {
    if (selectedInstruction ==
        'Other') {
      return customInstructionController
          .text
          .trim();
    }

    return selectedInstruction;
  }

  // ==================================================
  // Existing image URL
  // ==================================================

  String? get existingImageUrl {
    return widget
        .medication?[
            'medicine_image_url']
        ?.toString();
  }

  // ==================================================
  // Initialisation
  // ==================================================

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      fillExistingMedication();
    }
  }

  // ==================================================
  // Load existing medication for edit mode
  // ==================================================

  void fillExistingMedication() {
    final Map<String, dynamic>
        medication =
        widget.medication!;

    medicineNameController.text =
        medication['medicine_name']
                ?.toString() ??
            'Prescribed Medication';

    dosageQuantity =
        parseDosageQuantity(
      medication['dosage_quantity']
                  ?.toString() ??
              medication['dosage']
                  ?.toString() ??
              '',
    );

    final String
        existingInstruction =
        medication['instructions']
                ?.toString() ??
            '';

    if (existingInstruction ==
            'Before Food' ||
        existingInstruction ==
            'After Food') {
      selectedInstruction =
          existingInstruction;
    } else if (existingInstruction
        .isNotEmpty) {
      selectedInstruction =
          'Other';

      customInstructionController
              .text =
          existingInstruction;
    }

    medicationType =
        medication['medication_type']
                ?.toString() ??
            'long_term';

    quantityController.text =
        medication[
                    'remaining_quantity']
                ?.toString() ??
            '';

    lowStockController.text =
        medication[
                    'low_stock_threshold']
                ?.toString() ??
            '5';

    final DateTime?
        existingStartDate =
        DateTime.tryParse(
      medication['start_date']
              ?.toString() ??
          '',
    );

    if (existingStartDate != null) {
      startDate =
          existingStartDate;
    }

    final String endDateText =
        medication['end_date']
                ?.toString() ??
            '';

    if (endDateText.isNotEmpty) {
      endDate =
          DateTime.tryParse(
        endDateText,
      );
    }

    loadExistingSchedules(
      medication['schedules'],
    );
  }

  // ==================================================
  // Extract dosage number
  // Example:
  // "2 tablets" -> 2
  // ==================================================

  int parseDosageQuantity(
    String dosage,
  ) {
    final RegExpMatch? match =
        RegExp(
      r'\d+',
    ).firstMatch(
      dosage,
    );

    final int quantity =
        int.tryParse(
              match?.group(0) ??
                  '',
            ) ??
            1;

    return quantity < 1
        ? 1
        : quantity;
  }

  // ==================================================
  // Load existing reminder schedules
  // ==================================================

  void loadExistingSchedules(
    dynamic schedulesData,
  ) {
    if (schedulesData is! List ||
        schedulesData.isEmpty) {
      return;
    }

    amReminderEnabled = false;
    pmReminderEnabled = false;

    for (final dynamic item
        in schedulesData) {
      if (item
          is! Map<String, dynamic>) {
        continue;
      }

      final TimeOfDay? time =
          parseTime(
        item['reminder_time']
                ?.toString() ??
            '',
      );

      if (time == null) {
        continue;
      }

      if (time.hour < 12 &&
          !amReminderEnabled) {
        amReminderEnabled =
            true;

        amReminderTime =
            time;
      } else if (time.hour >= 12 &&
          !pmReminderEnabled) {
        pmReminderEnabled =
            true;

        pmReminderTime =
            time;
      }
    }

    final dynamic firstSchedule =
        schedulesData.first;

    if (firstSchedule
        is Map<String, dynamic>) {
      repeatType =
          firstSchedule[
                      'repeat_type']
                  ?.toString() ??
              'daily';

      final String repeatDaysText =
          firstSchedule[
                      'repeat_days']
                  ?.toString() ??
              '';

      selectedDays.clear();

      selectedDays.addAll(
        repeatDaysText
            .split(',')
            .map(
              (String day) =>
                  day.trim(),
            )
            .where(
              (String day) =>
                  day.isNotEmpty,
            ),
      );
    }

    if (!amReminderEnabled &&
        !pmReminderEnabled) {
      amReminderEnabled =
          true;
    }
  }

  // ==================================================
  // Convert database time to TimeOfDay
  // ==================================================

  TimeOfDay? parseTime(
    String value,
  ) {
    final List<String> parts =
        value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final int? hour =
        int.tryParse(
      parts[0],
    );

    final int? minute =
        int.tryParse(
      parts[1],
    );

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  // ==================================================
  // Dispose
  // ==================================================

  @override
  void dispose() {
    medicineNameController
        .dispose();

    customInstructionController
        .dispose();

    quantityController.dispose();

    lowStockController.dispose();

    super.dispose();
  }

  // ==================================================
  // Format date for PHP
  // ==================================================

  String formatDateForServer(
    DateTime date,
  ) {
    final String year =
        date.year
            .toString()
            .padLeft(
              4,
              '0',
            );

    final String month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  // ==================================================
  // Format reminder time for PHP
  // ==================================================

  String formatTimeForServer(
    TimeOfDay time,
  ) {
    final String hour =
        time.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String minute =
        time.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  // ==================================================
  // Snackbar
  // ==================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ==================================================
  // Image options
  // ==================================================

  Future<void>
      showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder:
          (
        BuildContext
            bottomSheetContext,
      ) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons.camera_alt,
                ),
                title:
                    const Text(
                  'Take Photo',
                ),
                onTap: () {
                  Navigator.pop(
                    bottomSheetContext,
                  );

                  selectImage(
                    ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(
                  Icons.photo_library,
                ),
                title:
                    const Text(
                  'Choose from Gallery',
                ),
                onTap: () {
                  Navigator.pop(
                    bottomSheetContext,
                  );

                  selectImage(
                    ImageSource.gallery,
                  );
                },
              ),
              if (selectedImage != null)
                ListTile(
                  leading:
                      const Icon(
                    Icons
                        .delete_outline,
                    color:
                        Colors.red,
                  ),
                  title:
                      const Text(
                    'Remove New Photo',
                    style:
                        TextStyle(
                      color:
                          Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    setState(() {
                      selectedImage =
                          null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================================================
  // Select image
  // ==================================================

  Future<void> selectImage(
    ImageSource source,
  ) async {
    try {
      final XFile? image =
          await _imagePicker
              .pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (image == null ||
          !mounted) {
        return;
      }

      setState(() {
        selectedImage =
            image;
      });
    } catch (error) {
      showMessage(
        'Unable to select image: '
        '$error',
      );
    }
  }

  // ==================================================
  // Select exact AM or PM reminder time
  // ==================================================

  Future<void>
      selectReminderTime({
    required bool isAm,
  }) async {
    final TimeOfDay
        selectedInitialTime =
        isAm
            ? amReminderTime
            : pmReminderTime;

    final TimeOfDay?
        selectedTime =
        await showTimePicker(
      context: context,
      initialTime:
          selectedInitialTime,
      helpText: isAm
          ? 'Select AM Reminder Time'
          : 'Select PM Reminder Time',
    );

    if (selectedTime == null) {
      return;
    }

    if (isAm &&
        selectedTime.hour >= 12) {
      showMessage(
        'Please select a morning AM time.',
      );

      return;
    }

    if (!isAm &&
        selectedTime.hour < 12) {
      showMessage(
        'Please select an afternoon or evening PM time.',
      );

      return;
    }

    setState(() {
      if (isAm) {
        amReminderTime =
            selectedTime;
      } else {
        pmReminderTime =
            selectedTime;
      }
    });
  }

  // ==================================================
  // Start date
  // ==================================================

  Future<void>
      selectStartDate() async {
    final DateTime?
        selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          startDate,
      firstDate:
          DateTime.now().subtract(
        const Duration(
          days: 365,
        ),
      ),
      lastDate:
          DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      startDate =
          selectedDate;

      if (endDate != null &&
          endDate!.isBefore(
            startDate,
          )) {
        endDate =
            null;
      }
    });
  }

  // ==================================================
  // End date
  //
  // BOTH chronic and acute medicines can select this.
  //
  // Chronic:
  // optional
  //
  // Acute:
  // required
  // ==================================================

  Future<void>
      selectEndDate() async {
    final DateTime?
        selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          endDate ??
              startDate,
      firstDate:
          startDate,
      lastDate:
          DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      endDate =
          selectedDate;
    });
  }

  // ==================================================
  // Build schedules
  // ==================================================

  List<Map<String, dynamic>>
      buildSchedules() {
    final List<
            Map<String, dynamic>>
        schedules =
        [];

    final String repeatDays =
        repeatType ==
                'selected_days'
            ? weekDays
                .where(
                  selectedDays
                      .contains,
                )
                .join(',')
            : '';

    if (amReminderEnabled) {
      schedules.add({
        'reminder_time':
            formatTimeForServer(
          amReminderTime,
        ),
        'time_label':
            'AM',
        'repeat_type':
            repeatType,
        'repeat_days':
            repeatDays,
        'early_window_minutes':
            30,
        'late_window_minutes':
            60,
      });
    }

    if (pmReminderEnabled) {
      schedules.add({
        'reminder_time':
            formatTimeForServer(
          pmReminderTime,
        ),
        'time_label':
            'PM',
        'repeat_type':
            repeatType,
        'repeat_days':
            repeatDays,
        'early_window_minutes':
            30,
        'late_window_minutes':
            60,
      });
    }

    return schedules;
  }

  // ==================================================
  // Save medication
  // ==================================================

  Future<void>
      saveMedication() async {
    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    // At least one reminder required.
    if (!amReminderEnabled &&
        !pmReminderEnabled) {
      showMessage(
        'Please enable at least one reminder.',
      );

      return;
    }

    // Selected days require at least one day.
    if (repeatType ==
            'selected_days' &&
        selectedDays.isEmpty) {
      showMessage(
        'Please select at least one repeat day.',
      );

      return;
    }

    // Acute medication MUST have an end date.
    if (medicationType ==
            'short_term' &&
        endDate == null) {
      showMessage(
        'Please select an end date for an acute medication.',
      );

      return;
    }

    // Other instruction requires text.
    if (selectedInstruction ==
            'Other' &&
        customInstructionController
            .text
            .trim()
            .isEmpty) {
      showMessage(
        'Please enter the medication instructions.',
      );

      return;
    }

    setState(() {
      isSaving =
          true;
    });

    try {
      final http.MultipartRequest
          request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          isEditMode
              ? updateMedicationUrl
              : addMedicationUrl,
        ),
      );

      request.fields.addAll({
        if (isEditMode)
          'medication_id':
              widget
                  .medication![
                      'medication_id']
                  .toString(),

        'elderly_user_id':
            widget.userId
                .toString(),

        'medicine_name':
            medicineNameController
                .text
                .trim(),

        'dosage':
            dosageText,

        'dosage_quantity':
            dosageQuantity
                .toString(),

        'instructions':
            finalInstruction,

        'medication_type':
            medicationType,

        'start_date':
            formatDateForServer(
          startDate,
        ),

        // Chronic medication may have:
        // - an end date
        // - no end date
        //
        // Acute medication must have one.
        'end_date':
            endDate == null
                ? ''
                : formatDateForServer(
                    endDate!,
                  ),

        'remaining_quantity':
            quantityController
                .text
                .trim(),

        'low_stock_threshold':
            lowStockController
                .text
                .trim(),

        'schedules':
            jsonEncode(
          buildSchedules(),
        ),
      });

      // ==================================================
      // Upload medicine image
      // ==================================================

      if (selectedImage != null) {
        request.files.add(
          await http
              .MultipartFile
              .fromPath(
            'medicine_image',
            selectedImage!
                .path,
          ),
        );
      }

      // ==================================================
      // Send request
      // ==================================================

      final http.StreamedResponse
          streamedResponse =
          await request
              .send()
              .timeout(
        const Duration(
          seconds: 30,
        ),
      );

      final http.Response
          response =
          await http.Response
              .fromStream(
        streamedResponse,
      );

      if (response.statusCode !=
          200) {
        throw Exception(
          'Server returned status '
          '${response.statusCode}.',
        );
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (!mounted) {
        return;
      }

      if(decoded is Map<String, dynamic> && decoded['success'] == true)
      {
        final int medicationId = 
            int.tryParse(
              decoded['medication_id']?.toString() ?? ' ',
            ) ??
            0;

            final List<dynamic> newSchedules = 
                decoded['schedules'] is List
                    ? decoded['schedules']
                    : [];

        // ==================================================
        // If editing, cancel the OLD alarms first.
        // ==================================================    

            if(isEditMode){
              final dynamic oldSchedules = 
                  widget.medication?['schedules'];

            if (oldSchedules is List){
              await NotifiService.cancelMedicationAlarms(
                schedules:oldSchedules,
                );
              }
            }
            // ==================================================
            //  Schedule the NEW alarms.
            //===================================================

            if (medicationId > 0 &&
                newSchedules.isNotEmpty){
                  try{
                    await NotifiService.scheduleMedicationAlarms(
                      medicationId: medicationId,
                      medicineName: 
                            medicineNameController.text.trim(),
                      dosage: dosageText,
                      schedules: newSchedules,
                      );
                  } catch (notificationError){
                    debugPrint(
                      'Medication saved but alarm scheduling failed.'
                      '$notificationError',
                    );

                    if(mounted){
                      showMessage(
                        'Medicine saved, but the alarm could not be scheduled.',
                      );
                    }
                  }
                }

                if (!mounted){
                  return;
                }

                showMessage(
                  decoded['message'] ?.toString() ??
                      (isEditMode
                          ? 'Medication updated successfully.'
                          : 'Medication added successfully.'),
                );

                Navigator.pop(
                  context,
                  true,
                );
                
                return;
      }

      final String message =
          decoded
                  is Map<String,
                      dynamic>
              ? decoded['message']
                      ?.toString() ??
                  'Unable to save medication.'
              : 'Invalid response from server.';

      showMessage(
        message,
      );
    } catch (error) {
      showMessage(
        isEditMode
            ? 'Error updating medication: $error'
            : 'Error adding medication: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving =
              false;
        });
      }
    }
  }

  // ==================================================
  // Section title
  // ==================================================

  Widget sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 16,
        bottom: 10,
      ),
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ==================================================
  // Text field decoration
  // ==================================================

  InputDecoration
      fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,
      hintText:
          hint,
      prefixIcon:
          Icon(icon),
      filled:
          true,
      fillColor:
          Colors.white,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.orange,
          width:
              1.5,
        ),
      ),
    );
  }

  // ==================================================
  // Photo placeholder
  // ==================================================

  Widget
      buildPhotoPlaceholder() {
    return Container(
      color:
          const Color(
        0xFFFFF7ED,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .add_a_photo_outlined,
            size:
                72,
            color:
                Colors.orange[700],
          ),
          const SizedBox(
            height:
                12,
          ),
          const Text(
            'Add Medicine Photo',
            style:
                TextStyle(
              fontSize:
                  21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height:
                7,
          ),
          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  20,
            ),
            child:
                Text(
              'Take a clear photo so the elderly user can recognise the medicine.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    14,
                color:
                    Colors.grey[
                        700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Large medicine photo area
  // ==================================================

  Widget buildPhotoArea() {
    Widget imageContent;

    if (selectedImage != null) {
      imageContent =
          Image.file(
        File(
          selectedImage!
              .path,
        ),
        fit:
            BoxFit.cover,
      );
    } else if (existingImageUrl !=
            null &&
        existingImageUrl!
            .isNotEmpty) {
      imageContent =
          Image.network(
        existingImageUrl!,
        fit:
            BoxFit.cover,
        errorBuilder:
            (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return buildPhotoPlaceholder();
        },
      );
    } else {
      imageContent =
          buildPhotoPlaceholder();
    }

    return GestureDetector(
      onTap:
          showImageOptions,
      child: Container(
        height:
            280,
        width:
            double.infinity,
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          border:
              Border.all(
            color:
                Colors.orange
                    .withValues(
              alpha:
                  0.5,
            ),
            width:
                1.5,
          ),
        ),
        clipBehavior:
            Clip.antiAlias,
        child:
            Stack(
          fit:
              StackFit.expand,
          children: [
            imageContent,
            Align(
              alignment:
                  Alignment
                      .bottomCenter,
              child:
                  Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical:
                      11,
                  horizontal:
                      12,
                ),
                color:
                    Colors.black
                        .withValues(
                  alpha:
                      0.58,
                ),
                child:
                    const Text(
                  'Tap to take or change photo',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Dosage +/- stepper
  // ==================================================

  Widget buildDosageStepper() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons
                .local_pharmacy_outlined,
          ),
          const SizedBox(
            width:
                12,
          ),
          const Expanded(
            child:
                Text(
              'Dosage',
              style:
                  TextStyle(
                fontSize:
                    17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip:
                'Reduce dosage',
            onPressed:
                dosageQuantity <=
                        1
                    ? null
                    : () {
                        setState(
                          () {
                            dosageQuantity--;
                          },
                        );
                      },
            icon:
                const Icon(
              Icons.remove,
            ),
          ),
          SizedBox(
            width:
                110,
            child:
                Text(
              dosageText,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize:
                    17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          IconButton.filled(
            tooltip:
                'Increase dosage',
            onPressed:
                () {
              setState(() {
                dosageQuantity++;
              });
            },
            icon:
                const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Instruction choice
  // ==================================================

  Widget buildInstructionOption({
    required String value,
    required IconData icon,
  }) {
    final bool selected =
        selectedInstruction ==
            value;

    return ChoiceChip(
      selected:
          selected,
      avatar:
          Icon(
        icon,
        size:
            19,
        color:
            selected
                ? Colors.white
                : Colors.orange[
                    800],
      ),
      label:
          Text(value),
      labelStyle:
          TextStyle(
        color:
            selected
                ? Colors.white
                : Colors.black87,
        fontWeight:
            FontWeight.w600,
      ),
      selectedColor:
          Colors.orange,
      onSelected:
          (_) {
        setState(() {
          selectedInstruction =
              value;
        });
      },
    );
  }

  // ==================================================
  // Reminder card
  // ==================================================

  Widget buildReminderCard({
    required String period,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool>
        onChanged,
    required VoidCallback
        onEditTime,
  }) {
    final bool isMorning =
        period ==
            'AM';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            12,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              enabled
                  ? Colors.orange
                      .withValues(
                      alpha:
                          0.55,
                    )
                  : Colors.grey
                      .withValues(
                      alpha:
                          0.2,
                    ),
        ),
      ),
      child:
          Column(
        children: [
          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            value:
                enabled,
            onChanged:
                onChanged,
            secondary:
                Icon(
              isMorning
                  ? Icons
                      .wb_sunny_outlined
                  : Icons
                      .nightlight_outlined,
              color:
                  Colors.orange,
              size:
                  30,
            ),
            title:
                Text(
              '$period Medication',
              style:
                  const TextStyle(
                fontSize:
                    17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                Text(
              enabled
                  ? 'Reminder is enabled'
                  : 'Reminder is disabled',
            ),
          ),
          if (enabled) ...[
            const Divider(),
            ListTile(
              contentPadding:
                  EdgeInsets.zero,
              leading:
                  const Icon(
                Icons.alarm,
                color:
                    Colors.blueGrey,
              ),
              title:
                  const Text(
                'Exact Reminder Time',
              ),
              subtitle:
                  Text(
                time.format(
                  context,
                ),
                style:
                    const TextStyle(
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              trailing:
                  const Icon(
                Icons.edit,
              ),
              onTap:
                  onEditTime,
            ),
          ],
        ],
      ),
    );
  }

  // ==================================================
  // Chronic / Acute selector
  // ==================================================

  Widget buildMedicationTypeOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final bool selected =
        medicationType ==
            value;

    return Expanded(
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        onTap:
            () {
          setState(() {
            // IMPORTANT:
            //
            // Changing to Chronic no longer removes
            // an existing end date.
            medicationType =
                value;
          });
        },
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds:
                180,
          ),
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color:
                selected
                    ? Colors.orange
                        .withValues(
                        alpha:
                            0.14,
                      )
                    : Colors.white,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? Colors.orange
                      : Colors.grey
                          .withValues(
                          alpha:
                              0.25,
                        ),
              width:
                  selected
                      ? 2
                      : 1,
            ),
          ),
          child:
              Column(
            children: [
              Icon(
                icon,
                color:
                    selected
                        ? Colors.orange[
                            800]
                        : Colors.grey[
                            700],
                size:
                    30,
              ),
              const SizedBox(
                height:
                    8,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize:
                      16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height:
                    5,
              ),
              Text(
                description,
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize:
                      12,
                  color:
                      Colors.grey[
                          700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF5F6FA,
      ),
      appBar:
          AppBar(
        title:
            Text(
          isEditMode
              ? 'Edit Medicine'
              : 'Add Medicine',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation:
            0,
      ),
      body:
          Form(
        key:
            _formKey,
        child:
            ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            // ==========================================
            // PHOTO
            // ==========================================

            buildPhotoArea(),

            // ==========================================
            // MEDICINE DETAILS
            // ==========================================

            sectionTitle(
              'Medicine Details',
            ),

            TextFormField(
              controller:
                  medicineNameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration:
                  fieldDecoration(
                label:
                    'Medicine Name',
                icon:
                    Icons.medication,
                hint:
                    'Edit the prescribed medicine name',
              ),
              validator:
                  (
                String? value,
              ) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Please enter the medicine name.';
                }

                return null;
              },
            ),

            const SizedBox(
              height:
                  12,
            ),

            buildDosageStepper(),

            // ==========================================
            // INSTRUCTIONS
            // ==========================================

            sectionTitle(
              'Instructions',
            ),

            Wrap(
              spacing:
                  9,
              runSpacing:
                  9,
              children: [
                buildInstructionOption(
                  value:
                      'Before Food',
                  icon:
                      Icons.restaurant_outlined,
                ),
                buildInstructionOption(
                  value:
                      'After Food',
                  icon:
                      Icons.restaurant,
                ),
                buildInstructionOption(
                  value:
                      'Other',
                  icon:
                      Icons.edit_note,
                ),
              ],
            ),

            if (selectedInstruction ==
                'Other') ...[
              const SizedBox(
                height:
                    12,
              ),
              TextFormField(
                controller:
                    customInstructionController,
                maxLines:
                    2,
                decoration:
                    fieldDecoration(
                  label:
                      'Other Instructions',
                  icon:
                      Icons.notes,
                  hint:
                      'Enter the prescribed instructions',
                ),
              ),
            ],

            // ==========================================
            // MEDICINE TYPE
            // ==========================================

            sectionTitle(
              'Medicine Type',
            ),

            Row(
              children: [
                buildMedicationTypeOption(
                  value:
                      'long_term',
                  title:
                      'Chronic',
                  description:
                      'Long-term medication',
                  icon:
                      Icons.autorenew,
                ),
                const SizedBox(
                  width:
                      12,
                ),
                buildMedicationTypeOption(
                  value:
                      'short_term',
                  title:
                      'Acute',
                  description:
                      'Short-term medication',
                  icon:
                      Icons.event_available,
                ),
              ],
            ),

            const SizedBox(
              height:
                  8,
            ),

            Text(
              medicationType ==
                      'long_term'
                  ? 'Chronic medication may continue indefinitely or have an optional end date.'
                  : 'Acute medication requires an end date.',
              style:
                  TextStyle(
                color:
                    Colors.grey[
                        700],
              ),
            ),

            // ==========================================
            // REMINDERS
            // ==========================================

            sectionTitle(
              'Reminder Times',
            ),

            buildReminderCard(
              period:
                  'AM',
              enabled:
                  amReminderEnabled,
              time:
                  amReminderTime,
              onChanged:
                  (
                bool enabled,
              ) {
                setState(() {
                  amReminderEnabled =
                      enabled;
                });
              },
              onEditTime:
                  () {
                selectReminderTime(
                  isAm:
                      true,
                );
              },
            ),

            buildReminderCard(
              period:
                  'PM',
              enabled:
                  pmReminderEnabled,
              time:
                  pmReminderTime,
              onChanged:
                  (
                bool enabled,
              ) {
                setState(() {
                  pmReminderEnabled =
                      enabled;
                });
              },
              onEditTime:
                  () {
                selectReminderTime(
                  isAm:
                      false,
                );
              },
            ),

            // ==========================================
            // REPEAT
            // ==========================================

            sectionTitle(
              'Repeat',
            ),

            SegmentedButton<String>(
              segments:
                  const [
                ButtonSegment<String>(
                  value:
                      'daily',
                  label:
                      Text(
                    'Every Day',
                  ),
                  icon:
                      Icon(
                    Icons.today,
                  ),
                ),
                ButtonSegment<String>(
                  value:
                      'selected_days',
                  label:
                      Text(
                    'Selected Days',
                  ),
                  icon:
                      Icon(
                    Icons.date_range,
                  ),
                ),
              ],
              selected:
                  {
                repeatType,
              },
              onSelectionChanged:
                  (
                Set<String>
                    selection,
              ) {
                setState(() {
                  repeatType =
                      selection.first;
                });
              },
            ),

            if (repeatType ==
                'selected_days') ...[
              const SizedBox(
                height:
                    14,
              ),
              Wrap(
                spacing:
                    8,
                runSpacing:
                    8,
                children:
                    weekDays
                        .map(
                  (String day) {
                    final bool
                        selected =
                        selectedDays
                            .contains(
                      day,
                    );

                    return FilterChip(
                      label:
                          Text(
                        day,
                      ),
                      selected:
                          selected,
                      onSelected:
                          (
                        bool value,
                      ) {
                        setState(() {
                          if (value) {
                            selectedDays
                                .add(
                              day,
                            );
                          } else {
                            selectedDays
                                .remove(
                              day,
                            );
                          }
                        });
                      },
                    );
                  },
                ).toList(),
              ),
            ],

            // ==========================================
            // MEDICATION DATES
            // ==========================================

            sectionTitle(
              'Medication Dates',
            ),

            Card(
              child:
                  ListTile(
                leading:
                    const Icon(
                  Icons.calendar_today,
                ),
                title:
                    const Text(
                  'Start Date',
                ),
                subtitle:
                    Text(
                  formatDateForServer(
                    startDate,
                  ),
                ),
                trailing:
                    const Icon(
                  Icons.edit,
                ),
                onTap:
                    selectStartDate,
              ),
            ),

            // ==========================================
            // END DATE
            //
            // FIXED:
            // Can now be selected for Chronic AND Acute.
            // ==========================================

            Card(
              child:
                  ListTile(
                leading:
                    const Icon(
                  Icons.event_available,
                ),

                title:
                    Text(
                  medicationType ==
                          'short_term'
                      ? 'End Date (Required)'
                      : 'End Date (Optional)',
                ),

                subtitle:
                    Text(
                  endDate ==
                          null
                      ? 'No end date'
                      : formatDateForServer(
                          endDate!,
                        ),
                ),

                trailing:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    if (endDate !=
                        null)
                      IconButton(
                        tooltip:
                            'Remove end date',
                        onPressed:
                            () {
                          setState(() {
                            endDate =
                                null;
                          });
                        },
                        icon:
                            const Icon(
                          Icons.clear,
                        ),
                      ),

                    const Icon(
                      Icons.edit,
                    ),
                  ],
                ),

                onTap:
                    selectEndDate,
              ),
            ),

            // ==========================================
            // STOCK
            // ==========================================

            sectionTitle(
              'Medicine Stock',
            ),

            TextFormField(
              controller:
                  quantityController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  fieldDecoration(
                label:
                    'Remaining Quantity',
                icon:
                    Icons.inventory_2_outlined,
                hint:
                    'Example: 30',
              ),
              validator:
                  (
                String? value,
              ) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return null;
                }

                final int?
                    quantity =
                    int.tryParse(
                  value.trim(),
                );

                if (quantity ==
                        null ||
                    quantity <
                        0) {
                  return 'Enter a valid quantity.';
                }

                return null;
              },
            ),

            const SizedBox(
              height:
                  12,
            ),

            TextFormField(
              controller:
                  lowStockController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  fieldDecoration(
                label:
                    'Low Stock Warning',
                icon:
                    Icons.warning_amber,
                hint:
                    'Example: 5',
              ),
              validator:
                  (
                String? value,
              ) {
                final int?
                    threshold =
                    int.tryParse(
                  value?.trim() ??
                      '',
                );

                if (threshold ==
                        null ||
                    threshold <
                        0) {
                  return 'Enter a valid warning quantity.';
                }

                return null;
              },
            ),

            const SizedBox(
              height:
                  26,
            ),

            // ==========================================
            // SAVE BUTTON
            // ==========================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : saveMedication,
                icon:
                    isSaving
                        ? const SizedBox(
                            width:
                                20,
                            height:
                                20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save,
                          ),
                label:
                    Text(
                  isSaving
                      ? 'Saving...'
                      : isEditMode
                          ? 'Save Changes'
                          : 'Add Medicine',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.orange,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        16,
                  ),
                  textStyle:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height:
                  30,
            ),
          ],
        ),
      ),
    );
  }
}