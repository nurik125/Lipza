"""
Lip reader service for predicting words from lip movements
Integrates a LipNet-style model (Conv3D + BiLSTM) and provides a
video-to-text prediction API. If a trained checkpoint isn't available
the service falls back to mock predictions.
"""

import os
import logging
import asyncio
import time
from typing import Dict, Any, List, Tuple, Optional, Union

import numpy as np
import cv2

import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import (
    Conv3D,
    LSTM,
    Dense,
    Dropout,
    Bidirectional,
    MaxPool3D,
    Activation,
    TimeDistributed,
    Flatten,
)

logger = logging.getLogger(__name__)

class LipReaderService:
    """Service for lip reading predictions"""

    # Default vocabulary (matches the example notebook)
    VOCAB = [x for x in "abcdefghijklmnopqrstuvwxyz'?!123456789 "]

    def __init__(self, model_path: Optional[str] = None) -> None:
        self.model: Optional[tf.keras.Model] = None
        self.is_initialized = False

        # Create StringLookup layers
        self.char_to_num = tf.keras.layers.StringLookup(vocabulary=self.VOCAB, oov_token="")
        self.num_to_char = tf.keras.layers.StringLookup(
            vocabulary=self.char_to_num.get_vocabulary(), invert=True, oov_token=""
        )

        # Try to initialize model from provided path or environment
        self._initialize_model(model_path)
        logger.info("LipReaderService initialized")

    @staticmethod
    def build_model(input_shape: Tuple[int, int, int, int], output_size: int) -> Sequential:
        """Builds the model architecture used in the LipNet-style notebook."""
        model = Sequential()
        model.add(Conv3D(128, 3, input_shape=input_shape, padding="same"))
        model.add(Activation("relu"))
        model.add(MaxPool3D((1, 2, 2)))

        model.add(Conv3D(256, 3, padding="same"))
        model.add(Activation("relu"))
        model.add(MaxPool3D((1, 2, 2)))

        model.add(Conv3D(75, 3, padding="same"))
        model.add(Activation("relu"))
        model.add(MaxPool3D((1, 2, 2)))

        model.add(TimeDistributed(Flatten()))

        model.add(Bidirectional(LSTM(128, kernel_initializer="Orthogonal", return_sequences=True)))
        model.add(Dropout(0.5))

        model.add(Bidirectional(LSTM(128, kernel_initializer="Orthogonal", return_sequences=True)))
        model.add(Dropout(0.5))

        model.add(Dense(output_size, kernel_initializer="he_normal", activation="softmax"))
        return model

    def _initialize_model(self, model_path: Optional[str] = None) -> None:
        """Attempt to build and load weights for the model.

        model_path: path to checkpoint (TensorFlow checkpoint or .h5 weights).
        """
        try:
            # Default input shape used in the notebook: (75,46,140,1)
            input_shape = (75, 46, 140, 1)
            output_size = len(self.char_to_num.get_vocabulary()) + 1
            self.model = self.build_model(input_shape, output_size)

            # Determine candidate weight paths
            candidates = []
            if model_path:
                candidates.append(model_path)
            candidates.append(os.path.join("models", "checkpoint"))
            candidates.append(os.path.join("model_preparation", "models", "checkpoint"))

            loaded = False
            for p in candidates:
                if not p:
                    continue
                if not os.path.exists(p):
                    continue

                # Try keras load_weights first (works for .h5 or saved weights)
                try:
                    self.model.load_weights(p)
                    logger.info(f"Loaded weights with model.load_weights from {p}")
                    loaded = True
                    break
                except Exception:
                    logger.debug(f"model.load_weights failed for {p}", exc_info=True)

                # If p is a directory, try TensorFlow Checkpoint restore
                try:
                    if os.path.isdir(p):
                        ckpt = tf.train.latest_checkpoint(p)
                        if ckpt:
                            checkpoint = tf.train.Checkpoint(model=self.model)
                            checkpoint.restore(ckpt).expect_partial()
                            logger.info(f"Restored TF checkpoint from {ckpt}")
                            loaded = True
                            break
                except Exception:
                    logger.debug(f"tf.train.Checkpoint restore failed for {p}", exc_info=True)

                # If p points to a .ckpt file (prefix), try restoring via tf.train.Checkpoint
                try:
                    if os.path.isfile(p) and (p.endswith('.ckpt') or 'ckpt' in p):
                        ckpt = p
                        checkpoint = tf.train.Checkpoint(model=self.model)
                        checkpoint.restore(ckpt).expect_partial()
                        logger.info(f"Restored TF checkpoint from {ckpt}")
                        loaded = True
                        break
                except Exception:
                    logger.debug(f"tf.train.Checkpoint restore failed for file {p}", exc_info=True)

            if not loaded:
                logger.warning("No trained weights found. Model will run with untrained weights (mock predictions).")
                self.is_initialized = False
            else:
                self.is_initialized = True

        except Exception as e:
            logger.exception("Failed to initialize LipReaderService model: %s", e)
            self.is_initialized = False

    async def predict(self, video_or_frames: Union[str, np.ndarray]) -> Dict[str, Any]:
        """Public async API: accept either a file path (str) or a numpy ndarray of frames.

        If a path is provided, the video will be read and preprocessed. If an ndarray is
        provided it will be adapted to the model input shape where possible.
        """
        start_time = time.time()

        try:
            # String path -> process as video file
            if isinstance(video_or_frames, str):
                video_path = video_or_frames
                if not os.path.exists(video_path):
                    return {"text": "", "confidence": 0.0, "processing_time": 0.0}

                result = await asyncio.to_thread(self._process_video, video_path)

            # ndarray -> assume frames or single-frame image
            elif isinstance(video_or_frames, np.ndarray):
                frames = video_or_frames
                # Normalize shapes to (1,T,H,W,1)
                if frames.ndim == 5:
                    arr = frames
                elif frames.ndim == 4:
                    # (T,H,W,1)
                    arr = np.expand_dims(frames, axis=0)
                elif frames.ndim == 3:
                    # single frame H,W,C or H,W
                    single = frames
                    if single.shape[-1] == 3:
                        single = np.mean(single, axis=-1)
                    # resize single frame
                    single = cv2.resize(single, (140, 46), interpolation=cv2.INTER_LINEAR)
                    arr = np.stack([single] * 75, axis=0).astype(np.float32) / 255.0
                    arr = np.expand_dims(arr, axis=-1)
                    arr = np.expand_dims(arr, axis=0)
                else:
                    return {"text": "", "confidence": 0.0, "processing_time": 0.0}

                result = await asyncio.to_thread(self._process_frames_array, arr)

            else:
                return {"text": "", "confidence": 0.0, "processing_time": 0.0}

            result["processing_time"] = time.time() - start_time
            return result

        except Exception as e:
            logger.exception("Error running prediction: %s", e)
            return {"text": "ERROR", "confidence": 0.0, "processing_time": time.time() - start_time}

    def _read_and_preprocess_video(self, video_path: str, target_frames: int = 75, crop: Tuple[int, int, int, int] = (190, 236, 80, 220)) -> Optional[np.ndarray]:
        """Read video with cv2, crop, convert to grayscale, normalize and return np.ndarray shape (1,T,H,W,1)."""
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                logger.error("Could not open video: %s", video_path)
                return None

            frames: List[np.ndarray] = []
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                # Convert to grayscale and crop
                y1, y2, x1, x2 = crop
                h, w = frame.shape[:2]
                # Clamp crop to frame bounds
                y1c, y2c = max(0, y1), min(h, y2)
                x1c, x2c = max(0, x1), min(w, x2)
                cropped = frame[y1c:y2c, x1c:x2c]
                gray = cv2.cvtColor(cropped, cv2.COLOR_BGR2GRAY)
                # Ensure size matches notebook expectation (46,140)
                gray = cv2.resize(gray, (140, 46), interpolation=cv2.INTER_LINEAR)
                frames.append(gray)

            cap.release()

            if len(frames) == 0:
                return None

            # Sample or pad frames to target_frames
            if len(frames) < target_frames:
                # pad by repeating last frame
                last = frames[-1]
                while len(frames) < target_frames:
                    frames.append(last.copy())
            elif len(frames) > target_frames:
                # sample uniformly
                idxs = np.linspace(0, len(frames) - 1, target_frames).astype(int)
                frames = [frames[i] for i in idxs]

            arr = np.stack(frames, axis=0).astype(np.float32) / 255.0
            arr = np.expand_dims(arr, axis=-1)  # (T,H,W,1)
            arr = np.expand_dims(arr, axis=0)   # (1,T,H,W,1)
            return arr

        except Exception:
            logger.exception("Error reading/preprocessing video %s", video_path)
            return None

    def _process_video(self, video_path: str) -> Dict[str, Any]:
        """Process video file and return prediction dict."""
        try:
            frames = self._read_and_preprocess_video(video_path)
            if frames is None:
                return {"text": "", "confidence": 0.0}

            if not self.is_initialized or self.model is None:
                # fallback to mock: pick text based on mean intensity
                return self._mock_prediction(frames)

            # model expects shape (batch, T, H, W, C)
            probs = self.model.predict(frames)
            # probs shape: (1, T, vocab_size)
            # decode with CTC greedy
            input_length = np.array([probs.shape[1]])
            decoded, _ = tf.keras.backend.ctc_decode(probs, input_length=input_length, greedy=True)
            decoded = decoded[0].numpy()

            # convert indices to chars
            if decoded.shape[1] == 0:
                text = ""
            else:
                seq = decoded[0]
                # remove padding and blanks (if present)
                chars = [self.num_to_char(int(i)).numpy().decode("utf-8") for i in seq if i != -1 and i != 0]
                text = "".join(chars)

            # simple confidence estimate: mean max-prob across timesteps
            timestep_max = np.max(probs, axis=-1)  # shape (1,T)
            confidence = float(np.mean(timestep_max))

            return {"text": text, "confidence": confidence}

        except Exception:
            logger.exception("Error in _process_video")
            return {"text": "", "confidence": 0.0}

    def _mock_prediction(self, frames: np.ndarray) -> Dict[str, Any]:
        """Generate a simple mock prediction when no model is available."""
        mock_words = ["hello", "goodbye", "thank you", "please", "yes", "no", "ok"]
        mean_intensity = float(np.mean(frames))
        confidence = min(max(0.1, 0.5 + (mean_intensity * 0.5)), 0.99)
        idx = int(mean_intensity * len(mock_words)) % len(mock_words)
        return {"text": mock_words[idx], "confidence": confidence}

    def _process_frames_array(self, arr: np.ndarray) -> Dict[str, Any]:
        """Process a preprocessed frames array of shape (1,T,H,W,1) and
        return prediction dict. This mirrors the logic in `_process_video`.
        """
        try:
            if arr is None:
                return {"text": "", "confidence": 0.0}

            if not self.is_initialized or self.model is None:
                return self._mock_prediction(arr)

            probs = self.model.predict(arr)
            input_length = np.array([probs.shape[1]])
            decoded, _ = tf.keras.backend.ctc_decode(probs, input_length=input_length, greedy=True)
            decoded = decoded[0].numpy()

            if decoded.shape[1] == 0:
                text = ""
            else:
                seq = decoded[0]
                chars = [self.num_to_char(int(i)).numpy().decode("utf-8") for i in seq if i != -1 and i != 0]
                text = "".join(chars)

            timestep_max = np.max(probs, axis=-1)
            confidence = float(np.mean(timestep_max))

            return {"text": text, "confidence": confidence}

        except Exception:
            logger.exception("Error in _process_frames_array")
            return {"text": "", "confidence": 0.0}
