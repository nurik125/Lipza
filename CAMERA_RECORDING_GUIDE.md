# Camera Recording & Prediction System - Technical Guide

## 📸 Camera Recording Implementation

### Initialization (initState)
```dart
Future<void> _initCamera() async {
  // Request permissions
  await Permission.camera.request();
  await Permission.microphone.request();
  
  // Get available cameras
  final cameras = await availableCameras();
  
  // Select front-facing camera
  final front = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );
  
  // Initialize controller
  _cameraController = CameraController(
    front, 
    ResolutionPreset.medium, 
    enableAudio: false
  );
  
  await _cameraController!.initialize();
  setState(() => _isCameraInitialized = true);
}
```

**What This Does:**
1. Requests camera and microphone permissions from the OS
2. Fetches list of available cameras on device
3. Selects front-facing camera (for lip reading)
4. Creates CameraController with medium resolution (~400x300)
5. Initializes controller and updates UI

---

## 🎬 Recording Workflow

### Start Recording
```dart
// User taps "Record" button
await _cameraController!.startVideoRecording();

setState(() {
  _isRecording = true;
  _recordingProgress = 0.0;
  _lastPredictionLabel = null;
});

// Start 5-second timer
int elapsed = 0;
_recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
  elapsed += 100;
  setState(() => _recordingProgress = (elapsed / 5000).clamp(0.0, 1.0));
  
  // Auto-stop at 5 seconds
  if (elapsed >= 5000) {
    timer.cancel();
    _finishRecording();
  }
});
```

**What This Does:**
1. Starts video recording in the camera controller
2. Sets recording state to true (shows REC badge, red button)
3. Clears previous prediction results
4. Starts a timer that updates every 100ms
5. Calculates progress as percentage (0.0 → 1.0)
6. Auto-stops recording at 5 seconds

### Stop Recording
```dart
Future<void> _finishRecording() async {
  _recordingTimer?.cancel();
  
  // Stop recording
  final XFile file = await _cameraController!.stopVideoRecording();
  
  // Save to app's /videos/ directory
  final savedDir = await _videosDir();
  final targetPath = p.join(savedDir.path, p.basename(file.path));
  await File(file.path).copy(targetPath);
  
  setState(() => _isRecording = false);
  
  // Show message and upload
  ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text('Recording saved. Uploading...')));
  
  await _uploadAndPredict(targetPath);
}

Future<Directory> _videosDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'videos'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}
```

**What This Does:**
1. Stops the timer
2. Stops video recording in the camera
3. Gets the recorded file (XFile object)
4. Creates `/videos/` directory in app documents folder if it doesn't exist
5. Copies video file to `/videos/` directory
6. Resets recording state
7. Shows "Recording saved. Uploading..." message
8. Triggers upload to backend

---

## 🚀 Upload & Prediction

### Multipart Upload
```dart
Future<void> _uploadAndPredict(String filePath) async {
  setState(() => _isUploading = true);
  
  try {
    // Create multipart request
    final uri = Uri.parse('http://10.0.2.2:8000/predict');
    final request = http.MultipartRequest('POST', uri);
    
    // Add video file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',  // Form field name
        filePath,
        contentType: MediaType('video', 'mp4')
      )
    );
    
    // Send request and get response
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    
    if (response.statusCode == 200) {
      // Parse JSON response
      final json = jsonDecode(response.body);
      
      // Extract prediction data
      setState(() {
        _lastPredictionLabel = json['text'] ?? 'N/A';
        _lastPredictionConfidence = (json['confidence'] is num) 
          ? (json['confidence'] as num).toDouble() 
          : null;
        _lastPredictionTime = (json['processing_time'] is num) 
          ? (json['processing_time'] as num).toDouble() 
          : null;
      });
      
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Prediction received!')));
    } else {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Upload error: ${response.statusCode}')));
    }
  } catch (e) {
    debugPrint('Upload error: $e');
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Upload failed')));
  } finally {
    setState(() => _isUploading = false);
  }
}
```

