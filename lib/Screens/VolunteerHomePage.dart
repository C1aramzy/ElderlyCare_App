import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'LoginPage.dart';
import 'RobotCameraPage.dart';
import 'EmergencyAssessmentPage.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() =>
      _VolunteerHomePageState();
}

class _VolunteerHomePageState
    extends State<VolunteerHomePage> {

  //==================================================
  // CONFIG
  //==================================================

  static const int volunteerId = 1;

  static const String dashboardUrl =
      "http://elderlym.atspace.cc/get_volunteer_dashboard.php";

  static const String acceptUrl =
      "http://elderlym.atspace.cc/accept_help_request.php";

  static const String finishUrl =
      "http://elderlym.atspace.cc/finish_help_request.php";

  //==================================================
  // DATA
  //==================================================

  bool isLoading = true;

  bool isRefreshing = false;

  String errorMessage = "";

  Map<String,dynamic>? assignment;

  Map<String,dynamic>? status;

  Map<String,dynamic>? emergency;

  List<dynamic> recentMotion = [];

  bool emergencyAccess = false;

  Timer? refreshTimer;

  //==================================================
  // INIT
  //==================================================

  @override
  void initState() {

    super.initState();

    loadDashboard();

    refreshTimer = Timer.periodic(

      const Duration(seconds:30),

      (timer){

        loadDashboard(
          showLoading:false,
        );

      },

    );

  }

  @override
  void dispose(){

    refreshTimer?.cancel();

    super.dispose();

  }

  //==================================================
  // LOAD DASHBOARD
  //==================================================

  Future<void> loadDashboard({

    bool showLoading=true,

  }) async{

    if(showLoading){

      setState((){

        isLoading=true;

      });

    }else{

      isRefreshing=true;

    }

    try{

      final response = await http.get(

        Uri.parse(

          "$dashboardUrl?volunteer_id=$volunteerId",

        ),

      );

      final data=jsonDecode(response.body);

      if(data["success"]==true){

        if(!mounted)return;

        setState((){

          assignment=data["assignment"];

          status=data["status"];

          emergency=data["emergency"];

          emergencyAccess=
              data["emergency_access"]??false;

          recentMotion=
              data["recent_motion"]??[];

          isLoading=false;

          isRefreshing=false;

          errorMessage="";

        });

      }else{

        throw Exception(

          data["message"],

        );

      }

    }catch(e){

      if(!mounted)return;

      setState((){

        errorMessage=e.toString();

        isLoading=false;

        isRefreshing=false;

      });

    }

  }

  //==================================================
  // ACCEPT EMERGENCY
  //==================================================

  Future<void> acceptEmergency() async{

    if(emergency==null)return;

    try{

      final response=await http.post(

        Uri.parse(acceptUrl),

        body:{

          "request_id":
          emergency!["request_id"].toString(),

          "volunteer_id":
          volunteerId.toString(),

        },

      );

      final data=jsonDecode(response.body);

      if(data["success"]==true){

        await loadDashboard();

      }

      if(!mounted)return;

      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content:Text(

            data["message"],

          ),

        ),

      );

    }catch(e){

      if(!mounted)return;

      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content:Text(e.toString()),

        ),

      );

    }

  }

  //==================================================
  // FINISH EMERGENCY
  //==================================================

  Future<void> finishEmergency({

    required String result,

    String notes="",

  }) async{

    if(emergency==null)return;

    try{

      final response=await http.post(

        Uri.parse(finishUrl),

        body:{

          "request_id":
          emergency!["request_id"].toString(),

          "volunteer_id":
          volunteerId.toString(),

          "assessment_result":
          result,

          "assessment_notes":
          notes,

        },

      );

      final data=jsonDecode(response.body);

      if(data["success"]==true){

        await loadDashboard();

      }

      if(!mounted)return;

      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content:Text(

            data["message"],

          ),

        ),

      );

    }catch(e){

      if(!mounted)return;

      ScaffoldMessenger.of(context)

          .showSnackBar(

        SnackBar(

          content:Text(e.toString()),

        ),

      );

    }
  }
  //==================================================
  // LOGOUT
  //==================================================

  void logout(){

    refreshTimer?.cancel();

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(

        builder:(_)=>const LoginPage(),

      ),

      (route)=>false,

    );

  }

  //==================================================
  // CAMERA
  //==================================================

  void openCamera(){

    if(!emergencyAccess){

      ScaffoldMessenger.of(context)

          .showSnackBar(

        const SnackBar(

          content:Text(

            "Camera is only available while handling an emergency.",

          ),

        ),

      );

      return;

    }

    Navigator.push(

      context,

      MaterialPageRoute(

        builder:(_)=>const RobotCameraPage(),

      ),

    );

  }

  Future<void> callEmergencyContact() async{
    if(!emergencyAccess) return;

    final phone = assignment?["emergency_phone"];

    if(phone == null || phone.toString().isEmpty){
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone.toString(),
    );

    await launchUrl(uri);
  }
