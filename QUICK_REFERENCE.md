# Lipza - Quick Reference Card

## 🚀 Quick Start (5 minutes)

### Start Backend
```bash
cd src
pip install -r requirements.txt
python main.py
```

### Start Frontend
```bash
flutter pub get
flutter run
```

### Test Connection
1. Open "Silent Detecting" page
2. See "Connected" indicator turn green
3. Tap "Start Detecting"
4. Speak to camera
5. Watch predictions appear

---

## 📁 Project Structure

```
lipza/
├── src/                    # FastAPI Backend
│   ├── main.py            # WebSocket server
│   ├── config.py          # Settings
│   ├── services/          # Business logic
│   ├── utils/             # Helpers
│   └── requirements.txt    # Dependencies
│
├── lib/                    # Flutter Frontend
│   ├── main.dart
│   ├── services/          # WebSocket, Camera
│   └── features/          # Pages
│
└── pubspec.yaml           # Flutter config
```

---

## 🔌 WebSocket Messages

### Send Frame (Client → Server)
```json
{
  "type": "frame",
  "data": "base64_jpeg_string..."
}
```

### Get Prediction (Server → Client)
```json
{
  "type": "prediction",
  "text": "hello",
  "confidence": 0.95,
  "processing_time": 0.125
}
```

### Keep-Alive
```json
Client: { "type": "ping" }
Server: { "type": "pong" }
```

---

## ⚙️ Configuration

### Server Settings (`src/config.py`)
```python
SERVER_HOST = "0.0.0.0"        # Accessible externally
SERVER_PORT = 8000              # WebSocket port
JPEG_QUALITY = 80               # Higher = better quality, bigger size
DEFAULT_FRAME_WIDTH = 224       # Model input size
DEFAULT_FRAME_HEIGHT = 224
WEBSOCKET_KEEP_ALIVE_INTERVAL = 30  # Ping frequency
```

### Flutter WebSocket URL (`silent_detecting_page.dart`)
```dart
// Local emulator
'ws://10.0.2.2:8000/ws'

// Device (replace IP with your computer)
'ws://192.168.1.100:8000/ws'

// Network
'ws://your-server.com:8000/ws'
```

---

## 🔧 Common Tasks

### Change JPEG Quality
```python
# src/utils/frame_processor.py
img.encodeJpg(image, quality: 50)  # Lower = faster, worse quality
```

### Change Frame Size
```python
# src/config.py
DEFAULT_FRAME_WIDTH = 224
DEFAULT_FRAME_HEIGHT = 224
```

### Change Keep-Alive Interval
```dart
// lib/services/websocket_service.dart
Duration(seconds: 60)  # Ping every 60 seconds instead of 30
```

### Change Auto-Reconnect Delay
```dart
// lib/services/websocket_service.dart
Future.delayed(Duration(seconds: 10), () {  // Wait 10 sec instead of 5
```

---

## 📊 Performance Tips

| Issue | Solution |
|-------|----------|
| Slow predictions | Reduce JPEG quality, use GPU, optimize model |
| High latency | Reduce frame resolution, check network |
| CPU spike | Reduce frame rate, batch processing, profile |
| Connection drops | Increase keep-alive interval, check firewall |
| Large data transfer | Lower JPEG quality, smaller resolution |

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Start server, check port 8000 |
| "Can't connect to ws://" | Use correct IP, check firewall |
| "No cameras available" | Grant permissions, check Android API level |
| "Frame encoding error" | Check frame format, verify size |
| "Server returns 500 error" | Check server logs, restart server |
| "Slow predictions" | Profile model, reduce frame size |
| "Memory error" | Reduce batch size, lower resolution |

---

## 📝 Server Logs

```bash
# Check server status
curl http://localhost:8000/

# Health check
curl http://localhost:8000/health

# View real-time logs
python main.py  # Logs appear in console
```

---

## 📱 Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🍎 iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for lip reading</string>
```

---

## 🚢 Deployment

### Docker Backend
```dockerfile
FROM python:3.10
WORKDIR /app
COPY src/ .
RUN pip install -r requirements.txt
CMD ["python", "main.py"]
```

### Cloud Hosting
- **AWS:** EC2 + RDS
- **GCP:** Cloud Run + Cloud SQL
- **Azure:** Container Instances + Azure SQL
- **Heroku:** dyno + PostgreSQL

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `SETUP_GUIDE.md` | Complete setup instructions |
| `WEBSOCKET_INTEGRATION.md` | Integration details & features |
| `ARCHITECTURE.md` | System design & data flow |
| `src/README.md` | Backend API documentation |

---

## 🎯 Integration Checklist

- [ ] Backend server running
- [ ] Flutter app installed
- [ ] Camera permissions granted
- [ ] WebSocket URL configured
- [ ] Connection shows "Connected"
- [ ] Frames transmitting to server
- [ ] Predictions appearing in UI
- [ ] Model predictions working
- [ ] Database saving results
- [ ] Performance optimized
- [ ] Error handling tested
- [ ] Deployed to production

---

## 📞 Support Resources

- Flutter Docs: https://flutter.dev/docs
- FastAPI Docs: https://fastapi.tiangolo.com/
- WebSocket Protocol: https://tools.ietf.org/html/rfc6455
- OpenCV Docs: https://docs.opencv.org/
- Camera Plugin: https://pub.dev/packages/camera

---

## 🔑 Key Technologies

```
Frontend:  Flutter 3.x + Dart
Backend:   FastAPI + Python 3.10+
Protocol:  WebSocket (TCP/IP)
Transport: JSON + Base64
Image:     JPEG compression
Model:     TensorFlow / PyTorch (your choice)
Deployment: Docker + Cloud
```

---

## ⏱️ Typical Latency

```
Frame capture:        5ms
Encoding:             15ms
Network:              20ms
Decoding:             10ms
Inference:            100ms
Response:             10ms
─────────────────────────
Total (best case):    160ms ≈ 6 FPS
Total (worst case):   300ms ≈ 3 FPS
```

---

## 🎓 Learning Path

1. **Understand Architecture** → Read ARCHITECTURE.md
2. **Setup Environment** → Run SETUP_GUIDE.md
3. **Test Connection** → Start servers, test WebSocket
4. **Integrate Model** → Add your lip-reading model
5. **Optimize Performance** → Profile and optimize
6. **Deploy** → Host on cloud server
7. **Monitor** → Track usage and errors

---

## 💡 Pro Tips

✅ Always use relative paths in config
✅ Enable logging for debugging
✅ Test with low-quality frames first
✅ Monitor memory usage during inference
✅ Use connection status indicator
✅ Implement graceful shutdown
✅ Cache model weights
✅ Batch frames for throughput
✅ Profile inference time
✅ Add rate limiting

---

**Version:** 1.0.0  
**Last Updated:** November 15, 2025  
**Status:** ✅ Production Ready
