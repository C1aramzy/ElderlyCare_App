import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmergencyAssessmentPage extends StatefulWidget {
  final int requestId;
  final int volunteerId;

  const EmergencyAssessmentPage({
    super.key,
    required this.requestId,
    required this.volunteerId,
  });

  @override
  State<EmergencyAssessmentPage> createState() =>
      _EmergencyAssessmentPageState();
}

class _EmergencyAssessmentPageState
    extends State<EmergencyAssessmentPage> {

  static const String finishUrl =
      "http://elderlym.atspace.cc/finish_help_request.php";

  bool isSubmitting = false;

  String assessment = "Elderly Safe";

  final TextEditingController notesController =
      TextEditingController();

  Widget buildRadio(
    String title,
    IconData icon,
    Color color,
  ) {

    return Card(

      elevation: 0,

      color: Colors.grey.shade100,

      margin: const EdgeInsets.only(bottom: 12),

      child: RadioListTile<String>(

        value: title,

        groupValue: assessment,

        activeColor: color,

        secondary: Icon(
          icon,
          color: color,
        ),

        title: Text(title),

        onChanged: (value) {

          setState(() {

            assessment = value!;

          });

        },

      ),

    );

  }

    Future<void> submitAssessment() async {

    setState(() {

      isSubmitting = true;

    });

    try {

      final response = await http.post(

        Uri.parse(finishUrl),

        body: {

          "request_id":
              widget.requestId.toString(),

          "volunteer_id":
              widget.volunteerId.toString(),

          "assessment_result":
              assessment,

          "assessment_notes":
              notesController.text,

        },

      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {

        isSubmitting = false;

      });

      if (data["success"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text(
              "Emergency response completed.",
            ),

            backgroundColor: Colors.green,

          ),

        );

        Navigator.pop(context, true);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(
              data["message"] ??
                  "Unable to complete emergency.",
            ),

            backgroundColor: Colors.red,

          ),

        );

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {

        isSubmitting = false;

      });

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(e.toString()),

          backgroundColor: Colors.red,

        ),

      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF5F6FA),

      appBar: AppBar(

        title: const Text(
          "Emergency Assessment",
        ),

        elevation: 0,

      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color: Colors.red,

                borderRadius:
                    BorderRadius.circular(20),

              ),

              child: const Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    "🚨 Emergency Assessment",

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 24,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                  SizedBox(height: 8),

                  Text(

                    "Complete the assessment before closing this emergency.",

                    style: TextStyle(

                      color: Colors.white,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 25),

            const Text(

              "Assessment Result",

              style: TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 18,

              ),

            ),

            const SizedBox(height: 15),

            buildRadio(

              "Elderly Safe",

              Icons.check_circle,

              Colors.green,

            ),

            buildRadio(

              "False Alarm",

              Icons.warning,

              Colors.orange,

            ),

            buildRadio(

              "Family Contacted",

              Icons.family_restroom,

              Colors.blue,

            ),

            buildRadio(

              "Ambulance Required",

              Icons.local_hospital,

              Colors.red,

            ),

            const SizedBox(height: 20),

            TextField(

              controller:
                  notesController,

              maxLines: 5,

              decoration:
                  InputDecoration(

                labelText:
                    "Assessment Notes",

                hintText:
                    "Enter any observations...",

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                ),

              ),

            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed:
                    isSubmitting
                        ? null
                        : submitAssessment,

                icon: isSubmitting

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
                        Icons.check,
                      ),

                label: Text(

                  isSubmitting

                      ? "Submitting..."

                      : "Finish Emergency Response",

                ),

                style: ElevatedButton.styleFrom(

                  backgroundColor:
                      Colors.green,

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets.symmetric(

                    vertical: 16,

                  ),

                  shape:
                      RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}