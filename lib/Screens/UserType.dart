import 'package:flutter/material.dart';
import 'ElderlyRegistrationPage.dart';
import 'VolunteerRegistrationPage.dart';

class UserTypePage extends StatefulWidget {
  const UserTypePage({super.key});

  @override
  State<UserTypePage> createState() => _UserTypePageState();
}

class _UserTypePageState extends State<UserTypePage> {
  String selectedUserType = 'elderly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F7),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF8F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            Navigator.pop(context);
          },          
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select\nuser type',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 30),

                  userTypeCard(
                    type: 'elderly',
                    title: 'Elderly User',
                    subtitle: 'Request help and receive care support',
                    icon: Icons.elderly,
                    color: Color(0xFF55CFC0),
                  ),

                  const SizedBox(height: 18),

                  userTypeCard(
                    type: 'volunteer',
                    title: 'Volunteer Caregiver',
                    subtitle: 'Help elderly users near your location',
                    icon: Icons.volunteer_activism,
                    color: Color(0xFF2F80ED),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        if (selectedUserType == 'elderly') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ElderlyRegistrationPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VolunteerRegistrationPage(),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget userTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final bool isSelected = selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUserType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 50,
              color: isSelected ? Colors.white : color,
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}