import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditElderlyProfilePage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> profile;

  const EditElderlyProfilePage({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  State<EditElderlyProfilePage> createState() =>
      _EditElderlyProfilePageState();
}

class _EditElderlyProfilePageState
    extends State<EditElderlyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final medicalController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  String selectedMobilityStatus = 'Independent';
  String selectedRelationship = 'Child';

  File? selectedImage;

  bool isSaving = false;

  static const String updateUrl =
      'http://elderlym.atspace.cc/update_elderly_profile.php';

  @override
  void initState() {
    super.initState();

    phoneController.text =
        widget.profile['phone']?.toString() ?? '';

    addressController.text =
        widget.profile['address']?.toString() ?? '';

    medicalController.text =
        widget.profile['medical_condition']?.toString() ?? '';

    emergencyContactController.text =
        widget.profile['emergency_contact']?.toString() ?? '';

    emergencyPhoneController.text =
        widget.profile['emergency_phone']?.toString() ?? '';

    final String mobility =
        widget.profile['mobility_status']?.toString() ?? '';

    if ([
      'Independent',
      'Requires walking aid',
      'Wheelchair user',
      'Bedridden',
    ].contains(mobility)) {
      selectedMobilityStatus = mobility;
    }

    final String relationship =
        widget.profile['relationship']?.toString() ?? '';

    if ([
      'Child',
      'Spouse',
      'Sibling',
      'Relative',
      'Friend',
      'Neighbour',
      'Other',
    ].contains(relationship)) {
      selectedRelationship = relationship;
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    medicalController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();

    super.dispose();
  }

  String get profileImageUrl =>
      widget.profile['profile_image_url']?.toString() ?? '';

  String get fullName =>
      widget.profile['full_name']?.toString() ?? 'User';

  String get initial {
    if (fullName.trim().isEmpty) {
      return '?';
    }

    return fullName.trim()[0].toUpperCase();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image =
          await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      showMessage(
        'Unable to select image.',
      );
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(updateUrl),
      );

      request.fields.addAll({
        'user_id': widget.userId.toString(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'medical_condition': medicalController.text.trim(),
        'mobility_status': selectedMobilityStatus,
        'emergency_contact':
            emergencyContactController.text.trim(),
        'emergency_phone':
            emergencyPhoneController.text.trim(),
        'relationship': selectedRelationship,
      });

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            selectedImage!.path,
          ),
        );
      }

      final streamedResponse =
          await request.send().timeout(
        const Duration(seconds: 20),
      );

      final response =
          await http.Response.fromStream(
        streamedResponse,
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
          'Invalid server response.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Unable to update profile.',
        );
      }

      if (!mounted) return;

      showMessage(
        decoded['message']?.toString() ??
            'Profile updated successfully.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      showMessage(
        'Unable to update profile: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  InputDecoration buildDecoration({
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 1.5,
        ),
      ),
    );
  }

  Widget buildProfileImage() {
    Widget imageWidget;

    if (selectedImage != null) {
      imageWidget = Image.file(
        selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (profileImageUrl.isNotEmpty) {
      imageWidget = Image.network(
        profileImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return buildInitialAvatar();
        },
      );
    } else {
      imageWidget = buildInitialAvatar();
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade50,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 12,
                  offset: const Offset(
                    0,
                    5,
                  ),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: imageWidget,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.blue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap: pickImage,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInitialAvatar() {
    return Container(
      alignment: Alignment.center,
      color: Colors.blue.shade50,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget buildReadOnlyInfo() {
    final String email =
        widget.profile['email']?.toString() ??
            'Not provided';

    final String age =
        widget.profile['age']?.toString() ??
            'Not provided';

    final String gender =
        widget.profile['gender']?.toString() ??
            'Not provided';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          buildReadOnlyRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: fullName,
          ),
          const Divider(),
          buildReadOnlyRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const Divider(),
          buildReadOnlyRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: age,
          ),
          const Divider(),
          buildReadOnlyRow(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: gender,
          ),
        ],
      ),
    );
  }

  Widget buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blueGrey,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:
                        Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline,
            size: 17,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 22,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
          color: Color(
            0xFF102044,
          ),
        ),
      ),
    );
  }

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
          'Edit Profile',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            const SizedBox(
              height: 10,
            ),

            buildProfileImage(),

            const SizedBox(
              height: 12,
            ),

            Center(
              child: TextButton.icon(
                onPressed:
                    pickImage,
                icon: const Icon(
                  Icons.photo_library_outlined,
                ),
                label: const Text(
                  'Change Profile Picture',
                ),
              ),
            ),

            buildSectionTitle(
              'Account Information',
            ),

            buildReadOnlyInfo(),

            buildSectionTitle(
              'Contact Information',
            ),

            TextFormField(
              controller:
                  phoneController,
              keyboardType:
                  TextInputType.phone,
              maxLength: 8,
              decoration:
                  buildDecoration(
                label:
                    'Phone Number',
                icon:
                    Icons.phone_outlined,
              ).copyWith(
                counterText: '',
              ),
              validator: (value) {
                final String phone =
                    value?.trim() ??
                        '';

                if (phone.length !=
                        8 ||
                    int.tryParse(phone) ==
                        null) {
                  return 'Enter a valid 8 digit phone number.';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 14,
            ),

            TextFormField(
              controller:
                  addressController,
              maxLines: 3,
              decoration:
                  buildDecoration(
                label:
                    'Home Address',
                icon: Icons
                    .location_on_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Please enter the address.';
                }

                return null;
              },
            ),

            buildSectionTitle(
              'Care Information',
            ),

            TextFormField(
              controller:
                  medicalController,
              maxLines: 3,
              decoration:
                  buildDecoration(
                label:
                    'Medical Conditions',
                hint:
                    'E.g. diabetes, high blood pressure',
                icon: Icons
                    .medical_services_outlined,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            DropdownButtonFormField<
                String>(
              value:
                  selectedMobilityStatus,
              decoration:
                  buildDecoration(
                label:
                    'Mobility Status',
                icon: Icons
                    .accessible_outlined,
              ),
              items: const [
                DropdownMenuItem(
                  value:
                      'Independent',
                  child: Text(
                    'Independent',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Requires walking aid',
                  child: Text(
                    'Requires walking aid',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Wheelchair user',
                  child: Text(
                    'Wheelchair user',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Bedridden',
                  child: Text(
                    'Bedridden',
                  ),
                ),
              ],
              onChanged: (value) {
                if (value ==
                    null) {
                  return;
                }

                setState(() {
                  selectedMobilityStatus =
                      value;
                });
              },
            ),

            buildSectionTitle(
              'Emergency Contact',
            ),

            TextFormField(
              controller:
                  emergencyContactController,
              decoration:
                  buildDecoration(
                label:
                    'Emergency Contact Name',
                icon: Icons
                    .contact_emergency_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Please enter an emergency contact.';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 14,
            ),

            TextFormField(
              controller:
                  emergencyPhoneController,
              keyboardType:
                  TextInputType.phone,
              maxLength: 8,
              decoration:
                  buildDecoration(
                label:
                    'Emergency Contact Number',
                icon: Icons
                    .phone_in_talk_outlined,
              ).copyWith(
                counterText: '',
              ),
              validator: (value) {
                final String phone =
                    value?.trim() ??
                        '';

                if (phone.length !=
                        8 ||
                    int.tryParse(phone) ==
                        null) {
                  return 'Enter a valid 8 digit emergency number.';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 14,
            ),

            DropdownButtonFormField<
                String>(
              value:
                  selectedRelationship,
              decoration:
                  buildDecoration(
                label:
                    'Relationship',
                icon: Icons
                    .family_restroom_outlined,
              ),
              items: const [
                DropdownMenuItem(
                  value:
                      'Child',
                  child:
                      Text('Child'),
                ),
                DropdownMenuItem(
                  value:
                      'Spouse',
                  child:
                      Text('Spouse'),
                ),
                DropdownMenuItem(
                  value:
                      'Sibling',
                  child:
                      Text('Sibling'),
                ),
                DropdownMenuItem(
                  value:
                      'Relative',
                  child:
                      Text('Relative'),
                ),
                DropdownMenuItem(
                  value:
                      'Friend',
                  child:
                      Text('Friend'),
                ),
                DropdownMenuItem(
                  value:
                      'Neighbour',
                  child:
                      Text('Neighbour'),
                ),
                DropdownMenuItem(
                  value:
                      'Other',
                  child:
                      Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value ==
                    null) {
                  return;
                }

                setState(() {
                  selectedRelationship =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : saveProfile,
                icon: isSaving
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
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.blue,
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
                        16,
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
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}