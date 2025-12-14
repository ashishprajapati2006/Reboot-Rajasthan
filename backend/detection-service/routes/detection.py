from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from typing import Optional
import exifread
from datetime import datetime
import hashlib
import redis
import json
from models.yolo_detector import detector
from utils.gps_validator import validate_gps_coordinates, calculate_distance
from utils.image_validator import validate_image, check_image_manipulation
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize router
router = APIRouter(prefix="/api/v1/issues", tags=["Detection"])

# Redis client for duplicate detection
redis_client = redis.Redis(
    host='localhost',
    port=6379,
    db=0,
    decode_responses=True
)


@router.post("/detect")
async def detect_civic_issue(
    image: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    device_id: str = Form(...),
    timestamp: str = Form(...),
    sensor_data: Optional[str] = Form(None)
):
    """
    Detect civic issues in uploaded image with fraud prevention
    
    Args:
        image: Image file containing potential civic issue
        latitude: GPS latitude
        longitude: GPS longitude
        device_id: Unique device identifier
        timestamp: Submission timestamp (ISO format)
        sensor_data: Optional sensor data (accelerometer, light sensor) as JSON
        
    Returns:
        Detection results with fraud risk assessment
    """
    try:
        # Read image bytes
        image_bytes = await image.read()
        
        # 1. VALIDATE IMAGE FORMAT AND INTEGRITY
        validation_result = validate_image(image_bytes, image.filename)
        if not validation_result['valid']:
            raise HTTPException(
                status_code=400,
                detail=f"Image validation failed: {validation_result['error']}"
            )
        
        # 2. CHECK FOR IMAGE MANIPULATION
        manipulation_check = check_image_manipulation(image_bytes)
        if manipulation_check['manipulated']:
            logger.warning(f"Potential image manipulation detected: {manipulation_check['indicators']}")
        
        # 3. VALIDATE GPS COORDINATES
        gps_validation = validate_gps_coordinates(latitude, longitude)
        if not gps_validation['valid']:
            raise HTTPException(
                status_code=400,
                detail=f"GPS validation failed: {gps_validation['error']}"
            )
        
        # 4. CHECK FOR DUPLICATE SUBMISSIONS
        # Create hash of image for duplicate detection
        image_hash = hashlib.md5(image_bytes).hexdigest()
        duplicate_key = f"submission:{image_hash}"
        
        # Check if this image was submitted recently (within 1 hour)
        recent_submission = redis_client.get(duplicate_key)
        if recent_submission:
            submission_data = json.loads(recent_submission)
            
            # Calculate distance from previous submission
            prev_lat = submission_data['latitude']
            prev_lon = submission_data['longitude']
            distance = calculate_distance(latitude, longitude, prev_lat, prev_lon)
            
            # If same image within 100 meters, likely duplicate
            if distance < 0.1:  # 100 meters
                raise HTTPException(
                    status_code=409,
                    detail="Duplicate submission detected. Same image submitted recently from nearby location."
                )
        
        # 5. CHECK DEVICE SUBMISSION RATE
        device_rate_key = f"device_rate:{device_id}"
        submission_count = redis_client.incr(device_rate_key)
        
        if submission_count == 1:
            # Set expiry to 1 hour
            redis_client.expire(device_rate_key, 3600)
        
        # Alert if device submitting too frequently (> 10 per hour)
        if submission_count > 10:
            logger.warning(f"High submission rate from device {device_id}: {submission_count}/hour")
        
        # 6. EXTRACT EXIF DATA FOR VERIFICATION
        exif_data = {}
        try:
            tags = exifread.process_file(image.file)
            exif_data = {
                'datetime': str(tags.get('EXIF DateTimeOriginal', '')),
                'make': str(tags.get('Image Make', '')),
                'model': str(tags.get('Image Model', '')),
                'gps_latitude': str(tags.get('GPS GPSLatitude', '')),
                'gps_longitude': str(tags.get('GPS GPSLongitude', ''))
            }
        except Exception as e:
            logger.warning(f"Failed to extract EXIF data: {e}")
        
        # 7. RUN YOLO DETECTION
        detection_result = detector.detect(image_bytes)
        
        # 8. CALCULATE COMPREHENSIVE FRAUD RISK SCORE
        fraud_risk_factors = []
        total_fraud_score = detection_result['fraud_risk_score']
        
        # Add manipulation risk
        if manipulation_check['manipulated']:
            fraud_risk_factors.append('Image manipulation detected')
            total_fraud_score += 0.3
        
        # Add GPS spoofing risk
        if gps_validation.get('possible_spoofing'):
            fraud_risk_factors.append('GPS spoofing suspected')
            total_fraud_score += 0.4
        
        # Add high submission rate risk
        if submission_count > 10:
            fraud_risk_factors.append('Abnormal submission frequency')
            total_fraud_score += 0.2
        
        # Add EXIF inconsistency risk
        if exif_data.get('datetime'):
            try:
                exif_time = datetime.strptime(exif_data['datetime'], '%Y:%m:%d %H:%M:%S')
                submitted_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                time_diff = abs((submitted_time - exif_time).total_seconds())
                
                # If time difference > 1 hour, suspicious
                if time_diff > 3600:
                    fraud_risk_factors.append('EXIF timestamp mismatch')
                    total_fraud_score += 0.15
            except:
                pass
        
        # Normalize fraud score
        total_fraud_score = min(1.0, total_fraud_score)
        
        # 9. STORE SUBMISSION DATA FOR DUPLICATE DETECTION
        submission_data = {
            'latitude': latitude,
            'longitude': longitude,
            'device_id': device_id,
            'timestamp': timestamp,
            'detection_count': detection_result['num_detections']
        }
        redis_client.setex(duplicate_key, 3600, json.dumps(submission_data))
        
        # 10. PREPARE RESPONSE
        response = {
            'success': True,
            'detection': detection_result,
            'fraud_assessment': {
                'risk_score': round(total_fraud_score, 2),
                'risk_level': _get_risk_level(total_fraud_score),
                'risk_factors': fraud_risk_factors + detection_result['fraud_indicators']
            },
            'gps_validation': gps_validation,
            'metadata': {
                'device_id': device_id,
                'timestamp': timestamp,
                'submission_count_hourly': submission_count,
                'exif_data': exif_data
            }
        }
        
        logger.info(
            f"Detection completed - Issues: {detection_result['num_detections']}, "
            f"Fraud Risk: {total_fraud_score:.2f}"
        )
        
        return JSONResponse(content=response)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Detection endpoint error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/verify-completion")
