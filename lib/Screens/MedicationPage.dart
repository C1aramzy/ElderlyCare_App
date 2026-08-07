import 'dart:convert';

import '../Services/notifiService.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'AddMedicationPage.dart';
import 'MedicationHistoryPage.dart';

class MedicationPage extends StatefulWidget {
  final int userId;

  const MedicationPage({
    super.key,
    required this.userId,
  });

  @override
  State<MedicationPage> createState() =>
      _MedicationPageState();
}

class _MedicationPageState
    extends State<MedicationPage> {
  bool isLoading = true;
  int? markingScheduleId;
  bool isDeletingMedication = false;

  String errorMessage = '';

  List<dynamic> medications = [];
  List<dynamic> todayMedications = [];

  static const String getMedicationUrl =
      'http://elderlym.atspace.cc/Medication/get_medications.php';

  static const String getTodayMedicationUrl =
      'http://elderlym.atspace.cc/Medication/get_today_medications.php';

  static const String markTakenUrl =
      'http://elderlym.atspace.cc/Medication/mark_medication_taken.php';

  static const String archiveMedicationUrl =
      'http://elderlym.atspace.cc/Medication/archive_medication.php';

  @override
  void initState() {
    super.initState();
    loadMedicationPage();
  }

  Future<void> loadMedicationPage() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final List<List<dynamic>> results =
          await Future.wait([
        _getAllMedications(),
        _getTodayMedications(),
      ]);

      if (!mounted) return;

      setState(() {
        medications = results[0];
        todayMedications = results[1];
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Connection error: $error';

        isLoading = false;
      });
    }
  }

  Future<List<dynamic>>
      _getAllMedications() async {
    final http.Response response =
        await http
            .get(
              Uri.parse(
                '$getMedicationUrl'
                '?user_id=${widget.userId}',
              ),
            )
            .timeout(
              const Duration(seconds: 15),
            );

    if (response.statusCode != 200) {
      throw Exception(
        'Medication server returned '
        '${response.statusCode}.',
      );
    }

    final dynamic data =
        jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid medication response.',
      );
    }

    if (data['success'] != true) {
      throw Exception(
        data['message']?.toString() ??
            'Unable to load medications.',
      );
    }

    final dynamic list =
        data['medications'];

    return list is List ? list : [];
  }

  Future<List<dynamic>>
      _getTodayMedications() async {
    final http.Response response =
        await http
            .get(
              Uri.parse(
                '$getTodayMedicationUrl'
                '?user_id=${widget.userId}',
              ),
            )
            .timeout(
              const Duration(seconds: 15),
            );

    if (response.statusCode != 200) {
      throw Exception(
        'Today medication server returned '
        '${response.statusCode}.',
      );
    }

    final dynamic data =
        jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid today medication response.',
      );
    }

    if (data['success'] != true) {
      throw Exception(
        data['message']?.toString() ??
            'Unable to load today’s medications.',
      );
    }

    final dynamic list =
        data['medications'];

    return list is List ? list : [];
  }

  Future<void> markMedicationTaken(
    int scheduleId,
  ) async {
    if (markingScheduleId == scheduleId) {
      return;
    }

    setState(() {
      markingScheduleId = scheduleId;
    });

    try {
      final http.Response response =
          await http
              .post(
                Uri.parse(markTakenUrl),
                body: {
                  'elderly_user_id':
                      widget.userId.toString(),
                  'schedule_id':
                      scheduleId.toString(),
                },
              )
              .timeout(
                const Duration(seconds: 15),
              );

      final dynamic data =
          jsonDecode(response.body);

      if (!mounted) return;

      final String message =
          data is Map<String, dynamic>
              ? data['message']?.toString() ??
                  'Unable to update medication.'
              : 'Unable to update medication.';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      if (data is Map<String, dynamic> &&
          data['success'] == true) {
        await loadMedicationPage();
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error updating medication: '
            '$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          markingScheduleId = null;
        });
      }
    }
  }

  Future<void>
      openAddMedicationPage() async {
    final bool? added =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddMedicationPage(
            userId: widget.userId,
          );
        },
      ),
    );

    if (added == true) {
      await loadMedicationPage();
    }
  }

  Future<void> openEditMedicationPage(
    Map<String, dynamic> medication,
  ) async {
    final bool? updated =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddMedicationPage(
            userId: widget.userId,
            medication: medication,
          );
        },
      ),
    );

    if (updated == true) {
      await loadMedicationPage();
    }
  }

  void openMedicationHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return MedicationHistoryPage(
            userId: widget.userId,
          );
        },
      ),
    );
  }

  Future<void>
      confirmArchiveMedication(
    Map<String, dynamic> medication,
  ) async {
    final String medicineName =
        medication['medicine_name']
                ?.toString() ??
            'this medication';

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Remove Medication?',
          ),
          content: Text(
            '$medicineName will be removed '
            'from the active medication list. '
            'Future reminders will stop, but '
            'existing medication history will '
            'be kept.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await archiveMedication(
        medication,
      );
    }
  }

  Future<void> archiveMedication(
    Map<String, dynamic> medication,
  ) async {
    if (isDeletingMedication) {
      return;
    }

    final int medicationId =
        int.tryParse(
          medication['medication_id']
                  ?.toString() ??
              '',
        ) ??
        0;

    if (medicationId <= 0) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid medication ID.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isDeletingMedication = true;
    });

    try {
      final http.Response response =
          await http
              .post(
                Uri.parse(
                  archiveMedicationUrl,
                ),
                body: {
                  'medication_id':
                      medicationId.toString(),
                  'elderly_user_id':
                      widget.userId.toString(),
                },
              )
              .timeout(
                const Duration(seconds: 15),
              );

      final dynamic data =
          jsonDecode(response.body);

      if (!mounted) return;

      final String message =
          data is Map<String, dynamic>
              ? data['message']?.toString() ??
                  'Unable to remove medication.'
              : 'Unable to remove medication.';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      if (data is Map<String, dynamic> &&
          data['success'] == true){

            final dynamic schedules = 
                medication['schedules'];

            if (schedules is List){
              medication['schedules'];

              if(schedules is List){
                try{
                  await NotifiService.cancelMedicationAlarms(
                    schedules: schedules,
                  );
                } catch(notificationError){
                  debugPrint(
                    'Medication removed but alarm cancellation failed.'
                    '$notificationError',
                  );
                }
              }
              await loadMedicationPage();
            }
          }

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error removing medication: '
            '$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeletingMedication = false;
        });
      }
    }
  }

  String formatTime(String time) {
    if (time.isEmpty) {
      return 'Unknown time';
    }

    final List<String> parts =
        time.split(':');

    if (parts.length < 2) {
      return time;
    }

    int hour =
        int.tryParse(parts[0]) ?? 0;

    final String minute = parts[1];

    final String period =
        hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  String formatTakenTime(
    String? dateTime,
  ) {
    if (dateTime == null ||
        dateTime.isEmpty) {
      return '';
    }

    try {
      final DateTime parsed =
          DateTime.parse(dateTime);

      final TimeOfDay time =
          TimeOfDay.fromDateTime(
        parsed,
      );

      return time.format(context);
    } catch (_) {
      return dateTime;
    }
  }

  Color getDoseStatusColor(
    String status,
  ) {
    switch (status) {
      case 'taken':
        return Colors.green;

      case 'taken_late':
        return Colors.orange;

      case 'missed':
        return Colors.red;

      case 'pending':
      default:
        return Colors.blueGrey;
    }
  }

  IconData getDoseStatusIcon(
    String status,
  ) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;

      case 'taken_late':
        return Icons.schedule;

      case 'missed':
        return Icons.cancel;

      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String getDoseStatusText(
    String status,
    String takenAt,
  ) {
    switch (status) {
      case 'taken':
        return 'Taken at '
            '${formatTakenTime(takenAt)}';

      case 'taken_late':
        return 'Taken late at '
            '${formatTakenTime(takenAt)}';

      case 'missed':
        return 'Missed';

      case 'pending':
      default:
        return 'Pending';
    }
  }

  String getTodayProgressText() {
    if (todayMedications.isEmpty) {
      return 'No medication scheduled today';
    }

    final int takenCount =
        todayMedications.where(
      (dynamic item) {
        if (item
            is! Map<String, dynamic>) {
          return false;
        }

        final String status =
            item['dose_status']
                    ?.toString() ??
                'pending';

        return status == 'taken' ||
            status == 'taken_late';
      },
    ).length;

    return '$takenCount of '
        '${todayMedications.length} taken';
  }

  String getMedicationType(
    Map<String, dynamic> medication,
  ) {
    return medication['medication_type']
            ?.toString() ??
        'long_term';
  }

  Widget buildMedicationTypeBadge(
    String medicationType,
  ) {
    final bool isChronic =
        medicationType != 'short_term';

    final Color badgeColor =
        isChronic
            ? Colors.blue
            : Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        isChronic
            ? 'Chronic'
            : 'Acute',
        style: TextStyle(
          color: isChronic
              ? Colors.blue[800]
              : Colors.purple[800],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void showLargeMedicationImage({
    required String imageUrl,
    required String medicineName,
  }) {
    if (imageUrl.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return Dialog(
          insetPadding:
              const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.only(
                    left: 18,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          medicineName,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color:
                        const Color(0xFFF5F6FA),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons
                                .broken_image_outlined,
                            size: 72,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMedicationImage({
    required String? imageUrl,
    required String medicineName,
    double size = 112,
  }) {
    final bool hasImage =
        imageUrl != null &&
        imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasImage
          ? () {
              showLargeMedicationImage(
                imageUrl: imageUrl,
                medicineName:
                    medicineName,
              );
            }
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(
            alpha: 0.12,
          ),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: Colors.orange.withValues(
              alpha: 0.2,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Icon(
                    Icons.medication,
                    color:
                        Colors.orange[700],
                    size: size * 0.43,
                  );
                },
              )
            : Icon(
                Icons.medication,
                color: Colors.orange[700],
                size: size * 0.43,
              ),
      ),
    );
  }

  Widget buildTodayMedicationCard(
    Map<String, dynamic> medication,
  ) {
    final String status =
        medication['dose_status']
                ?.toString() ??
            'pending';

    final bool alreadyTaken =
        status == 'taken' ||
        status == 'taken_late';

    final int scheduleId =
        int.tryParse(
          medication['schedule_id']
                  ?.toString() ??
              '',
        ) ??
        0;

    final String takenAt =
        medication['taken_at']
                ?.toString() ??
            '';

    final String imageUrl =
        medication['medicine_image_url']
                ?.toString() ??
            '';

    final String medicineName =
        medication['medicine_name']
                ?.toString() ??
            'Medicine';

    final String dosage =
        medication['dosage']
                ?.toString() ??
            '';

    final String instructions =
        medication['instructions']
                ?.toString() ??
            '';

    final String medicationType =
        getMedicationType(medication);

    final Color statusColor =
        getDoseStatusColor(status);

    final bool isThisDoseUpdating =
        markingScheduleId == scheduleId;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              buildMedicationImage(
                imageUrl: imageUrl,
                medicineName:
                    medicineName,
                size: 120,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    buildMedicationTypeBadge(
                      medicationType,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medicineName,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (dosage.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        dosage,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Colors.grey[800],
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                    if (instructions
                        .isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        instructions,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm,
                          size: 20,
                          color:
                              Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formatTime(
                              medication[
                                          'reminder_time']
                                      ?.toString() ??
                                  '',
                            ),
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (alreadyTaken ||
              status == 'missed')
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color:
                    statusColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    getDoseStatusIcon(
                      status,
                    ),
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getDoseStatusText(
                        status,
                        takenAt,
                      ),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    markingScheduleId != null ||
                            scheduleId <= 0
                        ? null
                        : () {
                            markMedicationTaken(
                              scheduleId,
                            );
                          },
                icon: isThisDoseUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle,
                      ),
                label: Text(
                  isThisDoseUpdating
                      ? 'Updating...'
                      : 'Mark as Taken',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange,
                  foregroundColor:
                      Colors.white,
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
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAllMedicationCard(
    Map<String, dynamic> medication,
  ) {
    final List<dynamic> schedules =
        medication['schedules'] is List
            ? medication['schedules']
            : [];

    final String? imageUrl =
        medication['medicine_image_url']
            ?.toString();

    final String medicineName =
        medication['medicine_name']
                ?.toString() ??
            'Unnamed Medicine';

    final dynamic remaining =
        medication['remaining_quantity'];

    final int lowStockThreshold =
        int.tryParse(
          medication['low_stock_threshold']
                  ?.toString() ??
              '5',
        ) ??
        5;

    final int? remainingQuantity =
        remaining == null
            ? null
            : int.tryParse(
                remaining.toString(),
              );

    final bool lowStock =
        remainingQuantity != null &&
        remainingQuantity <=
            lowStockThreshold;

    final String dosage =
        medication['dosage']
                ?.toString() ??
            '';

    final String instructions =
        medication['instructions']
                ?.toString() ??
            '';

    final String medicationType =
        getMedicationType(medication);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          buildMedicationImage(
            imageUrl: imageUrl,
            medicineName:
                medicineName,
            size: 108,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        medicineName,
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip:
                          'Medication options',
                      onSelected:
                          (String value) {
                        if (value == 'edit') {
                          openEditMedicationPage(
                            medication,
                          );
                        } else if (value ==
                            'remove') {
                          confirmArchiveMedication(
                            medication,
                          );
                        }
                      },
                      itemBuilder:
                          (
                        BuildContext context,
                      ) {
                        return const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .edit_outlined,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Edit Medication',
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                      Colors.red,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Remove Medication',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                buildMedicationTypeBadge(
                  medicationType,
                ),
                if (dosage.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    dosage,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
                if (instructions
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    instructions,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      schedules.map<Widget>(
                    (dynamic schedule) {
                      if (schedule
                          is! Map<String,
                              dynamic>) {
                        return const SizedBox
                            .shrink();
                      }

                      final String label =
                          schedule['time_label']
                                  ?.toString() ??
                              '';

                      final String time =
                          formatTime(
                        schedule['reminder_time']
                                ?.toString() ??
                            '',
                      );

                      return Chip(
                        avatar: Icon(
                          label == 'PM'
                              ? Icons
                                  .nightlight_outlined
                              : Icons
                                  .wb_sunny_outlined,
                          size: 17,
                        ),
                        label: Text(
                          label.isEmpty
                              ? time
                              : '$label • $time',
                        ),
                      );
                    },
                  ).toList(),
                ),
                if (remainingQuantity !=
                    null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        lowStock
                            ? Icons
                                .warning_amber
                            : Icons
                                .inventory_2_outlined,
                        size: 18,
                        color: lowStock
                            ? Colors.red
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lowStock
                              ? 'Low stock: '
                                  '$remainingQuantity '
                                  'remaining'
                              : 'Remaining: '
                                  '$remainingQuantity',
                          style: TextStyle(
                            color: lowStock
                                ? Colors.red
                                : Colors.grey[700],
                            fontWeight:
                                FontWeight.w600,
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
    );
  }

  Widget buildHistoryCard() {
    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: openMedicationHistory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.05,
              ),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.blueGrey,
              size: 32,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View previous medication records.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Medication',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : loadMedicationPage,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: openAddMedicationPage,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label:
            const Text('Add Medicine'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 54,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          errorMessage,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              loadMedicationPage,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label:
                              const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadMedicationPage,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    children: [
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          18,
                        ),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(
                                0xFFFF9800,
                              ),
                              Color(
                                0xFFFFB74D,
                              ),
                            ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Today’s Medication',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 21,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              getTodayProgressText(),
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      if (todayMedications
                          .isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(
                            20,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child:
                              const Column(
                            children: [
                              Icon(
                                Icons
                                    .event_available,
                                size: 46,
                                color:
                                    Colors.grey,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'No medication scheduled for today.',
                                textAlign:
                                    TextAlign
                                        .center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...todayMedications
                            .map(
                          (dynamic item) {
                            if (item
                                is! Map<String,
                                    dynamic>) {
                              return const SizedBox
                                  .shrink();
                            }

                            return buildTodayMedicationCard(
                              item,
                            );
                          },
                        ),
                      const SizedBox(
                        height: 22,
                      ),
                      const Text(
                        'All Medicines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (medications.isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(
                            24,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .medication_outlined,
                                size: 64,
                                color:
                                    Colors.grey[
                                        400],
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              const Text(
                                'No medication added yet.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Tap “Add Medicine” to create the first reminder.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey[
                                          600],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...medications.map(
                          (dynamic item) {
                            if (item
                                is! Map<String,
                                    dynamic>) {
                              return const SizedBox
                                  .shrink();
                            }

                            return buildAllMedicationCard(
                              item,
                            );
                          },
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      buildHistoryCard(),
                      const SizedBox(
                        height: 90,
                      ),
                    ],
                  ),
                ),
    );
  }
}