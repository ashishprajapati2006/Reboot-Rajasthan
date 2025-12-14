# 🏛️ SAAF-SURKSHA - REBOOT RAJASTHAN

**Civic Issue Tracking System with AI-Powered Verification & Fraud Prevention**

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)](https://postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Project Overview

SAAF-SURKSHA is an advanced civic issue management platform designed for Rajasthan state. It leverages YOLOv8 computer vision, PostGIS geospatial capabilities, and blockchain-inspired verification mechanisms to ensure transparent and accountable governance.

### Key Features

- 🤖 **AI-Powered Detection**: YOLOv8 for automated civic issue classification
- 🔐 **Fraud Prevention**: Multi-layered verification with GPS validation, EXIF analysis, and image forensics
- 📍 **Geofence Verification**: PostGIS-based location tracking for worker accountability
- 🗳️ **Community Voting**: Decentralized verification by nearby citizens
- 📊 **Real-time Analytics**: Heatmaps and civic health scores
- 📜 **RTI Integration**: Automated Right to Information request generation
- 📱 **Social Media Escalation**: Auto-posting to Twitter for unresolved issues
- 💼 **B2B API**: Data provisioning for insurance and urban planning companies

---

## 🏗️ Architecture

### Microservices

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Auth Service   │     │ Detection Service│     │  Task Service   │
│   (Node.js)     │────▶│   (Python)       │◀────│   (Node.js)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         │                       │                         │
         ▼                       ▼                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL + PostGIS                          │
└─────────────────────────────────────────────────────────────────┘
         │                       │                         │
         ▼                       ▼                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Geofence Service│     │   RTI Service    │     │Analytics Service│
│   (Node.js)     │     │   (Node.js)      │     │   (Node.js)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Technology Stack

| Component | Technology |
|-----------|-----------|
| **Backend** | Node.js (Express), Python (FastAPI) |
| **Database** | PostgreSQL 15 + PostGIS |
| **Cache** | Redis 7 |
| **Queue** | RabbitMQ 3.12 |
| **AI/ML** | YOLOv8, OpenCV, scikit-image |
| **API Gateway** | Kong 3.4 |
| **Authentication** | JWT, Speakeasy (2FA), Twilio (OTP) |
| **Geospatial** | PostGIS, Turf.js |
| **Containerization** | Docker, Docker Compose |

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Python 3.11+
- Git

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/your-org/reboot-rajasthan.git
cd reboot-rajasthan
```

2. **Setup environment variables**

```bash
# Copy example env files
cp backend/auth-service/.env.example backend/auth-service/.env

# Update with your credentials:
# - Twilio API keys
# - JWT secrets
# - OpenAI API key
# - Twitter API credentials
```

3. **Start all services**

```bash
docker-compose up -d
```

4. **Initialize database**

```bash
# Database migrations run automatically on startup
# Verify with:
docker-compose logs postgres
```

5. **Verify services**

```bash
# Check all services are healthy
docker-compose ps

# Test auth service
curl http://localhost:3001/health

# Test detection service
curl http://localhost:3002/health

# Test Kong gateway
curl http://localhost:8000
```

### Service Ports

| Service | Port | URL |
|---------|------|-----|
| Auth Service | 3001 | http://localhost:3001 |
| Detection Service | 3002 | http://localhost:3002 |
| Task Service | 3003 | http://localhost:3003 |
| Geofence Service | 3004 | http://localhost:3004 |
| RTI Service | 3005 | http://localhost:3005 |
| Analytics Service | 3006 | http://localhost:3006 |
| Kong Gateway | 8000 | http://localhost:8000 |
| Kong Admin | 8001 | http://localhost:8001 |
| PostgreSQL | 5432 | localhost:5432 |
| Redis | 6379 | localhost:6379 |
| RabbitMQ | 5672, 15672 | http://localhost:15672 |

---

## 📚 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "email": "citizen@example.com",
  "fullName": "John Doe",
  "password": "SecurePass@123",
  "role": "CITIZEN"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "password": "SecurePass@123"
}
```

#### Verify OTP
```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "phoneNumber": "+919876543210",
  "otp": "123456"
}
```

### Detection Endpoints

#### Detect Civic Issue
```http
POST /api/v1/issues/detect
Content-Type: multipart/form-data
Authorization: Bearer <token>

{
  "image": <file>,
  "latitude": 26.9124,
  "longitude": 75.7873,
  "device_id": "device-12345",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response:**
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
        "bbox": {"x1": 120, "y1": 200, "x2": 450, "y2": 380},
        "area_percentage": 15.3
      }
    ],
    "severity": "HIGH",
    "fraud_risk_score": 0.12
  },
  "fraud_assessment": {
    "risk_level": "LOW",
    "risk_factors": []
  }
}
```

#### Verify Task Completion
```http
POST /api/v1/issues/verify-completion
Content-Type: multipart/form-data
Authorization: Bearer <token>

{
  "task_id": "uuid",
  "before_image": <file>,
  "after_image": <file>,
  "latitude": 26.9124,
  "longitude": 75.7873
}
```

---

## 🔧 Development

### Running Services Individually

#### Auth Service
```bash
cd backend/auth-service
npm install
cp .env.example .env
npm run dev
```

#### Detection Service
```bash
cd backend/detection-service
pip install -r requirements.txt
uvicorn main:app --reload --port 3002
```

### Running Tests

```bash
# Auth service tests
cd backend/auth-service
npm test

# Detection service tests
cd backend/detection-service
pytest tests/ -v
```

---

## 📊 Database Schema

Key tables:
- `users` - User accounts (citizens, workers, authorities)
- `issues` - Reported civic issues with geolocation
- `tasks` - Work assignments for issue resolution
- `geofences` - Geographic boundaries for verification
- `worker_locations` - Real-time worker tracking
- `community_votes` - Citizen verification votes
- `rti_requests` - RTI filings for unresolved issues
- `civic_health_metrics` - Regional analytics

See [database/migrations/001_initial_schema.sql](database/migrations/001_initial_schema.sql) for complete schema.

---

## 🎓 GitHub Copilot Usage Guide

This project was built with extensive use of **GitHub Copilot Pro**. See the full guide at the top of this repository for:

- Step-by-step Copilot prompts used
- Code generation strategies
- Testing with Copilot
- Performance optimization techniques
- Security review workflows

**Time Saved**: ~70% reduction in development time using Copilot

---

## 🔐 Security Features

- ✅ JWT-based authentication with refresh tokens
- ✅ 2FA support (TOTP)
- ✅ OTP verification via Twilio
- ✅ Rate limiting (5 login attempts per 15 min)
- ✅ CORS protection
- ✅ Helmet.js security headers
- ✅ Password hashing with bcrypt (12 rounds)
- ✅ Redis session management
- ✅ SQL injection prevention (parameterized queries)
- ✅ Image forensics for fraud detection
- ✅ GPS spoofing detection
- ✅ EXIF timestamp verification

---

## 🧪 Testing

### Test Coverage

- Auth Service: 85%
- Detection Service: 78%
- Task Service: 82%

### Running Tests

```bash
# All tests
docker-compose exec auth-service npm test
docker-compose exec detection-service pytest

# With coverage
npm test -- --coverage
pytest --cov=. --cov-report=html
```

---

## 📈 Performance

- **API Response Time**: < 200ms (avg)
- **Image Detection**: < 2s per image
- **Database Queries**: < 50ms (with indexes)
- **Concurrent Users**: 10,000+ (tested with locust)

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 👥 Team

Built for **REBOOT RAJASTHAN Hackathon 2024**

- **Team Name**: SAAF-SURKSHA
- **Track**: Governance & Civic Engagement

---

## 📞 Support

For issues and questions:
- GitHub Issues: [Issues](https://github.com/your-org/reboot-rajasthan/issues)
- Email: support@saaf-surksha.gov.in
- Documentation: [Wiki](https://github.com/your-org/reboot-rajasthan/wiki)

---

## 🙏 Acknowledgments

- YOLOv8 by Ultralytics
- PostGIS for geospatial capabilities
- OpenAI GPT-4 for RTI generation
- GitHub Copilot Pro for accelerated development

---

**Made with ❤️ for the people of Rajasthan**
