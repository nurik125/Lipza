import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SilentDetectingPage extends StatefulWidget {
  const SilentDetectingPage({super.key});

  @override
  State<SilentDetectingPage> createState() => _SilentDetectingPageState();
}

class _SilentDetectingPageState extends State<SilentDetectingPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String? _cameraErrorMessage;
  bool _isRecording = false;
  Timer? _recordingTimer;
  double _recordingProgress = 0.0;
  String? _lastPredictionLabel;
  double? _lastPredictionConfidence;
  double? _lastPredictionTime;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _initCamera());
  }

  Future<void> _initCamera() async {
    try {
      debugPrint('Requesting camera permission...');
      final cameraStatus = await Permission.camera.request();
      debugPrint('Camera permission: $cameraStatus');
      
      debugPrint('Requesting microphone permission...');
      final micStatus = await Permission.microphone.request();
      debugPrint('Microphone permission: $micStatus');
      
      if (!cameraStatus.isGranted) {
        debugPrint('Camera permission denied');
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _cameraErrorMessage = 'Camera permission denied. Please enable it in settings.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera permission required'), duration: Duration(seconds: 3))
          );
        }
        return;
      }
      
      debugPrint('Getting available cameras...');
      final cameras = await availableCameras();
      debugPrint('Available cameras: ${cameras.length}');
      
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _cameraErrorMessage = 'No cameras found on device';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No cameras available'), duration: Duration(seconds: 3))
          );
        }
        return;
      }
      
      debugPrint('Selecting front camera...');
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      debugPrint('Selected camera: ${front.name}');
      
      debugPrint('Creating camera controller...');
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      debugPrint('Initializing camera controller...');
      await _cameraController!.initialize();
      
      debugPrint('Camera initialized successfully');
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
          _cameraErrorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = 'Camera error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), duration: Duration(seconds: 3))
        );
      }
    }
  }

  Future<Directory> _videosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (!_isRecording) {
      // START recording
      try {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingProgress = 0.0;
          _lastPredictionLabel = null;
          _lastPredictionConfidence = null;
          _lastPredictionTime = null;
        });

        // Start 5s timer with progress updates
        int elapsed = 0;
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
          elapsed += 100;
          setState(() => _recordingProgress = (elapsed / 5000).clamp(0.0, 1.0));
          if (elapsed >= 5000) {
            timer.cancel();
            // Auto-stop at 5s
            _finishRecording();
          }
        });
      } catch (e) {
        debugPrint('Recording start error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed to start')));
      }
    } else {
      // STOP recording manually
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    _recordingTimer?.cancel();
    if (!_isRecording || _cameraController == null || !_cameraController!.value.isRecordingVideo) return;

    try {
      final XFile file = await _cameraController!.stopVideoRecording();
      final savedDir = await _videosDir();
      final targetPath = p.join(savedDir.path, p.basename(file.path));
      await File(file.path).copy(targetPath);

      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording saved. Uploading...')));

      // Auto-upload to backend
      await _uploadAndPredict(targetPath);
    } catch (e) {
      debugPrint('Recording stop error: $e');
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording save failed')));
    }
  }

  Future<void> _uploadAndPredict(String filePath) async {
    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse('http://localhost/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath, contentType: MediaType('video', 'mp4')));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _lastPredictionLabel = json['text'] ?? 'N/A';
          _lastPredictionConfidence = (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : null;
          _lastPredictionTime = (json['processing_time'] is num) ? (json['processing_time'] as num).toDouble() : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prediction received!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: ${response.statusCode}')));
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Silent Detecting'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ECDC4), Color(0xFF81E6D9)],
            ),
          ),
        ),
        actions: [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Challenge Yourself',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Speak the words silently with your lips',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Color(0xFF757575),
                    ),
                  ),
                  SizedBox(height: 60),
                  // Camera preview with ROI overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Color(0xFF4ECDC4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4ECDC4).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: _isCameraError
                            ? Container(
                                color: Colors.black87,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 48, color: Colors.red),
                                      SizedBox(height: 16),
                                      Text(
                                        'Camera Error',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          _cameraErrorMessage ?? 'Failed to initialize camera',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => _initCamera(),
                                        child: Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _isCameraInitialized && _cameraController != null
                                ? Stack(
                                    children: [
                                      CameraPreview(_cameraController!),
                                      // Enhanced ROI overlay with cv2-style appearance
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Center(
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Main face box
                                                Container(
                                                  width: 160,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.redAccent, width: 3.0),
                                                    color: Colors.transparent,
                                                  ),
                                                ),
                                                // Corner markers (cv2 style)
                                                Positioned(
                                                  top: 50,
                                                  left: 70,
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(color: Colors.redAccent, width: 3),
                                                        left: BorderSide(color: Colors.redAccent, width: 3),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 50,
                                                  right: 70,
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(color: Colors.redAccent, width: 3),
                                                        right: BorderSide(color: Colors.redAccent, width: 3),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 50,
                                                  left: 70,
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(color: Colors.redAccent, width: 3),
                                                        left: BorderSide(color: Colors.redAccent, width: 3),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 50,
                                                  right: 70,
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(color: Colors.redAccent, width: 3),
                                                        right: BorderSide(color: Colors.redAccent, width: 3),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Recording indicator
                                      if (_isRecording)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                                SizedBox(width: 4),
                                                Text('REC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.black87,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Initializing Camera...',
                                            style: TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Progress bar (5s limit visualization)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isRecording)
                          Text('${((_recordingProgress * 5).toStringAsFixed(1))}s / 5s', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                        if (_isRecording) SizedBox(height: 4),
                        if (_isRecording)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _recordingProgress,
                              minHeight: 6,
                              backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Record button
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isCameraInitialized && !_isUploading ? _toggleRecording : null,
                      icon: Icon(_isRecording ? Icons.stop_circle : Icons.fiber_manual_record, size: 28),
                      label: Text(_isRecording ? 'Stop' : 'Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : Color(0xFF4ECDC4),
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Word to speak:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '"Hello"',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            color: Color(0xFF4ECDC4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Prediction results box
                  if (_lastPredictionLabel != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6BCB77).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF6BCB77), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Prediction Result',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                          ),
                          SizedBox(height: 12),
                          Text(
                            _lastPredictionLabel ?? 'N/A',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6BCB77)),
                          ),
                          SizedBox(height: 12),
                          if (_lastPredictionConfidence != null)
                            Text(
                              'Confidence: ${(_lastPredictionConfidence! * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                            ),
                          if (_lastPredictionTime != null)
                            Text(
                              'Processing time: ${_lastPredictionTime!.toStringAsFixed(2)}s',
                              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                            ),
                        ],
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
}