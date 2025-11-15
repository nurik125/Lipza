import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class LipRecorderWidget extends StatefulWidget {
  final String uploadUrl; // e.g. "http://10.0.2.2:8000/predict"
  const LipRecorderWidget({super.key, required this.uploadUrl});

  @override
  _LipRecorderWidgetState createState() => _LipRecorderWidgetState();
}

class _LipRecorderWidgetState extends State<LipRecorderWidget> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  Timer? _recordTimer;
  double _progress = 0.0;
  final int _maxSeconds = 5;
  String? _lastSavedPath;
  String? _predictedLabel;
  double? _predictedConfidence;
  double? _predictedTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<Directory> _videosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _onRecordButtonPressed() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      // stop recording
      try {
        final file = await _controller!.stopVideoRecording();
        // move to videos dir
        final savedDir = await _videosDir();
        final target = File(p.join(savedDir.path, p.basename(file.path)));
        await File(file.path).copy(target.path);
        _finishRecording(target.path);
      } catch (e) {
        debugPrint('Stop recording error: $e');
      }
    } else {
      // start
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _progress = 0.0;
        });

        int elapsed = 0;
        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(Duration(milliseconds: 200), (t) async {
          elapsed += 200;
          setState(() {
            _progress = (elapsed / (_maxSeconds * 1000)).clamp(0.0, 1.0);
          });
          if (elapsed >= _maxSeconds * 1000) {
            _recordTimer?.cancel();
            if (_controller != null && _controller!.value.isRecordingVideo) {
              try {
                final file = await _controller!.stopVideoRecording();
                final savedDir = await _videosDir();
                final target = File(p.join(savedDir.path, p.basename(file.path)));
                await File(file.path).copy(target.path);
                _finishRecording(target.path);
              } catch (e) {
                debugPrint('Auto-stop error: $e');
              }
            }
          }
        });
      } catch (e) {
        debugPrint('Start recording error: $e');
      }
    }
  }

  void _finishRecording(String savedPath) {
    setState(() {
      _isRecording = false;
      _recordTimer?.cancel();
      _progress = 0.0;
      _lastSavedPath = savedPath;
    });
    _uploadFile(savedPath);
  }

  Future<void> _uploadFile(String path) async {
    setState(() {
      _predictedLabel = 'Predicting...';
      _predictedConfidence = null;
      _predictedTime = null;
    });

    try {
      final uri = Uri.parse(widget.uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', path, contentType: MediaType('video', 'mp4')));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _predictedLabel = json['text'] ?? '';
          _predictedConfidence = (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : null;
          _predictedTime = (json['processing_time'] is num) ? (json['processing_time'] as num).toDouble() : null;
        });
      } else {
        setState(() {
          _predictedLabel = 'Upload error: ${res.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      setState(() {
        _predictedLabel = 'Upload failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color(0xFF4ECDC4), width: 3),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            children: [
              CameraPreview(_controller!),
              // ROI overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.width * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent, width: 3.0),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: LinearProgressIndicator(value: _progress),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _onRecordButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(_isRecording ? 'Stop' : 'Record'),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                final dir = await _videosDir();
                final files = dir.listSync().map((e) => e.path).toList();
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: Text('Saved videos'),
                  content: SizedBox(
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: files.reversed.map((f) => Text(p.basename(f))).toList(),
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                ));
              },
              child: Text('Saved'),
            )
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text('Prediction: ${_predictedLabel ?? '-'}', style: TextStyle(fontSize: 16)),
              if (_predictedConfidence != null) Text('Confidence: ${(_predictedConfidence! * 100).toStringAsFixed(1)}%'),
              if (_predictedTime != null) Text('Processing time: ${_predictedTime!.toStringAsFixed(2)}s'),
            ],
          ),
        ),
      ],
    );
  }
}
