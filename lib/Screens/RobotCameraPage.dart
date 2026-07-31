import 'package:flutter/material.dart';
import 'package:mjpeg_stream/mjpeg_stream.dart';

class RobotCameraPage extends StatelessWidget {
  const RobotCameraPage({super.key});

  // Change this if your Raspberry Pi IP changes
  static const String raspberryPiIp = '10.63.142.152';

  static const String cameraStreamUrl =
      'http://$raspberryPiIp:5000/video_feed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Robot Camera"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Live Camera Feed",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Use the robot camera to remotely check on the elderly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,

                    child: MJPEGStreamScreen(
                      streamUrl: cameraStreamUrl,
                      showLiveIcon: true,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      timeout: const Duration(seconds: 10),
                      showLogs: true,
                      showWatermark: false,
                      borderRadius: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Future microphone function
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text("Talk"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.call_end),
                      label: const Text("End Session"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}