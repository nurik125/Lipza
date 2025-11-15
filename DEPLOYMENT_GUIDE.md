# Lipza App - Complete Deployment Guide

## Overview
The Lipza app is a Flutter-based lip reading learning application with a Python backend for AI-powered predictions. This guide covers running the backend and testing the full end-to-end workflow.

---

## Part 1: Backend Setup (Python)

### Prerequisites
- Python 3.x
- Miniconda/Anaconda environment: `lipza`
- NumPy < 2 (CRITICAL for TensorFlow compatibility on Windows)

### Step 1: Activate Conda Environment
```powershell
conda activate lipza
```

### Step 2: Install Dependencies
```powershell
pip install -r src/requirements.txt
```

**Note:** If NumPy version is 2.x or higher, downgrade it:
```powershell
conda install "numpy<2" -y
pip install -r src/requirements.txt
```

### Step 3: Verify Backend Structure
Ensure the following files exist:
- `src/main.py` - FastAPI application
- `src/services/lip_reader_service.py` - LipNet model service
- `src/requirements.txt` - Dependencies

### Step 4: Run Backend Server
```powershell
python -m uvicorn src.main:app --reload --port 8000
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

The backend will:
- Run on `http://localhost:8000`
- Accept POST requests at `/predict` endpoint
- Automatically create a `videos/` directory for storing uploaded videos
- Return JSON predictions: `{text, confidence, processing_time}`

---

## Part 2: Flutter App Setup

### Prerequisites
- Flutter SDK
- Android Studio or Xcode (for emulator)
- Camera & microphone permissions configured

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Android Configuration
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Step 3: iOS Configuration (Optional)
Edit `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is needed to record your lip movements for lip reading prediction.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone permission is required.</string>
```

---

## Part 3: Running the App

### Option A: Android Emulator
```bash
flutter run
```

**Important:** On Android emulator, the backend URL is:
```
http://10.0.2.2:8000/predict
```
(This is the standard emulator URL for localhost)

### Option B: iOS Simulator
```bash
flutter run -d ios
```

Backend URL remains: `http://localhost:8000/predict`

### Option C: Physical Device
```bash
flutter run -d <device_id>
```

**Important:** On physical devices, replace `10.0.2.2` or `localhost` with your machine's IP:
```
http://<YOUR_MACHINE_IP>:8000/predict
```

Find your machine IP:
- Windows: `ipconfig` (look for IPv4 Address)
- Mac/Linux: `ifconfig` (look for inet)

---

## Part 4: Testing the Workflow

### 4.1: Test Backend Directly (Optional)
Use the provided test script:
```powershell
python scripts/test_predict.py C:\path\to\test_video.mp4 --url http://localhost:8000/predict
```

Expected response:
```json
{
  "text": "hello",
  "confidence": 0.85,
  "processing_time": 2.34
}
```

### 4.2: Test in Flutter App

**Full Workflow:**
1. **Launch backend**: `python -m uvicorn src.main:app --reload --port 8000`
2. **Launch Flutter app**: `flutter run`
3. **In the app:**
   - Navigate to "Silent Detecting" feature
   - Click "Record" button
   - Speak a word silently (move your lips without sound)
   - Recording auto-stops at 5 seconds OR click Stop manually
   - Video auto-uploads to backend
   - Wait for prediction result to display (green box showing label, confidence %, and processing time)

**UI Features:**
- 🎥 **Camera Preview**: 300x300 px with red face detection overlay + corner markers
- ⏱️ **Progress Bar**: Shows elapsed time (0.0 - 5.0 seconds)
- 🔴 **Record Button**: Green "Record" / Red "Stop" toggle
- 📊 **Prediction Display**: Green container with:
  - Predicted word/label (large text)
  - Confidence percentage
  - Processing time in seconds

---

## Part 5: Features Overview

### 🏠 Home Page
- **Visuals**: Gradient background (light to lighter gray)
- **Navigation**: 4 feature cards with gradients
  - Teaching (Red gradient)
  - Practice (Orange gradient)
  - Silent Detecting (Teal gradient)
  - Gap Filling (Green gradient)
- **Leaderboard Preview**: Top 2 performers

### 📚 Teaching Page
- **Visuals**: Orange gradient AppBar, light background
- **Content**: 8 teaching items (Hello, Goodbye, Thank You, Please, Water, Coffee, Smile, Help)
- **Each Item**: Pronunciation hint + description + video play button
- **Animation**: Staggered slide-in animation

