import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mjpeg_stream/mjpeg_stream.dart';

class RobotCameraPage extends StatefulWidget {
  const RobotCameraPage({super.key});

  @override
  State<RobotCameraPage> createState() => _RobotCameraPageState();
}

class _RobotCameraPageState extends State<RobotCameraPage>
    with WidgetsBindingObserver {
  // ==================================================
  // Raspberry Pi configuration
  // ==================================================

  // Use the Pi IP address during testing.
  // You can try "pi.local" later if mDNS works on the phone.
  static const String raspberryPiAddress = '10.150.2.152';

  static const String cameraBaseUrl =
      'http://$raspberryPiAddress:5000';

  static const String teleopBaseUrl =
      'http://$raspberryPiAddress:5001';

  static const String cameraStreamUrl =
      '$cameraBaseUrl/video_feed';

  static const String teleopStatusUrl =
      '$teleopBaseUrl/status';

  static const String emergencyStopUrl =
      '$teleopBaseUrl/emergency_stop';

  // Add the API key only when your groupmate confirms
  // how the key must be sent.
  //
  // For example:
  // static const String robotApiKey = 'YOUR_API_KEY';
  //
  // Then add it inside _requestHeaders.
  static const Map<String, String> _requestHeaders = {
    'Accept': 'application/json',

    // Uncomment only if the robot server expects this header:
    // 'X-API-Key': robotApiKey,

    // Or it may expect:
    // 'Authorization': 'Bearer $robotApiKey',
  };

  // ==================================================
  // Controller settings and state
  // ==================================================

  static const Duration commandInterval =
      Duration(milliseconds: 300);

  static const Duration requestTimeout =
      Duration(seconds: 3);

  Timer? _movementTimer;

  String? _activeDirection;

  bool _teleopOnline = false;
  bool _checkingStatus = true;
  bool _emergencyStopping = false;

  String _statusMessage = 'Checking robot connection...';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkTeleopStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _movementTimer?.cancel();

    // Send a final stop command when this page is closed.
    // dispose() cannot await an asynchronous operation.
    _sendStopCommand(showError: false);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop the robot if the app becomes inactive,
    // enters the background, or loses focus.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopMovement(showError: false);
    }
  }

  // ==================================================
  // Robot API functions
  // ==================================================

  Future<void> _checkTeleopStatus() async {
    if (mounted) {
      setState(() {
        _checkingStatus = true;
        _statusMessage = 'Checking robot connection...';
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse(teleopStatusUrl),
            headers: _requestHeaders,
          )
          .timeout(requestTimeout);

      final bool online =
          response.statusCode >= 200 &&
          response.statusCode < 300;

      if (!mounted) return;

      setState(() {
        _teleopOnline = online;
        _checkingStatus = false;
        _statusMessage = online
            ? 'Robot controls connected'
            : 'Robot API returned ${response.statusCode}';
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _teleopOnline = false;
        _checkingStatus = false;
        _statusMessage = 'Robot connection timed out';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _teleopOnline = false;
        _checkingStatus = false;
        _statusMessage = 'Robot controls unavailable';
      });

      debugPrint('Teleop status error: $error');
    }
  }

  Future<bool> _sendMovementCommand(
    String direction, {
    bool showError = true,
  }) async {
    final Uri url = Uri.parse(
      '$teleopBaseUrl/move/$direction',
    );

    try {
      // These endpoints are assumed to use GET.
      // Change http.get to http.post only if your
      // groupmate confirms that the API requires POST.
      final response = await http
          .get(
            url,
            headers: _requestHeaders,
          )
          .timeout(requestTimeout);

      final bool successful =
          response.statusCode >= 200 &&
          response.statusCode < 300;

      if (!successful && showError) {
        _showMessage(
          'Robot command failed: ${response.statusCode}',
        );
      }

      if (mounted && successful && !_teleopOnline) {
        setState(() {
          _teleopOnline = true;
          _statusMessage = 'Robot controls connected';
        });
      }

      return successful;
    } on TimeoutException {
      if (showError) {
        _showMessage('Robot command timed out.');
      }

      return false;
    } catch (error) {
      debugPrint('Movement command error: $error');

      if (showError) {
        _showMessage('Unable to contact the robot.');
      }

      return false;
    }
  }

  Future<void> _sendStopCommand({
    bool showError = true,
  }) async {
    await _sendMovementCommand(
      'stop',
      showError: showError,
    );
  }

  void _startMovement(String direction) {
    // Avoid starting multiple timers for the same press.
    if (_activeDirection == direction &&
        _movementTimer?.isActive == true) {
      return;
    }

    _movementTimer?.cancel();

    setState(() {
      _activeDirection = direction;
    });

    // Send immediately instead of waiting 300 ms.
    _sendMovementCommand(direction);

    // Continue sending every 300 ms while held.
    _movementTimer = Timer.periodic(
      commandInterval,
      (_) {
        if (_activeDirection == direction) {
          _sendMovementCommand(
            direction,
            showError: false,
          );
        }
      },
    );
  }

  Future<void> _stopMovement({
    bool showError = true,
  }) async {
    _movementTimer?.cancel();
    _movementTimer = null;

    if (mounted) {
      setState(() {
        _activeDirection = null;
      });
    } else {
      _activeDirection = null;
    }

    await _sendStopCommand(showError: showError);
  }

  Future<void> _activateEmergencyStop() async {
    _movementTimer?.cancel();
    _movementTimer = null;

    setState(() {
      _activeDirection = null;
      _emergencyStopping = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse(emergencyStopUrl),
            headers: _requestHeaders,
          )
          .timeout(requestTimeout);

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        _showMessage(
          'Emergency stop activated.',
          backgroundColor: Colors.red,
        );
      } else {
        _showMessage(
          'Emergency stop failed: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      if (mounted) {
        _showMessage('Emergency stop request timed out.');
      }
    } catch (error) {
      debugPrint('Emergency stop error: $error');

      if (mounted) {
        _showMessage(
          'Unable to contact the robot.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _emergencyStopping = false;
        });
      }
    }
  }

  Future<void> _endSession() async {
    await _stopMovement(showError: false);

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

  // ==================================================
  // Controller widgets
  // ==================================================

  Widget _movementButton({
    required String direction,
    required IconData icon,
    required String tooltip,
  }) {
    final bool isPressed =
        _activeDirection == direction;

    return Listener(
      behavior: HitTestBehavior.opaque,

      onPointerDown: (_) {
        _startMovement(direction);
      },

      onPointerUp: (_) {
        _stopMovement();
      },

      onPointerCancel: (_) {
        _stopMovement(showError: false);
      },

      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isPressed
                ? Colors.blue.shade700
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.blue.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isPressed ? 0.06 : 0.12,
                ),
                blurRadius: isPressed ? 3 : 8,
                offset: Offset(
                  0,
                  isPressed ? 1 : 4,
                ),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 36,
            color: isPressed
                ? Colors.white
                : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildRobotController() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.gamepad_outlined,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Robot Movement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh robot status',
                onPressed: _checkingStatus
                    ? null
                    : _checkTeleopStatus,
                icon: _checkingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _teleopOnline
                    ? Icons.circle
                    : Icons.error_outline,
                size: 13,
                color: _teleopOnline
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _teleopOnline
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _movementButton(
            direction: 'forward',
            icon: Icons.keyboard_arrow_up,
            tooltip: 'Hold to move forward',
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _movementButton(
                direction: 'left',
                icon: Icons.keyboard_arrow_left,
                tooltip: 'Hold to turn left',
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: () {
                  _stopMovement();
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              _movementButton(
                direction: 'right',
                icon: Icons.keyboard_arrow_right,
                tooltip: 'Hold to turn right',
              ),
            ],
          ),

          const SizedBox(height: 10),

          _movementButton(
            direction: 'backward',
            icon: Icons.keyboard_arrow_down,
            tooltip: 'Hold to move backward',
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _emergencyStopping
                  ? null
                  : _activateEmergencyStop,
              icon: _emergencyStopping
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.warning_amber_rounded,
                    ),
              label: Text(
                _emergencyStopping
                    ? 'Stopping Robot...'
                    : 'Emergency Stop',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Press and hold a direction button to move. '
            'Releasing it automatically stops the robot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // Page
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        Object? result,
      ) async {
        if (didPop) return;

        await _stopMovement(showError: false);

        if (!context.mounted) return;

        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Robot Check-In'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Live Camera Feed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Use the robot camera and controls to '
                    'remotely check on the elderly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      height: 310,
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

                const SizedBox(height: 20),

                _buildRobotController(),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showMessage(
                              'Talk function will be added later.',
                            );
                          },
                          icon: const Icon(Icons.mic),
                          label: const Text('Talk'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _endSession,
                          icon: const Icon(Icons.call_end),
                          label: const Text('End Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}