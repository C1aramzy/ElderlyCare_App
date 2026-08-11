import 'dart:async';
<<<<<<< HEAD
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:mjpeg_stream/mjpeg_stream.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
=======

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mjpeg_stream/mjpeg_stream.dart';
>>>>>>> origin/main

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

<<<<<<< HEAD
  // Fixed Raspberry Pi hostname
  static const String raspberryPiAddress = '10.21.170.152';

  // Camera API
  static const String cameraBaseUrl =
      'http://$raspberryPiAddress:5000';

  // Robot control / Nav2 API
  static const String teleopBaseUrl =
      'http://$raspberryPiAddress:5001';

  // Two-way audio WebSocket
  static const String audioWebSocketUrl =
      'ws://$raspberryPiAddress:5002';

=======
  // Use the Pi IP address during testing.
  // You can try "pi.local" later if mDNS works on the phone.
  static const String raspberryPiAddress = '10.150.2.152';

  static const String cameraBaseUrl =
      'http://$raspberryPiAddress:5000';

  static const String teleopBaseUrl =
      'http://$raspberryPiAddress:5001';

>>>>>>> origin/main
  static const String cameraStreamUrl =
      '$cameraBaseUrl/video_feed';

  static const String teleopStatusUrl =
      '$teleopBaseUrl/status';

  static const String emergencyStopUrl =
      '$teleopBaseUrl/emergency_stop';

<<<<<<< HEAD
  static const Map<String, String> _requestHeaders = {
    'Accept': 'application/json',
  };

  // ==================================================
  // Controller settings
=======
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
>>>>>>> origin/main
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

<<<<<<< HEAD
  // ==================================================
  // Audio settings
  // ==================================================

  // Must match Raspberry Pi audio_server.py
  static const int audioSampleRate = 16000;
  static const int audioChannels = 1;
  static const int audioBufferSize = 4096;

  final AudioRecorder _audioRecorder = AudioRecorder();

  final FlutterSoundPlayer _audioPlayer =
      FlutterSoundPlayer();

  WebSocketChannel? _audioChannel;

  StreamSubscription<Uint8List>?
      _microphoneSubscription;

  StreamSubscription<dynamic>?
      _webSocketSubscription;

  bool _audioConnected = false;
  bool _audioStarting = false;
  bool _playerOpened = false;
  bool _closingAudio = false;

  String _audioStatus = 'Audio disconnected';

  // This is used to keep incoming audio buffers
  // in the correct playback order.
  Future<void> _playbackQueue = Future.value();

  // ==================================================
  // Init
  // ==================================================

=======
>>>>>>> origin/main
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkTeleopStatus();
  }

<<<<<<< HEAD
  // ==================================================
  // Dispose
  // ==================================================

=======
>>>>>>> origin/main
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _movementTimer?.cancel();

<<<<<<< HEAD
    // Stop robot when leaving page.
    unawaited(
      _sendStopCommand(
        showError: false,
      ),
    );

    // Clean up audio.
    unawaited(_disposeAudioResources());
=======
    // Send a final stop command when this page is closed.
    // dispose() cannot await an asynchronous operation.
    _sendStopCommand(showError: false);
>>>>>>> origin/main

    super.dispose();
  }

<<<<<<< HEAD
  Future<void> _disposeAudioResources() async {
    await _shutdownAudio();

    try {
      await _audioRecorder.dispose();
    } catch (error) {
      debugPrint(
        'Audio recorder dispose error: $error',
      );
    }
  }

  // ==================================================
  // App lifecycle
  // ==================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
=======
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop the robot if the app becomes inactive,
    // enters the background, or loses focus.
>>>>>>> origin/main
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
<<<<<<< HEAD
      _stopMovement(
        showError: false,
      );

      _stopAudioSession(
        showMessage: false,
      );
=======
      _stopMovement(showError: false);
>>>>>>> origin/main
    }
  }

  // ==================================================
<<<<<<< HEAD
  // Robot status