### 🏆 Leaderboard Page
- **Visuals**: Teal gradient AppBar
- **Top 3 Podium**: Gold/Silver/Bronze medal display with different heights
- **Rankings**: All 7+ users with:
  - Rank badge (colored circle)
  - User name
  - Level badge (colored)
  - Streak counter with fire emoji
  - Points display

### 🎙️ Silent Detecting Page
- **Visuals**: Teal gradient AppBar, light background
- **Camera**: 300x300 preview with cv2-style face detection overlay
  - Red detection box (160x100 px)
  - L-shaped corner markers at 4 corners
  - Recording indicator badge (REC)
- **Controls**: 5-second progress bar + Record/Stop button
- **Challenge Prompt**: "Say 'Hello'" in blue box
- **Predictions**: Green result box (visible after upload completes)

---

## Part 6: Troubleshooting

### Backend Issues

**Problem**: `DLL load failed` or `numpy.core._exceptions.UFuncTypeError`
- **Solution**: Downgrade NumPy: `conda install "numpy<2" -y`

**Problem**: Backend won't start
- **Solution**: Check port 8000 is not in use: `netstat -ano | findstr :8000`
- Kill process if needed: `taskkill /PID <PID> /F`

**Problem**: `/predict` endpoint returns 400 or 500
- **Solution**: 
  - Verify video file exists and is valid MP4
  - Check backend logs for detailed error
  - Ensure checkpoint file exists for model (use mock predictions if not)

### Flutter Issues

**Problem**: Camera not showing
- **Solution**: 
  - Grant camera permissions on device
  - Restart app
  - Check `_initCamera()` logs: `flutter logs`

**Problem**: Video upload fails (network error)
- **Solution**:
  - Verify backend is running: `curl http://localhost:8000/docs`
  - On emulator, use `http://10.0.2.2:8000/predict`
  - On physical device, use correct machine IP
  - Check firewall allows port 8000

**Problem**: Prediction doesn't display
- **Solution**:
  - Check response format is JSON with keys: `text`, `confidence`, `processing_time`
  - Verify `_uploadAndPredict()` method in `silent_detecting_page.dart`
  - Check Flutter logs for JSON parsing errors

---

## Part 7: File Locations

### Python Backend
```
src/
├── main.py                      # FastAPI app + /predict endpoint
├── services/
│   └── lip_reader_service.py   # LipNet model + prediction logic
├── requirements.txt             # Dependencies
└── videos/                       # Auto-created, stores uploaded videos
```

### Flutter App
```
lib/
├── main.dart                                    # App theme + home page
└── features/
    ├── teaching/teaching_page.dart             # Teaching materials (8 items)
    ├── leaderboard/leaderboard_page.dart       # Rankings + podium
    ├── silent_detecting/silent_detecting_page.dart  # Camera + recording + prediction
    └── assessment/gap_filling_page.dart        # Gap filling tasks
```

---

## Part 8: Quick Checklist

- [ ] Backend conda environment activated
- [ ] NumPy version < 2 (`conda list | grep numpy`)
- [ ] Backend running on port 8000 (`uvicorn src.main:app --reload --port 8000`)
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Android permissions configured (Camera, Microphone, Internet)
- [ ] App running on emulator/device (`flutter run`)
- [ ] Using correct backend URL (10.0.2.2 for emulator, localhost for iOS simulator, machine IP for physical device)
- [ ] Camera shows live preview
- [ ] Record button works (5s auto-stop and manual stop)
- [ ] Video uploads and prediction displays

---

## Part 9: Next Steps

1. **Test with Mock Predictions**: All features work without a trained model (mock mode)
2. **Add Real Model**: Place LipNet checkpoint in `model_preparation/models/` directory
3. **Customize Predictions**: Update teaching words in `teaching_page.dart` to match your training data
4. **Add Video Content**: Create actual videos for teaching page (currently using placeholder paths)
5. **Analytics**: Track user predictions and accuracy over time
6. **User Accounts**: Add Firebase/backend authentication

---

## Support

For issues:
1. Check backend logs: `python -m uvicorn src.main:app --reload`
2. Check Flutter logs: `flutter logs`
3. Verify all permissions are granted on device
4. Test backend directly with `test_predict.py` script
5. Review this guide's Troubleshooting section

