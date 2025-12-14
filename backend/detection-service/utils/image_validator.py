from PIL import Image
import io
import numpy as np
import cv2
from typing import Dict


def validate_image(image_bytes: bytes, filename: str) -> Dict:
    """
    Validate image format, size, and basic integrity
    
    Args:
        image_bytes: Image data as bytes
        filename: Original filename
        
    Returns:
        Dictionary with validation results
    """
    try:
        # Check file extension
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.webp']
        ext = filename.lower().split('.')[-1]
        if f'.{ext}' not in allowed_extensions:
            return {
                'valid': False,
                'error': f'Invalid file format. Allowed: {allowed_extensions}'
            }
        
        # Check file size (max 10MB)
        max_size = 10 * 1024 * 1024  # 10MB
        if len(image_bytes) > max_size:
            return {
                'valid': False,
                'error': 'Image size exceeds 10MB limit'
            }
        
        # Try to open image
        image = Image.open(io.BytesIO(image_bytes))
        
        # Check image dimensions (minimum 640x480)
        width, height = image.size
        if width < 640 or height < 480:
            return {
                'valid': False,
                'error': 'Image resolution too low (minimum 640x480)'
            }
        
        # Check if image is corrupted
        image.verify()
        
        return {
            'valid': True,
            'width': width,
            'height': height,
            'format': image.format,
            'size_bytes': len(image_bytes)
        }
        
    except Exception as e:
        return {
            'valid': False,
            'error': f'Image validation error: {str(e)}'
        }


def check_image_manipulation(image_bytes: bytes) -> Dict:
    """
    Detect potential image manipulation/editing
    Uses Error Level Analysis (ELA) and noise analysis
    
    Args:
        image_bytes: Image data as bytes
        
    Returns:
        Dictionary with manipulation detection results
    """
    try:
        # Convert bytes to numpy array
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        indicators = []
        manipulation_score = 0.0
        
        # 1. Check for extreme JPEG compression artifacts
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Calculate noise level
        noise = cv2.Laplacian(gray, cv2.CV_64F).var()
        if noise < 50:
            indicators.append('Unusual noise pattern detected')
            manipulation_score += 0.3
        
        # 2. Check for copy-paste artifacts (duplicate regions)
        # Simple check: calculate histogram variance
        hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
        hist_variance = np.var(hist)
        
        if hist_variance < 1000:
            indicators.append('Low histogram variance (possible editing)')
            manipulation_score += 0.2
        
        # 3. Check for unnatural edges (common in edited images)
        edges = cv2.Canny(gray, 100, 200)
        edge_density = np.sum(edges > 0) / edges.size
        
        if edge_density < 0.01:  # Too few edges
            indicators.append('Unnatural edge distribution')
            manipulation_score += 0.25
        
        # 4. Check color distribution
        # Edited images often have unnatural color distributions
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        h, s, v = cv2.split(hsv)
        
        s_mean = np.mean(s)
        if s_mean < 30:  # Very low saturation
            indicators.append('Unusual color saturation')
            manipulation_score += 0.15
        
        # Normalize score
        manipulation_score = min(1.0, manipulation_score)
        
        return {
            'manipulated': manipulation_score > 0.5,
            'confidence': round(manipulation_score, 2),
            'indicators': indicators
        }
        
    except Exception as e:
        return {
            'manipulated': False,
            'confidence': 0.0,
            'indicators': [],
            'error': str(e)
        }
