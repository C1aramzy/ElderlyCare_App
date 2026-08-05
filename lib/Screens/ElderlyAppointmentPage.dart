import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  final int userId;

  const AppointmentPage({
    super.key,
    required this.userId,
  });

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // ==================================================
  // Colours matching the Medication page
  // ==================================================

  static const Color pageBackground = Color(0xFFF5F6FA);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color secondaryOrange = Color(0xFFFFB74D);
  static const Color lightOrange = Color(0xFFFFF1DC);

  static const Color darkText = Color(0xFF20252D);
  static const Color secondaryText = Color(0xFF808080);

  static const Color lightBlueButton = Color(0xFFD7E9FF);

  static const Color deleteRed = Color(0xFFFF4949);
  static const Color lightDeleteRed = Color(0xFFFFE5E5);

  // ==================================================
  // API
  // ==================================================

  final String baseUrl =
      "http://elderlym.atspace.cc/ElderlyAppointments";

  // ==================================================
  // Appointment data
  // ==================================================

  List<Map<String, dynamic>> appointments = [];

  bool isLoading = true;
  bool isSubmitting = false;
  bool isSavingReminder = false;

  // ==================================================
  // Calendar data
  // ==================================================

  DateTime focusedDay = DateTime.now();
  DateTime selectedCalendarDay = DateTime.now();

  // ==================================================
  // Form controllers
  // ==================================================

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  final TextEditingController reminderController =
      TextEditingController();

  DateTime? selectedAppointmentDate;
  TimeOfDay? selectedAppointmentTime;

  // ==================================================
  // Reminder
  // ==================================================

  String reminderText =
      "Please remember to bring your NRIC, appointment letter "
      "and any required medical documents.";

  // ==================================================
  // Lifecycle
  // ==================================================

  @override
  void initState() {
    super.initState();
    loadAppointmentPage();
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    notesController.dispose();
    reminderController.dispose();

    super.dispose();
  }

  // ==================================================
  // Load page
  // ==================================================

  Future<void> loadAppointmentPage() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await fetchAppointments();
    await fetchReminder();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ==================================================
  // Fetch appointments
  // ==================================================

  Future<void> fetchAppointments({
    bool showError = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/get_appointments.php"
          "?user_id=${widget.userId}",
        ),
      );

      debugPrint(
        "FETCH APPOINTMENTS STATUS: ${response.statusCode}",
      );
      debugPrint(
        "FETCH APPOINTMENTS RESPONSE: ${response.body}",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server status ${response.statusCode}",
        );
      }

      final dynamic decodedData =
          jsonDecode(response.body.trim());

      if (decodedData is! Map<String, dynamic>) {
        throw Exception("Invalid appointment response");
      }

      final dynamic appointmentData =
          decodedData["appointments"];

      final List<Map<String, dynamic>> loadedAppointments = [];

      if (appointmentData is List) {
        for (final item in appointmentData) {
          if (item is Map) {
            loadedAppointments.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      loadedAppointments.sort((first, second) {
        return getAppointmentDateTime(first).compareTo(
          getAppointmentDateTime(second),
        );
      });

      if (!mounted) return;

      setState(() {
        appointments = loadedAppointments;
      });
    } catch (error) {
      debugPrint("Fetch appointments error: $error");

      if (!mounted || !showError) return;

      showMessage(
        "Unable to load appointments. Please try again.",
      );
    }
  }

  // ==================================================
  // Fetch reminder
  // ==================================================

  Future<void> fetchReminder() async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/get_appointment_reminder.php"
          "?user_id=${widget.userId}",
        ),
      );

      if (response.statusCode != 200) {
        return;
      }

      final String responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        return;
      }

      final dynamic decodedData = jsonDecode(responseBody);

      if (decodedData is! Map<String, dynamic>) {
        return;
      }

      if (decodedData["success"] == true) {
        final String loadedReminder =
            decodedData["reminder_text"]
                    ?.toString()
                    .trim() ??
                "";

        if (loadedReminder.isNotEmpty && mounted) {
          setState(() {
            reminderText = loadedReminder;
          });
        }
      }
    } catch (error) {
      // Keep the default reminder if the reminder PHP
      // has not been created yet.
      debugPrint("Fetch reminder error: $error");
    }
  }

  // ==================================================
  // Save reminder
  // ==================================================

  Future<void> saveReminder(String newReminder) async {
    final String cleanedReminder = newReminder.trim();

    if (cleanedReminder.isEmpty) {
      showMessage("The reminder cannot be empty.");
      return;
    }

    setState(() {
      isSavingReminder = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/save_appointment_reminder.php",
        ),
        body: {
          "user_id": widget.userId.toString(),
          "reminder_text": cleanedReminder,
        },
      );

      final String responseBody = response.body.trim();

      debugPrint(
        "SAVE REMINDER STATUS: ${response.statusCode}",
      );
      debugPrint(
        "SAVE REMINDER RESPONSE: $responseBody",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server status ${response.statusCode}",
        );
      }

      final dynamic decodedData =
          jsonDecode(responseBody);

      if (decodedData is! Map<String, dynamic>) {
        throw Exception("Invalid reminder response");
      }

      if (!mounted) return;

      if (decodedData["success"] == true) {
        setState(() {
          reminderText = cleanedReminder;
        });

        showMessage(
          decodedData["message"]?.toString() ??
              "Reminder updated successfully.",
        );
      } else {
        showMessage(
          decodedData["message"]?.toString() ??
              "Unable to update reminder.",
        );
      }
    } catch (error) {
      debugPrint("Save reminder error: $error");

      if (!mounted) return;

      showMessage(
        "Unable to save the reminder. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingReminder = false;
        });
      }
    }
  }

  // ==================================================
  // Add appointment
  // ==================================================

  Future<void> addAppointment() async {
    if (!validateAppointmentForm()) return;

    final DateTime newDate = selectedAppointmentDate!;

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_appointment.php"),
        body: {
          "user_id": widget.userId.toString(),
          "title": titleController.text.trim(),
          "appointment_date": formatDateForDatabase(
            selectedAppointmentDate!,
          ),
          "appointment_time": formatTimeForDatabase(
            selectedAppointmentTime!,
          ),
          "location": locationController.text.trim(),
          "notes": notesController.text.trim(),
        },
      );

      final String responseBody = response.body.trim();

      debugPrint("ADD STATUS: ${response.statusCode}");
      debugPrint("ADD RESPONSE: $responseBody");

      if (response.statusCode != 200) {
        throw Exception(
          "Server returned status ${response.statusCode}",
        );
      }

      Map<String, dynamic>? decodedData;

      try {
        final dynamic result = jsonDecode(responseBody);

        if (result is Map<String, dynamic>) {
          decodedData = result;
        } else if (result is Map) {
          decodedData = Map<String, dynamic>.from(result);
        }
      } catch (error) {
        debugPrint("Add JSON decoding error: $error");
      }

      if (!mounted) return;

      /*
       * Some existing PHP files successfully insert the
       * appointment but return invalid or extra output.
       *
       * Refresh the list first. This prevents the app from
       * wrongly saying the appointment failed when it was saved.
       */
      await fetchAppointments(showError: false);

      if (!mounted) return;

      final bool appointmentWasLoaded =
          appointments.any((appointment) {
        final String savedDate =
            appointment["appointment_date"]
                    ?.toString()
                    .trim() ??
                "";

        final String savedTitle =
            appointment["title"]?.toString().trim() ?? "";

        return savedDate ==
                formatDateForDatabase(newDate) &&
            savedTitle.toLowerCase() ==
                titleController.text
                    .trim()
                    .toLowerCase();
      });

      final bool serverSaysSuccess =
          decodedData?["success"] == true;

      if (serverSaysSuccess || appointmentWasLoaded) {
        final String successMessage =
            decodedData?["message"]?.toString() ??
                "Appointment added successfully.";

        clearAppointmentForm();

        setState(() {
          selectedCalendarDay = DateTime(
            newDate.year,
            newDate.month,
            newDate.day,
          );

          focusedDay = selectedCalendarDay;
        });

        showMessage(successMessage);
      } else {
        showMessage(
          decodedData?["message"]?.toString() ??
              "Unable to add appointment.",
        );
      }
    } catch (error) {
      debugPrint("ADD APPOINTMENT ERROR: $error");

      /*
       * Try refreshing because the PHP may already have inserted
       * the appointment before returning an unusual response.
       */
      await fetchAppointments(showError: false);

      if (!mounted) return;

      showMessage(
        "Unable to confirm the server response. Refresh the page to check the appointment.",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ==================================================
  // Update appointment
  // ==================================================

  Future<void> updateAppointment(
    String appointmentId,
  ) async {
    if (!validateAppointmentForm()) return;

    final DateTime updatedDate =
        selectedAppointmentDate!;

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_appointment.php"),
        body: {
          "appointment_id": appointmentId,
          "user_id": widget.userId.toString(),
          "title": titleController.text.trim(),
          "appointment_date": formatDateForDatabase(
            selectedAppointmentDate!,
          ),
          "appointment_time": formatTimeForDatabase(
            selectedAppointmentTime!,
          ),
          "location": locationController.text.trim(),
          "notes": notesController.text.trim(),
        },
      );

      final String responseBody = response.body.trim();

      debugPrint(
        "UPDATE STATUS: ${response.statusCode}",
      );
      debugPrint(
        "UPDATE RESPONSE: $responseBody",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server returned status ${response.statusCode}",
        );
      }

      final dynamic decodedData =
          jsonDecode(responseBody);

      if (decodedData is! Map<String, dynamic>) {
        throw Exception("Invalid update response");
      }

      if (!mounted) return;

      if (decodedData["success"] == true) {
        clearAppointmentForm();

        await fetchAppointments(showError: false);

        if (!mounted) return;

        setState(() {
          selectedCalendarDay = DateTime(
            updatedDate.year,
            updatedDate.month,
            updatedDate.day,
          );

          focusedDay = selectedCalendarDay;
        });

        showMessage(
          decodedData["message"]?.toString() ??
              "Appointment updated successfully.",
        );
      } else {
        showMessage(
          decodedData["message"]?.toString() ??
              "Unable to update appointment.",
        );
      }
    } catch (error) {
      debugPrint("Update appointment error: $error");

      if (!mounted) return;

      showMessage(
        "Unable to update appointment. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ==================================================
  // Delete appointment
  // ==================================================

  Future<void> deleteAppointment(
    String appointmentId,
  ) async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_appointment.php"),
        body: {
          "appointment_id": appointmentId,
          "user_id": widget.userId.toString(),
        },
      );

      final String responseBody = response.body.trim();

      debugPrint(
        "DELETE STATUS: ${response.statusCode}",
      );
      debugPrint(
        "DELETE RESPONSE: $responseBody",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server returned status ${response.statusCode}",
        );
      }

      final dynamic decodedData =
          jsonDecode(responseBody);

      if (decodedData is! Map<String, dynamic>) {
        throw Exception("Invalid delete response");
      }

      if (!mounted) return;

      if (decodedData["success"] == true) {
        await fetchAppointments(showError: false);

        if (!mounted) return;

        showMessage(
          decodedData["message"]?.toString() ??
              "Appointment deleted successfully.",
        );
      } else {
        showMessage(
          decodedData["message"]?.toString() ??
              "Unable to delete appointment.",
        );
      }
    } catch (error) {
      debugPrint("Delete appointment error: $error");

      if (!mounted) return;

      showMessage(
        "Unable to delete appointment. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ==================================================
  // Appointment filtering
  // ==================================================

  List<Map<String, dynamic>> getAppointmentsForDay(
    DateTime day,
  ) {
    return appointments.where((appointment) {
      final String dateText =
          appointment["appointment_date"]
                  ?.toString()
                  .trim() ??
              "";

      final DateTime? appointmentDate =
          DateTime.tryParse(dateText);

      if (appointmentDate == null) {
        return false;
      }

      return isSameDay(appointmentDate, day);
    }).toList();
  }

  List<Map<String, dynamic>>
      get selectedDayAppointments {
    return getAppointmentsForDay(
      selectedCalendarDay,
    );
  }

  // ==================================================
  // Formatting
  // ==================================================

  String formatDateForDatabase(DateTime date) {
    final String year = date.year.toString();

    final String month =
        date.month.toString().padLeft(2, "0");

    final String day =
        date.day.toString().padLeft(2, "0");

    return "$year-$month-$day";
  }

  String formatTimeForDatabase(TimeOfDay time) {
    final String hour =
        time.hour.toString().padLeft(2, "0");

    final String minute =
        time.minute.toString().padLeft(2, "0");

    return "$hour:$minute:00";
  }

  String formatReadableDate(DateTime date) {
    const List<String> weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    const List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${weekdays[date.weekday - 1]}, "
        "${date.day} ${months[date.month - 1]} "
        "${date.year}";
  }

  String formatAppointmentTime(
    String? databaseTime,
  ) {
    if (databaseTime == null ||
        databaseTime.trim().isEmpty) {
      return "No time";
    }

    final List<String> parts =
        databaseTime.split(":");

    if (parts.length < 2) {
      return databaseTime;
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return databaseTime;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    ).format(context);
  }

  DateTime getAppointmentDateTime(
    Map<String, dynamic> appointment,
  ) {
    final String dateText =
        appointment["appointment_date"]
                ?.toString()
                .trim() ??
            "";

    final String timeText =
        appointment["appointment_time"]
                ?.toString()
                .trim() ??
            "00:00:00";

    final DateTime date =
        DateTime.tryParse(dateText) ??
            DateTime(2100);

    final List<String> timeParts =
        timeText.split(":");

    final int hour = timeParts.isNotEmpty
        ? int.tryParse(timeParts[0]) ?? 0
        : 0;

    final int minute = timeParts.length > 1
        ? int.tryParse(timeParts[1]) ?? 0
        : 0;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  // ==================================================
  // Form validation
  // ==================================================

  bool validateAppointmentForm() {
    if (titleController.text.trim().isEmpty) {
      showMessage(
        "Please enter an appointment title.",
      );

      return false;
    }

    if (selectedAppointmentDate == null) {
      showMessage(
        "Please select an appointment date.",
      );

      return false;
    }

    if (selectedAppointmentTime == null) {
      showMessage(
        "Please select an appointment time.",
      );

      return false;
    }

    return true;
  }

  void clearAppointmentForm() {
    titleController.clear();
    locationController.clear();
    notesController.clear();

    selectedAppointmentDate = null;
    selectedAppointmentTime = null;
  }

  // ==================================================
  // Add appointment dialog
  // ==================================================

  void showAddAppointmentDialog() {
    clearAppointmentForm();

    final DateTime now = DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime selectedDay = DateTime(
      selectedCalendarDay.year,
      selectedCalendarDay.month,
      selectedCalendarDay.day,
    );

    selectedAppointmentDate =
        selectedDay.isBefore(today)
            ? today
            : selectedDay;

    showAppointmentDialog();
  }

  // ==================================================
  // Edit appointment dialog
  // ==================================================

  void showEditAppointmentDialog(
    Map<String, dynamic> appointment,
  ) {
    titleController.text =
        appointment["title"]?.toString() ?? "";

    locationController.text =
        appointment["location"]?.toString() ?? "";

    notesController.text =
        appointment["notes"]?.toString() ?? "";

    selectedAppointmentDate = DateTime.tryParse(
      appointment["appointment_date"]
              ?.toString() ??
          "",
    );

    final String timeText =
        appointment["appointment_time"]
                ?.toString() ??
            "";

    final List<String> timeParts =
        timeText.split(":");

    if (timeParts.length >= 2) {
      selectedAppointmentTime = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 0,
        minute: int.tryParse(timeParts[1]) ?? 0,
      );
    } else {
      selectedAppointmentTime = null;
    }

    showAppointmentDialog(
      appointmentId:
          appointment["appointment_id"].toString(),
    );
  }

  // ==================================================
  // Add/edit dialog
  // ==================================================

  void showAppointmentDialog({
    String? appointmentId,
  }) {
    final bool isEditing =
        appointmentId != null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            Future<void> selectDate() async {
              final DateTime now =
                  DateTime.now();

              final DateTime today =
                  DateTime(
                now.year,
                now.month,
                now.day,
              );

              DateTime firstAllowedDate =
                  today;

              if (isEditing &&
                  selectedAppointmentDate != null &&
                  selectedAppointmentDate!
                      .isBefore(today)) {
                firstAllowedDate =
                    selectedAppointmentDate!;
              }

              DateTime initialDate =
                  selectedAppointmentDate ??
                      today;

              if (initialDate
                  .isBefore(firstAllowedDate)) {
                initialDate =
                    firstAllowedDate;
              }

              final DateTime? pickedDate =
                  await showDatePicker(
                context: dialogContext,
                initialDate: initialDate,
                firstDate: firstAllowedDate,
                lastDate:
                    DateTime(2035, 12, 31),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(
                      colorScheme:
                          const ColorScheme.light(
                        primary:
                            primaryOrange,
                        onPrimary:
                            Colors.white,
                        onSurface: darkText,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                setDialogState(() {
                  selectedAppointmentDate =
                      pickedDate;
                });
              }
            }

            Future<void> selectTime() async {
              final TimeOfDay? pickedTime =
                  await showTimePicker(
                context: dialogContext,
                initialTime:
                    selectedAppointmentTime ??
                        TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(
                      colorScheme:
                          const ColorScheme.light(
                        primary:
                            primaryOrange,
                        onPrimary:
                            Colors.white,
                        onSurface: darkText,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null) {
                setDialogState(() {
                  selectedAppointmentTime =
                      pickedTime;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              title: Text(
                isEditing
                    ? "Edit Appointment"
                    : "Add Appointment",
                style: const TextStyle(
                  color: darkText,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      buildDialogTextField(
                        controller:
                            titleController,
                        label:
                            "Appointment title",
                        hint:
                            "Example: Doctor appointment",
                        icon: Icons
                            .event_note_outlined,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      buildDialogTextField(
                        controller:
                            locationController,
                        label: "Location",
                        hint:
                            "Example: Bishan Polyclinic",
                        icon: Icons
                            .location_on_outlined,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      buildDialogTextField(
                        controller:
                            notesController,
                        label: "Notes",
                        hint: "Optional notes",
                        icon:
                            Icons.notes_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      buildDateTimeSelector(
                        icon: Icons
                            .calendar_month_outlined,
                        text:
                            selectedAppointmentDate ==
                                    null
                                ? "Select date"
                                : formatReadableDate(
                                    selectedAppointmentDate!,
                                  ),
                        onTap: selectDate,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      buildDateTimeSelector(
                        icon: Icons
                            .access_time_outlined,
                        text:
                            selectedAppointmentTime ==
                                    null
                                ? "Select time"
                                : selectedAppointmentTime!
                                    .format(
                                    context,
                                  ),
                        onTap: selectTime,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: secondaryText,
                    ),
                  ),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryOrange,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!validateAppointmentForm()) {
                            return;
                          }

                          Navigator.pop(
                            dialogContext,
                          );

                          if (isEditing) {
                            await updateAppointment(
                              appointmentId,
                            );
                          } else {
                            await addAppointment();
                          }
                        },
                  child: Text(
                    isEditing
                        ? "Update"
                        : "Save",
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      clearAppointmentForm();
    });
  }

  Widget buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: primaryOrange,
        ),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFFFFBF5),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE6E6E6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE6E6E6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryOrange,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildDateTimeSelector({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: primaryOrange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Reminder dialog
  // ==================================================

  void showEditReminderDialog() {
    reminderController.text =
        reminderText;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            "Edit Reminder",
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: reminderController,
            minLines: 4,
            maxLines: 7,
            maxLength: 500,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  "Enter a general appointment reminder",
              filled: true,
              fillColor:
                  const Color(0xFFFFFBF5),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color: primaryOrange,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryOrange,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed: isSavingReminder
                  ? null
                  : () async {
                      final String
                          updatedText =
                          reminderController
                              .text
                              .trim();

                      if (updatedText
                          .isEmpty) {
                        showMessage(
                          "The reminder cannot be empty.",
                        );

                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      await saveReminder(
                        updatedText,
                      );
                    },
              child: const Text(
                "Save",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================================================
  // Delete confirmation
  // ==================================================

  Future<void>
      confirmDeleteAppointment(
    String appointmentId,
    String appointmentTitle,
  ) async {
    final bool? shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            "Delete Appointment",
            style: TextStyle(
              color: darkText,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$appointmentTitle"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    deleteRed,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteAppointment(
        appointmentId,
      );
    }
  }

  // ==================================================
  // Reminder card
  // ==================================================

  Widget buildReminderCard() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        10,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            primaryOrange,
            secondaryOrange,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .notifications_active_outlined,
                color: Colors.white,
                size: 27,
              ),
              SizedBox(width: 10),
              Text(
                "Reminder",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reminderText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  isSavingReminder
                      ? null
                      : showEditReminderDialog,
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    Colors.white,
              ),
              icon: isSavingReminder
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
              label: const Text(
                "Edit reminder",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Calendar
  // ==================================================

  Widget buildCalendar() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        12,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child:
          TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime(2020, 1, 1),
        lastDay:
            DateTime(2035, 12, 31),
        focusedDay: focusedDay,
        startingDayOfWeek:
            StartingDayOfWeek.monday,
        selectedDayPredicate: (day) {
          return isSameDay(
            selectedCalendarDay,
            day,
          );
        },
        eventLoader:
            getAppointmentsForDay,
        headerStyle:
            const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: primaryOrange,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: primaryOrange,
          ),
          titleTextStyle: TextStyle(
            color: darkText,
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        daysOfWeekStyle:
            const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: secondaryText,
            fontWeight:
                FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: secondaryText,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle:
              const TextStyle(
            color: darkText,
            fontSize: 15,
          ),
          weekendTextStyle:
              const TextStyle(
            color: darkText,
            fontSize: 15,
          ),
          selectedDecoration:
              const BoxDecoration(
            color: primaryOrange,
            shape: BoxShape.circle,
          ),
          selectedTextStyle:
              const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
          todayDecoration:
              BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryOrange,
              width: 2,
            ),
          ),
          todayTextStyle:
              const TextStyle(
            color: primaryOrange,
            fontWeight:
                FontWeight.bold,
          ),
          markerDecoration:
              const BoxDecoration(
            color: primaryOrange,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 1,
          markerMargin:
              const EdgeInsets.only(
            top: 1,
          ),
        ),
        onDaySelected: (
          selectedDay,
          newFocusedDay,
        ) {
          setState(() {
            selectedCalendarDay =
                selectedDay;

            focusedDay =
                newFocusedDay;
          });
        },
        onPageChanged:
            (newFocusedDay) {
          focusedDay =
              newFocusedDay;
        },
        calendarBuilders:
            CalendarBuilders(
          defaultBuilder: (
            context,
            day,
            focused,
          ) {
            final bool
                hasAppointment =
                getAppointmentsForDay(
                  day,
                ).isNotEmpty;

            if (!hasAppointment) {
              return null;
            }

            return Center(
              child: Container(
                width: 39,
                height: 39,
                decoration:
                    const BoxDecoration(
                  color: lightOrange,
                  shape:
                      BoxShape.circle,
                ),
                alignment:
                    Alignment.center,
                child: Text(
                  "${day.day}",
                  style:
                      const TextStyle(
                    color:
                        primaryOrange,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          todayBuilder: (
            context,
            day,
            focused,
          ) {
            final bool selected =
                isSameDay(
              selectedCalendarDay,
              day,
            );

            final bool
                hasAppointment =
                getAppointmentsForDay(
                  day,
                ).isNotEmpty;

            if (selected) {
              return buildSelectedCalendarCircle(
                day,
              );
            }

            return Center(
              child: Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: hasAppointment
                      ? lightOrange
                      : Colors
                          .transparent,
                  shape:
                      BoxShape.circle,
                  border: Border.all(
                    color:
                        primaryOrange,
                    width: 2,
                  ),
                ),
                alignment:
                    Alignment.center,
                child: Text(
                  "${day.day}",
                  style:
                      const TextStyle(
                    color:
                        primaryOrange,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          selectedBuilder: (
            context,
            day,
            focused,
          ) {
            return buildSelectedCalendarCircle(
              day,
            );
          },
        ),
      ),
    );
  }

  Widget buildSelectedCalendarCircle(
    DateTime day,
  ) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration:
            const BoxDecoration(
          color: primaryOrange,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          "${day.day}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // Selected date section
  // ==================================================

  Widget buildSelectedDateSection() {
    final dayAppointments =
        selectedDayAppointments;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        120,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            formatReadableDate(
              selectedCalendarDay,
            ),
            style: const TextStyle(
              color: darkText,
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (dayAppointments.isEmpty)
            buildEmptyAppointmentCard()
          else
            ...dayAppointments.map(
              buildAppointmentCard,
            ),
        ],
      ),
    );
  }

  Widget buildEmptyAppointmentCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: const Icon(
              Icons
                  .event_available_outlined,
              color: primaryOrange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No appointments on this date",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            "Tap Add Appointment to create one.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Appointment card
  // ==================================================

  Widget buildAppointmentCard(
    Map<String, dynamic> appointment,
  ) {
    final String appointmentId =
        appointment["appointment_id"]
                ?.toString() ??
            "";

    final String title =
        appointment["title"]
                ?.toString() ??
            "Appointment";

    final String time =
        formatAppointmentTime(
      appointment["appointment_time"]
          ?.toString(),
    );

    final String location =
        appointment["location"]
                ?.toString()
                .trim() ??
            "";

    final String notes =
        appointment["notes"]
                ?.toString()
                .trim() ??
            "";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration:
                    BoxDecoration(
                  color: lightOrange,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: primaryOrange,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color: darkText,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color:
                              secondaryText,
                          size: 19,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          time,
                          style:
                              const TextStyle(
                            color: darkText,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (location
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Icon(
                            Icons
                                .location_on_outlined,
                            color:
                                secondaryText,
                            size: 19,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          Expanded(
                            child: Text(
                              location,
                              style:
                                  const TextStyle(
                                color:
                                    secondaryText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notes
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Icon(
                            Icons
                                .notes_outlined,
                            color:
                                secondaryText,
                            size: 19,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          Expanded(
                            child: Text(
                              notes,
                              style:
                                  const TextStyle(
                                color:
                                    secondaryText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                              showEditAppointmentDialog(
                                appointment,
                              );
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        lightOrange,
                    foregroundColor:
                        primaryOrange,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                  ),
                  label: const Text(
                    "Edit",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                              confirmDeleteAppointment(
                                appointmentId,
                                title,
                              );
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        lightDeleteRed,
                    foregroundColor:
                        deleteRed,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                  ),
                  label: const Text(
                    "Delete",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Message
  // ==================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ==================================================
  // Main page
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        surfaceTintColor:
            Colors.white,
        title: const Text(
          "Appointments",
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                "Refresh appointments",
            onPressed: isLoading
                ? null
                : loadAppointmentPage,
            icon: const Icon(
              Icons.refresh,
              color: darkText,
              size: 27,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton:
          ElevatedButton.icon(
        onPressed: isSubmitting
            ? null
            : showAddAppointmentDialog,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              lightBlueButton,
          foregroundColor: darkText,
          elevation: 5,
          shadowColor:
              Colors.black.withOpacity(
            0.2,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 21,
            vertical: 17,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: darkText,
                ),
              )
            : const Icon(
                Icons.add,
                size: 24,
              ),
        label: const Text(
          "Add Appointment",
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryOrange,
              ),
            )
          : RefreshIndicator(
              color: primaryOrange,
              onRefresh:
                  loadAppointmentPage,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  buildReminderCard(),
                  buildCalendar(),
                  buildSelectedDateSection(),
                ],
              ),
            ),
    );
  }
}