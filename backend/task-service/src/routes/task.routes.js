const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const taskController = require('../controllers/task.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validation');

// Create new task (Admin/RWA only)
router.post(
  '/',
  authMiddleware,
  [
    body('issueId').isUUID().withMessage('Invalid issue ID'),
    body('workerId').isUUID().withMessage('Invalid worker ID'),
    body('departmentId').optional().isUUID()
  ],
  validate,
  taskController.createTask
);

// Start task (Worker only)
router.patch(
  '/:taskId/start',
  authMiddleware,
  [
    param('taskId').isUUID(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 })
  ],
  validate,
  taskController.startTask
);

// Submit task completion (Worker only)
router.patch(
  '/:taskId/submit',
  authMiddleware,
  [
    param('taskId').isUUID(),
    body('beforePhotoUrl').isURL(),
    body('afterPhotoUrl').isURL(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('notes').optional().isString()
  ],
  validate,
  taskController.submitTask
);

// Get worker's tasks
router.get(
  '/worker/:workerId',
  authMiddleware,
  [
    param('workerId').isUUID(),
    query('status').optional().isIn(['ASSIGNED', 'STARTED', 'IN_PROGRESS', 'SUBMITTED', 'VERIFIED', 'REJECTED', 'COMPLETED'])
  ],
  validate,
  taskController.getWorkerTasks
);

// Get worker statistics
router.get(
  '/stats/worker/:workerId',
  authMiddleware,
  [
    param('workerId').isUUID(),
    query('month').optional().isISO8601()
  ],
  validate,
  taskController.getWorkerStats
);

// Get task details
router.get(
  '/:taskId',
  authMiddleware,
  [param('taskId').isUUID()],
  validate,
  taskController.getTaskDetails
);

// Vote on task (Citizen only)
router.post(
  '/:taskId/vote',
  authMiddleware,
  [
    param('taskId').isUUID(),
    body('vote').isIn(['UPVOTE', 'DOWNVOTE']),
    body('comment').optional().isString()
  ],
  validate,
  taskController.voteOnTask
);

module.exports = router;
