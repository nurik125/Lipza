# Lipza - Setup & Running Guide

## Overview

Lipza is a Flutter lip-reading application with a FastAPI WebSocket backend for real-time frame processing and predictions.

```
Flutter App ←→ WebSocket ←→ FastAPI Server ←→ ML Model
```

## Backend Setup (FastAPI)

### 1. Navigate to Backend Directory
```bash
cd src
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the Server
```bash
python main.py
```

Expected output:
```
INFO:     Started server process [12345]
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**Server will be available at:**
- REST API: `http://localhost:8000`
- WebSocket: `ws://localhost:8000/ws`
- Health Check: `http://localhost:8000/health`

### 4. Test the Server
Open your browser and visit: `http://localhost:8000/`

Expected response:
```json
{
  "status": "online",
  "service": "Lipza Backend",
  "websocket_url": "ws://localhost:8000/ws"
}
```

## Flutter App Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Update WebSocket URL

In `lib/features/silent_detecting/silent_detecting_page.dart`, update the server URL to match your backend:

```dart
// For local testing
_wsService = WebSocketService(serverUrl: 'ws://localhost:8000/ws');

// For device testing (replace with your computer IP)
_wsService = WebSocketService(serverUrl: 'ws://192.168.1.100:8000/ws');
```

### 3. Run the App

#### On Emulator/Simulator
```bash
flutter run
```

#### On Device
```bash
flutter run -d <device_id>
```

To list available devices:
```bash
flutter devices
```

## Architecture Flow

### 1. User starts "Silent Detecting"
- Camera initializes (front camera)
- Connects to WebSocket server
- Status indicator shows connection state

### 2. User taps "Start Detecting"
- App starts capturing camera frames
- Frames are converted to JPEG format
- Each frame is encoded as base64
- Sent to server via WebSocket

### 3. Server receives frame
- Decodes base64 back to image
- Processes with lip-reading model
- Returns prediction with confidence

### 4. App displays prediction
- Updates UI with recognized word
- Shows confidence score
- Processing time displayed

## Configuration

### WebSocket Settings

**Connection Timeout:** 30 seconds
**Ping Interval:** 30 seconds (keep-alive)
**Auto-reconnect:** 5 second delay

To modify, edit in `lib/services/websocket_service.dart`.

### Frame Settings

**Frame Resolution:** High (Camera preset)
**Frame Format:** JPEG, Quality 80
**Max Frame Size:** 10MB

To modify, edit:
- Camera resolution: `silent_detecting_page.dart` (ResolutionPreset)
- JPEG quality: `camera_frame_service.dart` (quality: 80)

## Project Structure

```
lipza/
├── lib/
│   ├── main.dart                          # App entry & theme
│   ├── features/
│   │   ├── silent_detecting/
│   │   │   └── silent_detecting_page.dart # WebSocket integration
│   │   ├── teaching/
│   │   ├── leaderboard/
│   │   └── assessment/
│   └── services/
│       ├── websocket_service.dart         # WebSocket client
│       └── camera_frame_service.dart      # Frame conversion
│
├── src/                                    # Backend
│   ├── main.py                            # FastAPI server
│   ├── requirements.txt                   # Python dependencies
│   ├── services/
│   │   ├── camera_service.py
│   │   └── lip_reader_service.py
│   └── utils/
│       └── frame_processor.py
│
└── pubspec.yaml                           # Flutter dependencies
```

## Troubleshooting

### App won't connect to server
1. Check server is running: `http://localhost:8000/health`
2. Verify WebSocket URL in Flutter app
3. Check firewall allows port 8000
4. For device: use computer IP instead of localhost

### Server returns errors
1. Check console logs for error messages
2. Verify frame format is JPEG
3. Ensure frame size < 10MB
4. Check model is properly initialized

### Camera not working
1. Grant camera permissions (check AndroidManifest.xml)
2. Use emulator with camera support
3. For Android: API level 21+
4. For iOS: iOS 11.0+

### Slow predictions
1. Monitor server CPU usage
2. Check network latency
3. Reduce frame resolution
4. Reduce JPEG quality
5. Profile model inference time

## Performance Monitoring

### Server Metrics
```bash
# Monitor CPU/Memory
python -m psutil

# Check connection count
curl http://localhost:8000/health
```

### App Metrics
- Check logs in console
- Monitor prediction confidence
- Track processing time
- Watch frame transmission rate

## Next Steps

1. **Integrate Real Model:** Replace mock predictions with your lip-reading model
2. **Add Database:** Store predictions and user progress
3. **Implement Authentication:** Add user login/registration
4. **Add Statistics:** Track accuracy, history, achievements
5. **Optimize Performance:** Implement frame batching, model caching
6. **Deploy:** Host FastAPI backend on cloud (AWS, GCP, Azure)

## Support

For issues or questions, check:
- Backend README: `src/README.md`
- Flutter documentation: https://flutter.dev/docs
- FastAPI documentation: https://fastapi.tiangolo.com/
