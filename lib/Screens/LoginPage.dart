<<<<<<< HEAD

=======
>>>>>>> origin/main
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:firebase_messaging/firebase_messaging.dart';
=======
>>>>>>> origin/main

import 'UserType.dart';
import 'ElderlyHomePage.dart';
import 'VolunteerHomePage.dart';
import 'FogotPasswordPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

<<<<<<< HEAD
  // ==================================================
  // Login
  // ==================================================

=======
>>>>>>> origin/main
  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
<<<<<<< HEAD
      final response = await http
          .post(
            Uri.parse(
              'http://elderlym.atspace.cc/login.php',
            ),
            body: {
              'email': emailController.text.trim(),
              'password': passwordController.text.trim(),
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );
=======
      final response = await http.post(
        Uri.parse('http://elderlym.atspace.cc/login.php'),
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        },
      ).timeout(const Duration(seconds: 10));
>>>>>>> origin/main

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['success'] == true) {
<<<<<<< HEAD
        // ==================================================
        // Get logged-in user's ID
        // ==================================================

        final int userId = int.parse(
          data['user_id'].toString(),
        );

        debugPrint('====================================');
        debugPrint('LOGIN SUCCESS');
        debugPrint('User ID: $userId');
        debugPrint('Name: ${data['full_name']}');
        debugPrint('Role: ${data['role']}');
        debugPrint('====================================');

        // ==================================================
        // Get FCM token for this device
        // ==================================================

        try {
          final FirebaseMessaging messaging =
              FirebaseMessaging.instance;

          final String? token =
              await messaging.getToken();

          debugPrint('====================================');
          debugPrint('FCM TOKEN FOR USER $userId');
          debugPrint(token);
          debugPrint('====================================');

          if (token != null && token.isNotEmpty) {
            await saveFcmToken(
              userId: userId,
              token: token,
            );
          } else {
            debugPrint(
              'WARNING: FCM token is null or empty.',
            );
          }
        } catch (e) {
          debugPrint(
            'ERROR GETTING/SAVING FCM TOKEN: $e',
          );
        }

        // ==================================================
        // Continue to correct account
        // ==================================================

=======
>>>>>>> origin/main
        if (data['role'] == 'elderly') {
          showMessage('Login successful.');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
<<<<<<< HEAD
              builder: (context) => ElderlyHomePage(
                userId: userId,
                fullName:
                    data['full_name'] ?? 'User',
=======
              builder: (context) =>  ElderlyHomePage(
                userId: int.parse(data['user_id'].toString()),
                fullName: data["full_name"] ?? 'User',
>>>>>>> origin/main
              ),
            ),
          );
        } else if (data['role'] == 'volunteer') {
          showMessage('Login successful.');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
<<<<<<< HEAD
              builder: (context) =>
                  const VolunteerHomePage(),
            ),
          );
        } else {
          showMessage(
            'Unknown account type: ${data['role']}',
          );
        }
      } else {
        showMessage(
          data['message'] ??
              'Invalid email or password.',
        );
      }
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      showMessage(
        'Unable to login. Please try again later.',
      );
=======
              builder: (context) => const VolunteerHomePage(),
            ),
          );
        } else {
          showMessage('Unknown account type: ${data['role']}');
        }
      } else {
        showMessage(data['message'] ?? 'Invalid email or password.');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to login. Please try again later.');
>>>>>>> origin/main
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

<<<<<<< HEAD
  // ==================================================
  // Save FCM token to ATSpace
  // ==================================================

  Future<void> saveFcmToken({
    required int userId,
    required String token,
  }) async {
    try {
      debugPrint('====================================');
      debugPrint('SAVING FCM TOKEN');
      debugPrint('User ID: $userId');
      debugPrint('====================================');

      final response = await http
          .post(
            Uri.parse(
              'http://elderlym.atspace.cc/save_fcm_token.php',
            ),
            body: {
              'user_id': userId.toString(),
              'fcm_token': token,
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        'FCM TOKEN SERVER STATUS: ${response.statusCode}',
      );

      debugPrint(
        'FCM TOKEN SERVER RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR: FCM token server returned '
          'status ${response.statusCode}.',
        );

        return;
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        debugPrint(
          'FCM TOKEN SAVED SUCCESSFULLY '
          'FOR USER $userId',
        );
      } else {
        debugPrint(
          'FCM TOKEN SAVE FAILED: '
          '${data['message']}',
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR SAVING FCM TOKEN: $e',
      );
    }
  }

  // ==================================================
  // Show message
  // ==================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==================================================
  // Dispose
  // ==================================================

=======
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

>>>>>>> origin/main
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F8FF),
=======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
>>>>>>> origin/main
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
<<<<<<< HEAD
              borderRadius:
                  const BorderRadius.only(
                bottomLeft:
                    Radius.circular(35),
                bottomRight:
                    Radius.circular(35),
=======
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
>>>>>>> origin/main
              ),
              child: Image.asset(
                'lib/Assets/Images/LoginBanner.png',
                width: double.infinity,
                height: 330,
                fit: BoxFit.cover,
              ),
            ),
