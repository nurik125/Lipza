"""
Camera service for handling camera-related operations
"""

import logging
from typing import Optional, Dict, Any
import cv2
import numpy as np

logger = logging.getLogger(__name__)


class CameraService:
    """Service for camera operations"""
    
    def __init__(self) -> None:
        self.is_initialized = False
        logger.info("CameraService initialized")
    
    def process_frame(self, frame: np.ndarray) -> Optional[np.ndarray]:
        """
        Process a camera frame for lip reading
        
        Args:
            frame: Input frame as numpy array
            
        Returns:
            Processed frame or None if processing fails
        """
        try:
            if frame is None:
                return None
            
            # Resize frame to standard size for model input
            processed_frame = cv2.resize(frame, (224, 224))
            
            # Convert to RGB if needed
            if len(processed_frame.shape) == 2:
                processed_frame = cv2.cvtColor(processed_frame, cv2.COLOR_GRAY2RGB)
            elif processed_frame.shape[2] == 4:
                processed_frame = cv2.cvtColor(processed_frame, cv2.COLOR_BGRA2RGB)
            
            return processed_frame
            
        except Exception as e:
            logger.error(f"Error processing frame: {e}")
            return None
    
    def extract_roi(self, frame: np.ndarray, face_region: Dict[str, Any]) -> Optional[np.ndarray]:
        """
        Extract Region of Interest (ROI) from frame
        
        Args:
            frame: Input frame
            face_region: Dictionary with x, y, width, height of face region
            
        Returns:
            Extracted ROI or None
        """
        try:
            x = face_region.get("x", 0)
            y = face_region.get("y", 0)
            width = face_region.get("width", frame.shape[1])
            height = face_region.get("height", frame.shape[0])
            
            roi = frame[y:y+height, x:x+width]
            
            if roi.size == 0:
                return None
            
            return roi
            
        except Exception as e:
            logger.error(f"Error extracting ROI: {e}")
            return None
