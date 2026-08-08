import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ContactHelplinePage extends StatefulWidget {
  final int userId;

  const ContactHelplinePage({
    super.key,
    required this.userId,
  });

  @override
  State<ContactHelplinePage> createState() =>
      _ContactHelplinePageState();
}

class _ContactHelplinePageState extends State<ContactHelplinePage> {
  bool isLoading = true;
  String errorMessage = '';

  Map<String, dynamic>? profile;

  // ==================================================
  // DEMO HELPLINE NUMBERS
  //
  // Replace these with your own test numbers.
  // ==================================================

  static const String medicalAssistanceNumber = '87989110';

  static const String generalAssistanceNumber = '87989110';

  static const String communitySupportNumber = '87989110';

  // ==================================================
  // API
  // ==================================================

  static const String profileUrl =
      'http://elderlym.atspace.cc/get_elderly_profile.php';

  @override
  void initState() {
    super.initState();

    fetchProfile();
  }

  // ==================================================
  // Fetch elderly emergency contact
  // ==================================================

  Future<void> fetchProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$profileUrl?user_id=${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}.',
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
              'Unable to load emergency contact.',
        );
      }

      final dynamic receivedProfile =
          decoded['profile'];

      if (receivedProfile is! Map) {
        throw Exception(
          'Profile information is missing.',
        );
      }

      if (!mounted) return;

      setState(() {
        profile =
            Map<String, dynamic>.from(
          receivedProfile,
        );

        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load emergency contact: $e';
      });
    }
  }

  // ==================================================
  // Value helper
  // ==================================================

  String valueOrNotProvided(
    dynamic value,
  ) {
    if (value == null) {
      return 'Not provided';
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return 'Not provided';
    }

    return text;
  }

  // ==================================================
  // Make phone call
  // ==================================================

  Future<void> callNumber(
    String phoneNumber,
  ) async {
    final String cleanNumber =
        phoneNumber.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleanNumber.isEmpty ||
        cleanNumber == 'Notprovided') {
      showMessage(
        'No phone number is available.',
      );
      return;
    }

    final Uri phoneUri =
        Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      final bool launched =
          await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        showMessage(
          'Unable to open the phone dialer.',
        );
      }
    } catch (e) {
      showMessage(
        'Unable to make call.',
      );
    }
  }

  // ==================================================
  // Snackbar
  // ==================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

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
  // Main page
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
      appBar: AppBar(
        title: const Text(
          'Contact Helpline',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh:
            fetchProfile,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            buildHeader(),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Assistance',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            buildHelplineCard(
              icon:
                  Icons
                      .medical_services_outlined,
              title:
                  'Medical Assistance',
              description:
                  'Contact for medical assistance or health-related support.',
              phoneNumber:
                  medicalAssistanceNumber,
              color:
                  Colors.red,
            ),

            const SizedBox(
              height: 12,
            ),

            buildHelplineCard(
              icon:
                  Icons
                      .support_agent_outlined,
              title:
                  'General Assistance',
              description:
                  'Contact when general assistance or support is required.',
              phoneNumber:
                  generalAssistanceNumber,
              color:
                  Colors.orange,
            ),

            const SizedBox(
              height: 12,
            ),

            buildHelplineCard(
              icon:
                  Icons
                      .groups_outlined,
              title:
                  'Community Support',
              description:
                  'Contact for community or elderly support services.',
              phoneNumber:
                  communitySupportNumber,
              color:
                  Colors.blue,
            ),

            const SizedBox(
              height: 26,
            ),

            const Text(
              'Personal Emergency Contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (isLoading)
              buildLoadingContact()
            else if (errorMessage
                .isNotEmpty)
              buildContactError()
            else
              buildEmergencyContact(),

            const SizedBox(
              height: 24,
            ),

            buildDemoNotice(),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Header
  // ==================================================

  Widget buildHeader() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(
              0xFF4A90E2,
            ),
            Color(
              0xFF6FB1FC,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child:
          const Row(
        children: [
          Icon(
            Icons
                .phone_in_talk_outlined,
            color:
                Colors.white,
            size:
                42,
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Need Assistance?',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'Choose the appropriate contact below to get help.',
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        14,
                    height:
                        1.4,
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
  // Helpline card
  // ==================================================

  Widget buildHelplineCard({
    required IconData icon,
    required String title,
    required String description,
    required String phoneNumber,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.05,
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
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration:
                    BoxDecoration(
                  color:
                      color
                          .withValues(
                    alpha:
                        0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      color,
                  size:
                      28,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize:
                            17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      description,
                      style:
                          TextStyle(
                        color:
                            Colors.grey[
                                600],
                        fontSize:
                            13,
                        height:
                            1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        14,
                    vertical:
                        12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF5F6FA,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size:
                            19,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        phoneNumber,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              ElevatedButton.icon(
                onPressed:
                    () {
                  callNumber(
                    phoneNumber,
                  );
                },
                icon:
                    const Icon(
                  Icons.call,
                  size:
                      19,
                ),
                label:
                    const Text(
                  'Call',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.green,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        16,
                    vertical:
                        13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
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
  // Emergency contact from DB
  // ==================================================

  Widget buildEmergencyContact() {
    final String name =
        valueOrNotProvided(
      profile?[
          'emergency_contact'],
    );

    final String relationship =
        valueOrNotProvided(
      profile?[
          'relationship'],
    );

    final String phone =
        valueOrNotProvided(
      profile?[
          'emergency_phone'],
    );

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
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
        children: [
          Row(
            children: [
              Container(
                width:
                    58,
                height:
                    58,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.pink
                          .withValues(
                    alpha:
                        0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .contact_emergency_outlined,
                  color:
                      Colors.pink,
                  size:
                      30,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      relationship,
                      style:
                          TextStyle(
                        color:
                            Colors.grey[
                                600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  phone ==
                          'Not provided'
                      ? null
                      : () {
                          callNumber(
                            phone,
                          );
                        },
              icon:
                  const Icon(
                Icons.call,
              ),
              label:
                  Text(
                phone ==
                        'Not provided'
                    ? 'No Contact Number'
                    : 'Call $phone',
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.green,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical:
                      14,
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

  Widget buildLoadingContact() {
    return Container(
      height: 130,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          const Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }

  Widget buildContactError() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Column(
        children: [
          const Icon(
            Icons
                .cloud_off_outlined,
            color:
                Colors.red,
            size:
                40,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            errorMessage,
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(
            height: 12,
          ),
          OutlinedButton.icon(
            onPressed:
                fetchProfile,
            icon:
                const Icon(
              Icons.refresh,
            ),
            label:
                const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Demonstration notice
  // ==================================================

  Widget buildDemoNotice() {
    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.orange
                .withValues(
          alpha: 0.1,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .info_outline,
            color:
                Colors.orange,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Text(
              'The assistance numbers shown in this prototype are demonstration contacts and can be configured for deployment.',
              style:
                  TextStyle(
                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}