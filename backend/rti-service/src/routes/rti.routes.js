const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const rtiController = require('../controllers/rti.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validation');

// Generate RTI draft
router.post(
  '/draft',
  authMiddleware,
  [
    body('complaintId').isUUID(),
    body('authorityName').isString().isLength({ min: 3, max: 255 })
  ],
  validate,
  rtiController.generateDraft
);

// File RTI officially
router.post(
  '/:rtiId/file',
  authMiddleware,
  [
    param('rtiId').isUUID(),
    body('emailTo').isEmail()
  ],
  validate,
  rtiController.fileRTI
);

// Escalate on social media
router.post(
  '/escalate/social',
  authMiddleware,
  [
    body('complaintId').isUUID(),
    body('includePhoto').optional().isBoolean()
  ],
  validate,
  rtiController.socialMediaEscalate
);

// Monitor SLA
router.get(
  '/sla/:complaintId',
  authMiddleware,
  [param('complaintId').isUUID()],
  validate,
  rtiController.monitorSLA
);

// Manual escalation
router.post(
  '/complaints/:complaintId/escalate',
  authMiddleware,
  [
    param('complaintId').isUUID(),
    body('escalationLevel').isInt({ min: 1, max: 3 })
  ],
  validate,
  rtiController.escalateComplaint
);

// Get RTI status
router.get(
  '/:rtiId/status',
  authMiddleware,
  [param('rtiId').isUUID()],
  validate,
  rtiController.getRTIStatus
);

// Get escalation history
router.get(
  '/complaints/:complaintId/history',
  authMiddleware,
  [param('complaintId').isUUID()],
  validate,
  rtiController.getEscalationHistory
);

module.exports = router;
