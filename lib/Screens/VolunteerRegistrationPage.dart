import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VolunteerRegistrationPage extends StatefulWidget {
  const VolunteerRegistrationPage({super.key});

  @override
  State<VolunteerRegistrationPage> createState() =>
      _VolunteerRegistrationPageState();
}

class _VolunteerRegistrationPageState extends State<VolunteerRegistrationPage> {
  int currentStep = 1;

  String selectedExperience = 'None';
  String selectedAvailability = 'Weekends';
  String selectedDistance = '3 km';

  bool emergencyResponseConsent = false;
  bool locationConsent = false;
  bool isLoading = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final postalCodeController = TextEditingController();
  final skillsController = TextEditingController();

  String detectedArea = '';
  List<String> locationSuggestions = [];

  Future<void> updateDetectedArea(String value) async {
    if (value.isEmpty) {
      setState(() {
        locationSuggestions = [];
        detectedArea = '';
      });
      return;
    }

    if (value.length < 3) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.onemap.gov.sg/api/common/elastic/search'
          '?searchVal=$value'
          '&returnGeom=Y'
          '&getAddrDetails=Y'
          '&pageNum=1',
        ),
      );

      final data = jsonDecode(response.body);

      List<String> results = [];

      if (data['results'] != null) {
        for (var item in data['results']) {
          final postal = item['POSTAL'] ?? '';
          final address = item['ADDRESS'] ?? '';

          if (postal != 'NIL' && address.toString().isNotEmpty) {
            results.add('$postal - $address');
          }
        }
      }

      setState(() {
        locationSuggestions = results;
      });
    } catch (e) {
      setState(() {
        locationSuggestions = [];
      });
    }
  }

  Future<void> registerVolunteer() async {
    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.isEmpty ||
        postalCodeController.text.isEmpty ||
        skillsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://elderlym.atspace.cc/register_volunteer.php'),
        body: {
          'full_name': fullNameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'phone': phoneController.text,
          'availability': selectedAvailability,
          'skills': skillsController.text,
          'preferred_location': postalCodeController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          currentStep = 4;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    postalCodeController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text('Volunteer Registration'),
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
                  ? 'Become a Volunteer'
                  : currentStep == 2
                      ? 'Volunteer Details'
                      : currentStep == 3
                          ? 'Response Preferences'
                          : 'Registration Complete!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102044),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentStep == 1
                  ? 'Create your volunteer account.'
                  : currentStep == 2
                      ? 'Tell us where and how you can help.'
                      : currentStep == 3
                          ? 'Set your preferred response area.'
                          : 'Thank you for joining the care network.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            buildStepIndicator(),
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
          isPassword: true,
          controller: passwordController,
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
          label: 'Postal Code / Area',
          hint: 'Enter postal code or street name',
          icon: Icons.location_on_outlined,
          controller: postalCodeController,
          onChanged: updateDetectedArea,
        ),
        if (locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          buildLocationSuggestionList(),
        ],
        const SizedBox(height: 20),
        buildDropdownField(
          label: 'Caregiving Experience',
          value: selectedExperience,
          items: const [
            'None',
            'Basic',
            'Experienced',
            'Healthcare trained',
          ],
          icon: Icons.health_and_safety_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedExperience = newValue!;
            });
          },
        ),
        const SizedBox(height: 20),
        buildTextField(
          label: 'Skills',
          hint: 'E.g. first aid, elderly care',
          icon: Icons.handyman_outlined,
          controller: skillsController,
        ),
        const SizedBox(height: 20),
        buildDropdownField(
          label: 'Availability',
          value: selectedAvailability,
          items: const [
            'Weekdays',
            'Weekends',
            'Evenings',
            'Anytime',
          ],
          icon: Icons.calendar_month_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedAvailability = newValue!;
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
        buildDropdownField(
          label: 'Preferred Response Distance',
          value: selectedDistance,
          items: const ['1 km', '3 km', '5 km', '10 km'],
          icon: Icons.near_me_outlined,
          onChanged: (newValue) {
            setState(() {
              selectedDistance = newValue!;
            });
          },
        ),
        const SizedBox(height: 18),
        buildServiceAreaCard(),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: emergencyResponseConsent,
          onChanged: (value) {
            setState(() {
              emergencyResponseConsent = value!;
            });
          },
          title: const Text(
            'I am willing to receive emergency response requests from nearby elderly users.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: locationConsent,
          onChanged: (value) {
            setState(() {
              locationConsent = value!;
            });
          },
          title: const Text(
            'I agree to location-based matching for nearby elderly alerts.',
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
                onPressed: () {
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
                    : () {
                        if (!emergencyResponseConsent || !locationConsent) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please tick both consent checkboxes.',
                              ),
                            ),
                          );
                          return;
                        }

                        registerVolunteer();
                      },
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildLocationSuggestionList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: locationSuggestions.map((location) {
          return ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: Colors.blue,
            ),
            title: Text(location),
            onTap: () {
              setState(() {
                postalCodeController.text = location;
                detectedArea = location;
                locationSuggestions = [];
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildServiceAreaCard() {
    final area = postalCodeController.text.isEmpty
        ? 'your selected area'
        : postalCodeController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2F80ED),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.radar,
              color: Color(0xFF2F80ED),
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Service Area Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102044),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will receive alerts within $selectedDistance of $area.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5D6B82),
              height: 1.4,
            ),
          ),
        ],
      ),
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
              color: Colors.blue.withValues(alpha: 0.12),
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
                Icons.volunteer_activism,
                size: 65,
                color: Color(0xFF55CFC0),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Volunteer Account Created!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102044),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for joining our elderly care network.',
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
            return DropdownMenuItem(value: item, child: Text(item));
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
}