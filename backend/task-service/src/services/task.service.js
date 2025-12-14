const db = require('../config/database');
const geolib = require('geolib');
const axios = require('axios');
const logger = require('../utils/logger');
const NotificationService = require('./notification.service');

class TaskService {
  /**
   * Create a new task from an issue
   */
  async createTask(issueId, workerId, departmentId) {
    const client = await db.connect();
    
    try {
      await client.query('BEGIN');
      
      // Check if issue exists and is not already assigned
      const issueCheck = await client.query(
        `SELECT id, status FROM issues WHERE id = $1`,
        [issueId]
      );
      
      if (issueCheck.rows.length === 0) {
        throw new Error('Issue not found');
      }
      
      if (issueCheck.rows[0].status === 'ASSIGNED') {
        throw new Error('Issue already assigned');
      }
      
      // Create task
      const taskResult = await client.query(
        `INSERT INTO tasks (issue_id, worker_id, task_status, assigned_at)
         VALUES ($1, $2, 'ASSIGNED', CURRENT_TIMESTAMP)
         RETURNING *`,
        [issueId, workerId]
      );
      
      // Update issue status
      await client.query(
        `UPDATE issues SET 
         status = 'ASSIGNED',
         assigned_to_id = $1,
         assigned_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [workerId, issueId]
      );
      
      await client.query('COMMIT');
      
      const task = taskResult.rows[0];
      
      // Send notification to worker
      await NotificationService.sendWorkerNotification(
        workerId,
        `New task assigned: Issue #${issueId}`,
        'TASK_ASSIGNED',
        { taskId: task.id, issueId }
      );
      
      logger.info(`Task created: ${task.id} for worker: ${workerId}`);
      
      return task;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Task creation failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Verify if worker is within geofence
   */
  async verifyGeofenceEntry(taskId, latitude, longitude) {
    try {
      // Get task and issue location
      const result = await db.query(
        `SELECT 
         t.id,
         t.geofence_entered_at,
         i.latitude as issue_lat,
         i.longitude as issue_lon
         FROM tasks t
         JOIN issues i ON t.issue_id = i.id
         WHERE t.id = $1`,
        [taskId]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Task not found');
      }
      
      const task = result.rows[0];
      
      // Check if worker is within geofence (100m radius)
      const distance = geolib.getDistance(
        { latitude: task.issue_lat, longitude: task.issue_lon },
        { latitude, longitude }
      );
      
      const isWithinGeofence = distance <= 100; // 100 meters
      
      if (isWithinGeofence && !task.geofence_entered_at) {
        // First time entering geofence
        await db.query(
          `UPDATE tasks 
           SET geofence_entered_at = CURRENT_TIMESTAMP,
               task_status = 'STARTED'
           WHERE id = $1`,
          [taskId]
        );
        
        logger.info(`Worker entered geofence for task: ${taskId}`);
      }
      
      return {
        isWithinGeofence,
        distanceMeters: distance,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Geofence verification failed:', error);
      throw error;
    }
  }

  /**
   * Verify task completion using AI
   */
  async verifyTaskCompletion(taskId, beforePhotoUrl, afterPhotoUrl, workerLat, workerLon) {
    const client = await db.connect();
    
    try {
      await client.query('BEGIN');
      
      // Get task details
      const taskResult = await client.query(
        `SELECT t.*, i.latitude, i.longitude
         FROM tasks t
         JOIN issues i ON t.issue_id = i.id
         WHERE t.id = $1`,
        [taskId]
      );
      
      if (taskResult.rows.length === 0) {
        throw new Error('Task not found');
      }
      
      const task = taskResult.rows[0];
      
      // Verify worker is at location
      const distance = geolib.getDistance(
        { latitude: task.latitude, longitude: task.longitude },
        { latitude: workerLat, longitude: workerLon }
      );
      
      if (distance > 100) {
        throw new Error('Worker not at task location');
      }
      
      // Call AI Detection Service for verification
      const detectionServiceUrl = process.env.DETECTION_SERVICE_URL || 'http://detection-service:3002';
      
      const verificationResult = await axios.post(
        `${detectionServiceUrl}/api/v1/verify-completion`,
        {
          task_id: taskId,
          before_photo_url: beforePhotoUrl,
          after_photo_url: afterPhotoUrl,
          gps_lat: workerLat,
          gps_lon: workerLon
        },
        {
          timeout: 30000 // 30 seconds
        }
      );
      
      const { issue_resolved, verification_confidence, analysis } = verificationResult.data;
      
      // Update task with AI verification
      const updateResult = await client.query(
        `UPDATE tasks SET 
         before_photo_url = $1,
         after_photo_url = $2,
         completed_at = CURRENT_TIMESTAMP,
         ai_verification_status = $3,
         ai_verification_score = $4,
         ai_verification_notes = $5,
         task_status = $6,
         task_duration_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - started_at)) / 60
         WHERE id = $7
         RETURNING *`,
        [
          beforePhotoUrl,
          afterPhotoUrl,
          issue_resolved ? 'VERIFIED' : 'FAILED',
          verification_confidence,
          analysis,
          issue_resolved ? 'VERIFIED' : 'REJECTED',
          taskId
        ]
      );
      
      const updatedTask = updateResult.rows[0];
      
      if (issue_resolved) {
        // Update issue status
        await client.query(
          `UPDATE issues SET 
           status = 'RESOLVED',
           actual_completion_date = CURRENT_DATE,
           resolution_notes = $1
           WHERE id = $2`,
          [analysis, task.issue_id]
        );
        
        // Trigger community voting
        await this.initiateCommunityVoting(taskId, client);
        
        logger.info(`Task verified and completed: ${taskId}`);
      } else {
        logger.warn(`Task verification failed: ${taskId}`);
      }
      
      await client.query('COMMIT');
      
      return updatedTask;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Task verification failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Initiate community voting for task verification
   */
  async initiateCommunityVoting(taskId, client) {
    try {
      const dbClient = client || await db.connect();
      const shouldRelease = !client;
      
      try {
        // Get issue location
        const locationResult = await dbClient.query(
          `SELECT i.latitude, i.longitude
           FROM tasks t
           JOIN issues i ON t.issue_id = i.id
           WHERE t.id = $1`,
          [taskId]
        );
        
        if (locationResult.rows.length === 0) {
          throw new Error('Task not found');
        }
        
        const { latitude, longitude } = locationResult.rows[0];
        
        // Find nearby citizens (within 500m) using PostGIS
        const nearbyUsersResult = await dbClient.query(
          `SELECT u.id, u.phone_number, u.email
           FROM users u
           WHERE u.user_role = 'CITIZEN'
           AND ST_DWithin(
             ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
             ST_SetSRID(ST_MakePoint(u.longitude, u.latitude), 4326)::geography,
             500
           )
           LIMIT 50`,
          [longitude, latitude]
        );
        
        // Send voting notifications
        const votingPromises = nearbyUsersResult.rows.map(user => 
          NotificationService.sendVotingNotification(
            user.id,
            taskId,
            'Please verify: Has this civic issue been resolved properly?'
          )
        );
        
        await Promise.all(votingPromises);
        
        logger.info(`Community voting initiated for task ${taskId}: ${nearbyUsersResult.rows.length} voters`);
      } finally {
        if (shouldRelease) {
          dbClient.release();
        }
      }
    } catch (error) {
      logger.error('Community voting initiation failed:', error);
      throw error;
    }
  }

  /**
   * Calculate worker performance score
   */
  async calculateWorkerScore(workerId, monthYear) {
    try {
      const scoreResult = await db.query(
        `SELECT 
         COUNT(*) as tasks_completed,
         SUM(CASE WHEN ai_verification_status = 'VERIFIED' THEN 1 ELSE 0 END) as verified_count,
         SUM(CASE WHEN ai_verification_status = 'FAILED' THEN 1 ELSE 0 END) as failed_count,
         AVG(ai_verification_score) as avg_verification_score,
         AVG(community_upvotes::float / NULLIF(community_upvotes + community_downvotes, 0)) as community_rating,
         AVG(task_duration_minutes) as avg_duration_minutes
         FROM tasks
         WHERE worker_id = $1
         AND DATE_TRUNC('month', completed_at) = DATE_TRUNC('month', $2::timestamp)
         AND task_status IN ('VERIFIED', 'COMPLETED', 'REJECTED')`,
        [workerId, monthYear]
      );
      
      const stats = scoreResult.rows[0];
      
      if (stats.tasks_completed === 0) {
        return {
          totalScore: 0,
          tasksCompleted: 0,
          message: 'No tasks completed in this period'
        };
      }
      
      // Calculate composite score (0-100)
      const completionRate = parseInt(stats.verified_count) / parseInt(stats.tasks_completed);
      const verificationScore = (parseFloat(stats.avg_verification_score) || 0) * 0.4;
      const communityScore = (parseFloat(stats.community_rating) || 0) * 0.3;
      const complianceScore = completionRate * 0.3;
      
      const totalScore = (verificationScore + communityScore + complianceScore) * 100;
      
      // Update worker performance table
      await db.query(
        `INSERT INTO worker_performance 
         (worker_id, month_year, tasks_assigned, tasks_completed, tasks_rejected, 
          average_verification_score, community_rating, compliance_score)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (worker_id, month_year) 
         DO UPDATE SET
         tasks_completed = $4,
         tasks_rejected = $5,
         average_verification_score = $6,
         community_rating = $7,
         compliance_score = $8,
         updated_at = CURRENT_TIMESTAMP`,
        [
          workerId,
          monthYear,
          parseInt(stats.tasks_completed),
          parseInt(stats.verified_count),
          parseInt(stats.failed_count),
          parseFloat(stats.avg_verification_score) || 0,
          parseFloat(stats.community_rating) || 0,
          complianceScore
        ]
      );
      
      // Update user's worker performance score
      await db.query(
        `UPDATE users SET worker_performance_score = $1 WHERE id = $2`,
        [totalScore, workerId]
      );
      
      logger.info(`Worker score calculated: ${workerId} - Score: ${totalScore.toFixed(2)}`);
      
      return {
        totalScore: Math.round(totalScore),
        tasksCompleted: parseInt(stats.tasks_completed),
        verifiedTasks: parseInt(stats.verified_count),
        rejectedTasks: parseInt(stats.failed_count),
        completionRate: Math.round(completionRate * 100),
        avgVerificationScore: Math.round((parseFloat(stats.avg_verification_score) || 0) * 100),
        communityRating: Math.round((parseFloat(stats.community_rating) || 0) * 100),
        avgDurationMinutes: Math.round(parseFloat(stats.avg_duration_minutes) || 0)
      };
    } catch (error) {
      logger.error('Worker score calculation failed:', error);
      throw error;
    }
  }

  /**
   * Get worker's active tasks
   */
  async getWorkerTasks(workerId, status = null) {
    try {
      let query = `
        SELECT 
          t.*,
          i.issue_type,
          i.severity,
          i.description,
          i.latitude,
          i.longitude,
          i.location_address,
          i.issue_photo_url
        FROM tasks t
        JOIN issues i ON t.issue_id = i.id
        WHERE t.worker_id = $1
      `;
      
      const params = [workerId];
      
      if (status) {
        query += ` AND t.task_status = $2`;
        params.push(status);
      }
      
      query += ` ORDER BY t.assigned_at DESC`;
      
      const result = await db.query(query, params);
      
      return result.rows;
    } catch (error) {
      logger.error('Failed to fetch worker tasks:', error);
      throw error;
    }
  }
}

module.exports = new TaskService();
