# SAAF-SURKSHA Setup Instructions

## Step 1: Prerequisites

Install the following on your system:

1. **Docker Desktop** (includes Docker Compose)
   - Windows: https://docs.docker.com/desktop/install/windows-install/
   - Download and install Docker Desktop
   - Enable WSL 2 backend if prompted

2. **Node.js 18+**
   - Download from: https://nodejs.org/
   - Verify: `node --version`

3. **Python 3.11+**
   - Download from: https://www.python.org/downloads/
   - Verify: `python --version`

4. **Git**
   - Download from: https://git-scm.com/downloads
   - Verify: `git --version`

## Step 2: Clone and Setup

```powershell
# Navigate to project directory
cd "c:\Users\ashis\Desktop\New folder (2)\reboot-rajasthan"

# Copy environment variables
Copy-Item backend\auth-service\.env.example backend\auth-service\.env

# Edit .env file and add your API keys
notepad backend\auth-service\.env
```

### Required API Keys

You'll need to sign up for these services and add keys to `.env`:

1. **Twilio** (for OTP):
   - Sign up: https://www.twilio.com/try-twilio
   - Get: Account SID, Auth Token, Phone Number

2. **OpenAI** (for RTI generation):
   - Sign up: https://platform.openai.com/signup
   - Get: API Key

3. **Twitter API** (for social escalation):
   - Sign up: https://developer.twitter.com/
   - Get: API Key, API Secret, Access Token, Access Secret

## Step 3: Start Services

```powershell
# Start all services with Docker Compose
docker-compose up -d

# This will start:
# - PostgreSQL database
# - Redis cache
# - RabbitMQ message queue
# - All 6 microservices
# - Kong API Gateway

# Wait 2-3 minutes for all services to start
```

## Step 4: Verify Installation

```powershell
# Check if all containers are running
docker-compose ps

# Should show all services as "Up" and "healthy"

# Test individual services
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Detection Service
curl http://localhost:3003/health  # Task Service
```

## Step 5: Access Services

- **API Documentation**: http://localhost:3002/api/docs
- **RabbitMQ Management**: http://localhost:15672 (admin/admin123)
- **Kong Admin API**: http://localhost:8001

## Step 6: Test Registration

```powershell
# Register a test user
curl -X POST http://localhost:3001/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "phoneNumber": "+919876543210",
    "email": "test@example.com",
    "fullName": "Test User",
    "password": "TestPass@123",
    "role": "CITIZEN"
  }'
```

## Troubleshooting

### Port Already in Use
```powershell
# Check which process is using the port
netstat -ano | findstr :3001

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Docker Not Starting
```powershell
# Restart Docker Desktop
# Or rebuild containers
docker-compose down
docker-compose up -d --build
```

### Database Connection Errors
```powershell
# Check PostgreSQL logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### View Logs
```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f auth-service
docker-compose logs -f detection-service
```

## Development Mode

To run services in development mode with hot reload:

```powershell
# Auth Service
cd backend\auth-service
npm install
npm run dev

# Detection Service
cd backend\detection-service
pip install -r requirements.txt
uvicorn main:app --reload
```

## Stopping Services

```powershell
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Next Steps

1. Open VS Code in project folder
2. Use GitHub Copilot to extend functionality
3. Follow the main guide for detailed feature implementation
4. Test endpoints with Postman or curl

## Need Help?

- Check logs: `docker-compose logs -f`
- Verify environment variables in `.env`
- Ensure all ports are free (3001-3006, 5432, 6379, 5672, 8000-8001)
- Restart services: `docker-compose restart`

## Database Access

```powershell
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d saaf_surksha

# Run queries
SELECT * FROM users;
SELECT * FROM issues;
\dt  # List all tables
\q   # Quit
```

## Redis Access

```powershell
# Connect to Redis
docker-compose exec redis redis-cli

# Test commands
KEYS *
GET otp:+919876543210
QUIT
```

---

**You're all set! Start building with SAAF-SURKSHA! 🚀**
