const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const geofenceController = require('../controllers/geofence.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validation');

// Create polygon geofence
router.post(
  '/',
  authMiddleware,
  [
    body('name').isString().isLength({ min: 3, max: 255 }),
    body('description').optional().isString(),
    body('polygon').isObject().withMessage('Polygon must be valid GeoJSON'),
    body('geofenceType').isIn(['TASK_LOCATION', 'WORKER_ZONE', 'RWA_BOUNDARY', 'DANGER_ZONE'])
  ],
  validate,
  geofenceController.createGeofence
);

// Create circular geofence
router.post(
  '/circular',
  authMiddleware,
  [
    body('name').isString().isLength({ min: 3, max: 255 }),
    body('description').optional().isString(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('radiusMeters').isInt({ min: 10, max: 10000 }),
    body('geofenceType').isIn(['TASK_LOCATION', 'WORKER_ZONE', 'RWA_BOUNDARY', 'DANGER_ZONE'])
  ],
  validate,
  geofenceController.createCircularGeofence
);

// Check if point is in geofence
router.post(
  '/check-point',
  authMiddleware,
  [
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('geofenceId').optional().isUUID()
  ],
  validate,
  geofenceController.checkPoint
);

// Get nearby geofences
router.get(
  '/nearby',
  authMiddleware,
  [
    query('latitude').isFloat({ min: -90, max: 90 }),
    query('longitude').isFloat({ min: -180, max: 180 }),
    query('radiusMeters').optional().isInt({ min: 100, max: 10000 }),
    query('type').optional().isIn(['TASK_LOCATION', 'WORKER_ZONE', 'RWA_BOUNDARY', 'DANGER_ZONE'])
  ],
  validate,
  geofenceController.getNearbyGeofences
);

// Track worker location
router.post(
  '/track',
  authMiddleware,
  [
    body('workerId').isUUID(),
    body('taskId').isUUID(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 })
  ],
  validate,
  geofenceController.trackWorkerLocation
);

// Get geofence breaches for task
router.get(
  '/breaches/:taskId',
  authMiddleware,
  [param('taskId').isUUID()],
  validate,
  geofenceController.getBreaches
);

// Update geofence status
router.patch(
  '/:geofenceId/status',
  authMiddleware,
  [
    param('geofenceId').isUUID(),
    body('isActive').isBoolean()
  ],
  validate,
  geofenceController.updateStatus
);

// Delete geofence
router.delete(
  '/:geofenceId',
  authMiddleware,
  [param('geofenceId').isUUID()],
  validate,
  geofenceController.deleteGeofence
);

// Get geofence area
router.get(
  '/:geofenceId/area',
  authMiddleware,
  [param('geofenceId').isUUID()],
  validate,
  geofenceController.getArea
);

module.exports = router;