//==================================================
// STATUS HELPERS
//==================================================

String getStatusTitle(String status){

  switch(status){

    case "normal_activity":
      return "Normal Activity";

    case "possible_fall":
      return "Possible Fall";

    case "fall_detected":
      return "Fall Detected";

    case "movement_resumed":
      return "Movement Resumed";

    case "no_presence":
      return "No Presence";

    case "sensor_offline":
      return "Sensor Offline";

    default:
      return "Unknown";

  }

}

Color getStatusColor(String status){

  switch(status){

    case "normal_activity":
      return Colors.green;

    case "possible_fall":
      return Colors.orange;

    case "fall_detected":
      return Colors.red;

    case "movement_resumed":
      return Colors.blue;

    case "no_presence":
      return Colors.deepOrange;

    case "sensor_offline":
      return Colors.grey;

    default:
      return Colors.grey;

  }

}

IconData getStatusIcon(String status){

  switch(status){

    case "normal_activity":
      return Icons.directions_walk;

    case "possible_fall":
      return Icons.warning;

    case "fall_detected":
      return Icons.emergency;

    case "movement_resumed":
      return Icons.check_circle;

    case "no_presence":
      return Icons.person_off;

    case "sensor_offline":
      return Icons.wifi_off;

    default:
      return Icons.info;

  }

}

//==================================================
// ASSIGNED ELDERLY CARD
//==================================================

