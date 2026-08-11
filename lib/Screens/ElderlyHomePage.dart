import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Services/mmWaveService.dart';
<<<<<<< HEAD

=======
>>>>>>> origin/main
import 'ContactHelplinePage.dart';
import 'ElderlyAppointmentPage.dart';
import 'ElderlyProfilePage.dart';
import 'LoginPage.dart';
import 'MedicationPage.dart';
import 'RobotCameraPage.dart';
<<<<<<< HEAD
import 'VibrationSensorPage.dart'; // NEW
=======
>>>>>>> origin/main

class ElderlyHomePage extends StatefulWidget {
  final int userId;
  final String fullName;

  const ElderlyHomePage({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  State<ElderlyHomePage> createState() =>
      _ElderlyHomePageState();
}

class _ElderlyHomePageState
    extends State<ElderlyHomePage> {
  Map<String, dynamic>? currentStatus;
<<<<<<< HEAD

=======
>>>>>>> origin/main
  List<dynamic> motionData = [];

  bool isLoading = true;
  bool isRefreshing = false;

  String errorMessage = '';

  Timer? _refreshTimer;

  // ==================================================
  // Page lifecycle
  // ==================================================

  @override
  void initState() {
    super.initState();

    fetchMotionData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          fetchMotionData(
            showLoading: false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ==================================================
  // Fetch motion sensor information
  // ==================================================

  Future<void> fetchMotionData({
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    } else {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      final Map<String, dynamic> data =
          await MmWaveService.getMotionData(
        widget.userId,
      );

      debugPrint(
        'Logged-in user ID: ${widget.userId}',
      );

      debugPrint(
        'Motion data: $data',
      );

      if (!mounted) return;

      if (data['success'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'Unable to retrieve motion sensor data.',
        );
      }

      final dynamic receivedStatus =
          data['current_status'];

      final dynamic receivedEvents =
          data['events'];

      setState(() {
        if (receivedStatus is Map) {
          currentStatus =
              Map<String, dynamic>.from(
            receivedStatus,
          );
        } else {
          currentStatus = null;
        }

        if (receivedEvents is List) {
<<<<<<< HEAD
          motionData = receivedEvents;
=======
          motionData =
              receivedEvents;
>>>>>>> origin/main
        } else {
          motionData = [];
        }

        isLoading = false;
        isRefreshing = false;
        errorMessage = '';
      });
    } catch (e) {
      debugPrint(
        'Motion data error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;

        if (showLoading ||
            currentStatus == null) {
          errorMessage =
              'Connection error: $e';
        }
      });
    }
  }

  // ==================================================
  // Sensor status helpers
  // ==================================================

  String getStatusTitle(
    String status,
  ) {
    switch (status) {
      case 'normal_activity':
        return 'Normal Activity';

      case 'stationary':
        return 'Person Stationary';

      case 'no_presence':
        return 'No Presence Detected';

      case 'possible_fall':
        return 'Checking Possible Fall';

      case 'fall_detected':
        return 'Fall Detected';

      case 'movement_resumed':
        return 'Movement Resumed';

      case 'sensor_offline':
        return 'Sensor Offline';

      default:
        return 'Status Unknown';
    }
  }

  IconData getStatusIcon(
    String status,
  ) {
    switch (status) {
      case 'normal_activity':
        return Icons.directions_walk;

      case 'stationary':
        return Icons.accessibility_new;

      case 'no_presence':
        return Icons.person_off;

      case 'possible_fall':
        return Icons.warning_amber_rounded;

      case 'fall_detected':
        return Icons.emergency;

      case 'movement_resumed':
        return Icons.check_circle_outline;

      case 'sensor_offline':
        return Icons.wifi_off;

      default:
        return Icons.sensors;
    }
  }

  Color getStatusColor(
    String status,
  ) {
    switch (status) {
      case 'normal_activity':
        return Colors.green;

      case 'stationary':
        return Colors.blueGrey;

      case 'no_presence':
        return Colors.orange;

      case 'possible_fall':
        return Colors.deepOrange;

      case 'fall_detected':
        return Colors.red;

      case 'movement_resumed':
        return Colors.blue;

      case 'sensor_offline':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String formatEventType(
    String eventType,
  ) {
    switch (eventType) {
      case 'normal_activity':
        return 'Normal Activity';

      case 'stationary':
        return 'Person Stationary';

      case 'no_presence':
        return 'No Presence Detected';

      case 'possible_fall':
        return 'Possible Fall';

      case 'fall_detected':
        return 'Fall Detected';

      case 'movement_resumed':
        return 'Movement Resumed';

      case 'sensor_offline':
        return 'Sensor Offline';

      case 'fall detected':
        return 'Fall Detected';

      case 'motion':
        return 'Motion Detected';

      case 'no motion':
        return 'No Motion Detected';

      case 'recovered':
        return 'Recovered';

      default:
        final String formatted =
            eventType
                .replaceAll('_', ' ')
                .trim();

        if (formatted.isEmpty) {
          return 'Unknown Activity';
        }

        return formatted
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty
                      ? word
                      : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  // ==================================================
  // Logout
  // ==================================================

  void logout() {
    _refreshTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginPage(),
      ),
    );
  }

  // ==================================================
  // Emergency help request
  // ==================================================

<<<<<<< HEAD
  Future<void> createHelpRequest() async {
    try {
      debugPrint(
        '====================================',
      );

      debugPrint(
        'CREATING HELP REQUEST',
      );

      debugPrint(
        'Elderly ID: ${widget.userId}',
      );

      debugPrint(
        'Elderly Name: ${widget.fullName}',
      );

      debugPrint(
        '====================================',
      );

      final response = await http.post(
=======
  Future<void>
      createHelpRequest() async {
    try {
      final response =
          await http.post(
>>>>>>> origin/main
        Uri.parse(
          'http://elderlym.atspace.cc/create_help_request.php',
        ),
        body: {
          'elderly_id':
<<<<<<< HEAD
              widget.userId.toString(),
=======
              widget.userId
                  .toString(),
>>>>>>> origin/main

          'elderly_name':
              widget.fullName,

          'request_type':
              'emergency',

<<<<<<< HEAD
          'message':
=======
          'description':
>>>>>>> origin/main
              'Immediate assistance needed',

          'location':
              'Unknown',
        },
<<<<<<< HEAD
      ).timeout(
        const Duration(seconds: 10),
      );

      debugPrint(
        '====================================',
      );

      debugPrint(
        'HELP REQUEST RESPONSE',
      );

      debugPrint(
        'Status code: ${response.statusCode}',
      );

      debugPrint(
        'Response body: ${response.body}',
      );

      debugPrint(
        '====================================',
      );

      if (response.statusCode != 200) {
=======
      );

      if (response.statusCode !=
          200) {
>>>>>>> origin/main
        throw Exception(
          'Server returned status ${response.statusCode}.',
        );
      }

      final dynamic decodedData =
          jsonDecode(
        response.body,
      );

      if (decodedData
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response from server.',
        );
      }

      if (!mounted) return;

<<<<<<< HEAD
      if (decodedData['success'] == true) {
        debugPrint(
          'HELP REQUEST CREATED SUCCESSFULLY',
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'An alert for help has been sent out. Please be patient.',
            ),
            backgroundColor:
                Colors.green,
            duration:
                Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              decodedData['message']
                      ?.toString() ??
                  'Unable to send help request.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '====================================',
      );

      debugPrint(
        'HELP REQUEST ERROR',
      );

      debugPrint(
        '$e',
      );

      debugPrint(
        '====================================',
      );

=======
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            decodedData['message']
                    ?.toString() ??
                'Help request submitted.',
          ),
        ),
      );
    } catch (e) {
>>>>>>> origin/main
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error creating help request: $e',
          ),
<<<<<<< HEAD
          backgroundColor:
              Colors.red,
=======
>>>>>>> origin/main
        ),
      );
    }
  }

  // ==================================================
<<<<<<< HEAD
  // Open Vibration Sensor Page
  // ==================================================

  void openVibrationSensorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const VibrationSensorPage(),
      ),
    );
  }

  // ==================================================
