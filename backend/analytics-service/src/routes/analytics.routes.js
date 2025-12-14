const express = require('express');
const { body, query, param } = require('express-validator');
const analyticsController = require('../controllers/analytics.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validation');

const router = express.Router();

// Generate heatmap
router.get('/heatmap',
  authMiddleware,
  [
    query('issueType').optional().isIn(['POTHOLE', 'STREET_LIGHT', 'DRAINAGE', 'WASTE', 'ROADS', 'OTHER']),
    query('north').optional().isFloat({ min: -90, max: 90 }),
    query('south').optional().isFloat({ min: -90, max: 90 }),
    query('east').optional().isFloat({ min: -180, max: 180 }),
    query('west').optional().isFloat({ min: -180, max: 180 }),
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601()
  ],
  validate,
  analyticsController.generateHeatmap
);

// Get civic health score
router.get('/civic-health',
  authMiddleware,
  [
    query('region').optional().isString().trim(),
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601()
  ],
  validate,
  analyticsController.getCivicHealthScore
);

// Get trends
router.get('/trends',
  authMiddleware,
  [
    query('months').optional().isInt({ min: 1, max: 12 })
  ],
  validate,
  analyticsController.getTrends
);

// Provision B2B API data
router.post('/provision',
  authMiddleware,
  [
    body('customerId').isUUID(),
    body('dataType').isIn(['POTHOLE_HEATMAP', 'CIVIC_HEALTH_SCORE', 'RISK_ASSESSMENT', 'INFRASTRUCTURE_STATUS']),
    body('params').optional().isObject()
  ],
  validate,
  analyticsController.provisionAPIData
);

// Worker analytics
router.get('/workers',
  authMiddleware,
  [
    query('workerId').optional().isUUID(),
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601()
  ],
  validate,
  analyticsController.getWorkerAnalytics
);

// Get dashboard summary
router.get('/dashboard',
  authMiddleware,
  analyticsController.getDashboardSummary
);

module.exports = router;
