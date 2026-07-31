import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ElderlyRegistrationPage extends StatefulWidget {
  const ElderlyRegistrationPage({super.key});

  @override
  State<ElderlyRegistrationPage> createState() =>
      _ElderlyRegistrationPageState();
}

class _ElderlyRegistrationPageState extends State<ElderlyRegistrationPage> {
  int currentStep = 1;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final postalCodeController = TextEditingController();
  final addressController = TextEditingController();
  final medicalController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final robotIdController = TextEditingController();
  final sensorKitIdController = TextEditingController();

  String selectedGender = 'Male';
  String selectedMobilityStatus = 'Independent';
  String selectedRelationship = 'Child';

  bool monitoringConsent = false;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isAddressLoading = false;

  File? profileImage;

  Future<void> pickProfileImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> fetchAddressFromPostalCode() async {
    final postalCode = postalCodeController.text.trim();

    if (postalCode.length != 6) {
      showMessage('Please enter a valid 6 digit postal code.');
      return;
    }

    setState(() {
      isAddressLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://www.onemap.gov.sg/api/common/elastic/search'
        '?searchVal=$postalCode'
        '&returnGeom=N'
        '&getAddrDetails=Y'
        '&pageNum=1',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final address = results[0]['ADDRESS'] ?? '';

          setState(() {
            addressController.text = address;
          });
        } else {
          showMessage('No address found for this postal code.');
        }
      } else {
        showMessage('Unable to search address. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to search address. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          isAddressLoading = false;
        });
      }
    }
  }

  bool validateForm() {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        postalCodeController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      showMessage('Please fill in all required fields.');
      return false;
    }

    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.')) {
      showMessage('Please enter a valid email address.');
      return false;
    }

    if (passwordController.text.length < 8) {
      showMessage('Password must be at least 8 characters.');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Passwords do not match.');
      return false;
    }

    if (phoneController.text.trim().length != 8) {
      showMessage('Please enter a valid 8 digit phone number.');
      return false;
    }

    if (postalCodeController.text.trim().length != 6) {
      showMessage('Please enter a valid 6 digit postal code.');
      return false;
    }

    return true;
  }

  Future<void> registerElderly() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://elderlym.atspace.cc/register_elderly.php'),
        body: {
          'full_name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'phone': phoneController.text.trim(),
          'age': ageController.text.trim(),
          'address': addressController.text.trim(),
          'medical_condition': medicalController.text.trim(),
          'emergency_contact': emergencyContactController.text.trim(),
          'emergency_phone': emergencyPhoneController.text.trim(),
          'gender': selectedGender,
          'mobility_status': selectedMobilityStatus,
          'relationship': selectedRelationship,
          'robot_id': robotIdController.text.trim(),
          'sensor_kit_id': sensorKitIdController.text.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200 &&
          response.body.contains('"success":true')) {
        setState(() {
          currentStep = 4;
        });
      } else if (response.body.toLowerCase().contains('duplicate')) {
        showMessage('An account with this email already exists.');
      } else {
        showMessage('Registration failed. Please check your details and try again.');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to connect. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getPasswordStrength() {
    final password = passwordController.text;

    if (password.isEmpty) return 'Not entered';

    if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Strong';
    }

    if (password.length >= 6 &&
        (password.contains(RegExp(r'[A-Z]')) ||
            password.contains(RegExp(r'[0-9]')))) {
      return 'Medium';
    }

    return 'Weak';
  }

  Color getPasswordStrengthColor() {
    final strength = getPasswordStrength();

    if (strength == 'Strong') return Colors.green;
    if (strength == 'Medium') return Colors.orange;
    if (strength == 'Weak') return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    ageController.dispose();
    postalCodeController.dispose();
    addressController.dispose();
    medicalController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();
    robotIdController.dispose();
    sensorKitIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text('Elderly Registration'),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStep == 1
                  ? 'Create Elderly Account'
                  : currentStep == 2
                      ? 'Personal & Care Details'
                      : currentStep == 3
                          ? 'Emergency & Device Setup'
                          : 'Registration Complete',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102044),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentStep == 1
                  ? 'Enter the account details first.'
                  : currentStep == 2
                      ? 'Tell us more about the elderly user.'
                      : currentStep == 3
                          ? 'Set emergency contact and monitoring details.'
                          : 'Your account has been created.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            if (currentStep != 4) buildStepIndicator(),
            const SizedBox(height: 30),
            if (currentStep == 1) buildStepOne(),
            if (currentStep == 2) buildStepTwo(),
            if (currentStep == 3) buildStepThree(),
            if (currentStep == 4) buildCompletePage(),
          ],
        ),
      ),
    );
  }

  Widget buildStepOne() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickProfileImage,
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.blue.shade50,
            backgroundImage:
                profileImage != null ? FileImage(profileImage!) : null,
            child: profileImage == null
                ? const Icon(Icons.add_a_photo_outlined,
                    size: 40, color: Colors.blue)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap to add profile picture',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),
        buildTextField(
          label: 'Full Name',
          hint: 'Enter full name',
          icon: Icons.person_outline,
          controller: fullNameController,
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Email',
          hint: 'Enter email address',
          icon: Icons.email_outlined,
          controller: emailController,
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Password',
          hint: 'Enter password',
          icon: Icons.lock_outline,
          isPassword: !isPasswordVisible,
          controller: passwordController,
          onChanged: (_) {
            setState(() {});
          },
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        buildPasswordStrength(),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Confirm Password',
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          isPassword: !isConfirmPasswordVisible,
          controller: confirmPasswordController,
          suffixIcon: IconButton(
            icon: Icon(
              isConfirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Phone Number',
          hint: 'Enter phone number',
          icon: Icons.phone_outlined,
          controller: phoneController,
        ),
        const SizedBox(height: 35),
        buildNextButton(),
      ],
    );
  }

  Widget buildStepTwo() {
    return Column(
      children: [
        buildTextField(
          label: 'Age',
          hint: 'Enter age',
          icon: Icons.cake_outlined,
          controller: ageController,
        ),
        const SizedBox(height: 20),
        buildDropdownField(
          label: 'Gender',
          value: selectedGender,
          items: const ['Male', 'Female', 'Prefer not to say'],
          icon: Icons.wc_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedGender = newValue!;
            });
          },
        ),
        const SizedBox(height: 20),
        buildPostalCodeField(),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Address',
          hint: 'Address will appear here after postal code search',
          icon: Icons.location_on_outlined,
          controller: addressController,
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Medical Conditions',
          hint: 'E.g. diabetes, dementia, high blood pressure',
          icon: Icons.medical_services_outlined,
          controller: medicalController,
        ),
        const SizedBox(height: 20),
        buildDropdownField(
          label: 'Mobility Status',
          value: selectedMobilityStatus,
          items: const [
            'Independent',
            'Requires walking aid',
            'Wheelchair user',
            'Bedridden',
          ],
          icon: Icons.accessible_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedMobilityStatus = newValue!;
            });
          },
        ),
        const SizedBox(height: 35),
        buildBackNextButtons(backStep: 1, nextStep: 3),
      ],
    );
  }

  Widget buildStepThree() {
    return Column(
      children: [
        buildTextField(
          label: 'Emergency Contact Name',
          hint: 'Enter emergency contact name',
          icon: Icons.contact_emergency_outlined,
          controller: emergencyContactController,
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Emergency Contact Number',
          hint: 'Enter emergency contact number',
          icon: Icons.phone_in_talk_outlined,
          controller: emergencyPhoneController,
        ),
        const SizedBox(height: 20),
        buildDropdownField(
          label: 'Relationship',
          value: selectedRelationship,
          items: const [
            'Child',
            'Spouse',
            'Sibling',
            'Relative',
            'Friend',
            'Not Applicable',
          ],
          icon: Icons.family_restroom_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedRelationship = newValue!;
            });
          },
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Robot ID',
          hint: 'E.g. ROBOT-001',
          icon: Icons.smart_toy_outlined,
          controller: robotIdController,
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Sensor Kit ID',
          hint: 'E.g. SENSOR-001',
          icon: Icons.sensors_outlined,
          controller: sensorKitIdController,
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: monitoringConsent,
          onChanged: (value) {
            setState(() {
              monitoringConsent = value!;
            });
          },
          title: const Text(
            'I consent to home monitoring and emergency alerts.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 35),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          currentStep = 2;
                        });
                      },
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (monitoringConsent != true) {
                          showMessage(
                            'Please agree to the consent before registering.',
                          );
                          return;
                        }

                        if (!validateForm()) return;

                        await registerElderly();
                      },
                child: Text(isLoading ? 'Submitting...' : 'Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPostalCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Postal Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: postalCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Enter postal code',
            prefixIcon: const Icon(Icons.location_searching_outlined),
            suffixIcon: isAddressLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: fetchAddressFromPostalCode,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onSubmitted: (_) {
            fetchAddressFromPostalCode();
          },
        ),
      ],
    );
  }

  Widget buildPasswordStrength() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Password strength: ${getPasswordStrength()}',
        style: TextStyle(
          color: getPasswordStrengthColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          setState(() {
            currentStep = 2;
          });
        },
        child: const Text('Next'),
      ),
    );
  }

  Widget buildBackNextButtons({
    required int backStep,
    required int nextStep,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              setState(() {
                currentStep = backStep;
              });
            },
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              setState(() {
                currentStep = nextStep;
              });
            },
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextEditingController? controller,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildStepCircle(
          stepNumber: 1,
          isActive: currentStep == 1,
          isCompleted: currentStep > 1,
        ),
        buildStepLine(currentStep > 1),
        buildStepCircle(
          stepNumber: 2,
          isActive: currentStep == 2,
          isCompleted: currentStep > 2,
        ),
        buildStepLine(currentStep > 2),
        buildStepCircle(
          stepNumber: 3,
          isActive: currentStep == 3,
          isCompleted: currentStep > 3,
        ),
      ],
    );
  }

  Widget buildStepCircle({
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? Colors.blue : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$stepNumber',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget buildStepLine(bool isCompleted) {
    return Container(
      width: 45,
      height: 3,
      color: isCompleted ? Colors.blue : Colors.grey.shade300,
    );
  }

  Widget buildCompletePage() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF55CFC0),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 65,
                color: Color(0xFF55CFC0),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Account Created!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102044),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your elderly monitoring account has been successfully registered.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.login),
                label: const Text(
                  'Go To Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}