=======
  // Robot API functions
>>>>>>> origin/main
  // ==================================================

  Future<void> _checkTeleopStatus() async {
    if (mounted) {
      setState(() {
        _checkingStatus = true;
<<<<<<< HEAD
        _statusMessage =
            'Checking robot connection...';
=======
        _statusMessage = 'Checking robot connection...';
>>>>>>> origin/main
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
<<<<<<< HEAD

=======
>>>>>>> origin/main
        _statusMessage = online
            ? 'Robot controls connected'
            : 'Robot API returned ${response.statusCode}';
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _teleopOnline = false;
        _checkingStatus = false;
<<<<<<< HEAD
        _statusMessage =
            'Robot connection timed out';
=======
        _statusMessage = 'Robot connection timed out';
>>>>>>> origin/main
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _teleopOnline = false;
        _checkingStatus = false;
<<<<<<< HEAD
        _statusMessage =
            'Robot controls unavailable';
      });

      debugPrint(
        'Teleop status error: $error',
      );
    }
  }

  // ==================================================
  // Robot movement API
  // ==================================================

=======
        _statusMessage = 'Robot controls unavailable';
      });

      debugPrint('Teleop status error: $error');
    }
  }

>>>>>>> origin/main
  Future<bool> _sendMovementCommand(
    String direction, {
    bool showError = true,
  }) async {
    final Uri url = Uri.parse(
      '$teleopBaseUrl/move/$direction',
    );

    try {
<<<<<<< HEAD
=======
      // These endpoints are assumed to use GET.
      // Change http.get to http.post only if your
      // groupmate confirms that the API requires POST.
>>>>>>> origin/main
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
<<<<<<< HEAD
          'Robot command failed: '
          '${response.statusCode}',
        );
      }

      if (mounted &&
          successful &&
          !_teleopOnline) {
        setState(() {
          _teleopOnline = true;
          _statusMessage =
              'Robot controls connected';
=======
          'Robot command failed: ${response.statusCode}',
        );
      }

      if (mounted && successful && !_teleopOnline) {
        setState(() {
          _teleopOnline = true;
          _statusMessage = 'Robot controls connected';
>>>>>>> origin/main
        });
      }

      return successful;
    } on TimeoutException {
      if (showError) {
<<<<<<< HEAD
        _showMessage(
          'Robot command timed out.',
        );
=======
        _showMessage('Robot command timed out.');
>>>>>>> origin/main
      }

      return false;
    } catch (error) {
<<<<<<< HEAD
      debugPrint(
        'Movement command error: $error',
      );

      if (showError) {
        _showMessage(
          'Unable to contact the robot.',
        );
=======
      debugPrint('Movement command error: $error');

      if (showError) {
        _showMessage('Unable to contact the robot.');
>>>>>>> origin/main
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

<<<<<<< HEAD
  void _startMovement(
    String direction,
  ) {
=======
  void _startMovement(String direction) {
    // Avoid starting multiple timers for the same press.
>>>>>>> origin/main
    if (_activeDirection == direction &&
        _movementTimer?.isActive == true) {
      return;
    }

    _movementTimer?.cancel();

<<<<<<< HEAD
    if (mounted) {
      setState(() {
        _activeDirection = direction;
      });
    }

    // Send immediately
    _sendMovementCommand(direction);

    // Continue sending while button is held
    _movementTimer =
        Timer.periodic(commandInterval, (_) {
      if (_activeDirection == direction) {
        _sendMovementCommand(
          direction,
          showError: false,
        );
      }
    });
=======
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
>>>>>>> origin/main
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

<<<<<<< HEAD
    await _sendStopCommand(
      showError: showError,
    );
  }

  // ==================================================
  // Emergency stop
  // ==================================================

  Future<void>
      _activateEmergencyStop() async {
    _movementTimer?.cancel();

    _movementTimer = null;

    if (mounted) {
      setState(() {
        _activeDirection = null;
        _emergencyStopping = true;
      });
    }
=======
    await _sendStopCommand(showError: showError);
  }

  Future<void> _activateEmergencyStop() async {
    _movementTimer?.cancel();
    _movementTimer = null;

    setState(() {
      _activeDirection = null;
      _emergencyStopping = true;
    });
>>>>>>> origin/main

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
<<<<<<< HEAD
          'Emergency stop failed: '
          '${response.statusCode}',
=======
          'Emergency stop failed: ${response.statusCode}',
>>>>>>> origin/main
        );
      }
    } on TimeoutException {
      if (mounted) {
<<<<<<< HEAD
        _showMessage(
          'Emergency stop request timed out.',
        );
      }
    } catch (error) {
      debugPrint(
        'Emergency stop error: $error',
      );
=======
        _showMessage('Emergency stop request timed out.');
      }
    } catch (error) {
      debugPrint('Emergency stop error: $error');
>>>>>>> origin/main

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

<<<<<<< HEAD
  // ==================================================
  // TWO-WAY AUDIO
  // ==================================================

  Future<void> _toggleAudioSession() async {
    if (_audioStarting) {
      return;
    }

    if (_audioConnected) {
      await _stopAudioSession();
    } else {
      await _startAudioSession();
    }
  }

  // ==================================================
  // Start two-way audio
  // ==================================================

  Future<void> _startAudioSession() async {
    if (_audioConnected ||
        _audioStarting) {
      return;
    }

    if (mounted) {
      setState(() {
        _audioStarting = true;
        _audioStatus =
            'Connecting audio...';
      });
    }

    try {
      // ----------------------------------------------
      // 1. Check microphone permission
      // ----------------------------------------------

      final bool hasPermission =
          await _audioRecorder.hasPermission();

      if (!hasPermission) {
        throw Exception(
          'Microphone permission denied',
        );
      }

      // ----------------------------------------------
      // 2. Open phone speaker/player
      // ----------------------------------------------

      if (!_playerOpened) {
        await _audioPlayer.openPlayer();

        _playerOpened = true;
      }

      // ----------------------------------------------
      // 3. Prepare Flutter Sound for raw PCM
      // ----------------------------------------------
      //
      // FIX:
      // interleaved is now required.
      //
      // Raspberry Pi sends:
      // PCM16
      // 16000 Hz
      // Mono
      // Little endian
      // ----------------------------------------------

      await _audioPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: audioChannels,
        sampleRate: audioSampleRate,
        bufferSize: audioBufferSize,
      );

      // ----------------------------------------------
      // 4. Connect WebSocket
      // ----------------------------------------------

      final WebSocketChannel channel =
          WebSocketChannel.connect(
        Uri.parse(audioWebSocketUrl),
      );

      // Wait until connection really succeeds
      await channel.ready.timeout(
        const Duration(seconds: 5),
      );

      _audioChannel = channel;

      debugPrint(
        'Audio WebSocket connected: '
        '$audioWebSocketUrl',
      );

      // ----------------------------------------------
      // 5. Listen for audio from robot
      // ----------------------------------------------
      //
      // Robot Bluetooth mic
      //        ↓
      // Raspberry Pi
      //        ↓
      // WebSocket
      //        ↓
      // Phone speaker
      // ----------------------------------------------

      _webSocketSubscription =
          channel.stream.listen(
        (dynamic data) {
          if (_closingAudio) {
            return;
          }

          Uint8List? audioData;

          if (data is Uint8List) {
            audioData = data;
          } else if (data is List<int>) {
            audioData =
                Uint8List.fromList(data);
          }

          if (audioData == null ||
              audioData.isEmpty) {
            return;
          }

          _queueIncomingAudio(audioData);
        },
        onError: (Object error) {
          debugPrint(
            'Audio WebSocket error: $error',
          );

          if (!_closingAudio &&
              mounted) {
            setState(() {
              _audioConnected = false;
              _audioStarting = false;
              _audioStatus =
                  'Audio connection lost';
            });
          }
        },
        onDone: () {
          debugPrint(
            'Audio WebSocket disconnected',
          );

          if (!_closingAudio &&
              mounted) {
            setState(() {
              _audioConnected = false;
              _audioStarting = false;
              _audioStatus =
                  'Audio disconnected';
            });
          }
        },
        cancelOnError: false,
      );

      // ----------------------------------------------
      // 6. Start phone microphone
      // ----------------------------------------------

      final Stream<Uint8List>
          microphoneStream =
          await _audioRecorder.startStream(
        const RecordConfig(
          encoder:
              AudioEncoder.pcm16bits,

          sampleRate:
              audioSampleRate,

          numChannels:
              audioChannels,

          // Communication processing
          echoCancel: true,
          noiseSuppress: true,
          autoGain: true,

          // Small packets for live audio
          streamBufferSize: 1024,
        ),
      );

      // Mark connected before receiving mic packets
      _audioConnected = true;

      // ----------------------------------------------
      // 7. Phone microphone -> robot speaker
      // ----------------------------------------------

      _microphoneSubscription =
          microphoneStream.listen(
        (Uint8List audioData) {
          if (!_audioConnected ||
              _closingAudio) {
            return;
          }

          if (audioData.isEmpty) {
            return;
          }

          try {
            _audioChannel?.sink.add(
              audioData,
            );
          } catch (error) {
            debugPrint(
              'Microphone send error: $error',
            );
          }
        },
        onError: (Object error) {
          debugPrint(
            'Microphone stream error: $error',
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _audioConnected = true;
        _audioStarting = false;
        _audioStatus =
            'Two-way audio connected';
      });

      _showMessage(
        'Two-way audio connected.',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      debugPrint(
        'Unable to start audio: $error',
      );

      await _shutdownAudio();

      if (!mounted) return;

      setState(() {
        _audioConnected = false;
        _audioStarting = false;
        _audioStatus =
            'Audio unavailable';
      });

      _showMessage(
        'Unable to connect two-way audio.',
      );
    }
  }

  // ==================================================
  // Incoming robot audio playback
  // ==================================================

  void _queueIncomingAudio(
    Uint8List audioData,
  ) {
    // Flutter Sound says buffers using
    // feedUint8FromStream should be awaited.
    //
    // This queue prevents several WebSocket packets
    // from being fed to the player at the same time.

    _playbackQueue =
        _playbackQueue.then((_) async {
      if (_closingAudio ||
          !_playerOpened ||
          !_audioPlayer.isPlaying) {
        return;
      }

      try {
        await _audioPlayer
            .feedUint8FromStream(
          audioData,
        );
      } catch (error) {
        debugPrint(
          'Audio playback error: $error',
        );
      }
    });
  }

  // ==================================================
  // Stop audio
  // ==================================================

  Future<void> _stopAudioSession({
    bool showMessage = true,
  }) async {
    if (!_audioConnected &&
        !_audioStarting) {
      return;
    }

    if (mounted) {
      setState(() {
        _audioStarting = true;
        _audioStatus =
            'Disconnecting audio...';
      });
    }

    await _shutdownAudio();

    if (!mounted) {
      return;
    }

    setState(() {
      _audioConnected = false;
      _audioStarting = false;
      _audioStatus =
          'Audio disconnected';
    });

    if (showMessage) {
      _showMessage(
        'Two-way audio disconnected.',
      );
    }
  }

  // ==================================================
  // Audio cleanup
  // ==================================================

  Future<void> _shutdownAudio() async {
    if (_closingAudio) {
      return;
    }

    _closingAudio = true;

    _audioConnected = false;

    // ----------------------------------------------
    // Stop phone microphone stream
    // ----------------------------------------------

    try {
      await _microphoneSubscription
          ?.cancel();
    } catch (error) {
      debugPrint(
        'Mic subscription stop error: $error',
      );
    }

    _microphoneSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (error) {
      debugPrint(
        'Recorder stop error: $error',
      );
    }

    // ----------------------------------------------
    // Stop WebSocket listener
    // ----------------------------------------------

    try {
      await _webSocketSubscription
          ?.cancel();
    } catch (error) {
      debugPrint(
        'WebSocket subscription stop error: $error',
      );
    }

    _webSocketSubscription = null;

    // ----------------------------------------------
    // Close WebSocket
    // ----------------------------------------------

    try {
      await _audioChannel?.sink.close();
    } catch (error) {
      debugPrint(
        'WebSocket close error: $error',
      );
    }

    _audioChannel = null;

    // ----------------------------------------------
    // Stop phone speaker
    // ----------------------------------------------

    try {
      if (_audioPlayer.isPlaying) {
        await _audioPlayer.stopPlayer();
      }
    } catch (error) {
      debugPrint(
        'Player stop error: $error',
      );
    }

    if (_playerOpened) {
      try {
        await _audioPlayer.closePlayer();
      } catch (error) {
        debugPrint(
          'Player close error: $error',
        );
      }

      _playerOpened = false;
    }

    // Reset playback queue
    _playbackQueue = Future.value();

    _closingAudio = false;
  }

  // ==================================================
  // End entire robot session
  // ==================================================

  Future<void> _endSession() async {
    await _stopMovement(
      showError: false,
    );

    await _stopAudioSession(
      showMessage: false,
    );
=======
  Future<void> _endSession() async {
    await _stopMovement(showError: false);
>>>>>>> origin/main

    if (!mounted) return;

    Navigator.pop(context);
  }

<<<<<<< HEAD
  // ==================================================
  // Snackbar
  // ==================================================

=======
>>>>>>> origin/main
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
<<<<<<< HEAD
          backgroundColor:
              backgroundColor,
=======
          backgroundColor: backgroundColor,
>>>>>>> origin/main
        ),
      );
  }

  // ==================================================
<<<<<<< HEAD
  // Movement button
=======
  // Controller widgets
>>>>>>> origin/main
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
<<<<<<< HEAD
        _stopMovement(
          showError: false,
        );
=======
        _stopMovement(showError: false);
>>>>>>> origin/main
      },

      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
