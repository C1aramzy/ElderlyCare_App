import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'LoginPage.dart';
import 'EditElderlyProfilePage.dart';

class ElderlyProfilePage extends StatefulWidget {
  final int userId;

  const ElderlyProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<ElderlyProfilePage> createState() =>
      _ElderlyProfilePageState();
}

class _ElderlyProfilePageState
    extends State<ElderlyProfilePage> {
  bool isLoading = true;
  bool isRefreshing = false;

  String errorMessage = '';

  Map<String, dynamic>? profile;

  static const String profileUrl =
      'http://elderlym.atspace.cc/get_elderly_profile.php';

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile({
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
              'Unable to load profile.',
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
        isRefreshing = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage =
            'Unable to load profile: $e';
      });
    }
  }

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

  String get fullName =>
      valueOrNotProvided(
        profile?['full_name'],
      );

  String get profileImageUrl =>
      profile?['profile_image_url']
              ?.toString()
              .trim() ??
          '';

  String get firstInitial {
    final String name =
        fullName.trim();

    if (name.isEmpty ||
        name == 'Not provided') {
      return '?';
    }

    return name[0].toUpperCase();
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (route) => false,
    );
  }

  void showComingSoon(
    String feature,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
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
          const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
        actions: [
          if (isRefreshing)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 16,
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
              tooltip: 'Refresh',
              onPressed: () {
                fetchProfile(
                  showLoading: false,
                );
              },
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? buildErrorState()
              : RefreshIndicator(
                  onRefresh: () {
                    return fetchProfile(
                      showLoading: false,
                    );
                  },
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    children: [
                      buildProfileHeader(),

                      const SizedBox(
                        height: 20,
                      ),

                      buildSectionTitle(
                        'Personal Information',
                      ),

                      buildInformationCard(
                        children: [
                          buildInfoRow(
                            icon:
                                Icons.email_outlined,
                            label:
                                'Email',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'email'],
                            ),
                          ),
                          buildDivider(),
                          buildInfoRow(
                            icon:
                                Icons.phone_outlined,
                            label:
                                'Phone Number',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'phone'],
                            ),
                          ),
                          buildDivider(),
                          buildInfoRow(
                            icon:
                                Icons.cake_outlined,
                            label:
                                'Age',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'age'],
                            ),
                          ),
                          buildDivider(),
                          buildInfoRow(
                            icon:
                                Icons.wc_outlined,
                            label:
                                'Gender',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'gender'],
                            ),
                          ),
                          buildDivider(),
                          buildInfoRow(
                            icon:
                                Icons
                                    .location_on_outlined,
                            label:
                                'Address',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'address'],
                            ),
                            multiline:
                                true,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      buildSectionTitle(
                        'Care Information',
                      ),

                      buildInformationCard(
                        children: [
                          buildInfoRow(
                            icon:
                                Icons
                                    .medical_services_outlined,
                            label:
                                'Medical Conditions',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'medical_condition'],
                            ),
                            multiline:
                                true,
                          ),
                          buildDivider(),
                          buildInfoRow(
                            icon:
                                Icons
                                    .accessible_outlined,
                            label:
                                'Mobility Status',
                            value:
                                valueOrNotProvided(
                              profile?[
                                  'mobility_status'],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      buildSectionTitle(
                        'Emergency Contact',
                      ),

                      buildEmergencyContactCard(),

                      const SizedBox(
                        height: 20,
                      ),

                      buildSectionTitle(
                        'Account',
                      ),

                      buildAccountCard(),

                      const SizedBox(
                        height: 24,
                      ),

                      buildEditProfileButton(),

                      const SizedBox(
                        height: 12,
                      ),

                      buildChangePasswordButton(),

                      const SizedBox(
                        height: 12,
                      ),

                      buildLogoutButton(),

                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .account_circle_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              errorMessage,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton.icon(
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
      ),
    );
  }

  Widget buildProfileHeader() {
    final String age =
        valueOrNotProvided(
      profile?['age'],
    );

    final String mobility =
        valueOrNotProvided(
      profile?['mobility_status'],
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF6FB1FC),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue
                .withValues(
              alpha: 0.2,
            ),
            blurRadius: 14,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          buildAvatar(),

          const SizedBox(
            height: 14,
          ),

          Text(
            fullName,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Wrap(
            alignment:
                WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (age !=
                  'Not provided')
                buildHeaderChip(
                  icon:
                      Icons.cake_outlined,
                  label:
                      '$age years old',
                ),
              if (mobility !=
                  'Not provided')
                buildHeaderChip(
                  icon:
                      Icons
                          .accessible_outlined,
                  label:
                      mobility,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAvatar() {
    if (profileImageUrl.isNotEmpty) {
      return Container(
        width: 112,
        height: 112,
        decoration:
            BoxDecoration(
          shape:
              BoxShape.circle,
          color:
              Colors.white,
          border:
              Border.all(
            color:
                Colors.white,
            width:
                4,
          ),
        ),
        clipBehavior:
            Clip.antiAlias,
        child:
            Image.network(
          profileImageUrl,
          fit:
              BoxFit.cover,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return buildInitialAvatar();
          },
        ),
      );
    }

    return buildInitialAvatar();
  }

  Widget buildInitialAvatar() {
    return Container(
      width: 112,
      height: 112,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color:
            Colors.white,
        border:
            Border.all(
          color:
              Colors.white,
          width:
              4,
        ),
      ),
      alignment:
          Alignment.center,
      child: Text(
        firstInitial,
        style:
            const TextStyle(
          fontSize: 46,
          fontWeight:
              FontWeight.bold,
          color:
              Color(
            0xFF4A90E2,
          ),
        ),
      ),
    );
  }

  Widget buildHeaderChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.18,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color:
                Colors.white,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w600,
            ),
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
        left: 2,
        bottom: 10,
      ),
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
          color:
              Color(0xFF102044),
        ),
      ),
    );
  }

  Widget buildInformationCard({
    required List<Widget>
        children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
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
        children:
            children,
      ),
    );
  }

  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child:
          Row(
        crossAxisAlignment:
            multiline
                ? CrossAxisAlignment
                    .start
                : CrossAxisAlignment
                    .center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  Colors.blue
                      .withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  Colors.blue[
                      700],
              size:
                  22,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(
                    fontSize:
                        13,
                    color:
                        Colors.grey[
                            600],
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.w600,
                    height:
                        1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return Divider(
      height: 1,
      color:
          Colors.grey.shade200,
    );
  }

  Widget
      buildEmergencyContactCard() {
    final String name =
        valueOrNotProvided(
      profile?['emergency_contact'],
    );

    final String phone =
        valueOrNotProvided(
      profile?['emergency_phone'],
    );

    final String relationship =
        valueOrNotProvided(
      profile?['relationship'],
    );

    return Container(
      width: double.infinity,
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
                width: 55,
                height: 55,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.red
                          .withValues(
                    alpha: 0.1,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .contact_emergency_outlined,
                  color:
                      Colors.red,
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
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .all(
              13,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF5F6FA,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .phone_in_talk_outlined,
                  color:
                      Colors.red,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      Text(
                    phone,
                    style:
                        const TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountCard() {
    return Container(
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
          ListTile(
            leading:
                const Icon(
              Icons
                  .manage_accounts_outlined,
              color:
                  Colors.blue,
            ),
            title:
                const Text(
              'Account Type',
            ),
            subtitle:
                const Text(
              'Elderly / Caregiver Shared Account',
            ),
          ),
          Divider(
            height: 1,
            color:
                Colors.grey.shade200,
          ),
          ListTile(
            leading:
                const Icon(
              Icons
                  .verified_user_outlined,
              color:
                  Colors.green,
            ),
            title:
                const Text(
              'Home Monitoring',
            ),
            subtitle:
                const Text(
              'Monitoring and emergency alerts enabled',
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child:
          ElevatedButton.icon(
        onPressed: profile == null
          ? null
          : () async{
            final bool? updated = 
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                          EditElderlyProfilePage(
                            userId: widget.userId,
                             profile: profile!,
                        ),
                      ),
                    );

                    if(updated == true){
                      await fetchProfile(
                        showLoading: false,
                      );
                    }
                  },
        icon:
            const Icon(
          Icons.edit_outlined,
        ),
        label:
            const Text(
          'Edit Profile',
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.blue,
          foregroundColor:
              Colors.white,
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 15,
          ),
          textStyle:
              const TextStyle(
            fontSize: 16,
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
    );
  }

  Widget
      buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child:
          OutlinedButton.icon(
        onPressed: () {
          showComingSoon(
            'Change Password',
          );
        },
        icon:
            const Icon(
          Icons.lock_outline,
        ),
        label:
            const Text(
          'Change Password',
        ),
        style:
            OutlinedButton.styleFrom(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 15,
          ),
          textStyle:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w600,
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
    );
  }

  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child:
          OutlinedButton.icon(
        onPressed:
            logout,
        icon:
            const Icon(
          Icons.logout,
        ),
        label:
            const Text(
          'Logout',
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              Colors.red,
          side:
              const BorderSide(
            color:
                Colors.red,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 15,
          ),
          textStyle:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w600,
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
    );
  }
}