# SAAF-SURKSHA API Documentation

Base URL: `http://localhost:8000` (via Kong Gateway)

## Authentication

All protected endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <access_token>
```

---

## 📝 Auth Service API

### Register User

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "email": "user@example.com",
  "fullName": "John Doe",
  "password": "SecurePass@123",
  "role": "CITIZEN"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your phone number.",
  "data": {
    "user": {
      "id": "uuid",
      "phoneNumber": "+919876543210",
      "email": "user@example.com",
      "fullName": "John Doe",
      "role": "CITIZEN",
      "isVerified": false,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "15m"
  }
}
```

### Request OTP

```http
POST /api/v1/auth/request-otp
Content-Type: application/json

{
  "phoneNumber": "+919876543210"
}
```

**Rate Limit:** 3 requests per 5 minutes

**Response (200):**
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

### Verify OTP

```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "otp": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Phone number verified successfully"
}
```

### Login

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "password": "SecurePass@123"
}
```

**Rate Limit:** 5 attempts per 15 minutes

**Response (200) - Without 2FA:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "phoneNumber": "+919876543210",
      "email": "user@example.com",
      "fullName": "John Doe",
      "role": "CITIZEN",
      "isVerified": true,
      "twoFAEnabled": false
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "15m"
  }
}
```

**Response (200) - With 2FA:**
```json
{
  "success": true,
  "message": "Please provide 2FA token",
  "data": {
    "requires2FA": true,
    "tempToken": "temp-uuid-token"
  }
}
```

### Verify 2FA

```http
POST /api/v1/auth/verify-2fa
Content-Type: application/json

{
  "tempToken": "temp-uuid-token",
  "token": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {...},
    "accessToken": "...",
    "refreshToken": "...",
    "expiresIn": "15m"
  }
}
```

### Refresh Token

```http
POST /api/v1/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "15m"
  }
}
```

### Setup 2FA

```http
POST /api/v1/auth/setup-2fa
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "2FA setup initiated. Scan QR code with authenticator app.",
  "data": {
    "secret": "JBSWY3DPEHPK3PXP",
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "manualEntryKey": "JBSWY3DPEHPK3PXP"
  }
}
```

### Confirm 2FA

```http
POST /api/v1/auth/confirm-2fa
Authorization: Bearer <token>
Content-Type: application/json

{
  "token": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "2FA enabled successfully"
}
```

### Logout

```http
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## 🔍 Detection Service API

### Detect Civic Issue

```http
POST /api/v1/issues/detect
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "image": <file>,
  "latitude": 26.9124,
  "longitude": 75.7873,
  "device_id": "device-12345",
  "timestamp": "2024-01-15T10:30:00Z",
  "sensor_data": "{\"accelerometer\": {...}, \"light\": 850}"
}
```

**Response (200):**
```json
{
  "success": true,
  "detection": {
    "detected": true,
    "num_detections": 1,
    "detections": [
      {
        "issue_type": "POTHOLE",
        "confidence": 0.892,
        "bbox": {
          "x1": 120,
          "y1": 200,
          "x2": 450,
          "y2": 380
        },
        "area_percentage": 15.3
      }
    ],
    "severity": "HIGH",
    "total_area_percentage": 15.3,
    "image_dimensions": {
      "width": 1920,
      "height": 1080
    },
    "fraud_risk_score": 0.12,
    "fraud_indicators": []
  },
  "fraud_assessment": {
    "risk_score": 0.12,
    "risk_level": "LOW",
    "risk_factors": []
  },
  "gps_validation": {
    "valid": true,
    "in_rajasthan": true,
    "possible_spoofing": false,
    "warnings": [],
    "coordinates": {
      "latitude": 26.9124,
      "longitude": 75.7873
    }
  },
  "metadata": {
    "device_id": "device-12345",
    "timestamp": "2024-01-15T10:30:00Z",
    "submission_count_hourly": 1,
    "exif_data": {
      "datetime": "2024:01:15 10:28:30",
      "make": "Apple",
      "model": "iPhone 13 Pro",
      "gps_latitude": "26.9124",
      "gps_longitude": "75.7873"
    }
  }
}
```

**Fraud Risk Levels:**
- `LOW` (0.0 - 0.3): Safe to approve
- `MEDIUM` (0.4 - 0.6): Requires review
- `HIGH` (0.7 - 1.0): Likely fraud, reject

**Issue Types:**
- `POTHOLE`
- `STREETLIGHT_FAILURE`
- `ANIMAL_CARCASS`
- `WASTE_ACCUMULATION`
- `TOILET_UNCLEAN`
- `STAFF_ABSENT`

**Severity Levels:**
- `CRITICAL`: Immediate action required
- `HIGH`: Priority attention
- `MEDIUM`: Standard processing
- `LOW`: Can be scheduled

### Verify Task Completion

```http
POST /api/v1/issues/verify-completion
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "task_id": "uuid",
  "before_image": <file>,
  "after_image": <file>,
  "latitude": 26.9124,
  "longitude": 75.7873
}
```

**Response (200):**
```json
{
  "success": true,
  "task_id": "uuid",
  "verification": {
    "issue_resolved": true,
    "verification_confidence": 0.876,
    "similarity_score": 0.234,
    "before_detections": 1,
    "after_detections": 0,
    "analysis": "Issue verified as resolved. Before: 1 issue(s), After: 0 issue(s). Images show 76.6% change."
  },
  "timestamp_verification": {
    "valid": true,
    "before_timestamp": "2024:01:15 10:28:30",
    "after_timestamp": "2024:01:16 14:45:20"
  },
  "verification_flags": [],
  "recommendation": "APPROVE - Issue verified as resolved with high confidence"
}
```

**Recommendations:**
- `APPROVE`: High confidence, approve payment
- `REVIEW`: Medium confidence, manual review needed
- `REJECT`: Low confidence or fraud detected, reject

---

## 📋 Task Service API

### Create Task

```http
POST /api/v1/tasks
Authorization: Bearer <token>
Content-Type: application/json

