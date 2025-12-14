# ================================
# SAAF SURKSHA - Quick Start Script
# ================================
# This script automates the complete setup process
# Author: REBOOT RAJASTHAN Team
# Date: December 2025
# ================================

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) {
    Write-ColorOutput Green "✓ $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "ℹ $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "⚠ $message"
}

function Write-Error-Custom($message) {
    Write-ColorOutput Red "✗ $message"
}

function Write-Header($message) {
    Write-Host ""
    Write-ColorOutput Magenta "========================================="
    Write-ColorOutput Magenta " $message"
    Write-ColorOutput Magenta "========================================="
    Write-Host ""
}

# ================================
# Step 1: Check Prerequisites
# ================================
Write-Header "Checking Prerequisites"

# Check Docker
Write-Info "Checking Docker installation..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker found: $dockerVersion"
} catch {
    Write-Error-Custom "Docker is not installed!"
    Write-Info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check Docker Compose
Write-Info "Checking Docker Compose..."
try {
    $composeVersion = docker-compose --version
    Write-Success "Docker Compose found: $composeVersion"
} catch {
    Write-Error-Custom "Docker Compose is not installed!"
    exit 1
}

# Check if Docker is running
Write-Info "Checking if Docker daemon is running..."
try {
    docker info | Out-Null
    Write-Success "Docker daemon is running"
} catch {
    Write-Error-Custom "Docker daemon is not running!"
    Write-Info "Please start Docker Desktop and try again"
    exit 1
}

# Check Node.js (optional but recommended for local development)
Write-Info "Checking Node.js installation..."
try {
    $nodeVersion = node --version
    Write-Success "Node.js found: $nodeVersion"
} catch {
    Write-Warning "Node.js not found (optional for containerized setup)"
}

# Check Python (optional)
Write-Info "Checking Python installation..."
try {
    $pythonVersion = python --version
    Write-Success "Python found: $pythonVersion"
} catch {
    Write-Warning "Python not found (optional for containerized setup)"
}

# ================================
# Step 2: Environment Setup
# ================================
Write-Header "Environment Configuration"

# Check if .env exists
if (Test-Path ".env") {
    Write-Warning ".env file already exists"
    $response = Read-Host "Do you want to overwrite it? (y/n)"
    if ($response -eq "y") {
        Copy-Item ".env.example" ".env" -Force
        Write-Success ".env file created from template"
    } else {
        Write-Info "Using existing .env file"
    }
} else {
    Copy-Item ".env.example" ".env"
    Write-Success ".env file created from template"
}

Write-Info "Please update the .env file with your API keys:"
Write-Host "  - TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN (for OTP)"
Write-Host "  - OPENAI_API_KEY (for RTI generation)"
Write-Host "  - TWITTER_API_* (for social escalation)"
Write-Host "  - AWS credentials (for file storage)"
Write-Host ""
$continueSetup = Read-Host "Have you configured the .env file? (y/n)"

if ($continueSetup -ne "y") {
    Write-Warning "Setup paused. Please configure .env and run this script again"
    exit 0
}

# ================================
# Step 3: Clean Previous Containers
# ================================
Write-Header "Cleaning Previous Setup"

Write-Info "Stopping existing containers..."
docker-compose down -v 2>&1 | Out-Null
Write-Success "Cleaned up existing containers"

# ================================
# Step 4: Build and Start Services
# ================================
Write-Header "Building Docker Images"

Write-Info "Building all service images (this may take 5-10 minutes)..."
docker-compose build --no-cache

Write-Success "All images built successfully"

# ================================
# Step 5: Start Services
# ================================
Write-Header "Starting All Services"

Write-Info "Starting database services first..."
docker-compose up -d postgres redis rabbitmq

Write-Info "Waiting for databases to be ready (30 seconds)..."
Start-Sleep -Seconds 30

Write-Info "Starting application services..."
docker-compose up -d auth-service detection-service

Write-Info "Starting remaining services..."
docker-compose up -d task-service geofence-service rti-service analytics-service

Write-Info "Starting API Gateway (Kong)..."
docker-compose up -d kong-database
Start-Sleep -Seconds 10
docker-compose up -d kong-migration
Start-Sleep -Seconds 5
docker-compose up -d kong

Write-Success "All services started!"

# ================================
# Step 6: Wait for Services to be Healthy
# ================================
Write-Header "Verifying Service Health"

Write-Info "Waiting for services to be healthy (60 seconds)..."
Start-Sleep -Seconds 60

# Check PostgreSQL
Write-Info "Checking PostgreSQL..."
try {
    docker-compose exec -T postgres pg_isready -U postgres | Out-Null
    Write-Success "PostgreSQL is healthy"
} catch {
    Write-Warning "PostgreSQL health check failed"
}

# Check Redis
Write-Info "Checking Redis..."
try {
    docker-compose exec -T redis redis-cli ping | Out-Null
    Write-Success "Redis is healthy"
} catch {
    Write-Warning "Redis health check failed"
}

# Check Auth Service
Write-Info "Checking Auth Service..."
try {
    $authHealth = Invoke-WebRequest -Uri "http://localhost:3001/health" -TimeoutSec 5 -UseBasicParsing
    if ($authHealth.StatusCode -eq 200) {
        Write-Success "Auth Service is healthy (Port 3001)"
    }
} catch {
    Write-Warning "Auth Service not responding yet"
}

# Check Detection Service
Write-Info "Checking Detection Service..."
try {
    $detectionHealth = Invoke-WebRequest -Uri "http://localhost:3002/health" -TimeoutSec 5 -UseBasicParsing
    if ($detectionHealth.StatusCode -eq 200) {
        Write-Success "Detection Service is healthy (Port 3002)"
    }
} catch {
    Write-Warning "Detection Service not responding yet (may still be loading YOLO models)"
}

# Check Kong Gateway
Write-Info "Checking Kong API Gateway..."
try {
    $kongHealth = Invoke-WebRequest -Uri "http://localhost:8001/status" -TimeoutSec 5 -UseBasicParsing
    if ($kongHealth.StatusCode -eq 200) {
        Write-Success "Kong API Gateway is healthy (Port 8000/8001)"
    }
} catch {
    Write-Warning "Kong API Gateway not responding yet"
}

# ================================
# Step 7: Database Initialization
# ================================
Write-Header "Database Initialization"

Write-Info "Checking if PostGIS extension is enabled..."
try {
    docker-compose exec -T postgres psql -U postgres -d saaf_surksha -c "SELECT PostGIS_version();" | Out-Null
    Write-Success "PostGIS extension is enabled"
} catch {
    Write-Warning "PostGIS check failed"
}

Write-Info "Running database migrations..."
docker-compose exec -T postgres psql -U postgres -d saaf_surksha -f /docker-entrypoint-initdb.d/001_initial_schema.sql 2>&1 | Out-Null
Write-Success "Database schema initialized"

# ================================
# Step 8: Test API Endpoints
# ================================
Write-Header "Testing API Endpoints"

Write-Info "Testing Auth Service health endpoint..."
try {
    $authTest = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get
    Write-Success "Auth Service: $($authTest.status)"
} catch {
    Write-Warning "Auth Service test failed"
}

Write-Info "Testing Detection Service health endpoint..."
try {
    $detectionTest = Invoke-RestMethod -Uri "http://localhost:3002/health" -Method Get
    Write-Success "Detection Service: $($detectionTest.status)"
} catch {
    Write-Warning "Detection Service test failed"
}

# ================================
# Step 9: Display Service URLs
# ================================
Write-Header "Service Information"

Write-Host ""
Write-ColorOutput Green "🚀 SAAF SURKSHA is now running!"
Write-Host ""
Write-Host "Service URLs:"
Write-Host "  ├─ Auth Service:       http://localhost:3001"
Write-Host "  ├─ Detection Service:  http://localhost:3002"
Write-Host "  ├─ Task Service:       http://localhost:3003"
Write-Host "  ├─ Geofence Service:   http://localhost:3004"
Write-Host "  ├─ RTI Service:        http://localhost:3005"
Write-Host "  ├─ Analytics Service:  http://localhost:3006"
Write-Host "  └─ API Gateway:        http://localhost:8000"
Write-Host ""
Write-Host "Management Dashboards:"
Write-Host "  ├─ PostgreSQL:         localhost:5432 (user: postgres, db: saaf_surksha)"
Write-Host "  ├─ Redis:              localhost:6379"
Write-Host "  ├─ RabbitMQ:           http://localhost:15672 (user: admin, pass: admin123)"
Write-Host "  └─ Kong Admin:         http://localhost:8001"
Write-Host ""

# ================================
# Step 10: Quick Test Commands
# ================================
Write-Header "Quick Test Commands"

Write-Host ""
Write-Host "Test user registration:"
Write-ColorOutput Yellow @"
Invoke-RestMethod -Uri http://localhost:3001/api/v1/auth/register ``
  -Method Post ``
  -ContentType 'application/json' ``
  -Body (@{
    phoneNumber = '+919876543210'
    email = 'test@example.com'
    fullName = 'Test User'
    password = 'Test@1234'
    role = 'CITIZEN'
  } | ConvertTo-Json)
"@

Write-Host ""
Write-Host "View logs for a specific service:"
Write-ColorOutput Yellow "docker-compose logs -f auth-service"
Write-Host ""
Write-Host "Stop all services:"
Write-ColorOutput Yellow "docker-compose down"
Write-Host ""
Write-Host "Restart a specific service:"
Write-ColorOutput Yellow "docker-compose restart detection-service"
Write-Host ""

# ================================
# Step 11: Next Steps
# ================================
Write-Header "Next Steps"

Write-Host ""
Write-Host "1. Open the project in VS Code:"
Write-ColorOutput Yellow "   code ."
Write-Host ""
Write-Host "2. Use GitHub Copilot to implement remaining services:"
Write-Host "   - Task Service (task management & verification)"
Write-Host "   - Geofence Service (location monitoring)"
Write-Host "   - RTI Service (complaint generation)"
Write-Host "   - Analytics Service (heatmaps & metrics)"
Write-Host ""
Write-Host "3. Check documentation:"
Write-Host "   - README.md - Project overview"
Write-Host "   - COPILOT_GUIDE.md - Implementation guide"
Write-Host "   - API_DOCUMENTATION.md - API reference"
Write-Host ""
Write-Host "4. View container status:"
Write-ColorOutput Yellow "   docker-compose ps"
Write-Host ""

Write-Success "Setup complete! Happy coding! 🎉"
Write-Host ""