<<<<<<< HEAD
          duration:
              const Duration(
            milliseconds: 100,
          ),
=======
          duration: const Duration(milliseconds: 100),
>>>>>>> origin/main
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isPressed
                ? Colors.blue.shade700
                : Colors.blue.shade50,
<<<<<<< HEAD
            borderRadius:
                BorderRadius.circular(18),
=======
            borderRadius: BorderRadius.circular(18),
>>>>>>> origin/main
            border: Border.all(
              color: Colors.blue.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
<<<<<<< HEAD
                color:
                    Colors.black.withValues(
                  alpha:
                      isPressed
                          ? 0.06
                          : 0.12,
                ),
                blurRadius:
                    isPressed ? 3 : 8,
=======
                color: Colors.black.withOpacity(
                  isPressed ? 0.06 : 0.12,
                ),
                blurRadius: isPressed ? 3 : 8,
>>>>>>> origin/main
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

<<<<<<< HEAD
  // ==================================================
  // Robot controller UI
  // ==================================================

  Widget _buildRobotController() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
=======
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
>>>>>>> origin/main
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
<<<<<<< HEAD
                    fontWeight:
                        FontWeight.bold,
=======
                    fontWeight: FontWeight.bold,
>>>>>>> origin/main
                  ),
                ),
              ),
              IconButton(
<<<<<<< HEAD
                tooltip:
                    'Refresh robot status',
                onPressed:
                    _checkingStatus
                        ? null
                        : _checkTeleopStatus,
=======
                tooltip: 'Refresh robot status',
                onPressed: _checkingStatus
                    ? null
                    : _checkTeleopStatus,
>>>>>>> origin/main
                icon: _checkingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
<<<<<<< HEAD
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                      ),
=======
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
>>>>>>> origin/main
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
<<<<<<< HEAD
            mainAxisAlignment:
                MainAxisAlignment.center,
