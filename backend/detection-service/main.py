from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.detection import router as detection_router
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="SAAF-SURKSHA Detection Service",
    description="YOLOv8-based Civic Issue Detection API with Fraud Prevention",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(detection_router)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "success": True,
        "message": "Detection Service is healthy",
        "service": "detection-service",
        "version": "1.0.0"
    }


@app.on_event("startup")
async def startup_event():
    """Startup event handler"""
    logger.info("Detection Service starting up...")
    logger.info("YOLOv8 model loaded and ready")


@app.on_event("shutdown")
async def shutdown_event():
    """Shutdown event handler"""
    logger.info("Detection Service shutting down...")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=3002,
        reload=True
    )
