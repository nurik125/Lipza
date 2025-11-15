"""
Configuration file for Lipza backend
Customize server settings here
"""

# Server Configuration
SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8000
LOG_LEVEL = "info"

# WebSocket Configuration
WEBSOCKET_KEEP_ALIVE_INTERVAL = 30  # seconds
MAX_FRAME_SIZE = 10 * 1024 * 1024  # 10MB

# Frame Processing Configuration
DEFAULT_FRAME_WIDTH = 224
DEFAULT_FRAME_HEIGHT = 224
JPEG_QUALITY = 80

# Model Configuration
MODEL_PATH = None  # "path/to/your/lip_reading_model"
MODEL_ENABLED = False  # Set to True when model is available

# Logging Configuration
ENABLE_FRAME_LOGGING = False  # Log frame reception timestamps
ENABLE_PREDICTION_LOGGING = True  # Log all predictions
LOG_BATCH_SIZE = 100  # Log stats every N predictions

# Performance Configuration
ENABLE_FRAME_CACHING = False  # Cache processed frames
MAX_CACHED_FRAMES = 100
USE_GPU = False  # Use GPU for inference if available

# CORS Configuration (if needed)
CORS_ORIGINS = ["*"]
CORS_CREDENTIALS = True
CORS_METHODS = ["*"]
CORS_HEADERS = ["*"]
