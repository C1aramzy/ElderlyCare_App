import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RobotCameraPage.dart';

import 'LoginPage.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  bool isAvailable = true;
  bool isLoading = true;
  List helpRequests = [];
  String errorMessage = '';

  final String getRequestsUrl =
      'http://elderlym.atspace.cc/get_help_requests.php';

  final String acceptRequestUrl =
      'http://elderlym.atspace.cc/accept_help_request.php';

  @override
  void initState() {
    super.initState();
    fetchHelpRequests();
  }

  Future<void> fetchHelpRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(getRequestsUrl));
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          helpRequests = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Unable to load help requests.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> acceptRequest(String requestId) async{
    try{
      final response = await http.post(
        Uri.parse(acceptRequestUrl),
        body: {
          'request_id' : requestId,
          'volunteer_id' : '1', 
        },
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if(data['success'] == true){
        final bool? startCheckIn = await showDialog<bool>(
          context : context,
          builder: (context) {
            return AlertDialog(
              title : const Text('Request Accepted'),
              content : const Text(
                'Would you like to start a robot check-in now?'
              ),
              actions : [
                TextButton(
                  onPressed : (){
                    Navigator.pop(context, false);
                  },
                  child: const Text('Later'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.videocam),
                  label:const Text('Start Check-In'),
                ),
              ],
            );
          },
        );

        await fetchHelpRequests();

        if (startCheckIn == true && mounted){
          openRobotCamera();
        }
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Unable to accept request.',
            ),
          ),
        );
      }
    } catch (e) {
      if(!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
        ),
      );
    }
  }

  void openRobotCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RobotCameraPage(),
      ),
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Widget requestCard(dynamic request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text(
                'Assistance Request',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Elderly: ${request['elderly_name'] ?? 'Unknown'}'),
          const SizedBox(height: 6),
          Text('Type: ${request['request_type'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Location: ${request['location'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Message: ${request['message'] ?? '-'}'),
          const SizedBox(height: 6),
          Text(
            'Broadcasted: ${request['created_at'] ?? '-'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAvailable
                  ? () {
                      acceptRequest(request['request_id'].toString());
                    }
                  : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Volunteer Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchHelpRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchHelpRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Volunteer Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Respond to nearby elderly assistance requests',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.pause_circle,
                      color: isAvailable ? Colors.green : Colors.grey,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAvailable
                            ? 'Available to receive alerts'
                            : 'Currently unavailable',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Nearby Assistance Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                )
              else if (helpRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'No active assistance requests yet.',
                    style: TextStyle(fontSize: 15),
                  ),
                )
              else
                Column(
                  children: helpRequests.map((request) {
                    return requestCard(request);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}