# SAAF-SURKSHA Quick Start Script
# Run this script to setup the entire project

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  SAAF-SURKSHA Project Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker --version | Out-Null
    Write-Host "✓ Docker installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found. Please install Docker Desktop" -ForegroundColor Red
    exit 1
}

# Check Docker Compose
try {
    docker-compose --version | Out-Null
    Write-Host "✓ Docker Compose installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose not found" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    node --version | Out-Null
    Write-Host "✓ Node.js installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    python --version | Out-Null
    Write-Host "✓ Python installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Please install Python 3.11+" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All prerequisites met!" -ForegroundColor Green
Write-Host ""

# Setup environment files
Write-Host "Setting up environment files..." -ForegroundColor Yellow
if (!(Test-Path "backend\auth-service\.env")) {
    Copy-Item "backend\auth-service\.env.example" "backend\auth-service\.env"
    Write-Host "✓ Created .env file for auth-service" -ForegroundColor Green
    Write-Host "  ⚠ Please edit backend\auth-service\.env and add your API keys" -ForegroundColor Yellow
} else {
    Write-Host "✓ .env file already exists" -ForegroundColor Green
}

Write-Host ""

# Start Docker services
Write-Host "Starting Docker services..." -ForegroundColor Yellow
Write-Host "This will take 2-3 minutes..." -ForegroundColor Cyan
Write-Host ""

docker-compose up -d

# Wait for services to be healthy
Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check service health
Write-Host ""
Write-Host "Checking service health..." -ForegroundColor Yellow

$services = @(
    @{Name="Auth Service"; Port=3001; Url="http://localhost:3001/health"},
    @{Name="Detection Service"; Port=3002; Url="http://localhost:3002/health"},
    @{Name="Kong Gateway"; Port=8000; Url="http://localhost:8001"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $($service.Name) is healthy" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ $($service.Name) is not responding" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Access the services at:" -ForegroundColor Yellow
Write-Host "  Auth API:       http://localhost:3001" -ForegroundColor Cyan
Write-Host "  Detection API:  http://localhost:3002" -ForegroundColor Cyan
Write-Host "  API Docs:       http://localhost:3002/api/docs" -ForegroundColor Cyan
Write-Host "  RabbitMQ UI:    http://localhost:15672 (admin/admin123)" -ForegroundColor Cyan
Write-Host "  Kong Gateway:   http://localhost:8000" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit backend\auth-service\.env with your API keys" -ForegroundColor White
Write-Host "2. Test the API: curl http://localhost:3001/health" -ForegroundColor White
Write-Host "3. Read SETUP.md for detailed instructions" -ForegroundColor White
Write-Host "4. Read COPILOT_GUIDE.md for development tips" -ForegroundColor White
Write-Host ""

Write-Host "To stop services: docker-compose down" -ForegroundColor Yellow
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Yellow
Write-Host ""
Write-Host "Happy building! 🚀" -ForegroundColor Green