Widget assignedCard(){

  if(assignment==null){

    return const SizedBox();

  }

  return Container(

    width:double.infinity,

    padding:const EdgeInsets.all(20),

    decoration:BoxDecoration(

      gradient:const LinearGradient(

        colors:[

          Color(0xff4A90E2),

          Color(0xff6FB1FC),

        ],

      ),

      borderRadius:
          BorderRadius.circular(22),

    ),

    child:Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children:[

        const Text(

          "Assigned Elderly",

          style:TextStyle(

            color:Colors.white70,

            fontSize:18,

            fontWeight:FontWeight.bold,

          ),

        ),

        const SizedBox(height:18),

        Row(

          children:[

            const CircleAvatar(

              radius:28,

              backgroundColor:Colors.white,

              child:Icon(

                Icons.person,

                color:Colors.blue,

                size:34,

              ),

            ),

            const SizedBox(width:15),

            Expanded(

              child:Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children:[

                  Text(

                    assignment!["full_name"] ??
                        "-",

                    style:const TextStyle(

                      color:Colors.white,

                      fontSize:24,

                      fontWeight:FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height:4),

                  Text(

                    "${assignment!["age"] ?? "-"} years old",

                    style:const TextStyle(

                      color:Colors.white70,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ],

    ),

  );

}

//==================================================
// CURRENT STATUS CARD
//==================================================

Widget monitoringCard(){

  final statusCode =
      status?["current_status"] ??
      "unknown";

  final sensorOnline =
      status?["sensor_online"] == 1 ||
      status?["sensor_online"] == "1";

  return Container(

    width:double.infinity,

    padding:const EdgeInsets.all(20),

    decoration:BoxDecoration(

      gradient:LinearGradient(

        colors:[

          getStatusColor(statusCode),

          getStatusColor(statusCode)
              .withValues(alpha:0.75),

        ],

      ),

      borderRadius:
          BorderRadius.circular(22),

    ),

    child:Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children:[

        const Text(

          "Current Monitoring Status",

          style:TextStyle(

            color:Colors.white70,

            fontSize:18,

            fontWeight:FontWeight.bold,

          ),

        ),

        const SizedBox(height:18),

        Row(

          children:[

            Icon(

              getStatusIcon(statusCode),

              color:Colors.white,

              size:32,

            ),

            const SizedBox(width:12),

            Expanded(

              child:Text(

                getStatusTitle(statusCode),

                style:const TextStyle(

                  color:Colors.white,

                  fontWeight:FontWeight.bold,

                  fontSize:24,

                ),

              ),

            ),

          ],

        ),

        const SizedBox(height:12),

        Text(

          status?["status_description"] ??
              "",

          style:const TextStyle(

            color:Colors.white,

          ),

        ),

        const SizedBox(height:18),

        Row(

          children:[

            Icon(

              Icons.circle,

              size:12,

              color:sensorOnline

                  ? Colors.greenAccent

                  : Colors.white,

            ),

            const SizedBox(width:8),

            Text(

              sensorOnline

                  ? "Sensor Online"

                  : "Sensor Offline",

              style:const TextStyle(

                color:Colors.white,

              ),

            ),

          ],

        ),

      ],

    ),

  );

}
//==================================================
// EMERGENCY CARD
//==================================================

Widget emergencyCard() {

  // No emergency
  if (emergency == null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 45,
          ),
          SizedBox(height: 10),
          Text(
            "No Active Emergency",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Everything is operating normally.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // Pending emergency
  //--------------------------------------------------

  if (emergency!["status"] == "pending") {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          const Text(
            "🚨 EMERGENCY ALERT",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            emergency!["message"] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            emergency!["created_at"] ?? "",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: acceptEmergency,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                "Accept Emergency",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    Colors.red,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
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

  //--------------------------------------------------
  // Volunteer accepted
  //--------------------------------------------------

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "🚨 EMERGENCY BEING ACCESSED",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          "You are currently handling this emergency.",
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 25),

        ElevatedButton.icon(
          onPressed: openCamera,
          icon: const Icon(Icons.videocam),
          label: const Text("Open Camera"),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 50),
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.location_on),
          label: Text(
            assignment?["address"] ??
                "Address Hidden",
          ),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 50),
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: emergencyAccess
              ? callEmergencyContact
              :null,
          icon: const Icon(Icons.phone),
          label: Text(
            assignment?["emergency_contact"] ??
                "Emergency Contact Hidden",
          ),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 50),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon:
                const Icon(Icons.check),
            label: const Text(
              "Finish Emergency Response",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.green,
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
            onPressed: () async {
              final finished = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmergencyAssessmentPage(
                    requestId: int.parse(
                      emergency!["request_id"].toString(),
                    ),

                    volunteerId: volunteerId,
                  ),
                ),
              );

              if(finished == true){
                await loadDashboard();

                if(!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Emergency case closed"),
                    backgroundColor: Colors.green,
                    ), 
                );
              }
            },
          ),
        ),

      ],
    ),
  );
}
//==================================================
// RECENT MOTION CARD
//==================================================