=======
            mainAxisAlignment: MainAxisAlignment.center,
>>>>>>> origin/main
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
<<<<<<< HEAD

              const SizedBox(width: 7),

=======
              const SizedBox(width: 7),
>>>>>>> origin/main
              Flexible(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _teleopOnline
<<<<<<< HEAD
                        ? Colors
                            .green.shade700
                        : Colors
                            .orange
                            .shade800,
                    fontWeight:
                        FontWeight.w500,
=======
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
>>>>>>> origin/main
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

<<<<<<< HEAD
          // Forward
          _movementButton(
            direction: 'forward',
            icon:
                Icons.keyboard_arrow_up,
            tooltip:
                'Hold to move forward',
=======
          _movementButton(
            direction: 'forward',
            icon: Icons.keyboard_arrow_up,
            tooltip: 'Hold to move forward',
>>>>>>> origin/main
          ),

          const SizedBox(height: 10),

          Row(
<<<<<<< HEAD
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              // Left
              _movementButton(
                direction: 'left',
                icon: Icons
                    .keyboard_arrow_left,
                tooltip:
                    'Hold to turn left',
=======
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _movementButton(
                direction: 'left',
                icon: Icons.keyboard_arrow_left,
                tooltip: 'Hold to turn left',
>>>>>>> origin/main
              ),

              const SizedBox(width: 12),

<<<<<<< HEAD
              // Stop
=======
>>>>>>> origin/main
              GestureDetector(
                onTap: () {
                  _stopMovement();
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
<<<<<<< HEAD
                    color:
                        Colors.grey.shade800,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
=======
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(18),
>>>>>>> origin/main
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(width: 12),

<<<<<<< HEAD
              // Right
              _movementButton(
                direction: 'right',
                icon: Icons
                    .keyboard_arrow_right,
                tooltip:
                    'Hold to turn right',
=======
              _movementButton(
                direction: 'right',
                icon: Icons.keyboard_arrow_right,
                tooltip: 'Hold to turn right',
>>>>>>> origin/main
              ),
            ],
          ),

          const SizedBox(height: 10),

<<<<<<< HEAD
          // Backward
          _movementButton(
            direction: 'backward',
            icon:
                Icons.keyboard_arrow_down,
            tooltip:
                'Hold to move backward',
=======
          _movementButton(
            direction: 'backward',
            icon: Icons.keyboard_arrow_down,
            tooltip: 'Hold to move backward',
>>>>>>> origin/main
          ),

          const SizedBox(height: 18),

<<<<<<< HEAD
          // Emergency stop
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _emergencyStopping
                      ? null
                      : _activateEmergencyStop,
=======
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _emergencyStopping
                  ? null
                  : _activateEmergencyStop,
>>>>>>> origin/main
              icon: _emergencyStopping
                  ? const SizedBox(
                      width: 19,
                      height: 19,
<<<<<<< HEAD
                      child:
                          CircularProgressIndicator(
=======
                      child: CircularProgressIndicator(
>>>>>>> origin/main
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
<<<<<<< HEAD
                      Icons
                          .warning_amber_rounded,
=======
                      Icons.warning_amber_rounded,
>>>>>>> origin/main
                    ),
              label: Text(
                _emergencyStopping
                    ? 'Stopping Robot...'
                    : 'Emergency Stop',
              ),
<<<<<<< HEAD
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
=======
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
>>>>>>> origin/main
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Press and hold a direction button to move. '
            'Releasing it automatically stops the robot.',
<<<<<<< HEAD
            textAlign:
                TextAlign.center,
=======
            textAlign: TextAlign.center,
>>>>>>> origin/main
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
<<<<<<< HEAD
  // Audio status UI
  // ==================================================

  Widget _buildAudioStatus() {
    Color statusColor;

    if (_audioConnected) {
      statusColor = Colors.green;
    } else if (_audioStarting) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            _audioConnected
                ? Icons.mic
                : Icons.mic_off,
            size: 18,
            color: statusColor,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              _audioStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
=======
>>>>>>> origin/main
  // Page
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
<<<<<<< HEAD

      onPopInvokedWithResult:
          (
=======
      onPopInvokedWithResult: (
>>>>>>> origin/main
        bool didPop,
        Object? result,
      ) async {
        if (didPop) return;

<<<<<<< HEAD
        await _stopMovement(
          showError: false,
        );

        await _stopAudioSession(
          showMessage: false,
        );
=======
        await _stopMovement(showError: false);
>>>>>>> origin/main

        if (!context.mounted) return;

        Navigator.pop(context);
      },
<<<<<<< HEAD

      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F7FA),

        appBar: AppBar(
          title:
              const Text(
            'Robot Check-In',
          ),
          centerTitle: true,
          backgroundColor:
              Colors.blue,
          foregroundColor:
              Colors.white,
        ),

        body: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.only(
              bottom: 24,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),

                // ======================================
                // CAMERA TITLE
                // ======================================
=======
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
>>>>>>> origin/main

                const Text(
                  'Live Camera Feed',
                  style: TextStyle(
                    fontSize: 24,
<<<<<<< HEAD
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Text(
                    'Use the robot camera and controls to '
                    'remotely check on the elderly.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          Colors.black54,
=======
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
>>>>>>> origin/main
                    ),
                  ),
                ),

<<<<<<< HEAD
                const SizedBox(
                  height: 20,
                ),

                // ======================================
                // LIVE CAMERA
                // ======================================

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    child: Container(
                      width:
                          double.infinity,
                      height: 310,
                      color: Colors.black,
                      child:
                          MJPEGStreamScreen(
                        streamUrl:
                            cameraStreamUrl,
                        showLiveIcon: true,
                        fit:
                            BoxFit.contain,
                        width:
                            double.infinity,
                        height:
                            double.infinity,
                        timeout:
                            const Duration(
                          seconds: 10,
                        ),
                        showLogs: true,
                        showWatermark:
                            false,
=======
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
>>>>>>> origin/main
                        borderRadius: 18,
                      ),
                    ),
                  ),
                ),

<<<<<<< HEAD
                const SizedBox(
                  height: 20,
                ),

                // ======================================
                // MOVEMENT CONTROLS
                // ======================================

                _buildRobotController(),

                const SizedBox(
                  height: 16,
                ),

                // ======================================
                // AUDIO STATUS
                // ======================================

                _buildAudioStatus(),

                const SizedBox(
                  height: 12,
                ),

                // ======================================
                // TALK + END SESSION BUTTONS
                // ======================================

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
=======
                const SizedBox(height: 20),

                _buildRobotController(),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(
>>>>>>> origin/main
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
<<<<<<< HEAD
                      // TALK
                      Expanded(
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _audioStarting
                                  ? null
                                  : _toggleAudioSession,

                          icon:
                              _audioStarting
                                  ? const SizedBox(
                                      width:
                                          18,
                                      height:
                                          18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _audioConnected
                                          ? Icons
                                              .mic_off
                                          : Icons
                                              .mic,
                                    ),

                          label: Text(
                            _audioStarting
                                ? 'Connecting...'
                                : _audioConnected
                                    ? 'Stop Talk'
                                    : 'Talk',
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                _audioConnected
                                    ? Colors
                                        .green
                                        .shade700
                                    : Colors
                                        .blue,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
=======
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
>>>>>>> origin/main
                          ),
                        ),
                      ),

<<<<<<< HEAD
                      const SizedBox(
                        width: 12,
                      ),

                      // END SESSION
                      Expanded(
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _endSession,

                          icon:
                              const Icon(
                            Icons.call_end,
                          ),

                          label:
                              const Text(
                            'End Session',
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.red,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
=======
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
>>>>>>> origin/main
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