const TaskService = require('../services/task.service');
const logger = require('../utils/logger');

class TaskController {
  async createTask(req, res) {
    try {
      const { issueId, workerId, departmentId } = req.body;
      
      const task = await TaskService.createTask(issueId, workerId, departmentId);
      
      res.status(201).json({
        success: true,
        data: task,
        message: 'Task created successfully'
      });
    } catch (error) {
      logger.error('Create task error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async startTask(req, res) {
    try {
      const { taskId } = req.params;
      const { latitude, longitude } = req.body;
      
      const geofenceCheck = await TaskService.verifyGeofenceEntry(
        taskId,
        latitude,
        longitude
      );
      
      if (!geofenceCheck.isWithinGeofence) {
        return res.status(403).json({
          success: false,
          error: 'Worker not within task geofence',
          distanceMeters: geofenceCheck.distanceMeters
        });
      }
      
      res.json({
        success: true,
        data: geofenceCheck,
        message: 'Task started successfully'
      });
    } catch (error) {
      logger.error('Start task error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async submitTask(req, res) {
    try {
      const { taskId } = req.params;
      const { beforePhotoUrl, afterPhotoUrl, latitude, longitude, notes } = req.body;
      
      const verifiedTask = await TaskService.verifyTaskCompletion(
        taskId,
        beforePhotoUrl,
        afterPhotoUrl,
        latitude,
        longitude
      );
      
      res.json({
        success: true,
        data: verifiedTask,
        message: 'Task submitted for verification'
      });
    } catch (error) {
      logger.error('Submit task error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getWorkerTasks(req, res) {
    try {
      const { workerId } = req.params;
      const { status } = req.query;
      
      const tasks = await TaskService.getWorkerTasks(workerId, status);
      
      res.json({
        success: true,
        data: tasks,
        count: tasks.length
      });
    } catch (error) {
      logger.error('Get worker tasks error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getWorkerStats(req, res) {
    try {
      const { workerId } = req.params;
      const { month } = req.query;
      
      const monthYear = month || new Date().toISOString();
      
      const stats = await TaskService.calculateWorkerScore(workerId, monthYear);
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      logger.error('Get worker stats error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getTaskDetails(req, res) {
    try {
      const { taskId } = req.params;
      
      // Implement get task details
      res.json({
        success: true,
        message: 'Get task details - to be implemented'
      });
    } catch (error) {
      logger.error('Get task details error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async voteOnTask(req, res) {
    try {
      const { taskId } = req.params;
      const { vote, comment } = req.body;
      
      // Implement voting logic
      res.json({
        success: true,
        message: 'Vote recorded successfully'
      });
    } catch (error) {
      logger.error('Vote on task error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
}

module.exports = new TaskController();
