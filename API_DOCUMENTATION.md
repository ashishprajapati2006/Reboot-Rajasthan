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
  "timestamp": "2024-01-15T10:30:00Z",
  "device_id": "device-12345",
  "accelerometer_x": 0.245,
  "accelerometer_y": -0.156,
  "accelerometer_z": 9.812,
  "gyroscope_x": 0.015,
  "gyroscope_y": -0.023,
  "gyroscope_z": 0.008,
  "light_level": 850.5,
  "magnetometer_x": 12.5,
  "magnetometer_y": -8.3,
  "magnetometer_z": 42.1
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
  "sensor_readings": {
    "timestamp": "2024-01-15T10:30:00Z",
    "date": "2024-01-15",
    "time": "10:30:00",
    "accelerometer": {
      "x": 0.245,
      "y": -0.156,
      "z": 9.812,
      "unit": "m/s²"
    },
    "gyroscope": {
      "x": 0.015,
      "y": -0.023,
      "z": 0.008,
      "unit": "rad/s"
    },
    "magnetometer": {
      "x": 12.5,
      "y": -8.3,
      "z": 42.1,
      "unit": "µT"
    },
    "light_sensor": {
      "value": 850.5,
      "unit": "lux"
    }
  },
  "metadata": {
    "device_id": "device-12345",
    "timestamp": "2024-01-15T10:30:00Z",
    "submission_count_hourly": 1,
    "image_url": "https://storage.googleapis.com/bucket/issue-uuid.jpg",
    "exif_data": {
      "datetime": "2024:01:15 10:28:30",
      "date": "2024-01-15",
      "time": "10:28:30",
      "make": "Apple",
      "model": "iPhone 13 Pro",
      "gps_latitude": "26.9124",
      "gps_longitude": "75.7873",
      "gps_altitude": "200.5",
      "focal_length": "4.2",
      "flash": "Off"
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

## 🗄️ Database Schemas

### Issues Collection/Table

```sql
CREATE TABLE issues (
  id UUID PRIMARY KEY,
  reported_by UUID NOT NULL REFERENCES users(id),
  
  -- Issue Classification
  issue_type VARCHAR(50) NOT NULL, -- POTHOLE, STREETLIGHT_FAILURE, etc.
  severity VARCHAR(20) NOT NULL, -- CRITICAL, HIGH, MEDIUM, LOW
  status VARCHAR(30) NOT NULL, -- PENDING, ASSIGNED, IN_PROGRESS, COMPLETED, VERIFIED
  
  -- Location Data
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  address VARCHAR(255),
  geofence_id UUID REFERENCES geofences(id),
  
  -- Image & Media
  image_url VARCHAR(500) NOT NULL,
  image_path VARCHAR(500),
  image_size_kb INT,
  image_dimensions JSON, -- {"width": 1920, "height": 1080}
  image_hash VARCHAR(64), -- For duplicate detection
  
  -- Timestamp Data
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reported_date DATE NOT NULL,
  reported_time TIME NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Sensor Readings at Capture
  sensor_readings JSON, -- Complete sensor data object
  accelerometer_x DECIMAL(8, 6),
  accelerometer_y DECIMAL(8, 6),
  accelerometer_z DECIMAL(8, 6),
  gyroscope_x DECIMAL(8, 6),
  gyroscope_y DECIMAL(8, 6),
  gyroscope_z DECIMAL(8, 6),
  magnetometer_x DECIMAL(8, 2),
  magnetometer_y DECIMAL(8, 2),
  magnetometer_z DECIMAL(8, 2),
  light_level DECIMAL(8, 2),
  
  -- EXIF Data
  exif_data JSON, -- {datetime, date, time, camera_make, camera_model, focal_length, etc.}
  device_id VARCHAR(100),
  device_model VARCHAR(100),
  device_make VARCHAR(100),
  app_version VARCHAR(20),
  
  -- Detection Confidence
  detection_confidence DECIMAL(4, 3), -- 0.000 - 1.000
  fraud_risk_score DECIMAL(4, 3),
  fraud_risk_level VARCHAR(20), -- LOW, MEDIUM, HIGH
  
  -- Geo Validation
  gps_valid BOOLEAN DEFAULT true,
  gps_spoofing_suspected BOOLEAN DEFAULT false,
  
  -- Community Engagement
  upvotes INT DEFAULT 0,
  downvotes INT DEFAULT 0,
  net_votes INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  
  -- Assignment Info
  assigned_to UUID REFERENCES workers(id),
  assigned_at TIMESTAMP,
  priority INT, -- 1-10 priority score
  
  -- Completion Tracking
  completed_at TIMESTAMP,
  verified_at TIMESTAMP,
  verification_confidence DECIMAL(4, 3),
  
  -- Indexing
  INDEX idx_reported_by (reported_by),
  INDEX idx_status (status),
  INDEX idx_issue_type (issue_type),
  INDEX idx_severity (severity),
  INDEX idx_location (latitude, longitude),
  INDEX idx_created_at (created_at),
  INDEX idx_geofence (geofence_id),
  INDEX idx_assigned_to (assigned_to)
);
```

### Issues Sensor Data Extended Table

```sql
CREATE TABLE issue_sensor_readings (
  id UUID PRIMARY KEY,
  issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  
  -- Timestamp
  timestamp TIMESTAMP NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  
  -- Accelerometer (m/s²)
  accelerometer_x DECIMAL(8, 6) NOT NULL,
  accelerometer_y DECIMAL(8, 6) NOT NULL,
  accelerometer_z DECIMAL(8, 6) NOT NULL,
  accelerometer_magnitude DECIMAL(8, 6),
  
  -- Gyroscope (rad/s)
  gyroscope_x DECIMAL(8, 6),
  gyroscope_y DECIMAL(8, 6),
  gyroscope_z DECIMAL(8, 6),
  gyroscope_magnitude DECIMAL(8, 6),
  
  -- Magnetometer (µT - Microtesla)
  magnetometer_x DECIMAL(8, 2),
  magnetometer_y DECIMAL(8, 2),
  magnetometer_z DECIMAL(8, 2),
  magnetometer_magnitude DECIMAL(8, 2),
  
  -- Light Sensor (lux)
  light_level DECIMAL(10, 2) NOT NULL,
  
  -- Additional Environmental
  temperature DECIMAL(5, 2), -- Celsius
  humidity DECIMAL(5, 2), -- Percentage
  pressure DECIMAL(8, 2), -- hPa
  
  -- Device Info
  device_id VARCHAR(100),
  
  -- Data Quality
  sensor_accuracy VARCHAR(20), -- HIGH, MEDIUM, LOW
  calibration_needed BOOLEAN DEFAULT false,
  
  INDEX idx_issue_id (issue_id),
  INDEX idx_timestamp (timestamp)
);
```

### Tasks Table

```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY,
  issue_id UUID NOT NULL REFERENCES issues(id),
  worker_id UUID NOT NULL REFERENCES workers(id),
  
  -- Task Status & Timeline
  status VARCHAR(30) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_date DATE NOT NULL,
  created_time TIME NOT NULL,
  assigned_at TIMESTAMP,
  started_at TIMESTAMP,
  started_date DATE,
  started_time TIME,
  completed_at TIMESTAMP,
  completed_date DATE,
  completed_time TIME,
  deadline TIMESTAMP,
  
  -- Location Verification
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  geofence_verified BOOLEAN DEFAULT false,
  geofence_verified_at TIMESTAMP,
  
  -- Performance Metrics
  time_taken_minutes INT,
  
  -- Before/After Images
  before_image_url VARCHAR(500),
  after_image_url VARCHAR(500),
  before_image_timestamp TIMESTAMP,
  after_image_timestamp TIMESTAMP,
  
  -- Sensor Readings at Completion
  completion_sensor_readings JSON,
  completion_accelerometer_x DECIMAL(8, 6),
  completion_accelerometer_y DECIMAL(8, 6),
  completion_accelerometer_z DECIMAL(8, 6),
  completion_gyroscope_x DECIMAL(8, 6),
  completion_gyroscope_y DECIMAL(8, 6),
  completion_gyroscope_z DECIMAL(8, 6),
  completion_light_level DECIMAL(10, 2),
  completion_timestamp TIMESTAMP,
  completion_date DATE,
  completion_time TIME,
  
  -- Verification
  verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES users(id),
  verification_confidence DECIMAL(4, 3),
  verification_notes TEXT,
  
  INDEX idx_worker_id (worker_id),
  INDEX idx_issue_id (issue_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at),
  INDEX idx_deadline (deadline)
);
```

### Workers Table

```sql
CREATE TABLE workers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  
  -- Personal Info
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  email VARCHAR(100),
  
  -- Department & Role
  department VARCHAR(100),
  role VARCHAR(50),
  
  -- Verification Status
  verification_status VARCHAR(20), -- PENDING, VERIFIED, REJECTED
  verification_date DATE,
  verification_time TIME,
  verified_by UUID REFERENCES users(id),
  
  -- Employment
  hire_date DATE,
  hire_time TIME,
  status VARCHAR(20), -- ACTIVE, INACTIVE, ON_LEAVE
  
  -- Performance Metrics
  tasks_assigned INT DEFAULT 0,
  tasks_completed INT DEFAULT 0,
  completion_rate DECIMAL(5, 2),
  performance_score DECIMAL(4, 2),
  
  -- Location Data
  current_latitude DECIMAL(10, 8),
  current_longitude DECIMAL(11, 8),
  last_location_update TIMESTAMP,
  
  -- Sensor Data (Last Reading)
  last_accelerometer_x DECIMAL(8, 6),
  last_accelerometer_y DECIMAL(8, 6),
  last_accelerometer_z DECIMAL(8, 6),
  last_gyroscope_x DECIMAL(8, 6),
  last_gyroscope_y DECIMAL(8, 6),
  last_gyroscope_z DECIMAL(8, 6),
  last_light_level DECIMAL(10, 2),
  last_sensor_reading_timestamp TIMESTAMP,
  
  -- Timeline
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_date DATE NOT NULL,
  created_time TIME NOT NULL,
  updated_at TIMESTAMP,
  
  INDEX idx_user_id (user_id),
  INDEX idx_verification_status (verification_status),
  INDEX idx_department (department),
  INDEX idx_status (status)
);
```

### User Location History Table

```sql
CREATE TABLE user_location_history (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  
  -- Location
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy_meters DECIMAL(8, 2),
  
  -- Timestamp
  timestamp TIMESTAMP NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  
  -- Sensor Readings
  accelerometer_x DECIMAL(8, 6),
  accelerometer_y DECIMAL(8, 6),
  accelerometer_z DECIMAL(8, 6),
  gyroscope_x DECIMAL(8, 6),
  gyroscope_y DECIMAL(8, 6),
  gyroscope_z DECIMAL(8, 6),
  light_level DECIMAL(10, 2),
  
  -- Device Info
  device_id VARCHAR(100),
  
  INDEX idx_user_id (user_id),
  INDEX idx_timestamp (timestamp),
  INDEX idx_date (date)
);
```

### Firestore Collection Schema (NoSQL)

```javascript
// issues/{issueId}
{
  id: "uuid",
  reportedBy: "uuid",
  
  // Classification
  issueType: "POTHOLE",
  severity: "HIGH",
  status: "PENDING",
  
  // Location
  location: {
    latitude: 26.9124,
    longitude: 75.7873,
    address: "MG Road, Jaipur",
    geofenceId: "uuid"
  },
  
  // Image
  image: {
    url: "https://storage.googleapis.com/...",
    path: "issues/uuid.jpg",
    sizeKb: 2048,
    dimensions: { width: 1920, height: 1080 },
    hash: "sha256_hash"
  },
  
  // Timestamps
  createdAt: Timestamp("2024-01-15T10:30:00Z"),
  reportedDate: "2024-01-15",
  reportedTime: "10:30:00",
  updatedAt: Timestamp("2024-01-15T10:35:00Z"),
  
  // Sensor Readings
  sensorReadings: {
    timestamp: Timestamp("2024-01-15T10:30:00Z"),
    date: "2024-01-15",
    time: "10:30:00",
    accelerometer: {
      x: 0.245,
      y: -0.156,
      z: 9.812
    },
    gyroscope: {
      x: 0.015,
      y: -0.023,
      z: 0.008
    },
    magnetometer: {
      x: 12.5,
      y: -8.3,
      z: 42.1
    },
    lightLevel: 850.5
  },
  
  // EXIF Data
  exifData: {
    timestamp: Timestamp("2024-01-15T10:28:30Z"),
    date: "2024-01-15",
    time: "10:28:30",
    camera: {
      make: "Apple",
      model: "iPhone 13 Pro",
      focalLength: "4.2mm"
    },
    gps: {
      latitude: 26.9124,
      longitude: 75.7873,
      altitude: 200.5
    }
  },
  
  // Detection
  detection: {
    confidence: 0.892,
    fraudRiskScore: 0.12,
    fraudRiskLevel: "LOW"
  },
  
  // Device
  device: {
    id: "device-12345",
    model: "iPhone 13 Pro",
    make: "Apple",
    appVersion: "1.0.0"
  },
  
  // Engagement
  engagement: {
    upvotes: 5,
    downvotes: 1,
    netVotes: 4,
    comments: 2
  },
  
  // Assignment
  assignedTo: "uuid",
  assignedAt: Timestamp("..."),
  priority: 8,
  
  // Completion
  completedAt: Timestamp("..."),
  verifiedAt: Timestamp("..."),
  verificationConfidence: 0.95
}

// workers/{workerId}
{
  id: "uuid",
  userId: "uuid",
  fullName: "Rajesh Kumar",
  phone: "+919876543210",
  
  // Department
  department: "Pothole Repair",
  role: "WORKER",
  
  // Verification
  verificationStatus: "VERIFIED",
  verificationDate: "2024-06-15",
  verificationTime: "14:30:00",
  
  // Employment
  hireDate: "2024-06-15",
  hireTime: "09:00:00",
  status: "ACTIVE",
  
  // Performance
  tasksAssigned: 50,
  tasksCompleted: 45,
  completionRate: 90.0,
  performanceScore: 9.2,
  
  // Location
  currentLocation: {
    latitude: 26.9124,
    longitude: 75.7873,
    lastUpdate: Timestamp("...")
  },
  
  // Last Sensor Readings
  lastSensorReading: {
    timestamp: Timestamp("..."),
    date: "2024-01-15",
    time: "14:45:30",
    accelerometer: { x: 0.1, y: 0.2, z: 9.8 },
    gyroscope: { x: 0.01, y: 0.02, z: 0.00 },
    lightLevel: 650.0
  },
  
  // Timestamps
  createdAt: Timestamp("2024-06-15T09:00:00Z"),
  createdDate: "2024-06-15",
  createdTime: "09:00:00",
  updatedAt: Timestamp("...")
}
```

### Data Types Reference

| Field | Type | Range | Unit | Notes |
|-------|------|-------|------|-------|
| latitude | DECIMAL(10,8) | -90 to 90 | degrees | WGS84 standard |
| longitude | DECIMAL(11,8) | -180 to 180 | degrees | WGS84 standard |
| accelerometer_x/y/z | DECIMAL(8,6) | -10 to 10 | m/s² | Gravity included |
| gyroscope_x/y/z | DECIMAL(8,6) | -360 to 360 | rad/s | Angular velocity |
| magnetometer_x/y/z | DECIMAL(8,2) | -100 to 100 | µT (Microtesla) | Earth's field ~50µT |
| light_level | DECIMAL(10,2) | 0 to 100000+ | lux | 0=dark, 10000=bright sunlight |
| timestamp | TIMESTAMP | - | ISO 8601 | 2024-01-15T10:30:00Z |
| date | DATE | - | YYYY-MM-DD | Extracted from timestamp |
| time | TIME | - | HH:MM:SS | Extracted from timestamp |
| confidence | DECIMAL(4,3) | 0.000 to 1.000 | - | 0=no confidence, 1=100% sure |