=======
>>>>>>> origin/main
  // Main page
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final String statusCode =
        currentStatus?[
<<<<<<< HEAD
                'current_status']
            ?.toString() ??
        'unknown';

    final String statusDescription =
=======
                    'current_status']
                ?.toString() ??
            'unknown';

    final String
        statusDescription =
>>>>>>> origin/main
        currentStatus?[
                    'status_description']
                ?.toString() ??
            'No monitoring information available.';

<<<<<<< HEAD
    final String lastSensorUpdate =
=======
    final String
        lastSensorUpdate =
>>>>>>> origin/main
        currentStatus?[
                    'last_sensor_update']
                ?.toString() ??
            'No update received';

    final bool sensorOnline =
        currentStatus?[
                    'sensor_online']
                ?.toString() ==
            '1';

    return Scaffold(
      backgroundColor:
<<<<<<< HEAD
          const Color(0xFFF5F6FA),

=======
          const Color(
        0xFFF5F6FA,
      ),
>>>>>>> origin/main
      appBar: AppBar(
        title: const Text(
          'Elderly Home',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
<<<<<<< HEAD

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black87,

        elevation: 0,

=======
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
>>>>>>> origin/main
        actions: [
          if (isRefreshing)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
<<<<<<< HEAD
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh,
              ),
              onPressed: () {
                fetchMotionData();
              },
            ),

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: logout,
          ),
        ],
      ),