Widget recentMotionCard() {

  return Container(

    width: double.infinity,

    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(

      color: Colors.white,

      borderRadius: BorderRadius.circular(22),

      boxShadow: [

        BoxShadow(

          color: Colors.black.withValues(alpha: 0.05),

          blurRadius: 8,

          offset: const Offset(0,3),

        ),

      ],

    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(

          "Recent Motion Activity",

          style: TextStyle(

            fontSize: 20,

            fontWeight: FontWeight.bold,

          ),

        ),

        const SizedBox(height:18),

        if(recentMotion.isEmpty)

          const Text(

            "No recent motion activity.",

          )

        else

          ...recentMotion.map(

            (motion){

              return Card(

                elevation:0,

                color:const Color(0xffF5F6FA),

                margin:
                    const EdgeInsets.only(
                  bottom:12,
                ),

                child: ListTile(

                  leading: CircleAvatar(

                    backgroundColor:

                        getStatusColor(

                      motion["event_type"] ??
                          "",

                    ),

                    child: Icon(

                      getStatusIcon(

                        motion["event_type"] ??
                            "",

                      ),

                      color: Colors.white,

                    ),

                  ),

                  title: Text(

                    motion["event_description"] ??
                        "",

                  ),

                  subtitle: Text(

                    motion["detected_at"] ??
                        "",

                  ),

                ),

              );

            },

          ),

      ],

    ),

  );

}

//==================================================
// QUICK ACTIONS
//==================================================

Widget quickActionCard(){

  return Container(

    width:double.infinity,

    padding:const EdgeInsets.all(20),

    decoration:BoxDecoration(

      color:Colors.white,

      borderRadius:
          BorderRadius.circular(22),

      boxShadow:[

        BoxShadow(

          color:Colors.black.withValues(
            alpha:0.05,
          ),

          blurRadius:8,

          offset:const Offset(0,3),

        ),

      ],

    ),

    child:Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children:[

        const Text(

          "Quick Actions",

          style:TextStyle(

            fontSize:20,

            fontWeight:FontWeight.bold,

          ),

        ),

        const SizedBox(height:20),

        SizedBox(

          width:double.infinity,

          child:ElevatedButton.icon(

            icon:
                const Icon(Icons.refresh),

            label:
                const Text("Refresh Dashboard"),

            onPressed:(){

              loadDashboard();

            },

          ),

        ),

      ],

    ),

  );

}
@override
Widget build(BuildContext context) {

  return Scaffold(

    backgroundColor: const Color(0xffF5F6FA),

    appBar: AppBar(

      elevation: 0,

      backgroundColor: Colors.white,

      foregroundColor: Colors.black,

      title: const Text(

        "Volunteer Dashboard",

        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),

      ),

      actions: [

        IconButton(

          icon: const Icon(Icons.refresh),

          onPressed: () {

            loadDashboard();

          },

        ),

        IconButton(

          icon: const Icon(Icons.logout),

          onPressed: logout,

        ),

      ],

    ),

    body: isLoading

        ? const Center(

            child:
                CircularProgressIndicator(),

          )

        : RefreshIndicator(

            onRefresh: loadDashboard,

            child: ListView(

              padding:
                  const EdgeInsets.all(18),

              children: [

                Text(

                  "Welcome Volunteer",

                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(

                        fontWeight:
                            FontWeight.bold,

                      ),

                ),

                const SizedBox(height: 6),

                Text(

                  "Monitor your assigned elderly and respond quickly during emergencies.",

                  style: TextStyle(

                    color: Colors.grey[700],

                  ),

                ),

                const SizedBox(height: 22),

                //-----------------------------------
                // Assigned Elderly
                //-----------------------------------

                assignedCard(),

                const SizedBox(height: 18),

                //-----------------------------------
                // Monitoring Status
                //-----------------------------------

                monitoringCard(),

                const SizedBox(height: 18),

                //-----------------------------------
                // Emergency
                //-----------------------------------

                emergencyCard(),

                const SizedBox(height: 18),

                //-----------------------------------
                // Motion
                //-----------------------------------

                recentMotionCard(),

                const SizedBox(height: 18),

                //-----------------------------------
                // Quick Actions
                //-----------------------------------

                quickActionCard(),

                const SizedBox(height: 30),

              ],

            ),

          ),

    );

  }
}