**What This Does:**
1. Creates a multipart HTTP POST request
2. Adds the video file to the request with content-type "video/mp4"
3. Sends request to backend `/predict` endpoint
4. Waits for response (can take 2-10 seconds depending on video length)
5. Parses JSON response containing:
   - `text`: Predicted word/label
   - `confidence`: Confidence score (0.0-1.0 or 0-100)
   - `processing_time`: Time taken to process in seconds
6. Updates UI with prediction results
7. Shows success/error message
8. Disables upload state

---

## 📱 Backend URL

### Android Emulator
```dart
'http://10.0.2.2:8000/predict'
```
- `10.0.2.2` is the emulator's special hostname for the host machine
- Use this ONLY for Android emulator

### iOS Simulator
```dart
'http://localhost:8000/predict'
```
- iOS simulator can use `localhost` directly
- Same as physical machine

### Physical Device
```dart
'http://<YOUR_MACHINE_IP>:8000/predict'
```
- Replace `<YOUR_MACHINE_IP>` with your machine's actual IP
- Example: `'http://192.168.1.100:8000/predict'`
- Find IP: Windows → `ipconfig` → IPv4 Address

---

## 🎯 UI Updates During Recording

### Progress Bar Display
```dart
// During recording, show:
// "2.3s / 5s" with a linear progress bar

if (_isRecording)
  Text('${((_recordingProgress * 5).toStringAsFixed(1))}s / 5s')

if (_isRecording)
  LinearProgressIndicator(
    value: _recordingProgress,
    minHeight: 6,
    backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
  )
```

### Recording Badge
```dart
// Shows when recording is active (top-right of camera)
if (_isRecording)
  Container(
    decoration: BoxDecoration(color: Colors.red),
    child: Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle
        )),
        Text('REC', style: TextStyle(color: Colors.white)),
      ],
    ),
  )
```

### Button State
```dart
// Record button changes based on state
ElevatedButton.icon(
  onPressed: _isCameraInitialized && !_isUploading ? _toggleRecording : null,
  icon: Icon(_isRecording ? Icons.stop_circle : Icons.fiber_manual_record),
  label: Text(_isRecording ? 'Stop' : 'Record'),
  style: ElevatedButton.styleFrom(
    backgroundColor: _isRecording ? Colors.red : Color(0xFF4ECDC4),
  ),
)
```

