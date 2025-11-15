# Lipza Backend - FastAPI WebSocket Server

Real-time lip-reading WebSocket server built with FastAPI for streaming camera frames and receiving predictions.

## Architecture

```
Flutter App (Camera Feed)
       ↓ (WebSocket: base64 JPEG frames)
FastAPI Server (Frame Processing)
       ↓ (OpenCV: decode frame)
Lip Reading Model (ML Inference)
       ↓ (Prediction)
Flutter App (Display Result)
```

## Setup & Installation

### Prerequisites
- Python 3.10+
- FastAPI
- OpenCV
- NumPy
- Pillow

### Install Dependencies

```bash
cd src
pip install -r requirements.txt
```

### Run Server

```bash
python main.py
```

The server will start on `http://0.0.0.0:8000`

**WebSocket URL:** `ws://localhost:8000/ws`

## API Endpoints

### Health Check
```
GET /
GET /health
```

Returns server status and connection info.

### WebSocket Connection
```
ws://localhost:8000/ws
```

## WebSocket Message Protocol

### Client → Server

#### Send Frame
```json
{
  "type": "frame",
  "data": "base64_encoded_jpeg_string"
}
```

#### Keep-Alive Ping
```json
{
  "type": "ping"
}
```

#### Configuration
```json
{
  "type": "config",
  "config": {
    "model": "model_name",
    "settings": {}
  }
}
```

### Server → Client

#### Prediction Result
```json
{
  "type": "prediction",
  "text": "predicted_word",
  "confidence": 0.95,
  "processing_time": 0.125
}
```

#### Keep-Alive Pong
```json
{
  "type": "pong"
}
```

#### Error Response
```json
{
  "type": "error",
  "message": "Error description"
}
```

## Project Structure

```
src/
├── main.py                      # FastAPI app & WebSocket handler
├── requirements.txt             # Python dependencies
├── services/
│   ├── __init__.py
│   ├── camera_service.py        # Camera frame processing
│   └── lip_reader_service.py    # Lip reading predictions
└── utils/
    ├── __init__.py
    └── frame_processor.py       # Frame encoding/decoding utilities
```

## Key Components

### WebSocket Server (`main.py`)
- Manages client connections
- Receives camera frames in base64 format
- Sends predictions back to connected clients
- Handles keep-alive pings for connection stability

### Camera Service (`services/camera_service.py`)
- Processes camera frames for model input
- Extracts regions of interest (ROI)
- Frame resizing and normalization

### Lip Reader Service (`services/lip_reader_service.py`)
- Integrates your lip-reading ML model
- Returns predictions with confidence scores
- Currently uses mock predictions for testing

### Frame Processor (`utils/frame_processor.py`)
- Encodes/decodes JPEG frames from base64
- Frame normalization
- Frame statistics extraction

## Integrating Your Lip-Reading Model

To integrate your actual lip-reading model:

1. Update `services/lip_reader_service.py`:

```python
def _initialize_model(self):
    """Load your model here"""
    self.model = load_your_model('path/to/model')
    self.is_initialized = True

def _process_frame(self, frame: np.ndarray) -> Dict:
    """Use your model for prediction"""
    prediction = self.model.predict(frame)
    return {
        "text": prediction["word"],
        "confidence": prediction["confidence"]
    }
```

2. Install any additional dependencies your model requires
3. Update `requirements.txt` with new dependencies

## Configuration

### Server Settings
- **Host:** `0.0.0.0` (accessible from all interfaces)
- **Port:** `8000`
- **Log Level:** `info`

To change settings, edit the `uvicorn.run()` parameters in `main.py`.

### Frame Processing
- **Max Frame Size:** 10MB (configurable in `FrameProcessor`)
- **JPEG Quality:** 80 (configurable in encoding)
- **Input Resolution:** 224x224 (configurable in `CameraService`)

## Performance Tips

1. **Reduce Frame Size:** Smaller frames = faster transmission
   - Encode JPEG at lower quality (50-70)
   - Resize frames before sending

2. **Async Processing:** Uses async/await for non-blocking operations
   - Frame processing runs in thread pool
   - Multiple clients can be served concurrently

3. **Connection Stability:** Keep-alive pings every 30 seconds
   - Prevents connection timeout
   - Client auto-reconnect on disconnection

## Troubleshooting

### Connection Issues
- Check server is running: `GET http://localhost:8000/health`
- Verify WebSocket URL is correct (ws:// not http://)
- Check firewall allows port 8000

### Frame Processing Errors
- Verify JPEG encoding is valid
- Check frame dimensions are correct
- Ensure color format is supported (RGB, BGRA, NV21)

### Slow Predictions
- Profile model inference time
- Check server CPU/memory usage
- Consider model quantization or pruning
- Implement frame batching for throughput

## Future Enhancements

- [ ] Batch processing for multiple frames
- [ ] Model versioning and hot-swapping
- [ ] Performance metrics and monitoring
- [ ] Database integration for result logging
- [ ] Multi-language support
- [ ] Advanced face detection and tracking

## License

This project is part of the Lipza lip-reading application.
