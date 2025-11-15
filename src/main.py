"""
FastAPI WebSocket server for lip-reading application
Handles real-time camera frame transmission and processing
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, UploadFile, File, HTTPException
from pathlib import Path
import os
import time
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import asyncio
import json
from typing import Set, Dict, Any
import logging

from services.camera_service import CameraService
from services.lip_reader_service import LipReaderService
from utils.frame_processor import FrameProcessor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Lipza Backend",
    description="Real-time lip-reading WebSocket server",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
camera_service = CameraService()
lip_reader_service = LipReaderService()
frame_processor = FrameProcessor()

# Connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)
        logger.info(f"Client connected. Total connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)
        logger.info(f"Client disconnected. Total connections: {len(self.active_connections)}")

    async def broadcast(self, message: Dict[str, Any]) -> None:
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting message: {e}")
                disconnected.append(connection)
        
        for connection in disconnected:
            self.disconnect(connection)

manager = ConnectionManager()

# Ensure videos directory exists for uploaded recordings
VIDEOS_DIR = Path("videos")
VIDEOS_DIR.mkdir(parents=True, exist_ok=True)


@app.get("/")
async def root() -> Dict[str, Any]:
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "Lipza Backend",
        "websocket_url": "ws://localhost:8000/ws"
    }


@app.get("/health")
async def health() -> Dict[str, Any]:
    """Health check for monitoring"""
    return {
        "status": "healthy",
        "active_connections": len(manager.active_connections)
    }


@app.post("/predict")
async def predict_upload(file: UploadFile = File(...)) -> Dict[str, Any]:
    """Accept a multipart file upload, save it under `videos/`, and run prediction."""
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")

    suffix = Path(file.filename).suffix or ".mp4"
    dest = VIDEOS_DIR / f"{int(time.time()*1000)}{suffix}"

    try:
        content = await file.read()
        with open(dest, "wb") as f:
            f.write(content)
    except Exception as e:
        logger.exception("Failed to save uploaded file: %s", e)
        raise HTTPException(status_code=500, detail="Failed to save uploaded file")

    # Call the lip reader service; it accepts a path
    result = await lip_reader_service.predict(str(dest))
    return result


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """
    WebSocket endpoint for receiving camera frames and sending predictions
    
    Expected client message format:
    {
        "type": "frame",
        "data": "base64_encoded_jpeg"
    }
    
    Server response format:
    {
        "type": "prediction",
        "text": "predicted_word",
        "confidence": 0.95
    }
    """
    await manager.connect(websocket)
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                
                if message.get("type") == "frame":
                    # Process camera frame
                    frame_data = message.get("data")
                    
                    # Decode frame from base64
                    frame = frame_processor.decode_frame(frame_data)
                    
                    if frame is not None:
                        # Process frame with lip reader
                        result = await lip_reader_service.predict(frame)
                        
                        # Send prediction back to client
                        response = {
                            "type": "prediction",
                            "text": result.get("text", ""),
                            "confidence": result.get("confidence", 0.0),
                            "processing_time": result.get("processing_time", 0.0)
                        }
                        
                        await websocket.send_json(response)
                    else:
                        error_response = {
                            "type": "error",
                            "message": "Failed to decode frame"
                        }
                        await websocket.send_json(error_response)
                
                elif message.get("type") == "ping":
                    # Keep-alive ping
                    await websocket.send_json({"type": "pong"})
                
                elif message.get("type") == "config":
                    # Handle configuration messages
                    config = message.get("config", {})
                    logger.info(f"Received config: {config}")
                    await websocket.send_json({
                        "type": "config_received",
                        "status": "ok"
                    })
                
            except json.JSONDecodeError:
                error_response = {
                    "type": "error",
                    "message": "Invalid JSON format"
                }
                await websocket.send_json(error_response)
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                error_response = {
                    "type": "error",
                    "message": str(e)
                }
                await websocket.send_json(error_response)
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("WebSocket disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket)


if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