async def verify_task_completion(
    task_id: str = Form(...),
    before_image: UploadFile = File(...),
    after_image: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...)
):
    """
    Verify task completion by comparing before and after images
    
    Args:
        task_id: Unique task identifier
        before_image: Original issue image
        after_image: Post-resolution image
        latitude: GPS latitude
        longitude: GPS longitude
        
    Returns:
        Verification results with AI confidence score
    """
    try:
        # Read image bytes
        before_bytes = await before_image.read()
        after_bytes = await after_image.read()
        
        # Validate both images
        before_validation = validate_image(before_bytes, before_image.filename)
        after_validation = validate_image(after_bytes, after_image.filename)
        
        if not before_validation['valid'] or not after_validation['valid']:
            raise HTTPException(
                status_code=400,
                detail="Image validation failed for one or both images"
            )
        
        # Extract EXIF timestamps from both images
        before_exif_time = None
        after_exif_time = None
        
        try:
            before_tags = exifread.process_file(before_image.file)
            after_tags = exifread.process_file(after_image.file)
            
            before_exif_time = str(before_tags.get('EXIF DateTimeOriginal', ''))
            after_exif_time = str(after_tags.get('EXIF DateTimeOriginal', ''))
        except Exception as e:
            logger.warning(f"Failed to extract EXIF timestamps: {e}")
        
        # Verify timestamps: after image should be taken after before image
        timestamp_valid = True
        if before_exif_time and after_exif_time:
            try:
                before_dt = datetime.strptime(before_exif_time, '%Y:%m:%d %H:%M:%S')
                after_dt = datetime.strptime(after_exif_time, '%Y:%m:%d %H:%M:%S')
                
                if after_dt <= before_dt:
                    timestamp_valid = False
                    logger.warning("After image timestamp is not later than before image")
            except:
                pass
        
        # Run image comparison
        comparison_result = detector.compare_images(before_bytes, after_bytes)
        
        # Additional verification checks
        verification_flags = []
        
        if not timestamp_valid:
            verification_flags.append('Timestamp inconsistency detected')
            comparison_result['verification_confidence'] *= 0.7
        
        # Check for manipulation in after image
        after_manipulation = check_image_manipulation(after_bytes)
        if after_manipulation['manipulated']:
            verification_flags.append('After image may be manipulated')
            comparison_result['verification_confidence'] *= 0.6
        
        # Prepare response
        response = {
            'success': True,
            'task_id': task_id,
            'verification': comparison_result,
            'timestamp_verification': {
                'valid': timestamp_valid,
                'before_timestamp': before_exif_time,
                'after_timestamp': after_exif_time
            },
            'verification_flags': verification_flags,
            'recommendation': _get_verification_recommendation(
                comparison_result,
                verification_flags
            )
        }
        
        logger.info(
            f"Task verification completed - Task: {task_id}, "
            f"Resolved: {comparison_result['issue_resolved']}"
        )
        
        return JSONResponse(content=response)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Verification endpoint error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


def _get_risk_level(risk_score: float) -> str:
    """Determine risk level from fraud score"""
    if risk_score >= 0.7:
        return 'HIGH'
    elif risk_score >= 0.4:
        return 'MEDIUM'
    else:
        return 'LOW'


def _get_verification_recommendation(
    comparison_result: dict,
    verification_flags: list
) -> str:
    """Generate recommendation based on verification results"""
    if comparison_result['issue_resolved'] and not verification_flags:
        return 'APPROVE - Issue verified as resolved with high confidence'
    elif comparison_result['issue_resolved'] and verification_flags:
        return 'REVIEW - Issue appears resolved but has verification flags'
    elif not comparison_result['issue_resolved'] and comparison_result['after_detections'] == 0:
        return 'REVIEW - No issues detected but similarity too high'
    else:
        return 'REJECT - Issue not resolved, work incomplete'
