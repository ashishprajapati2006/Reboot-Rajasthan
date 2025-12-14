# SAAF-SURKSHA - Project Structure

```
reboot-rajasthan/
├── backend/
│   ├── auth-service/
│   │   ├── src/
│   │   │   ├── config/
│   │   │   │   ├── database.js          # PostgreSQL pool
│   │   │   │   ├── redis.js             # Redis client
│   │   │   │   └── twilio.js            # Twilio client
│   │   │   ├── controllers/             # Request handlers
│   │   │   ├── middleware/
│   │   │   │   └── auth.middleware.js   # JWT verification
│   │   │   ├── models/                  # Database models
│   │   │   ├── routes/
│   │   │   │   └── auth.routes.js       # Auth endpoints
│   │   │   ├── services/
│   │   │   │   └── auth.service.js      # Auth business logic
│   │   │   ├── utils/
│   │   │   │   └── logger.js            # Winston logger
│   │   │   └── index.js                 # Express server
│   │   ├── tests/                       # Jest tests
│   │   ├── .env.example                 # Environment template
│   │   ├── Dockerfile                   # Container config
│   │   └── package.json                 # Dependencies
│   │
│   ├── detection-service/
│   │   ├── models/
│   │   │   └── yolo_detector.py         # YOLOv8 detector
│   │   ├── routes/
│   │   │   └── detection.py             # FastAPI routes
│   │   ├── utils/
│   │   │   ├── image_validator.py       # Image validation
│   │   │   └── gps_validator.py         # GPS validation
│   │   ├── tests/                       # Pytest tests
│   │   ├── main.py                      # FastAPI app
│   │   ├── requirements.txt             # Python deps
│   │   └── Dockerfile                   # Container config
│   │
│   ├── task-service/                    # [To be implemented]
│   ├── geofence-service/                # [To be implemented]
│   ├── rti-service/                     # [To be implemented]
│   ├── analytics-service/               # [To be implemented]
│   └── gateway/                         # Kong config
│
├── database/
│   ├── migrations/
│   │   └── 001_initial_schema.sql       # Complete DB schema
│   └── seeds/                           # Sample data
│
├── docs/                                # Additional documentation
├── scripts/                             # Utility scripts
│
├── docker-compose.yml                   # All services
├── package.json                         # Root workspace config
├── .gitignore                           # Git ignore rules
├── README.md                            # Main documentation
├── SETUP.md                             # Setup instructions
├── COPILOT_GUIDE.md                     # Copilot usage guide
└── setup.ps1                            # Quick start script
```

## Services Overview

### 1. Auth Service (Node.js + Express)
**Port:** 3001
**Features:**
- User registration & login
- JWT authentication
- OTP verification (Twilio)
- 2FA with TOTP
- Refresh token management
- Password hashing (bcrypt)

### 2. Detection Service (Python + FastAPI)
**Port:** 3002
**Features:**
- YOLOv8 civic issue detection
- Image validation & forensics
- GPS validation & spoofing detection
- Before/after comparison
- Fraud risk assessment
- EXIF data extraction

### 3. Task Service (Node.js + Express)
**Port:** 3003
**Features:**
- Task creation & assignment
- Geofence verification
- Completion verification
- Community voting
- Worker scoring

### 4. Geofence Service (Node.js + Express)
**Port:** 3004
**Features:**
- PostGIS spatial queries
- Geofence creation & management
- Location tracking
- Breach detection

### 5. RTI Service (Node.js + Express)
**Port:** 3005
**Features:**
- RTI draft generation (GPT-4)
- Social media escalation
- SLA monitoring
- Auto-escalation

### 6. Analytics Service (Node.js + Express)
**Port:** 3006
**Features:**
- Heatmap generation
- Civic health scores
- B2B API provisioning
- Trend analysis

## Infrastructure

### PostgreSQL 15 + PostGIS
**Port:** 5432
- Geospatial database
- Complete schema with triggers
- Spatial indexes
- Sample data

### Redis 7
**Port:** 6379
- Session management
- OTP storage
- Rate limiting
- Caching

### RabbitMQ 3.12
**Ports:** 5672, 15672
- Message queue
- Task notifications
- Event processing

### Kong API Gateway
**Ports:** 8000, 8001
- API gateway
- Rate limiting
- Authentication
- Load balancing

## Technology Stack

**Backend:**
- Node.js 18 (Express)
- Python 3.11 (FastAPI)

**Database:**
- PostgreSQL 15
- PostGIS extension
- Redis 7

**AI/ML:**
- YOLOv8 (Ultralytics)
- OpenCV
- scikit-image

**Authentication:**
- JWT
- Speakeasy (2FA)
- Twilio (OTP)

**APIs:**
- OpenAI GPT-4
- Twitter API
- Twilio API

**Infrastructure:**
- Docker
- Docker Compose
- Kong Gateway

## Development Status

✅ **Completed:**
- Project structure
- Auth service (complete)
- Detection service (complete)
- Database schema
- Docker configuration
- Documentation

🚧 **In Progress:**
- Task service
- Geofence service
- RTI service
- Analytics service

📋 **Planned:**
- Frontend (React/Next.js)
- Mobile app (React Native)
- Admin dashboard
- CI/CD pipeline

## Quick Commands

```powershell
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down

# Rebuild
docker-compose up -d --build

# Run tests
npm test

# Check health
curl http://localhost:3001/health
```

## Documentation Files

1. **README.md** - Main project overview
2. **SETUP.md** - Detailed setup instructions
3. **COPILOT_GUIDE.md** - GitHub Copilot usage guide
4. **PROJECT_STRUCTURE.md** - This file

## Next Steps

1. Run `setup.ps1` to start services
2. Edit `.env` files with API keys
3. Test endpoints with curl/Postman
4. Implement remaining services
5. Add frontend application
6. Deploy to production

---

**Built with GitHub Copilot Pro** 🤖