=======
              tooltip:
                  'Refresh',
              icon:
                  const Icon(
                Icons.refresh,
              ),
              onPressed:
                  () {
                fetchMotionData();
              },
            ),
          IconButton(
            tooltip:
                'Logout',
            icon:
                const Icon(
              Icons.logout,
            ),
            onPressed:
                logout,
          ),
        ],
      ),
>>>>>>> origin/main
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
<<<<<<< HEAD
          : errorMessage.isNotEmpty &&
                  currentStatus == null
=======
          : errorMessage
                      .isNotEmpty &&
                  currentStatus ==
                      null
>>>>>>> origin/main
              ? buildErrorDisplay()
              : RefreshIndicator(
                  onRefresh: () {
                    return fetchMotionData(
<<<<<<< HEAD
                      showLoading: false,
                    );
                  },

=======
                      showLoading:
                          false,
                    );
                  },
>>>>>>> origin/main
                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
<<<<<<< HEAD

=======
>>>>>>> origin/main
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
<<<<<<< HEAD

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

=======
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
>>>>>>> origin/main
                      children: [
                        const Text(
                          'Good day 👋',
                          style:
                              TextStyle(
<<<<<<< HEAD
                            fontSize: 26,
=======
                            fontSize:
                                26,
>>>>>>> origin/main
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Welcome back, ${widget.fullName}!',
                          style:
                              TextStyle(
<<<<<<< HEAD
                            fontSize: 16,
=======
                            fontSize:
                                16,
>>>>>>> origin/main
                            color:
                                Colors.grey[
                                    700],
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        buildMonitoringStatusCard(
                          statusCode:
                              statusCode,
                          statusDescription:
                              statusDescription,
                          lastSensorUpdate:
                              lastSensorUpdate,
                          sensorOnline:
                              sensorOnline,
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        buildEmergencyButton(),

                        const SizedBox(
                          height: 24,
                        ),

<<<<<<< HEAD
                        // ==================================================
                        // Feature Cards
                        // ==================================================

                        GridView.count(
                          crossAxisCount:
                              2,

                          shrinkWrap:
                              true,

                          physics:
                              const NeverScrollableScrollPhysics(),

                          crossAxisSpacing:
                              12,

                          mainAxisSpacing:
                              12,

                          childAspectRatio:
                              1.35,

                          children: [
                            // ------------------------------
                            // Motion Sensor
                            // ------------------------------
=======
                        GridView.count(
                          crossAxisCount:
                              2,
                          shrinkWrap:
                              true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisSpacing:
                              12,
                          mainAxisSpacing:
                              12,
                          childAspectRatio:
                              1.35,
                          children: [
>>>>>>> origin/main
                            featureCard(
                              icon:
                                  sensorOnline
                                      ? Icons.sensors
                                      : Icons.sensors_off,
<<<<<<< HEAD

                              title:
                                  'Motion Sensor',

=======
                              title:
                                  'Motion Sensor',
>>>>>>> origin/main
                              subtitle:
                                  sensorOnline
                                      ? 'Active'
                                      : 'Offline',
<<<<<<< HEAD

=======
>>>>>>> origin/main
                              color:
                                  sensorOnline
                                      ? Colors.green
                                      : Colors.grey,
                            ),

<<<<<<< HEAD
                            // ------------------------------
                            // Vibration Sensor
                            // ------------------------------
                            featureCard(
                              icon:
                                  Icons.vibration,

                              title:
                                  'Vibration Sensor',

                              subtitle:
                                  'View Sensor Activity',

                              color:
                                  Colors.purple,

                              onTap:
                                  openVibrationSensorPage,
                            ),

                            // ------------------------------
                            // Medication
                            // ------------------------------
                            featureCard(
                              icon:
                                  Icons.medication,

                              title:
                                  'Medication',

                              subtitle:
                                  'View Medications',

                              color:
                                  Colors.orange,

                              onTap: () {
=======
                            featureCard(
                              icon:
                                  Icons.medication,
                              title:
                                  'Medication',
                              subtitle:
                                  'View Medications',
                              color:
                                  Colors.orange,
                              onTap:
                                  () {
>>>>>>> origin/main
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            MedicationPage(
                                      userId:
                                          widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),

<<<<<<< HEAD
                            // ------------------------------
                            // Appointments
                            // ------------------------------
                            featureCard(
                              icon:
                                  Icons.calendar_month,

                              title:
                                  'Appointments',

                              subtitle:
                                  'View Appointments',

                              color:
                                  Colors.blue,

                              onTap: () {
=======
                            featureCard(
                              icon:
                                  Icons.calendar_month,
                              title:
                                  'Appointments',
                              subtitle:
                                  'View Appointments',
                              color:
                                  Colors.blue,
                              onTap:
                                  () {
>>>>>>> origin/main
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            AppointmentPage(
                                      userId:
                                          widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),

<<<<<<< HEAD
                            // ------------------------------
                            // Emergency Camera
                            // ------------------------------
                            featureCard(
                              icon:
                                  Icons.videocam_rounded,

                              title:
                                  'Emergency Camera',

                              subtitle:
                                  'View Live Camera Feed',

                              color:
                                  Colors.red,

                              onTap: () {
=======
                            featureCard(
                              icon:
                                  Icons.videocam_rounded,
                              title:
                                  'Emergency Camera',
                              subtitle:
                                  'View Live Camera Feed',
                              color:
                                  Colors.red,
                              onTap:
                                  () {
>>>>>>> origin/main
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const RobotCameraPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

<<<<<<< HEAD
                        // ==================================================
                        // Recent Motion Activity
                        // ==================================================

=======
>>>>>>> origin/main
                        const Text(
                          'Recent Motion Activity',
                          style:
                              TextStyle(
<<<<<<< HEAD
                            fontSize: 20,
=======
                            fontSize:
                                20,
>>>>>>> origin/main
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildMotionHistory(),

                        const SizedBox(
                          height: 24,
                        ),

<<<<<<< HEAD
                        // ==================================================
                        // Quick Actions
                        // ==================================================

=======
>>>>>>> origin/main
                        const Text(
                          'Quick Actions',
                          style:
                              TextStyle(
<<<<<<< HEAD
                            fontSize: 20,
=======
                            fontSize:
                                20,
>>>>>>> origin/main
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  actionButton(
                                icon:
                                    Icons.help,
<<<<<<< HEAD

                                label:
                                    'Contact Helpline',

                                color:
                                    Colors.pink,

                                onTap: () {
=======
                                label:
                                    'Contact Helpline',
                                color:
                                    Colors.pink,
                                onTap:
                                    () {
>>>>>>> origin/main
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ContactHelplinePage(
                                        userId:
                                            widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                                  actionButton(
                                icon:
                                    Icons.person,
<<<<<<< HEAD

                                label:
                                    'View Profile',

                                color:
                                    Colors.blueGrey,

                                onTap: () {
=======
                                label:
                                    'View Profile',
                                color:
                                    Colors.blueGrey,
                                onTap:
                                    () {
>>>>>>> origin/main
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ElderlyProfilePage(
                                        userId:
                                            widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ==================================================
  // Error display
  // ==================================================

  Widget buildErrorDisplay() {
    return Center(
      child: Padding(
        padding:
<<<<<<< HEAD
            const EdgeInsets.all(20),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.red,
              size: 50,
=======
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color:
                  Colors.red,
              size:
                  50,
>>>>>>> origin/main
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              errorMessage,
              textAlign:
                  TextAlign.center,
<<<<<<< HEAD

              style:
                  const TextStyle(
                color: Colors.red,
=======
              style:
                  const TextStyle(
                color:
                    Colors.red,
>>>>>>> origin/main
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton.icon(
<<<<<<< HEAD
              onPressed: () {
                fetchMotionData();
              },

=======
              onPressed:
                  () {
                fetchMotionData();
              },
>>>>>>> origin/main
              icon:
                  const Icon(
                Icons.refresh,
              ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
              label:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Monitoring status card
  // ==================================================

<<<<<<< HEAD
  Widget buildMonitoringStatusCard({
=======
  Widget
      buildMonitoringStatusCard({
>>>>>>> origin/main
    required String statusCode,
    required String statusDescription,
    required String lastSensorUpdate,
    required bool sensorOnline,
  }) {
    final Color statusColor =
        getStatusColor(
      statusCode,
    );

    return Container(
<<<<<<< HEAD
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

=======
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
>>>>>>> origin/main
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            statusColor,
            statusColor.withValues(
              alpha: 0.72,
            ),
          ],
        ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
      child:
          currentStatus == null
              ? const Text(
                  'No sensor status available yet.',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        16,
                  ),
                )
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
<<<<<<< HEAD

=======
>>>>>>> origin/main
                  children: [
                    const Text(
                      'Monitoring Status',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Icon(
                          getStatusIcon(
                            statusCode,
                          ),
                          color:
                              Colors.white,
                          size:
                              30,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              Text(
                            getStatusTitle(
                              statusCode,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  23,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      statusDescription,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            15,
                        height:
                            1.35,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      'Last Update: $lastSensorUpdate',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            13,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color:
                              sensorOnline
                                  ? Colors.greenAccent
                                  : Colors.white70,
                          size:
                              12,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          sensorOnline
                              ? 'Sensor Online'
                              : 'Sensor Offline',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  // ==================================================
  // Emergency button
  // ==================================================

  Widget buildEmergencyButton() {
    return Container(
<<<<<<< HEAD
      width: double.infinity,

      decoration:
          BoxDecoration(
        color: Colors.red,

=======
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.red,
>>>>>>> origin/main
        borderRadius:
            BorderRadius.circular(
          20,
        ),
<<<<<<< HEAD

        boxShadow: [
          BoxShadow(
            color:
                Colors.red.withValues(
              alpha: 0.3,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
=======
        boxShadow: [
          BoxShadow(
            color:
                Colors.red
                    .withValues(
              alpha:
                  0.3,
            ),
            blurRadius:
                12,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child:
          Material(
        color:
            Colors.transparent,
        child:
            InkWell(
>>>>>>> origin/main
          borderRadius:
              BorderRadius.circular(
            20,
          ),
<<<<<<< HEAD

          onTap:
              createHelpRequest,

          child: const Padding(
            padding:
                EdgeInsets.all(20),

            child: Row(
=======
          onTap:
              createHelpRequest,
          child:
              const Padding(
            padding:
                EdgeInsets.all(
              20,
            ),
            child:
                Row(
>>>>>>> origin/main
              children: [
                Icon(
                  Icons.emergency,
                  color:
                      Colors.white,
<<<<<<< HEAD
                  size: 40,
=======
                  size:
                      40,
>>>>>>> origin/main
                ),

                SizedBox(
                  width: 15,
                ),

                Expanded(
<<<<<<< HEAD
                  child: Text(
=======
                  child:
                      Text(
>>>>>>> origin/main
                    'Press if immediate assistance is needed',
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          14,
                    ),
                  ),
                ),

                Icon(
<<<<<<< HEAD
                  Icons.arrow_forward_ios,
=======
                  Icons
                      .arrow_forward_ios,
>>>>>>> origin/main
                  color:
                      Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // Motion history
  // ==================================================

  Widget buildMotionHistory() {
    if (motionData.isEmpty) {
      return Container(
<<<<<<< HEAD
        width: double.infinity,

        padding:
            const EdgeInsets.all(20),

=======
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          20,
        ),
>>>>>>> origin/main
        decoration:
            BoxDecoration(
          color:
              Colors.white,
<<<<<<< HEAD

=======
>>>>>>> origin/main
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
        child:
            const Text(
          'No recent motion activity found.',
        ),
      );
    }

    // Only show the latest 10 cards.
    final int displayCount =
        motionData.length > 10
            ? 10
            : motionData.length;

    return ListView.builder(
      shrinkWrap:
          true,
<<<<<<< HEAD

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount:
          displayCount,

=======
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount:
          displayCount,
>>>>>>> origin/main
      itemBuilder:
          (
        context,
        index,
      ) {
        final dynamic rawItem =
            motionData[index];

        if (rawItem is! Map) {
          return const SizedBox
              .shrink();
        }

        final Map<String, dynamic>
            item =
            Map<String, dynamic>.from(
          rawItem,
        );

        final String eventType =
            item['event_type']
                    ?.toString() ??
                'unknown';

        final String description =
            item['event_description']
                    ?.toString() ??
                'No description available.';

        final String time =
            item['detected_at']
                    ?.toString() ??
                'Unknown time';

        return activityCard(
          eventType:
              eventType,
<<<<<<< HEAD

          description:
              description,

=======
          description:
              description,
>>>>>>> origin/main
          time:
              time,
        );
      },
    );
  }

  // ==================================================
  // Feature card
  // ==================================================

  Widget featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        18,
      ),
<<<<<<< HEAD

      onTap:
          onTap,

      child: Container(
        padding:
            const EdgeInsets.all(16),

=======
      onTap:
          onTap,
      child:
          Container(
        padding:
            const EdgeInsets.all(
          16,
        ),
>>>>>>> origin/main
        decoration:
            BoxDecoration(
          color:
              Colors.white,
<<<<<<< HEAD

=======
>>>>>>> origin/main
          borderRadius:
              BorderRadius.circular(
            18,
          ),
<<<<<<< HEAD

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.05,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

=======
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withValues(
                alpha:
                    0.05,
              ),
              blurRadius:
                  8,
              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
>>>>>>> origin/main
          children: [
            Icon(
              icon,
              color:
                  color,
<<<<<<< HEAD
              size: 30,
=======
              size:
                  30,
>>>>>>> origin/main
            ),

            const Spacer(),

            Text(
              title,
              style:
                  const TextStyle(
<<<<<<< HEAD
                fontSize: 15,
=======
                fontSize:
                    15,
>>>>>>> origin/main
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,
              style:
                  TextStyle(
<<<<<<< HEAD
                fontSize: 13,
                color:
                    Colors.grey[600],
=======
                fontSize:
                    13,
                color:
                    Colors.grey[
                        600],
>>>>>>> origin/main
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Activity card
  // ==================================================

  Widget activityCard({
    required String eventType,
    required String description,
    required String time,
  }) {
    final Color eventColor =
        getStatusColor(
      eventType,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
<<<<<<< HEAD

      padding:
          const EdgeInsets.all(14),

=======
      padding:
          const EdgeInsets.all(
        14,
      ),
>>>>>>> origin/main
      decoration:
          BoxDecoration(
        color:
            Colors.white,
<<<<<<< HEAD

=======
>>>>>>> origin/main
        borderRadius:
            BorderRadius.circular(
          18,
        ),
<<<<<<< HEAD

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

=======
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  0.04,
            ),
            blurRadius:
                8,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
>>>>>>> origin/main
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
<<<<<<< HEAD

            decoration:
                BoxDecoration(
              color:
                  eventColor.withValues(
                alpha: 0.12,
              ),

=======
            decoration:
                BoxDecoration(
              color:
                  eventColor
                      .withValues(
                alpha:
                    0.12,
              ),
>>>>>>> origin/main
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
<<<<<<< HEAD

            child: Icon(
              getStatusIcon(
                eventType,
              ),

              color:
                  eventColor,

              size: 28,
=======
            child:
                Icon(
              getStatusIcon(
                eventType,
              ),
              color:
                  eventColor,
              size:
                  28,
>>>>>>> origin/main
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
<<<<<<< HEAD
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

=======
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
>>>>>>> origin/main
              children: [
                Text(
                  formatEventType(
                    eventType,
                  ),
<<<<<<< HEAD

                  style:
                      const TextStyle(
                    fontSize: 17,
=======
                  style:
                      const TextStyle(
                    fontSize:
                        17,
>>>>>>> origin/main
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  description,
<<<<<<< HEAD

                  style:
                      const TextStyle(
                    fontSize: 14,
=======
                  style:
                      const TextStyle(
                    fontSize:
                        14,
>>>>>>> origin/main
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  time,
<<<<<<< HEAD

                  style:
                      const TextStyle(
                    fontSize: 13,
=======
                  style:
                      const TextStyle(
                    fontSize:
                        13,
>>>>>>> origin/main
                    color:
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Quick action button
  // ==================================================

  Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed:
          onTap,
<<<<<<< HEAD

=======
>>>>>>> origin/main
      icon:
          Icon(
        icon,
      ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
      label:
          Text(
        label,
      ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            color,
<<<<<<< HEAD

        foregroundColor:
            Colors.white,

        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),

=======
        foregroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          vertical:
              14,
        ),
>>>>>>> origin/main
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/main
