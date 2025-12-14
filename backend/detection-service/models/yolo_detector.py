import torch
import cv2
import numpy as np
from ultralytics import YOLO
from PIL import Image
from skimage.metrics import structural_similarity as ssim
from typing import Dict, List, Tuple
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class YOLODetector:
    """
    YOLOv8 detector for civic issue detection with fraud prevention
    """
    
    # Issue type mapping
    ISSUE_TYPES = {
        0: 'POTHOLE',
        1: 'STREETLIGHT_FAILURE',
        2: 'ANIMAL_CARCASS',
        3: 'WASTE_ACCUMULATION',
        4: 'TOILET_UNCLEAN',
        5: 'STAFF_ABSENT'
    }
    
    # Severity thresholds based on detection confidence and area
    SEVERITY_THRESHOLDS = {
        'CRITICAL': {'confidence': 0.85, 'area_percentage': 30},
        'HIGH': {'confidence': 0.75, 'area_percentage': 20},
        'MEDIUM': {'confidence': 0.65, 'area_percentage': 10},
        'LOW': {'confidence': 0.50, 'area_percentage': 5}
    }

    def __init__(self, model_path: str = 'yolov8n.pt', confidence_threshold: float = 0.5):
        """
        Initialize YOLOv8 detector
        
        Args:
            model_path: Path to YOLOv8 model file
            confidence_threshold: Minimum confidence for detections
        """
        self.confidence_threshold = confidence_threshold
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        
        try:
            # Load YOLOv8 model
            self.model = YOLO(model_path)
            self.model.to(self.device)
            logger.info(f"YOLOv8 model loaded successfully on {self.device}")
        except Exception as e:
            logger.error(f"Failed to load YOLOv8 model: {e}")
            raise

    def detect(
        self, 
        image_bytes: bytes, 
        confidence_threshold: float = None
    ) -> Dict:
        """
        Detect civic issues in an image
        
        Args:
            image_bytes: Image data as bytes
            confidence_threshold: Override default confidence threshold
            
        Returns:
            Dictionary containing detection results
        """
        try:
            # Use instance threshold if not provided
            conf_threshold = confidence_threshold or self.confidence_threshold
            
            # Convert bytes to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                raise ValueError("Failed to decode image")
            
            # Get image dimensions
            height, width = image.shape[:2]
            total_pixels = height * width
            
            # Run YOLO detection
            results = self.model.predict(
                image, 
                conf=conf_threshold,
                device=self.device,
                verbose=False
            )
            
            # Process detections
            detections = []
            total_issue_area = 0
            
            for result in results:
                boxes = result.boxes
                
                for box in boxes:
                    # Extract detection information
                    class_id = int(box.cls[0])
                    confidence = float(box.conf[0])
                    bbox = box.xyxy[0].cpu().numpy()
                    
                    # Calculate bounding box area
                    box_width = bbox[2] - bbox[0]
                    box_height = bbox[3] - bbox[1]
                    box_area = box_width * box_height
                    area_percentage = (box_area / total_pixels) * 100
                    
                    total_issue_area += box_area
                    
                    detection = {
                        'issue_type': self.ISSUE_TYPES.get(class_id, 'UNKNOWN'),
                        'confidence': round(confidence, 3),
                        'bbox': {
                            'x1': int(bbox[0]),
                            'y1': int(bbox[1]),
                            'x2': int(bbox[2]),
                            'y2': int(bbox[3])
                        },
                        'area_percentage': round(area_percentage, 2)
                    }
                    
                    detections.append(detection)
            
            # Calculate total area percentage
            total_area_percentage = (total_issue_area / total_pixels) * 100
            
            # Determine severity
            severity = self._determine_severity(detections, total_area_percentage)
            
            # Calculate fraud risk indicators
            fraud_indicators = self._calculate_fraud_indicators(image, detections)
            
            result_dict = {
                'detected': len(detections) > 0,
                'num_detections': len(detections),
                'detections': detections,
                'severity': severity,
                'total_area_percentage': round(total_area_percentage, 2),
                'image_dimensions': {
                    'width': width,
                    'height': height
                },
                'fraud_risk_score': fraud_indicators['risk_score'],
                'fraud_indicators': fraud_indicators['indicators']
            }
            
            logger.info(f"Detection completed: {len(detections)} issues found")
            return result_dict
            
        except Exception as e:
            logger.error(f"Detection error: {e}")
            raise

    def compare_images(
        self, 
        before_bytes: bytes, 
        after_bytes: bytes
    ) -> Dict:
        """
        Compare before and after images to verify issue resolution
        
        Args:
            before_bytes: Before image data as bytes
            after_bytes: After image data as bytes
            
        Returns:
            Dictionary with verification results
        """
        try:
            # Decode images
            before_arr = np.frombuffer(before_bytes, np.uint8)
            after_arr = np.frombuffer(after_bytes, np.uint8)
            
            before_img = cv2.imdecode(before_arr, cv2.IMREAD_COLOR)
            after_img = cv2.imdecode(after_arr, cv2.IMREAD_COLOR)
            
            if before_img is None or after_img is None:
                raise ValueError("Failed to decode one or both images")
            
            # Resize images to same dimensions
            height, width = before_img.shape[:2]
            after_img_resized = cv2.resize(after_img, (width, height))
            
            # Convert to grayscale for SSIM
            before_gray = cv2.cvtColor(before_img, cv2.COLOR_BGR2GRAY)
            after_gray = cv2.cvtColor(after_img_resized, cv2.COLOR_BGR2GRAY)
            
            # Calculate Structural Similarity Index (SSIM)
            similarity_score, diff_image = ssim(
                before_gray, 
                after_gray, 
                full=True
            )
            
            # Detect issues in both images
            before_detection = self.detect(before_bytes)
            after_detection = self.detect(after_bytes)
            
            # Calculate resolution metrics
            before_count = before_detection['num_detections']
            after_count = after_detection['num_detections']
            
            # Issue is resolved if:
            # 1. After image has fewer or no detections
            # 2. Similarity is not too high (images are different)
            # 3. After image doesn't show new issues
            
            is_resolved = (
                after_count < before_count and
                similarity_score < 0.95 and  # Images should be different
                (before_count > 0 and after_count == 0)  # Issues should be gone
            )
            
            # Calculate verification confidence
            if is_resolved:
                confidence = min(
                    1.0,
                    (1.0 - similarity_score) * 0.5 +  # Change factor
                    (1.0 - after_count / max(before_count, 1)) * 0.5  # Reduction factor
                )
            else:
                confidence = 0.0
            
            result = {
                'issue_resolved': is_resolved,
                'verification_confidence': round(confidence, 3),
                'similarity_score': round(similarity_score, 3),
                'before_detections': before_count,
                'after_detections': after_count,
                'analysis': self._generate_comparison_analysis(
                    is_resolved,
                    similarity_score,
                    before_count,
                    after_count
                )
            }
            
            logger.info(f"Image comparison completed: resolved={is_resolved}")
            return result
            
        except Exception as e:
            logger.error(f"Image comparison error: {e}")
            raise

    def _determine_severity(
        self, 
        detections: List[Dict], 
        total_area_percentage: float
    ) -> str:
        """
        Determine issue severity based on detections
        
        Args:
            detections: List of detection dictionaries
            total_area_percentage: Total area covered by issues
            
        Returns:
            Severity level string
        """
        if not detections:
            return 'NONE'
        
        # Get highest confidence detection
        max_confidence = max(d['confidence'] for d in detections)
        
        # Check severity thresholds
        for severity, thresholds in self.SEVERITY_THRESHOLDS.items():
            if (max_confidence >= thresholds['confidence'] and 
                total_area_percentage >= thresholds['area_percentage']):
                return severity
        
        return 'LOW'

    def _calculate_fraud_indicators(
        self, 
        image: np.ndarray, 
        detections: List[Dict]
    ) -> Dict:
        """
        Calculate fraud risk indicators from image analysis
        
        Args:
            image: Image as numpy array
            detections: List of detections
            
        Returns:
            Dictionary with fraud indicators
        """
        indicators = []
        risk_score = 0.0
        
        # Check image quality
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blur_score = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        if blur_score < 100:
            indicators.append('Low image quality detected')
            risk_score += 0.2
        
        # Check for unrealistic number of detections
        if len(detections) > 10:
            indicators.append('Unusually high number of issues in single image')
            risk_score += 0.3
        
        # Check image dimensions (too small might be suspicious)
        height, width = image.shape[:2]
        if width < 640 or height < 480:
            indicators.append('Image resolution below recommended minimum')
            risk_score += 0.1
        
        # Check for extreme brightness/darkness
        mean_brightness = np.mean(gray)
        if mean_brightness < 30 or mean_brightness > 225:
            indicators.append('Unusual lighting conditions')
            risk_score += 0.15
        
        # Normalize risk score
        risk_score = min(1.0, risk_score)
        
        return {
            'risk_score': round(risk_score, 2),
            'indicators': indicators
        }

    def _generate_comparison_analysis(
        self,
        is_resolved: bool,
        similarity_score: float,
        before_count: int,
        after_count: int
    ) -> str:
        """
        Generate human-readable analysis of image comparison
        
        Args:
            is_resolved: Whether issue is resolved
            similarity_score: SSIM similarity score
            before_count: Number of issues in before image
            after_count: Number of issues in after image
            
        Returns:
            Analysis string
        """
        if is_resolved:
            return (
                f"Issue verified as resolved. "
                f"Before: {before_count} issue(s), After: {after_count} issue(s). "
                f"Images show {(1-similarity_score)*100:.1f}% change."
            )
        elif similarity_score > 0.95:
            return (
                "Images are too similar. "
                "Possible duplicate or no work performed."
            )
        elif after_count >= before_count:
            return (
                f"Issue not resolved. "
                f"After image still shows {after_count} issue(s)."
            )
        else:
            return (
                "Unable to verify complete resolution. "
                "Some issues may remain."
            )


# Create singleton instance
detector = YOLODetector()