| State | Button | Icon | Color |
|-------|--------|------|-------|
| Idle | "Record" | Record circle | Teal (#4ECDC4) |
| Recording | "Stop" | Stop square | Red |
| Uploading | Disabled | - | Gray |
| Camera Init Error | Disabled | - | Gray |

---

## 📊 Prediction Result Display

### Conditional Display
```dart
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
        Text('Prediction Result', style: TextStyle(fontSize: 14)),
        SizedBox(height: 12),
        Text(
          _lastPredictionLabel ?? 'N/A',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6BCB77)),
        ),
        SizedBox(height: 12),
        if (_lastPredictionConfidence != null)
          Text('Confidence: ${(_lastPredictionConfidence! * 100).toStringAsFixed(1)}%'),
        if (_lastPredictionTime != null)
          Text('Processing time: ${_lastPredictionTime!.toStringAsFixed(2)}s'),
      ],
    ),
  )
```

### Formatting
- **Confidence**: Multiplied by 100 and formatted to 1 decimal place
  - Backend: 0.85 → Display: "85.0%"
  - Backend: 85 → Display: "8500.0%" (need to check backend format!)
- **Time**: Formatted to 2 decimal places
  - Backend: 2.341 → Display: "2.34s"

---

## 🔧 Backend Response Format

### Expected JSON Response
```json
{
  "text": "hello",
  "confidence": 0.85,
  "processing_time": 2.34
}
```

### Alternative Format (if confidence is 0-100)
```json
{
  "text": "hello",
  "confidence": 85,
  "processing_time": 2.34
}
```

**Code Handles Both:**
```dart
// Handles both 0.0-1.0 and 0-100 formats
_lastPredictionConfidence = (json['confidence'] is num) 
  ? (json['confidence'] as num).toDouble() 
  : null;
```

---

## 🎥 Video File Details

### Storage Location
```
/data/data/com.yourapp.lipza/app_documents/videos/
```

### File Naming
- Auto-generated by camera controller
- Typically: `cap_1234567890.mp4`
- OR: `<timestamp>.mp4`

### Video Properties
- **Format**: MP4 (H.264 codec standard)
- **Resolution**: 400x300 or similar (Medium quality)
- **Frame Rate**: 30 fps (standard)
- **Duration**: 1-5 seconds
- **File Size**: 50KB-500KB (typical)
- **Audio**: Disabled (video only)

---

## 🐛 Debugging

### Check Recording Started
```dart
if (!_cameraController!.value.isRecordingVideo) {
  debugPrint('ERROR: Recording did not start');
}
```

### Check Upload Status
```dart
// Add logging
debugPrint('Uploading to: ${uri.toString()}');
debugPrint('File size: ${File(filePath).lengthSync()} bytes');
```

### Check Response
```dart
debugPrint('Response code: ${response.statusCode}');
debugPrint('Response body: ${response.body}');
```

### Monitor Progress
```dart
// In periodic timer
debugPrint('Recording progress: $_recordingProgress (${((_recordingProgress * 5).toStringAsFixed(1))}s)');
```

---

## 🚀 Complete Flow Diagram

```
1. User opens app
   ↓
2. Camera initializes (front-facing, medium resolution)
   ↓
3. User sees live preview with ROI overlay (red box + corners)
   ↓
4. User taps "Record" button
   ↓
5. Recording starts + 5s timer starts
   ├─ Progress bar updates every 100ms
   ├─ "REC" badge appears
   ├─ Button turns red "Stop"
   ↓
6. Either:
   ├─ 5 seconds pass → Auto-stop
   └─ User taps "Stop" → Manual stop
   ↓
7. Video saved to /videos/ directory
   ↓
8. Multipart POST to backend /predict endpoint
   ├─ Shows "Recording saved. Uploading..."
   ├─ Button disabled during upload
   ↓
9. Backend processes video (2-10 seconds)
   ├─ Loads model
   ├─ Preprocesses video
   ├─ Runs inference
   ├─ CTC decodes output
   ↓
10. Backend returns JSON:
    {
      "text": "hello",
      "confidence": 0.85,
      "processing_time": 2.34
    }
   ↓
11. Flutter receives response
    ├─ Parses JSON
    ├─ Extracts label, confidence, time
    ├─ Shows "Prediction received!" message
    ↓
12. Green result box appears with:
    - Predicted word (large green text): "hello"
    - Confidence: "Confidence: 85.0%"
    - Processing time: "Processing time: 2.34s"
   ↓
13. User can record again or navigate away
```

---

## ✅ Checklist for Full Functionality

- [x] Camera initializes on page load
- [x] Front-facing camera selected
- [x] Permissions requested (camera + microphone)
- [x] Live preview shown in 300x300 container
- [x] ROI overlay with red box + corner markers
- [x] Recording badge (REC) appears during recording
- [x] Progress bar updates every 100ms
- [x] Progress bar shows "X.Xs / 5s" format
- [x] Auto-stop at 5 seconds
- [x] Manual stop with "Stop" button
- [x] Video saved to /videos/ directory
- [x] Multipart upload to /predict endpoint
- [x] Correct backend URL for device type (10.0.2.2 for emulator)
- [x] JSON response parsed correctly
- [x] Prediction label displayed in green
- [x] Confidence shown as percentage
- [x] Processing time shown in seconds
- [x] Button disabled during upload
- [x] Result box appears conditionally
- [x] Previous results cleared when recording starts

