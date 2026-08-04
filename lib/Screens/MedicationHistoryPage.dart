import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicationHistoryPage extends StatefulWidget {
  final int userId;

  const MedicationHistoryPage({
    super.key,
    required this.userId,
  });

  @override
  State<MedicationHistoryPage> createState() =>
      _MedicationHistoryPageState();
}

class _MedicationHistoryPageState
    extends State<MedicationHistoryPage> {
  static const String historyUrl =
      'http://elderlym.atspace.cc/Medication/get_medication_history.php';

  bool isLoading = true;
  String errorMessage = '';

  List<dynamic> archivedMedications = [];

  @override
  void initState() {
    super.initState();
    fetchMedicationHistory();
  }

  Future<void> fetchMedicationHistory() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$historyUrl?user_id=${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}.',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response from server.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Unable to load medication records.',
        );
      }

      final dynamic medicines =
          decoded['medications'];

      if (!mounted) return;

      setState(() {
        archivedMedications =
            medicines is List ? medicines : [];

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load medication records: $e';

        isLoading = false;
      });
    }
  }

  String formatDate(String? dateText) {
    if (dateText == null ||
        dateText.trim().isEmpty) {
      return 'Not recorded';
    }

    try {
      final date = DateTime.parse(dateText);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return dateText;
    }
  }

  String formatTime(String? timeText) {
    if (timeText == null ||
        timeText.trim().isEmpty) {
      return 'Unknown time';
    }

    final parts = timeText.split(':');

    if (parts.length < 2) {
      return timeText;
    }

    int hour =
        int.tryParse(parts[0]) ?? 0;

    final minute = parts[1];

    final period =
        hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  Widget buildMedicationImage(
    String? imageUrl,
  ) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null &&
              imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.medication,
                  color: Colors.orange,
                  size: 38,
                );
              },
            )
          : const Icon(
              Icons.medication,
              color: Colors.orange,
              size: 38,
            ),
    );
  }

  Widget buildScheduleChips(
    List<dynamic> schedules,
  ) {
    if (schedules.isEmpty) {
      return Text(
        'No reminder schedule recorded',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: schedules.map<Widget>(
        (dynamic schedule) {
          if (schedule
              is! Map<String, dynamic>) {
            return const SizedBox.shrink();
          }

          final String label =
              schedule['time_label']
                      ?.toString() ??
                  '';

          final String time =
              formatTime(
            schedule['reminder_time']
                ?.toString(),
          );

          return Chip(
            avatar: const Icon(
              Icons.access_time,
              size: 16,
            ),
            label: Text(
              label.isEmpty
                  ? time
                  : '$label • $time',
            ),
          );
        },
      ).toList(),
    );
  }

  Widget buildMedicationRecordCard(
    Map<String, dynamic> medication,
  ) {
    final String name =
        medication['medicine_name']
                ?.toString() ??
            'Unnamed Medicine';

    final String dosage =
        medication['dosage']
                ?.toString() ??
            '';

    final String instructions =
        medication['instructions']
                ?.toString() ??
            '';

    final String? imageUrl =
        medication['medicine_image_url']
            ?.toString();

    final String startDate =
        formatDate(
      medication['start_date']?.toString(),
    );

    final String endDate =
        formatDate(
      medication['end_date']?.toString(),
    );

    final List<dynamic> schedules =
        medication['schedules'] is List
            ? medication['schedules']
            : [];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
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
                imageUrl,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (dosage.isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        dosage,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Colors.grey[700],
                        ),
                      ),
                    ],

                    if (instructions
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        instructions,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF8F9FC,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.green,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Started',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      startDate,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 22),

                Row(
                  children: [
                    const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.red,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Stopped',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      endDate,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Previous Schedule',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          buildScheduleChips(
            schedules,
          ),
        ],
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
          'Previous Medication Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
                fetchMedicationHistory,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
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
                          size: 55,
                          color: Colors.red,
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
                              fetchMedicationHistory,
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
                      fetchMedicationHistory,
                  child:
                      archivedMedications
                              .isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.all(
                                24,
                              ),
                              children: [
                                const SizedBox(
                                  height: 130,
                                ),

                                Icon(
                                  Icons
                                      .history_rounded,
                                  size: 80,
                                  color: Colors
                                      .grey[400],
                                ),

                                const SizedBox(
                                  height: 18,
                                ),

                                const Text(
                                  'No previous medication records.',
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'Medicines that are removed from the active list will appear here.',
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      TextStyle(
                                    fontSize: 15,
                                    color: Colors
                                        .grey[600],
                                  ),
                                ),
                              ],
                            )
                          : ListView(
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
                                          0xFF607D8B,
                                        ),
                                        Color(
                                          0xFF90A4AE,
                                        ),
                                      ],
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                  child:
                                      const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'Past Medication',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              21,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 6,
                                      ),
                                      Text(
                                        'Medicines that are no longer active',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height: 18,
                                ),

                                ...archivedMedications
                                    .map(
                                  (dynamic item) {
                                    if (item
                                        is! Map<String,
                                            dynamic>) {
                                      return const SizedBox
                                          .shrink();
                                    }

                                    return buildMedicationRecordCard(
                                      item,
                                    );
                                  },
                                ),

                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                ),
    );
  }
}