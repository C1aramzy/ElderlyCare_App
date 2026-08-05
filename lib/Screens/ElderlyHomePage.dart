import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Services/mmWaveService.dart';
import 'ElderlyAppointmentPage.dart';
import 'LoginPage.dart';
import 'MedicationPage.dart';
import 'RobotCameraPage.dart';

class ElderlyHomePage extends StatefulWidget {
  final int userId;
  final String fullName;

  const ElderlyHomePage({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  State<ElderlyHomePage> createState() => _ElderlyHomePageState();
}

class _ElderlyHomePageState extends State<ElderlyHomePage> {
  Map<String, dynamic>? currentStatus;
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

    // Get the sensor data immediately when the page opens.
    fetchMotionData();

    // Automatically check the server every 30 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          fetchMotionData(showLoading: false);
        }
      },
    );
  }

  @override
  void dispose() {
    // Stop the timer when the user leaves this page.
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
      isRefreshing = true;
    }

    try {
      final Map<String, dynamic> data =
          await MmWaveService.getMotionData(widget.userId);

      debugPrint('Logged-in user ID: ${widget.userId}');
      debugPrint('Motion data: $data');

      if (!mounted) return;

      if (data['success'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'Unable to retrieve motion sensor data.',
        );
      }

      final dynamic receivedStatus = data['current_status'];
      final dynamic receivedEvents = data['events'];

      setState(() {
        if (receivedStatus is Map) {
          currentStatus = Map<String, dynamic>.from(receivedStatus);
        } else {
          currentStatus = null;
        }

        if (receivedEvents is List) {
          motionData = receivedEvents;
        } else {
          motionData = [];
        }

        isLoading = false;
        isRefreshing = false;
        errorMessage = '';
      });
    } catch (e) {
      debugPrint('Motion data error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;

        // Keep existing sensor information visible during a silent
        // automatic refresh failure.
        if (showLoading || currentStatus == null) {
          errorMessage = 'Connection error: $e';
        }
      });
    }
  }

  // ==================================================
  // Sensor status helpers
  // ==================================================

  String getStatusTitle(String status) {
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

  IconData getStatusIcon(String status) {
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

  Color getStatusColor(String status) {
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

  String formatEventType(String eventType) {
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
            eventType.replaceAll('_', ' ').trim();

        if (formatted.isEmpty) {
          return 'Unknown Activity';
        }

        return formatted
            .split(' ')
            .map(
              (word) => word.isEmpty
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
        builder: (context) => const LoginPage(),
      ),
    );
  }

  // ==================================================
  // Emergency help request
  // ==================================================

  Future<void> createHelpRequest() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://elderlym.atspace.cc/create_help_request.php',
        ),
        body: {
          'elderly_id': widget.userId.toString(),
          'elderly_name': widget.fullName,
          'request_type': 'emergency',
          'description': 'Immediate assistance needed',
          'location': 'Unknown',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}.',
        );
      }

      final dynamic decodedData = jsonDecode(response.body);

      if (decodedData is! Map<String, dynamic>) {
        throw Exception('Invalid response from server.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decodedData['message']?.toString() ??
                'Help request submitted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error creating help request: $e',
          ),
        ),
      );
    }
  }

  // ==================================================
  // Main page
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final String statusCode =
        currentStatus?['current_status']?.toString() ??
            'unknown';

    final String statusDescription =
        currentStatus?['status_description']?.toString() ??
            'No monitoring information available.';

    final String lastSensorUpdate =
        currentStatus?['last_sensor_update']?.toString() ??
            'No update received';

    final bool sensorOnline =
        currentStatus?['sensor_online']?.toString() == '1';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Elderly Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                fetchMotionData();
              },
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty &&
                  currentStatus == null
              ? buildErrorDisplay()
              : RefreshIndicator(
                  onRefresh: () {
                    return fetchMotionData(
                      showLoading: false,
                    );
                  },
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good day 👋',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome back, ${widget.fullName}!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),

                        const SizedBox(height: 18),

                        buildMonitoringStatusCard(
                          statusCode: statusCode,
                          statusDescription:
                              statusDescription,
                          lastSensorUpdate:
                              lastSensorUpdate,
                          sensorOnline: sensorOnline,
                        ),

                        const SizedBox(height: 20),

                        buildEmergencyButton(),

                        const SizedBox(height: 24),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: [
                            featureCard(
                              icon: sensorOnline
                                  ? Icons.sensors
                                  : Icons.sensors_off,
                              title: 'Motion Sensor',
                              subtitle: sensorOnline
                                  ? 'Active'
                                  : 'Offline',
                              color: sensorOnline
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            featureCard(
                              icon: Icons.medication,
                              title: 'Medication',
                              subtitle: 'View Medications',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MedicationPage(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            featureCard(
                              icon: Icons.calendar_month,
                              title: 'Appointments',
                              subtitle: 'View Appointments',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AppointmentPage(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            featureCard(
                              icon: Icons.videocam_rounded,
                              title: 'Emergency Camera',
                              subtitle:
                                  'View live Camera Feed',
                              color: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RobotCameraPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Recent Motion Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        buildMotionHistory(),

                        const SizedBox(height: 24),

                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: actionButton(
                                icon: Icons.help,
                                label: 'Contact Helpline',
                                color: Colors.pink,
                                onTap: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Contact Helpline feature coming soon',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: actionButton(
                                icon: Icons.person,
                                label: 'View Profile',
                                color: Colors.blueGrey,
                                onTap: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile feature coming soon',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                fetchMotionData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Monitoring status card
  // ==================================================

  Widget buildMonitoringStatusCard({
    required String statusCode,
    required String statusDescription,
    required String lastSensorUpdate,
    required bool sensorOnline,
  }) {
    final Color statusColor =
        getStatusColor(statusCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            statusColor.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: currentStatus == null
          ? const Text(
              'No sensor status available yet.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Icon(
                      getStatusIcon(statusCode),
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        getStatusTitle(statusCode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  statusDescription,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Last Update: $lastSensorUpdate',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: sensorOnline
                          ? Colors.greenAccent
                          : Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sensorOnline
                          ? 'Sensor Online'
                          : 'Sensor Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: createHelpRequest,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'Press if immediate assistance is needed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
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
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No recent motion activity found.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: motionData.length,
      itemBuilder: (context, index) {
        final dynamic rawItem = motionData[index];

        if (rawItem is! Map) {
          return const SizedBox.shrink();
        }

        final Map<String, dynamic> item =
            Map<String, dynamic>.from(rawItem);

        final String eventType =
            item['event_type']?.toString() ??
                'unknown';

        final String description =
            item['event_description']?.toString() ??
                'No description available.';

        final String time =
            item['detected_at']?.toString() ??
                'Unknown time';

        return activityCard(
          eventType: eventType,
          description: description,
          time: time,
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
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
        getStatusColor(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  eventColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              getStatusIcon(eventType),
              color: eventColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  formatEventType(eventType),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
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
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}