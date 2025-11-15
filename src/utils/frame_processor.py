"""
Frame processor utilities for handling camera frames
"""

import logging
import base64
import io
from typing import Optional, Dict, Any
import numpy as np
import cv2
from PIL import Image

logger = logging.getLogger(__name__)


class FrameProcessor:
    """Utility class for processing camera frames"""
    
    MAX_FRAME_SIZE = 10 * 1024 * 1024  # 10MB max frame size
    
    def decode_frame(self, frame_data: str) -> Optional[np.ndarray]:
        """
        Decode base64 encoded JPEG frame to numpy array
        
        Args:
            frame_data: Base64 encoded frame string
            
        Returns:
            Decoded frame as numpy array or None if decoding fails
        """
        try:
            if not frame_data or len(frame_data) > self.MAX_FRAME_SIZE:
                logger.warning("Invalid frame data size")
                return None
            
            # Decode base64
            frame_bytes = base64.b64decode(frame_data)
            
            # Convert bytes to numpy array
            nparr = np.frombuffer(frame_bytes, np.uint8)
            
            # Decode image from JPEG
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if frame is None:
                logger.warning("Failed to decode JPEG frame")
                return None
            
            return frame
            
        except Exception as e:
            logger.error(f"Error decoding frame: {e}")
            return None
    
    def encode_frame(self, frame: np.ndarray, quality: int = 80) -> Optional[str]:
        """
        Encode numpy array frame to base64 JPEG string
        
        Args:
            frame: Frame as numpy array
            quality: JPEG quality (0-100)
            
        Returns:
            Base64 encoded JPEG string or None if encoding fails
        """
        try:
            if frame is None or frame.size == 0:
                return None
            
            # Encode frame to JPEG
            success, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
            
            if not success:
                logger.warning("Failed to encode frame to JPEG")
                return None
            
            # Convert to base64 string
            frame_data = base64.b64encode(buffer).decode('utf-8')
            
            return frame_data
            
        except Exception as e:
            logger.error(f"Error encoding frame: {e}")
            return None
    
    def resize_frame(self, frame: np.ndarray, width: int, height: int) -> Optional[np.ndarray]:
        """
        Resize frame to specified dimensions
        
        Args:
            frame: Input frame
            width: Target width
            height: Target height
            
        Returns:
            Resized frame or None if resizing fails
        """
        try:
            if frame is None:
                return None
            
            resized = cv2.resize(frame, (width, height), interpolation=cv2.INTER_LINEAR)
            return resized
            
        except Exception as e:
            logger.error(f"Error resizing frame: {e}")
            return None
    
    def normalize_frame(self, frame: np.ndarray) -> Optional[np.ndarray]:
        """
        Normalize frame pixel values to 0-1 range
        
        Args:
            frame: Input frame
            
        Returns:
            Normalized frame or None if normalization fails
        """
        try:
            if frame is None:
                return None
            
            normalized = frame.astype(np.float32) / 255.0
            return normalized
            
        except Exception as e:
            logger.error(f"Error normalizing frame: {e}")
            return None
    
    def get_frame_stats(self, frame: np.ndarray) -> Dict[str, Any]:
        """
        Get statistics about a frame
        
        Args:
            frame: Input frame
            
        Returns:
            Dictionary with frame statistics
        """
        try:
            if frame is None or frame.size == 0:
                return {}
            
            return {
                "shape": frame.shape,
                "dtype": str(frame.dtype),
                "mean": float(np.mean(frame)),
                "std": float(np.std(frame)),
                "min": float(np.min(frame)),
                "max": float(np.max(frame))
            }
            
        except Exception as e:
            logger.error(f"Error getting frame stats: {e}")
            return {}
