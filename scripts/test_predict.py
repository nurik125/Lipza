#!/usr/bin/env python3
"""Upload a video file to the backend `/predict` endpoint and print JSON result.

Usage:
    python scripts/test_predict.py /path/to/video.mp4

Requirements:
    pip install requests
"""
import argparse
import os
import sys
import time
import requests


def main():
    p = argparse.ArgumentParser(description="Upload a video to /predict and print the response")
    p.add_argument("file", help="Path to the video file to upload")
    p.add_argument("--url", default="http://localhost:8000/predict", help="Prediction endpoint URL")
    p.add_argument("--timeout", type=int, default=60, help="Request timeout seconds")
    args = p.parse_args()

    if not os.path.exists(args.file):
        print(f"Error: file not found: {args.file}")
        sys.exit(2)

    url = args.url
    print(f"Uploading {args.file} to {url}...")

    start = time.time()
    try:
        with open(args.file, "rb") as fh:
            files = {"file": (os.path.basename(args.file), fh, "video/mp4")}
            resp = requests.post(url, files=files, timeout=args.timeout)

        elapsed = time.time() - start
        print(f"HTTP {resp.status_code} in {elapsed:.2f}s")
        try:
            j = resp.json()
            print("Response JSON:")
            import json
            print(json.dumps(j, indent=2))
        except Exception:
            print("Response text:")
            print(resp.text)

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