{
  "issue_id": "uuid",
  "worker_id": "uuid",
  "deadline": "2024-01-17T10:30:00Z"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "task_id": "uuid",
    "issue_id": "uuid",
    "worker_id": "uuid",
    "status": "PENDING",
    "deadline": "2024-01-17T10:30:00Z",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Update Task Status

```http
PATCH /api/v1/tasks/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "IN_PROGRESS",
  "latitude": 26.9124,
  "longitude": 75.7873
}
```

**Task Statuses:**
- `PENDING`: Assigned but not started
- `ACCEPTED`: Worker accepted
- `WORKER_EN_ROUTE`: Worker traveling
- `AT_LOCATION`: Worker at site (geofence verified)
- `IN_PROGRESS`: Work in progress
- `COMPLETED`: Work finished
- `VERIFIED`: AI verification passed
- `REJECTED`: Verification failed

### Get Worker Tasks

```http
GET /api/v1/tasks/worker/:worker_id
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "tasks": [
      {
        "task_id": "uuid",
        "issue_type": "POTHOLE",
        "severity": "HIGH",
        "status": "IN_PROGRESS",
        "location": {
          "latitude": 26.9124,
          "longitude": 75.7873,
          "address": "MG Road, Jaipur"
        },
        "deadline": "2024-01-17T10:30:00Z"
      }
    ],
    "count": 1
  }
}
```

---

## 📍 Geofence Service API

### Create Geofence

```http
POST /api/v1/geofences
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "MG Road Zone",
  "geofence_type": "WARD",
  "geometry": {
    "type": "Polygon",
    "coordinates": [[
      [75.7873, 26.9124],
      [75.7883, 26.9124],
      [75.7883, 26.9134],
      [75.7873, 26.9134],
      [75.7873, 26.9124]
    ]]
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "geofence_id": "uuid",
    "name": "MG Road Zone",
    "geofence_type": "WARD",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Check Point in Geofence

```http
POST /api/v1/geofences/:id/check
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 26.9124,
  "longitude": 75.7873
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "within_geofence": true,
    "geofence_name": "MG Road Zone",
    "distance_from_center_m": 45.3
  }
}
```

---

## 📊 Analytics Service API

### Generate Heatmap

```http
GET /api/v1/analytics/heatmap?issue_type=POTHOLE&region=jaipur
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [75.7873, 26.9124]
        },
        "properties": {
          "issue_count": 25,
          "severity": "HIGH"
        }
      }
    ]
  }
}
```

### Get Civic Health Score

```http
GET /api/v1/analytics/civic-health?region=jaipur
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "region": "Jaipur",
    "score": 72.5,
    "metrics": {
      "total_issues": 1250,
      "resolved_issues": 980,
      "resolution_rate": 78.4,
      "avg_resolution_time_hours": 36.5,
      "severity_distribution": {
        "CRITICAL": 12,
        "HIGH": 145,
        "MEDIUM": 523,
        "LOW": 570
      }
    },
    "calculated_at": "2024-01-15T10:30:00Z"
  }
}
```

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `POST /auth/login` | 5 per 15 minutes |
| `POST /auth/request-otp` | 3 per 5 minutes |
| `POST /issues/detect` | 10 per hour per device |
| Other endpoints | 100 per hour |

---

## Postman Collection

Import this collection for easy testing:

[Download Postman Collection](./postman_collection.json)

---

## WebSocket API (Coming Soon)

Real-time updates for:
- Task status changes
- New issue notifications
- Worker location tracking
- Community voting results

---

For more details, see:
- [README.md](README.md) - Project overview
- [SETUP.md](SETUP.md) - Setup instructions
- [COPILOT_GUIDE.md](COPILOT_GUIDE.md) - Development guide
