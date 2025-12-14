# 🚀 SAAF SURKSHA - Quick Start Guide

> Complete Docker-based setup for local development with GitHub Copilot Pro

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (5 minutes)](#quick-start)
3. [Manual Setup](#manual-setup)
4. [Service Architecture](#service-architecture)
5. [API Testing](#api-testing)
6. [Troubleshooting](#troubleshooting)
7. [Development Workflow](#development-workflow)

---

## ✅ Prerequisites

### Required Software

| Software | Version | Download Link |
|----------|---------|---------------|
| Docker Desktop | 20.x+ | https://www.docker.com/products/docker-desktop |
| Docker Compose | 2.x+ | Included with Docker Desktop |
| Git | 2.x+ | https://git-scm.com/downloads |

### Optional (for local development)

| Software | Version | Purpose |
|----------|---------|---------|
| Node.js | 18+ | Backend service development |
| Python | 3.11+ | Detection service development |
| VS Code | Latest | IDE with GitHub Copilot |
| Postman | Latest | API testing |

### System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space
- **GPU**: NVIDIA GPU (optional, for faster YOLOv8 detection)

---

## ⚡ Quick Start

### Option 1: Automated Setup (Recommended)

```powershell
# Clone the repository
git clone https://github.com/reboot-rajasthan/saaf-surksha.git
cd saaf-surksha

# Run the automated setup script
.\quick-start.ps1
```

The script will:
- ✅ Check prerequisites
- ✅ Create .env file
- ✅ Build Docker images
- ✅ Start all services
- ✅ Initialize database
- ✅ Verify service health

**Total time: 5-7 minutes**

### Option 2: One-Command Setup

```bash
# Copy environment file
cp .env.example .env

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

## 🔧 Manual Setup

### Step 1: Environment Configuration

```bash
# Create environment file
cp .env.example .env

# Edit .env with your API keys
# Required keys:
#   - JWT_SECRET (generate with: openssl rand -hex 32)
#   - TWILIO_* (for OTP functionality)
#   - OPENAI_API_KEY (for RTI generation)
```

### Step 2: Build Images

```bash
# Build all service images
docker-compose build

# Build specific service
docker-compose build auth-service
```

### Step 3: Start Infrastructure

```bash
# Start databases first
docker-compose up -d postgres redis rabbitmq

# Wait for health checks (30 seconds)
docker-compose ps
```

### Step 4: Start Application Services

```bash
# Start core services
docker-compose up -d auth-service detection-service

# Start remaining services
docker-compose up -d task-service geofence-service rti-service analytics-service

# Start API Gateway
docker-compose up -d kong-database kong-migration kong
```

### Step 5: Verify Installation

```bash
# Check all containers
docker-compose ps

# Check specific service logs
docker-compose logs auth-service

# Test health endpoints
curl http://localhost:3001/health
curl http://localhost:3002/health
```

---

## 🏗️ Service Architecture

### Container Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway (Kong)                        │
│                  http://localhost:8000                       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Auth Service │    │  Detection   │    │ Task Service │
│   :3001      │    │   Service    │    │    :3003     │
│              │    │    :3002     │    │              │
│ JWT + 2FA    │    │   YOLOv8     │    │  Geofencing  │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  PostgreSQL  │    │    Redis     │    │  RabbitMQ    │
│    +PostGIS  │    │              │    │              │
│    :5432     │    │    :6379     │    │    :5672     │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Service Ports

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Auth Service | 3001 | HTTP | User authentication, JWT, 2FA |
| Detection Service | 3002 | HTTP | YOLOv8 AI detection, fraud analysis |
| Task Service | 3003 | HTTP | Task management, verification |
| Geofence Service | 3004 | HTTP | Location tracking, geofencing |
| RTI Service | 3005 | HTTP | RTI generation, escalation |
| Analytics Service | 3006 | HTTP | Heatmaps, metrics, B2B APIs |
| Kong Gateway | 8000 | HTTP | API routing & rate limiting |
| Kong Admin | 8001 | HTTP | Gateway configuration |
| PostgreSQL | 5432 | TCP | Main database with PostGIS |
| Redis | 6379 | TCP | Cache & session storage |
| RabbitMQ | 5672 | AMQP | Message queue |
| RabbitMQ Management | 15672 | HTTP | Queue dashboard |

---

## 🧪 API Testing

### 1. User Registration

```powershell
# PowerShell
Invoke-RestMethod -Uri http://localhost:3001/api/v1/auth/register `
  -Method Post `
  -ContentType 'application/json' `
  -Body (@{
    phoneNumber = '+919876543210'
    email = 'test@example.com'
    fullName = 'Test User'
    password = 'Test@1234'
    role = 'CITIZEN'
  } | ConvertTo-Json)
```

```bash
# Bash/cURL
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210",
    "email": "test@example.com",
    "fullName": "Test User",
    "password": "Test@1234",
    "role": "CITIZEN"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210",
    "password": "Test@1234"
  }'
```

### 3. Image Detection

```bash
curl -X POST http://localhost:3002/api/v1/detect \
  -F "image=@pothole.jpg" \
  -F "gps_lat=26.9124" \
  -F "gps_lon=75.7873" \
  -F "gps_accuracy=5.0" \
  -F "phone_model=Samsung Galaxy S21" \
  -F "timestamp=2024-12-14T10:30:00Z" \
  -F "device_id=device-123"
```

---

## 🔍 Troubleshooting

### Container Issues

```bash
# Check container status
docker-compose ps

# View logs for specific service
docker-compose logs -f auth-service

# Restart a service
docker-compose restart detection-service

# Rebuild and restart
docker-compose up -d --build auth-service
```

### Database Issues

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d saaf_surksha

# Check PostGIS extension
docker-compose exec postgres psql -U postgres -d saaf_surksha -c "SELECT PostGIS_version();"

# Run migrations manually
docker-compose exec postgres psql -U postgres -d saaf_surksha -f /docker-entrypoint-initdb.d/001_initial_schema.sql
```

### Redis Issues

```bash
# Connect to Redis CLI
docker-compose exec redis redis-cli

# Test connection
docker-compose exec redis redis-cli ping

# Check keys
docker-compose exec redis redis-cli KEYS '*'
```

### Common Error Solutions

| Error | Solution |
|-------|----------|
| Port already in use | `docker-compose down` then change port in docker-compose.yml |
| Out of memory | Increase Docker Desktop memory to 4GB+ |
| Container won't start | Check logs: `docker-compose logs <service-name>` |
| Health check failing | Wait 60 seconds, services need time to initialize |
| Permission denied | Run as administrator or check file permissions |

### Reset Everything

```bash
# Stop and remove all containers, volumes, networks
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Start fresh
docker-compose up -d --build
```

---

## 💻 Development Workflow

### Hot Reload Setup

All services have hot reload enabled by default:

```yaml
# Volumes in docker-compose.yml enable hot reload
volumes:
  - ./backend/auth-service/src:/app/src
  - /app/node_modules
```

### Making Code Changes

1. Edit files in `backend/<service>/src/`
2. Service automatically restarts (Node.js services use nodemon)
3. Check logs: `docker-compose logs -f <service-name>`

### Adding Dependencies

```bash
# For Node.js services
docker-compose exec auth-service npm install <package-name>
docker-compose restart auth-service

# For Python services
docker-compose exec detection-service pip install <package-name>
docker-compose restart detection-service
```

### Running Tests

```bash
# Run tests inside container
docker-compose exec auth-service npm test

# Run with coverage
docker-compose exec auth-service npm run test:coverage
```

---

## 📚 Next Steps

### 1. Implement Remaining Services

Use GitHub Copilot to implement:
- **Task Service**: Task assignment, geofence verification
- **Geofence Service**: Location tracking, boundary monitoring
- **RTI Service**: Automated RTI generation, social escalation
- **Analytics Service**: Heatmap generation, civic health scores

Refer to [COPILOT_GUIDE.md](COPILOT_GUIDE.md) for detailed prompts.

### 2. Configure API Gateway (Kong)

```bash
# Add service to Kong
curl -X POST http://localhost:8001/services \
  -d name=auth-service \
  -d url=http://auth-service:3001

# Add route
curl -X POST http://localhost:8001/services/auth-service/routes \
  -d paths[]=/api/v1/auth
```

### 3. Set Up Monitoring

- **RabbitMQ Dashboard**: http://localhost:15672 (admin/admin123)
- **Kong Admin API**: http://localhost:8001
- **PostgreSQL**: Use pgAdmin or DBeaver

### 4. Deploy to Production

Refer to deployment guides:
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - AWS, GCP, Azure deployment
- [k8s/](k8s/) - Kubernetes manifests
- [ci-cd/](.github/workflows/) - GitHub Actions CI/CD

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Project overview & architecture |
| [COPILOT_GUIDE.md](COPILOT_GUIDE.md) | GitHub Copilot implementation guide |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | Complete API reference |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Directory structure & tech stack |
| [SETUP.md](SETUP.md) | Detailed installation instructions |

---

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/reboot-rajasthan/saaf-surksha/issues)
- **Wiki**: [GitHub Wiki](https://github.com/reboot-rajasthan/saaf-surksha/wiki)
- **Email**: tech@rebootrajasthan.in

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

**Built with ❤️ for REBOOT RAJASTHAN Hackathon**