<<<<<<< HEAD

            Transform.translate(
              offset:
                  const Offset(0, -35),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                ),
                padding:
                    const EdgeInsets.all(25),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey
                          .withOpacity(0.2),
=======
            Transform.translate(
              offset: const Offset(0, -35),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
>>>>>>> origin/main
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
<<<<<<< HEAD
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(
=======
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(

>>>>>>> origin/main
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
<<<<<<< HEAD
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF102044),
                            ),
                          ),

                          SizedBox(height: 8),

=======
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102044),
                            ),
                          ),
                          SizedBox(height: 8),
>>>>>>> origin/main
                          Text(
                            'Login to continue to your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Email',
<<<<<<< HEAD
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          emailController,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Enter your email address',
                        prefixIcon:
                            const Icon(
                          Icons.person_outline,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
=======
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
>>>>>>> origin/main
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Password',
<<<<<<< HEAD
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          passwordController,
                      obscureText:
                          !isPasswordVisible,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Enter your password',

                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                        ),

                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons
                                    .visibility_off_outlined
                                : Icons
                                    .visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible =
                                  !isPasswordVisible;
                            });
                          },
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment:
                          Alignment.centerRight,
=======
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    
                    Align(
                      alignment: Alignment.centerRight,
>>>>>>> origin/main
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
<<<<<<< HEAD
                              builder:
                                  (context) =>
                                      const ForgotPasswordPage(),
=======
                              builder: (context) => const ForgotPasswordPage(),
>>>>>>> origin/main
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
<<<<<<< HEAD
                          style: TextStyle(
                            color:
                                Color(0xFF3B5F91),
                            fontWeight:
                                FontWeight.bold,
=======
                          style:TextStyle(
                            color: Color(0xFF3B5F91),
                            fontWeight: FontWeight.bold,  
>>>>>>> origin/main
                          ),
                        ),
                      ),
                    ),
<<<<<<< HEAD

=======
>>>>>>> origin/main
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
<<<<<<< HEAD
                      child:
                          ElevatedButton(
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.blue,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),

                        onPressed:
                            isLoading
                                ? null
                                : loginUser,

                        child: Text(
                          isLoading
                              ? 'Logging In...'
                              : 'Log In',
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
=======
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: isLoading ? null : loginUser,
                        child: Text(
                          isLoading ? 'Logging In...' : 'Log In',
                          style: const TextStyle(fontSize: 16),
>>>>>>> origin/main
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

<<<<<<< HEAD
                    const Center(
                      child: Text('or'),
                    ),
=======
                    const Center(child: Text('or')),
>>>>>>> origin/main

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
<<<<<<< HEAD
                      child:
                          OutlinedButton.icon(
                        onPressed: () {},

                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 30,
                        ),

                        label: const Text(
                          'Continue with Google',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
=======
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
>>>>>>> origin/main
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
<<<<<<< HEAD
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                        ),

=======
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
>>>>>>> origin/main
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
<<<<<<< HEAD
                                builder:
                                    (context) =>
                                        const UserTypePage(),
                              ),
                            );
                          },

                          child:
                              const Text(
                            'Sign Up',
                          ),
=======
                                builder: (context) => const UserTypePage(),
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
>>>>>>> origin/main
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}

=======
}
>>>>>>> origin/main
