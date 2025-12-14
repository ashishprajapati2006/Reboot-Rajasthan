# 🤖 GitHub Copilot Pro - Complete Implementation Guide

**Building SAAF-SURKSHA with AI Assistance**

This document contains **ACTUAL PROMPTS** used to build this project with GitHub Copilot Pro.

---

## Table of Contents

1. [Setup Phase](#setup-phase)
2. [Auth Service Implementation](#auth-service-implementation)
3. [Detection Service (YOLOv8)](#detection-service-yolov8)
4. [Task Management](#task-management)
5. [Geofencing](#geofencing)
6. [RTI & Escalation](#rti--escalation)
7. [Analytics & Heatmaps](#analytics--heatmaps)
8. [Testing](#testing)
9. [Optimization](#optimization)
10. [Troubleshooting](#troubleshooting)

---

## Setup Phase

### Project Structure Generation

**Prompt:**
```
Create a complete microservices project structure for a civic issue tracking system with:
- 6 Node.js services (auth, task, geofence, rti, analytics, gateway)
- 1 Python FastAPI service (detection with YOLOv8)
- PostgreSQL with PostGIS for geospatial data
- Redis for caching and sessions
- RabbitMQ for message queuing
- Docker Compose configuration

Generate the folder structure with all necessary subdirectories.
```

**Usage:** Copy the generated folder structure and create it using mkdir commands.

---

## Auth Service Implementation

### 1. Package.json Generation

**Prompt:**
```
Generate a production-ready package.json for an Express.js authentication microservice with:

Dependencies:
- express 4.x for REST API
- express-rate-limit for rate limiting (5 attempts per 15 min)
- express-validator for input validation
- bcrypt for password hashing (12 rounds)
- jsonwebtoken for JWT tokens (access + refresh)
- redis 4.x for session storage
- pg with connection pooling for PostgreSQL
- twilio for SMS OTP verification
- speakeasy for TOTP 2FA
- qrcode for 2FA QR code generation
- cors with origin whitelist
- helmet for security headers
- dotenv for environment variables
- winston for structured logging
- joi for schema validation
- uuid for ID generation

Dev dependencies:
- nodemon for development
- jest for unit testing
- supertest for API testing
- eslint for code quality

Scripts:
- start: production mode
- dev: development with nodemon
- test: jest with coverage
- lint: eslint check

Include proper engines constraint for Node 18+
```

### 2. Auth Service Class

**Prompt:**
```
Create a complete AuthService class in JavaScript with these methods:

1. registerUser(phoneNumber, email, fullName, password, role='CITIZEN')
   - Check for existing user (phone/email)
   - Hash password with bcrypt (12 rounds)
   - Generate UUID for user ID
   - Insert into PostgreSQL users table
   - Send OTP via sendOTP()
   - Generate JWT tokens
   - Return user object + tokens
   - Handle database transactions (BEGIN/COMMIT/ROLLBACK)

2. sendOTP(phoneNumber)
   - Generate 6-digit random OTP
   - Store in Redis with 5-minute TTL (SETEX)
   - Send via Twilio SMS API
   - Log to console in development mode
   - Return success boolean

3. verifyOTP(phoneNumber, otp)
   - Retrieve OTP from Redis (GET)
   - Compare with input OTP
   - Mark user as verified in database
   - Delete OTP from Redis (DEL)
   - Throw error if expired or invalid

4. login(phoneNumber, password)
   - Fetch user from database
   - Verify password with bcrypt.compare()
   - Check if user is verified
   - If 2FA enabled: return requires2FA + tempToken
   - Store temp session in Redis (5 min)
   - Otherwise: generate tokens and return
   - Update last_login timestamp

5. generateTokens(userId, userRole)
   - Create JWT access token (15m expiry)
   - Create JWT refresh token (7d expiry)
   - Store refresh token in Redis
   - Return { accessToken, refreshToken, expiresIn }

6. setup2FA(userId)
   - Generate speakeasy secret
   - Include issuer name and user email
   - Store temporary secret in Redis (10 min)
   - Generate QR code as data URL
   - Return { secret, qrCode, manualEntryKey }

7. confirm2FA(userId, token)
   - Get temporary secret from Redis
   - Verify TOTP token (window=2)
   - Save secret to database permanently
   - Enable 2FA flag for user
   - Delete temporary secret

8. verify2FAToken(tempToken, token)
   - Get userId from temp session
   - Fetch user 2FA secret
   - Verify TOTP token
   - Generate final JWT tokens
   - Delete temp session
   - Update last_login

9. refreshAccessToken(refreshToken)
   - Verify refresh token JWT
   - Check token type === 'refresh'
   - Verify token exists in Redis
   - Generate new access token
   - Return { accessToken, expiresIn }

10. logout(userId)
    - Delete refresh token from Redis
    - Return success

Include:
- Proper error handling with try/catch
- Winston logger for all operations
- PostgreSQL connection pool from config
- Redis client from config
- Twilio client from config
- Export as singleton instance
```

### 3. Auth Routes

**Prompt:**
```
Generate Express.js routes for /api/v1/auth with these endpoints:

POST /register
- Validate: phoneNumber (E.164 format), email, fullName (2-100 chars), password (min 8, uppercase, lowercase, number, special char), role (CITIZEN/WORKER/AUTHORITY)
- Call authService.registerUser()
- Return 201 with user + tokens
- Rate limit: default

POST /request-otp
- Rate limit: 3 per 5 minutes
- Validate: phoneNumber
- Call authService.sendOTP()
- Return 200 success

POST /verify-otp
- Validate: phoneNumber, otp (6 digits)
- Call authService.verifyOTP()
- Return 200 success

POST /login
- Rate limit: 5 per 15 minutes
- Validate: phoneNumber, password
- Call authService.login()
- Return 200 with user + tokens (or requires2FA)

POST /verify-2fa
- Validate: tempToken, token (6 digits)
- Call authService.verify2FAToken()
- Return 200 with user + tokens

POST /refresh-token
- Validate: refreshToken
- Call authService.refreshAccessToken()
- Return 200 with new accessToken

POST /setup-2fa
- Require authMiddleware
- Call authService.setup2FA(req.user.userId)
- Return 200 with QR code

POST /confirm-2fa
- Require authMiddleware
- Validate: token (6 digits)
- Call authService.confirm2FA()
- Return 200 success

POST /logout
- Require authMiddleware
- Call authService.logout(req.user.userId)
- Return 200 success

Include:
- express-validator for all validations
- express-rate-limit for appropriate endpoints
- Error handling middleware
- Success/error response format: { success, message, data }
- Winston logger for all operations
```

### 4. JWT Middleware

**Prompt:**
```
Create authentication middleware for Express.js:

authMiddleware(req, res, next)
- Extract token from Authorization header (Bearer scheme)
- Return 401 if no token
- Verify JWT with process.env.JWT_SECRET
- Decode and attach { userId, role } to req.user
- Handle TokenExpiredError: return 401 with "Token expired"
- Handle JsonWebTokenError: return 401 with "Invalid token"
- Handle other errors: return 500
- Call next() if successful

authorizeRoles(...allowedRoles)
- Return middleware function
- Check if req.user exists
- Check if req.user.role is in allowedRoles
- Return 403 if not authorized
- Call next() if authorized

Export both functions
```

### 5. Configuration Files

**Prompt:**
```
Generate three configuration files:

1. database.js - PostgreSQL connection pool
   - Import pg.Pool
   - Configure: host, port, database, user, password from env
   - Set max: 20 connections
   - Set idleTimeoutMillis: 30000
   - Set connectionTimeoutMillis: 2000
   - Log 'connect' and 'error' events
   - Exit process on error
   - Export pool

2. redis.js - Redis client
   - Import redis
   - Create client with socket config
   - Connect with error handling
   - Log events: connect, error, ready
   - Export connected client

3. twilio.js - Twilio client
   - Import twilio
   - Initialize with TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN
   - Log warning if credentials missing
   - Export client (or null)
```

---

## Detection Service (YOLOv8)

### 1. YOLODetector Class

**Prompt:**
```
Create a YOLODetector class in Python with YOLOv8 for civic issue detection:

Class attributes:
- ISSUE_TYPES = {0: 'POTHOLE', 1: 'STREETLIGHT_FAILURE', 2: 'ANIMAL_CARCASS', 3: 'WASTE_ACCUMULATION', 4: 'TOILET_UNCLEAN', 5: 'STAFF_ABSENT'}
- SEVERITY_THRESHOLDS = {'CRITICAL': {'confidence': 0.85, 'area_percentage': 30}, 'HIGH': {...}, 'MEDIUM': {...}, 'LOW': {...}}

__init__(model_path='yolov8n.pt', confidence_threshold=0.5)
- Load YOLO model from ultralytics
- Detect CUDA availability
- Move model to device (cuda/cpu)
- Store confidence threshold
- Log initialization

detect(image_bytes, confidence_threshold=None)
- Decode image from bytes using cv2.imdecode()
- Get image dimensions (height, width)
- Run model.predict() with confidence threshold
- Process all detections:
  - Extract class_id, confidence, bbox
  - Calculate bbox area and percentage
  - Map class_id to issue type
  - Store detection dict
- Calculate total_area_percentage
- Determine severity using _determine_severity()
- Calculate fraud indicators using _calculate_fraud_indicators()
- Return dict: {detected, num_detections, detections[], severity, total_area_percentage, image_dimensions, fraud_risk_score, fraud_indicators}

compare_images(before_bytes, after_bytes)
- Decode both images
- Resize to same dimensions
- Convert to grayscale
- Calculate SSIM (structural similarity)
- Run detect() on both images
- Determine if resolved:
  - After detections < before detections
  - Similarity < 0.95 (images are different)
  - Before had issues, after has none
- Calculate verification confidence (0-1)
- Generate analysis text
- Return: {issue_resolved, verification_confidence, similarity_score, before_detections, after_detections, analysis}

_determine_severity(detections, total_area_percentage)
- Return 'NONE' if no detections
- Get max confidence from all detections
- Check thresholds (CRITICAL → LOW)
- Return matching severity level

_calculate_fraud_indicators(image, detections)
- Check blur score (Laplacian variance)
- Check histogram variance
- Check edge density with Canny
- Check color saturation (HSV)
- Check for excessive detections (>10)
- Check image resolution (min 640x480)
- Return {risk_score, indicators[]}

_generate_comparison_analysis(is_resolved, similarity_score, before_count, after_count)
- Return human-readable analysis string
- Handle cases: resolved, too similar, not resolved

Include:
- Type hints for all methods
- Proper error handling
- Logging for all operations
- Create singleton instance at end
```

### 2. Detection Routes (FastAPI)

**Prompt:**
```
Create FastAPI routes for /api/v1/issues with comprehensive fraud detection:

POST /detect
Parameters:
- image: UploadFile (required)
- latitude: float (required)
- longitude: float (required)
- device_id: str (required)
- timestamp: str (ISO format, required)
- sensor_data: Optional[str] (JSON)

Fraud Prevention Steps:
1. Validate image format (jpg/png/webp), size (<10MB), resolution (>640x480)
2. Check image manipulation using ELA and noise analysis
3. Validate GPS coordinates (range check, Rajasthan bounds, spoofing detection)
4. Check duplicate submissions using MD5 hash + Redis (1 hour window)
5. Check submission rate per device (max 10/hour) with Redis INCR
6. Extract EXIF data (datetime, make, model, GPS)
7. Run YOLOv8 detection
8. Calculate comprehensive fraud score:
   - Base AI fraud score
   - Image manipulation (+0.3)
   - GPS spoofing (+0.4)
   - High submission rate (+0.2)
   - EXIF timestamp mismatch (+0.15)
9. Store submission data in Redis for duplicate detection
10. Return detection results + fraud assessment

Response:
{
  success: bool,
  detection: {...},
  fraud_assessment: {risk_score, risk_level, risk_factors[]},
  gps_validation: {...},
  metadata: {...}
}

POST /verify-completion
Parameters:
- task_id: str
- before_image: UploadFile
- after_image: UploadFile
- latitude: float
- longitude: float

Steps:
1. Validate both images
2. Extract EXIF timestamps from both
3. Verify after timestamp > before timestamp
4. Run compare_images()
5. Check for manipulation in after image
6. Adjust confidence based on flags
7. Generate recommendation (APPROVE/REVIEW/REJECT)

Response:
{
  success: bool,
  task_id: str,
  verification: {...},
  timestamp_verification: {...},
  verification_flags: [],
  recommendation: str
}

Include:
- HTTPException for errors
- Logging for all operations
- Helper functions: _get_risk_level(), _get_verification_recommendation()
```

### 3. Image & GPS Validators

**Prompt:**
```
Create two utility modules:

1. image_validator.py

validate_image(image_bytes, filename)
- Check file extension (jpg/jpeg/png/webp)
- Check size (<10MB)
- Open with PIL.Image
- Verify dimensions (min 640x480)
- Verify image integrity
- Return {valid, width, height, format, size_bytes} or {valid: False, error}

check_image_manipulation(image_bytes)
- Convert to numpy array
- Calculate noise level (Laplacian variance)
- Check histogram variance
- Calculate edge density (Canny)
- Check color saturation (HSV)
- Build indicators[] and manipulation_score
- Return {manipulated, confidence, indicators}

2. gps_validator.py

validate_gps_coordinates(latitude, longitude)
- Validate range: lat (-90, 90), lon (-180, 180)
- Check for (0, 0) - common spoofing
- Check Rajasthan bounds (23.5-30.2 N, 69.5-78.3 E)
- Check for suspiciously precise coordinates (>8 decimals)
- Return {valid, in_rajasthan, possible_spoofing, warnings[], coordinates}

calculate_distance(lat1, lon1, lat2, lon2)
- Use Haversine formula
- Earth radius = 6371 km
- Return distance in km

is_within_geofence(latitude, longitude, center_lat, center_lon, radius_km)
- Calculate distance from center
- Compare with radius
- Return {within_geofence, distance_km, radius_km, distance_from_edge_km}
```

---

## Task Management

**Prompt:**
```
Create TaskService class for Node.js with PostgreSQL + PostGIS:

Methods:

createTask(issueId, workerId, deadline)
- Validate issue exists and is OPEN
- Create task record with status='PENDING'
- Update issue status to 'ASSIGNED'
- Set deadline (default: 48 hours)
- Create geofence around issue location (50m radius)
- Send notification to worker
- Return task object

verifyGeofenceEntry(taskId, latitude, longitude)
- Get task and issue location from database
- Use PostGIS ST_DWithin to check if worker is within 50m
- If yes:
  - Update task: geofence_entered=true, geofence_entry_time=NOW()
  - Update task_status='AT_LOCATION'
  - Return {within_geofence: true, distance_meters}
- Return {within_geofence: false, distance_meters}

verifyTaskCompletion(taskId, beforePhotoUrl, afterPhotoUrl)
- Fetch both images from URLs
- Call detection service POST /api/v1/issues/verify-completion
- Get verification result
- If issue_resolved && verification_confidence > 0.7:
  - Update task: ai_verification_status='VERIFIED', ai_verification_score
  - Update task_status='COMPLETED'
  - Initiate community voting
  - Return {verified: true, confidence, recommendation: 'APPROVE'}
- Else:
  - Update task_status='REJECTED'
  - Return {verified: false, confidence, recommendation: 'REJECT'}

initiateCommunityVoting(taskId)
- Find nearby citizens (within 1km of issue location)
- Use PostGIS: ST_DWithin(location, issue_location, 1000)
- Send notifications to citizens
- Set voting deadline (24 hours)
- Return {voters_notified: count}

calculateWorkerScore(workerId, monthYear)
- Count tasks: total, completed, rejected
- Calculate avg completion time
- Get citizen ratings from community_votes
- Calculate composite score:
  - Completion rate (40%)
  - Speed (30%)
  - Citizen rating (30%)
- Update worker_profiles.performance_score
- Return score (0-100)

Include:
- PostGIS queries with ST_ functions
- Error handling
- Logging
- Database transactions
```

---

## Geofencing

**Prompt:**
```
Create GeofenceService class with PostGIS:

createGeofence(name, polygon, geofenceType)
- Validate GeoJSON polygon format
- Convert to PostGIS GEOGRAPHY
- Calculate center point: ST_Centroid()
- Insert into geofences table
- Return geofence object

checkPointInGeofence(latitude, longitude, geofenceId)
- Create POINT from lat/lon
- Query: SELECT ST_Contains(geometry, ST_GeogFromText('POINT(lon lat)'))
- Return {within_geofence: bool, geofence_name, distance_from_center_m}

getGeofencesNear(latitude, longitude, radiusMeters)
- Create POINT from lat/lon
- Query: SELECT * FROM geofences WHERE ST_DWithin(geometry, point, radius)
- Return array of geofences

monitorGeofenceBreach(taskId, latitude, longitude)
- Get task's assigned geofence
- Check if point is outside geofence
- If breach detected:
  - Log location violation
  - Send alert notification
  - Update task with breach flag
  - Return {breach: true, distance_outside_m}

Use PostGIS functions:
- ST_GeogFromText() - create geography from WKT
- ST_Contains() - check if point in polygon
- ST_DWithin() - check distance
- ST_Centroid() - calculate center
- ST_Distance() - get distance
```

---

## RTI & Escalation

**Prompt:**
```
Create RTIService class with OpenAI GPT-4 and Twitter API:

generateRTIDraft(complaintId, authorityName)
- Fetch issue details from database
- Construct prompt for GPT-4:
  "Generate a formal RTI (Right to Information) request in English for:
   - Issue: [issue_type]
   - Location: [address]
   - Reported on: [date]
   - Status: Unresolved for [days] days
   
   Address it to [authorityName].
   Include:
   1. Formal greeting
   2. Issue description
   3. Questions about action taken
   4. Request for timeline
   5. Cite RTI Act 2005
   6. Formal closing"
- Call OpenAI API with GPT-4
- Store draft in rti_requests table
- Return RTI text

fileRTI(rtiId)
- Get RTI draft
- Mark as 'FILED'
- Set filed_at timestamp
- Calculate response_deadline (30 days)
- Send email to authority
- Return success

escalateOnSocialMedia(complaintId, platform='TWITTER')
- Fetch issue details
- Generate tweet text:
  "🚨 UNRESOLVED CIVIC ISSUE
   
   📍 [location]
   🏷️ [issue_type]
   ⏰ Pending for [days] days
   
   @[authority_handle] please take action!
   
   #SAAFSURKSHA #[city] #CivicIssue #Rajasthan"
- Upload before image
- Post via Twitter API
- Store post_id and post_url
- Return {success: true, post_url}

monitorSLA(complaintId)
- Get issue with deadline
- Check if deadline passed
- If yes and status != 'RESOLVED':
  - Increment escalation_level
  - If level === 1: File RTI
  - If level === 2: Post on Twitter
  - If level === 3: Legal notice
  - Update issue
- Return {escalation_needed: bool, level}

escalateComplaint(complaintId, level)
- Validate escalation level (1-3)
- Execute appropriate action:
  - Level 1: generateRTIDraft() + fileRTI()
  - Level 2: escalateOnSocialMedia()
  - Level 3: Generate legal notice
- Update issue.escalation_level
- Log escalation
- Return success

Include:
- OpenAI API integration with error handling
- Twitter API v2 integration
- Email sending (nodemailer)
- Proper authentication
- Rate limiting
```

---

## Analytics & Heatmaps

**Prompt:**
```
Create AnalyticsService class with PostGIS heatmaps:

generateHeatmap(issueType, regionBounds)
Parameters:
- issueType: 'POTHOLE' | 'WASTE_ACCUMULATION' | etc.
- regionBounds: {minLat, maxLat, minLon, maxLon}

Steps:
1. Create grid using ST_MakeEnvelope and ST_SquareGrid
2. Query to count issues per grid cell:
   SELECT 
     grid.geom,
     COUNT(i.id) as issue_count,
     ST_X(ST_Centroid(grid.geom)) as lon,
     ST_Y(ST_Centroid(grid.geom)) as lat
   FROM grid_cells grid
   LEFT JOIN issues i ON ST_Within(i.location, grid.geom)
   WHERE i.issue_type = $1
   GROUP BY grid.geom
3. Convert to GeoJSON FeatureCollection
4. Return heatmap data

generateCivicHealthScore(regionName)
Steps:
1. Count total issues in region (last 30 days)
2. Count resolved issues
3. Calculate resolution_rate = resolved/total
4. Calculate avg_resolution_time in hours
5. Get severity distribution
6. Calculate score (0-100):
   - Resolution rate: 40%
   - Resolution speed: 30%
   - Low severity ratio: 30%
7. Store in civic_health_metrics table
8. Return {score, metrics}

provisionAPIData(customerId, dataType, params)
Validate customer:
- Check api_key is active
- Check rate limit (Redis)
- Check allowed_data_types

Data types:
- HEATMAP: Call generateHeatmap(), return GeoJSON
- CIVIC_HEALTH: Call generateCivicHealthScore(), return metrics
- RISK_ASSESSMENT: Calculate insurance risk score by area
  - High issue density = high risk
  - Return risk score (0-1) per region

Log to api_usage_logs

getTrends(regionName, period='30d')
- Query issues grouped by date
- Calculate daily counts
- Detect trends (increasing/decreasing)
- Return time series data

Include:
- PostGIS spatial queries
- GeoJSON formatting
- Redis for rate limiting
- Caching for expensive queries
```

---

## Testing

### Unit Tests

**Prompt:**
```
Generate Jest unit tests for AuthService:

File: auth.service.test.js

Setup:
- Mock PostgreSQL pool
- Mock Redis client
- Mock Twilio client
- Use jest.fn() for all dependencies

Tests:

describe('AuthService', () => {
  describe('registerUser', () => {
    test('should register new user successfully', async () => {
      // Mock: no existing user
      // Mock: successful DB insert
      // Mock: sendOTP success
      // Mock: generateTokens success
      // Assert: user object returned
      // Assert: tokens present
    })
    
    test('should throw error if user exists', async () => {
      // Mock: existing user found
      // Assert: throws "User already exists"
    })
    
    test('should rollback transaction on error', async () => {
      // Mock: DB insert fails
      // Assert: ROLLBACK called
    })
  })
  
  describe('login', () => {
    test('should login with valid credentials', async () => {
      // Mock: user found
      // Mock: password match
      // Mock: user is verified
      // Assert: tokens returned
    })
    
    test('should return requires2FA if enabled', async () => {
      // Mock: user with 2FA enabled
      // Assert: {requires2FA: true, tempToken}
    })
    
    test('should throw error for invalid password', async () => {
      // Mock: password mismatch
      // Assert: throws "Invalid credentials"
    })
  })
  
  describe('verifyOTP', () => {
    test('should verify valid OTP', async () => {
      // Mock: OTP found in Redis
      // Mock: OTP matches
      // Mock: DB update success
      // Assert: returns true
      // Assert: Redis DEL called
    })
    
    test('should throw error for expired OTP', async () => {
      // Mock: OTP not found in Redis
      // Assert: throws "OTP expired"
    })
  })
})

Include:
- beforeEach: reset mocks
- afterEach: clear mocks
- Use expect() assertions
- Test both success and error cases
```

### Integration Tests

**Prompt:**
```
Generate Mocha + Supertest integration tests for auth routes:

File: auth.routes.test.js

Setup:
- Start test database (separate from production)
- Start Redis test instance
- Create test app instance
- Use supertest for HTTP requests

describe('POST /api/v1/auth/register', () => {
  it('should register new user with 201', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: '+919876543210',
        email: 'test@example.com',
        fullName: 'Test User',
        password: 'TestPass@123',
        role: 'CITIZEN'
      })
    
    expect(res.status).to.equal(201)
    expect(res.body.success).to.be.true
    expect(res.body.data).to.have.property('accessToken')
  })
  
  it('should return 400 for invalid email', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...validUser, email: 'invalid' })
    
    expect(res.status).to.equal(400)
  })
})

describe('POST /api/v1/auth/login', () => {
  it('should login successfully with 200', async () => {
    // Register user first
    // Then login
    // Assert tokens returned
  })
  
  it('should rate limit after 5 attempts', async () => {
    // Make 6 login attempts
    // Assert 6th returns 429
  })
})

Include:
- before: setup database
- after: teardown database
- beforeEach: clear test data
- Test success and error cases
- Test rate limiting
- Test validation
```

---

## Optimization

### Database Optimization

**Prompt:**
```
Analyze this slow query and optimize it:

SELECT i.*, u.full_name, w.performance_score
FROM issues i
LEFT JOIN users u ON i.reported_by = u.id
LEFT JOIN tasks t ON t.issue_id = i.id
LEFT JOIN worker_profiles w ON t.assigned_to = w.user_id
WHERE i.status = 'OPEN'
AND ST_DWithin(i.location, ST_GeogFromText('POINT(75.7873 26.9124)'), 5000)
ORDER BY i.reported_at DESC
LIMIT 20;

Provide:
1. Explain the current performance issues
2. Suggest indexes to create
3. Rewrite query for better performance
4. Add query hints if needed
5. Estimate performance improvement
```

### Caching Strategy

**Prompt:**
```
Design a Redis caching strategy for analytics endpoints:

Endpoints:
- GET /api/v1/analytics/heatmap (expensive PostGIS query)
- GET /api/v1/analytics/civic-health (aggregation query)
- GET /api/v1/analytics/trends (time-series data)

Requirements:
- Cache for 15 minutes
- Invalidate on new issue submission
- Support regional filtering
- Handle cache stampede

Provide:
1. Cache key naming strategy
2. TTL for each endpoint
3. Invalidation logic
4. Stampede prevention (lock mechanism)
5. Code implementation
```

---

## Troubleshooting

### Debugging with Copilot

**Prompt:**
```
I'm getting this error when calling the detection endpoint:

Error: ECONNREFUSED 127.0.0.1:6379
    at TCPConnectWrap.afterConnect [as oncomplete] (net.js:1148:16)

Context:
- Detection service trying to connect to Redis
- Docker Compose environment
- Redis container is running (docker ps shows it)

Debug steps:
1. What's causing this error?
2. How do I fix the connection?
3. What should I check in my configuration?
4. Provide corrected code
```

### Performance Profiling

**Prompt:**
```
This endpoint is taking 5-8 seconds to respond:

POST /api/v1/issues/detect

Current flow:
1. Validate image (200ms)
2. Check duplicate in Redis (50ms)
3. Run YOLOv8 detection (4-6 seconds) ← SLOW
4. Calculate fraud score (100ms)
5. Store in database (150ms)

Questions:
1. How can I speed up YOLOv8 inference?
2. Should I use GPU? How to enable in Docker?
3. Can I process images async?
4. Should I resize images before detection?
5. Provide optimized code

Target: <2 seconds total
```

---

## Advanced Techniques

### Multi-file Generation

**Prompt:**
```
Generate complete task-service with all files in one response:

Output format: Provide 5 code blocks, I'll create files manually.

1. package.json
2. src/index.js - Express server
3. src/services/task.service.js - TaskService class (full implementation)
4. src/routes/task.routes.js - All REST endpoints
5. src/middleware/auth.middleware.js - JWT verification

Requirements documented in [paste requirements]
```

### Code Review

**Prompt:**
```
Review this authentication code for security issues:

[PASTE CODE]

Check for:
1. SQL injection vulnerabilities
2. JWT implementation flaws
3. Password storage weaknesses
4. Session management issues
5. Rate limiting gaps
6. CORS misconfigurations
7. Input validation problems

For each issue:
- Severity (Critical/High/Medium/Low)
- Explanation
- Fix recommendation
- Updated code
```

---

## Pro Tips

### 1. Be Specific
❌ Bad: "Write auth service"
✅ Good: "Write AuthService class with these exact methods: [list], using bcrypt for passwords, JWT for tokens, Redis for sessions, PostgreSQL for storage"

### 2. Include Context
Always mention:
- Technology stack
- Dependencies
- Integration points
- Error handling requirements
- Security requirements

### 3. Iterate
1. Generate basic structure
2. Ask for improvements: "Add error handling"
3. Ask for optimization: "Make this more efficient"
4. Ask for tests: "Generate unit tests"

### 4. Use Examples
"Generate code like this example: [paste similar code], but for [your use case]"

### 5. Request Explanations
"Explain this code line-by-line, including why each design decision was made"

---

## Time Savings

| Task | Without Copilot | With Copilot | Savings |
|------|----------------|--------------|---------|
| Auth Service | 8 hours | 2 hours | 75% |
| YOLOv8 Integration | 12 hours | 3 hours | 75% |
| PostGIS Queries | 6 hours | 1 hour | 83% |
| Unit Tests | 10 hours | 2 hours | 80% |
| Documentation | 4 hours | 30 min | 87% |
| **Total Project** | **120 hours** | **30 hours** | **75%** |

---

## Conclusion

GitHub Copilot Pro accelerates development significantly when used correctly:

✅ Use detailed prompts with context
✅ Iterate on generated code
✅ Request explanations for learning
✅ Generate tests alongside code
✅ Use for boilerplate and patterns

❌ Don't blindly accept all suggestions
❌ Don't skip security reviews
❌ Don't ignore best practices
❌ Don't forget to test generated code

**Happy Coding with Copilot! 🚀**
