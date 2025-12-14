const pool = require('../config/database');
const logger = require('../utils/logger');
const redis = require('../config/redis');
const { startOfMonth, endOfMonth, subMonths, format } = require('date-fns');

class AnalyticsService {
  /**
   * Generate heatmap data for issue clustering
   * @param {string} issueType - Type of issue (POTHOLE, STREET_LIGHT, etc.)
   * @param {object} regionBounds - Geographic bounds {north, south, east, west}
   * @param {Date} startDate - Start date for filtering
   * @param {Date} endDate - End date for filtering
   * @returns {Promise<Array>} Heatmap points with coordinates and intensity
   */
  async generateHeatmap(issueType = null, regionBounds = null, startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          ST_X(location::geometry) as longitude,
          ST_Y(location::geometry) as latitude,
          COUNT(*) as issue_count,
          AVG(CASE 
            WHEN severity = 'LOW' THEN 1
            WHEN severity = 'MEDIUM' THEN 2
            WHEN severity = 'HIGH' THEN 3
            WHEN severity = 'CRITICAL' THEN 4
            ELSE 1
          END) as avg_severity,
          AVG(
            CASE 
              WHEN status = 'RESOLVED' AND resolved_at IS NOT NULL 
              THEN EXTRACT(EPOCH FROM (resolved_at - reported_at)) / 86400.0
              ELSE NULL
            END
          ) as avg_resolution_days
        FROM issues
        WHERE 1=1
      `;
      
      const params = [];
      let paramIndex = 1;
      
      if (issueType) {
        query += ` AND issue_type = $${paramIndex++}`;
        params.push(issueType);
      }
      
      if (regionBounds) {
        query += ` AND ST_Contains(
          ST_MakeEnvelope($${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++}, 4326),
          location::geometry
        )`;
        params.push(regionBounds.west, regionBounds.south, regionBounds.east, regionBounds.north);
      }
      
      if (startDate) {
        query += ` AND reported_at >= $${paramIndex++}`;
        params.push(startDate);
      }
      
      if (endDate) {
        query += ` AND reported_at <= $${paramIndex++}`;
        params.push(endDate);
      }
      
      query += `
        GROUP BY ST_SnapToGrid(location::geometry, 0.001)
        HAVING COUNT(*) >= 2
        ORDER BY issue_count DESC
        LIMIT 1000
      `;
      
      const result = await pool.query(query, params);
      
      return result.rows.map(row => ({
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        intensity: parseInt(row.issue_count),
        severity: parseFloat(row.avg_severity || 1),
        avgResolutionDays: parseFloat(row.avg_resolution_days || 0)
      }));
    } catch (error) {
      logger.error('Error generating heatmap:', error);
      throw error;
    }
  }

  /**
   * Calculate civic health score for a region
   * @param {string} region - Region identifier (city/ward/zone)
   * @param {Date} startDate - Start date for calculation
   * @param {Date} endDate - End date for calculation
   * @returns {Promise<object>} Civic health score with components
   */
  async generateCivicHealthScore(region = null, startDate = null, endDate = null) {
    try {
      const cacheKey = `civic_health:${region}:${format(startDate || new Date(), 'yyyy-MM-dd')}`;
      
      // Check cache
      const cached = await redis.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
      
      let query = `
        WITH issue_stats AS (
          SELECT 
            COUNT(*) as total_issues,
            COUNT(CASE WHEN status = 'RESOLVED' THEN 1 END) as resolved_issues,
            AVG(
              CASE 
                WHEN status = 'RESOLVED' AND resolved_at IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (resolved_at - reported_at)) / 86400.0
                ELSE NULL
              END
            ) as avg_resolution_days,
            AVG(CASE 
              WHEN severity = 'LOW' THEN 1
              WHEN severity = 'MEDIUM' THEN 2
              WHEN severity = 'HIGH' THEN 3
              WHEN severity = 'CRITICAL' THEN 4
              ELSE 1
            END) as avg_severity,
            COUNT(CASE WHEN status IN ('RESOLVED', 'IN_PROGRESS', 'ASSIGNED') THEN 1 END) as active_issues,
            COUNT(CASE WHEN status = 'PENDING' AND reported_at < NOW() - INTERVAL '72 hours' THEN 1 END) as overdue_issues
          FROM issues
          WHERE 1=1
      `;
      
      const params = [];
      let paramIndex = 1;
      
      if (region) {
        query += ` AND region = $${paramIndex++}`;
        params.push(region);
      }
      
      if (startDate) {
        query += ` AND reported_at >= $${paramIndex++}`;
        params.push(startDate);
      }
      
      if (endDate) {
        query += ` AND reported_at <= $${paramIndex++}`;
        params.push(endDate);
      }
      
      query += `
        ),
        worker_stats AS (
          SELECT 
            COUNT(DISTINCT worker_id) as total_workers,
            AVG(worker_performance_score) as avg_worker_score
          FROM tasks
          WHERE status = 'COMPLETED'
      `;
      
      if (startDate) {
        query += ` AND completed_at >= $${paramIndex++}`;
        params.push(startDate);
      }
      
      if (endDate) {
        query += ` AND completed_at <= $${paramIndex++}`;
        params.push(endDate);
      }
      
      query += `
        )
        SELECT 
          i.total_issues,
          i.resolved_issues,
          i.avg_resolution_days,
          i.avg_severity,
          i.active_issues,
          i.overdue_issues,
          w.total_workers,
          w.avg_worker_score,
          CASE 
            WHEN i.total_issues > 0 THEN (i.resolved_issues::float / i.total_issues * 100)
            ELSE 0
          END as resolution_rate
        FROM issue_stats i
        CROSS JOIN worker_stats w
      `;
      
      const result = await pool.query(query, params);
      
      if (result.rows.length === 0) {
        return {
          civicHealthScore: 0,
          components: {},
          metadata: { message: 'No data available' }
        };
      }
      
      const stats = result.rows[0];
      
      // Calculate component scores (0-100 scale)
      const resolutionScore = Math.min(100, parseFloat(stats.resolution_rate || 0));
      
      const severityScore = Math.max(0, 100 - (parseFloat(stats.avg_severity || 1) - 1) * 33.33);
      
      const targetResolutionDays = 7;
      const actualResolutionDays = parseFloat(stats.avg_resolution_days || targetResolutionDays);
      const speedScore = Math.max(0, 100 - ((actualResolutionDays - targetResolutionDays) / targetResolutionDays * 100));
      
      const workerScore = parseFloat(stats.avg_worker_score || 50);
      
      const overdueRate = stats.total_issues > 0 
        ? (parseInt(stats.overdue_issues) / parseInt(stats.total_issues)) * 100 
        : 0;
      const complianceScore = Math.max(0, 100 - overdueRate);
      
      // Weighted civic health score
      const civicHealthScore = (
        resolutionScore * 0.40 +
        severityScore * 0.20 +
        speedScore * 0.20 +
        workerScore * 0.10 +
        complianceScore * 0.10
      );
      
      const scoreData = {
        civicHealthScore: Math.round(civicHealthScore * 10) / 10,
        grade: this._getGrade(civicHealthScore),
        components: {
          resolutionScore: Math.round(resolutionScore * 10) / 10,
          severityScore: Math.round(severityScore * 10) / 10,
          speedScore: Math.round(speedScore * 10) / 10,
          workerScore: Math.round(workerScore * 10) / 10,
          complianceScore: Math.round(complianceScore * 10) / 10
        },
        statistics: {
          totalIssues: parseInt(stats.total_issues),
          resolvedIssues: parseInt(stats.resolved_issues),
          avgResolutionDays: parseFloat(stats.avg_resolution_days || 0).toFixed(2),
          avgSeverity: parseFloat(stats.avg_severity || 0).toFixed(2),
          overdueIssues: parseInt(stats.overdue_issues),
          totalWorkers: parseInt(stats.total_workers)
        },
        metadata: {
          region: region || 'All',
          startDate: startDate || null,
          endDate: endDate || null,
          calculatedAt: new Date()
        }
      };
      
      // Cache for 1 hour
      await redis.setex(cacheKey, 3600, JSON.stringify(scoreData));
      
      return scoreData;
    } catch (error) {
      logger.error('Error calculating civic health score:', error);
      throw error;
    }
  }

  _getGrade(score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }

  /**
   * Get trending issues analysis
   * @param {number} months - Number of months to analyze
   * @returns {Promise<object>} Trending data with patterns
   */
  async getTrends(months = 3) {
    try {
      const endDate = new Date();
      const startDate = subMonths(endDate, months);
      
      const query = `
        SELECT 
          DATE_TRUNC('week', reported_at) as week,
          issue_type,
          COUNT(*) as count,
          AVG(CASE 
            WHEN severity = 'LOW' THEN 1
            WHEN severity = 'MEDIUM' THEN 2
            WHEN severity = 'HIGH' THEN 3
            WHEN severity = 'CRITICAL' THEN 4
            ELSE 1
          END) as avg_severity
        FROM issues
        WHERE reported_at >= $1 AND reported_at <= $2
        GROUP BY DATE_TRUNC('week', reported_at), issue_type
        ORDER BY week DESC, count DESC
      `;
      
      const result = await pool.query(query, [startDate, endDate]);
      
      // Group by week
      const trendsByWeek = result.rows.reduce((acc, row) => {
        const weekKey = format(new Date(row.week), 'yyyy-MM-dd');
        if (!acc[weekKey]) {
          acc[weekKey] = [];
        }
        acc[weekKey].push({
          issueType: row.issue_type,
          count: parseInt(row.count),
          avgSeverity: parseFloat(row.avg_severity)
        });
        return acc;
      }, {});
      
      return {
        period: {
          startDate,
          endDate,
          months
        },
        trends: trendsByWeek
      };
    } catch (error) {
      logger.error('Error getting trends:', error);
      throw error;
    }
  }

  /**
   * Provision B2B API data for external customers
   * @param {string} customerId - Customer UUID
   * @param {string} dataType - Type of data requested
   * @param {object} params - Additional parameters
   * @returns {Promise<object>} Provisioned data
   */
  async provisionAPIData(customerId, dataType, params = {}) {
    try {
      // Log API usage
      await pool.query(
        `INSERT INTO api_usage_logs (customer_id, data_type, request_params, requested_at)
         VALUES ($1, $2, $3, NOW())`,
        [customerId, dataType, JSON.stringify(params)]
      );
      
      let data;
      
      switch (dataType) {
        case 'POTHOLE_HEATMAP':
          data = await this.generateHeatmap('POTHOLE', params.regionBounds, params.startDate, params.endDate);
          break;
          
        case 'CIVIC_HEALTH_SCORE':
          data = await this.generateCivicHealthScore(params.region, params.startDate, params.endDate);
          break;
          
        case 'RISK_ASSESSMENT':
          data = await this._getRiskAssessment(params.region, params.issueTypes);
          break;
          
        case 'INFRASTRUCTURE_STATUS':
          data = await this._getInfrastructureStatus(params.region);
          break;
          
        default:
          throw new Error(`Unknown data type: ${dataType}`);
      }
      
      return {
        customerId,
        dataType,
        data,
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
      };
    } catch (error) {
      logger.error('Error provisioning API data:', error);
      throw error;
    }
  }

  async _getRiskAssessment(region, issueTypes) {
    const query = `
      SELECT 
        region,
        issue_type,
        COUNT(*) as total_count,
        COUNT(CASE WHEN severity IN ('HIGH', 'CRITICAL') THEN 1 END) as high_risk_count,
        AVG(EXTRACT(EPOCH FROM (NOW() - reported_at)) / 86400.0) as avg_age_days
      FROM issues
      WHERE status != 'RESOLVED'
        ${region ? 'AND region = $1' : ''}
        ${issueTypes ? `AND issue_type = ANY($${region ? 2 : 1})` : ''}
      GROUP BY region, issue_type
      ORDER BY high_risk_count DESC
    `;
    
    const params = [];
    if (region) params.push(region);
    if (issueTypes) params.push(issueTypes);
    
    const result = await pool.query(query, params);
    
    return result.rows.map(row => ({
      region: row.region,
      issueType: row.issue_type,
      totalCount: parseInt(row.total_count),
      highRiskCount: parseInt(row.high_risk_count),
      riskScore: Math.min(100, (parseInt(row.high_risk_count) / parseInt(row.total_count)) * 100),
      avgAgeDays: parseFloat(row.avg_age_days).toFixed(2)
    }));
  }

  async _getInfrastructureStatus(region) {
    const query = `
      SELECT 
        issue_type,
        status,
        COUNT(*) as count,
        AVG(CASE 
          WHEN severity = 'LOW' THEN 1
          WHEN severity = 'MEDIUM' THEN 2
          WHEN severity = 'HIGH' THEN 3
          WHEN severity = 'CRITICAL' THEN 4
          ELSE 1
        END) as avg_severity
      FROM issues
      WHERE ${region ? 'region = $1' : '1=1'}
      GROUP BY issue_type, status
      ORDER BY issue_type, status
    `;
    
    const result = await pool.query(query, region ? [region] : []);
    
    // Group by issue type
    const statusByType = result.rows.reduce((acc, row) => {
      if (!acc[row.issue_type]) {
        acc[row.issue_type] = {};
      }
      acc[row.issue_type][row.status] = {
        count: parseInt(row.count),
        avgSeverity: parseFloat(row.avg_severity)
      };
      return acc;
    }, {});
    
    return {
      region: region || 'All',
      infrastructureStatus: statusByType,
      generatedAt: new Date()
    };
  }

  /**
   * Get worker performance analytics
   * @param {string} workerId - Worker UUID (optional)
   * @param {Date} startDate - Start date
   * @param {Date} endDate - End date
   * @returns {Promise<object>} Worker performance metrics
   */
  async getWorkerAnalytics(workerId = null, startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          u.user_id,
          u.full_name,
          COUNT(t.task_id) as total_tasks,
          COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END) as completed_tasks,
          COUNT(CASE WHEN t.ai_verification_status = 'VERIFIED' THEN 1 END) as verified_tasks,
          AVG(t.worker_performance_score) as avg_score,
          AVG(
            CASE WHEN t.completed_at IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (t.completed_at - t.started_at)) / 3600.0
            ELSE NULL END
          ) as avg_completion_hours,
          COUNT(CASE WHEN t.geofence_entered_at IS NOT NULL THEN 1 END) as geofence_compliant_tasks
        FROM users u
        LEFT JOIN tasks t ON u.user_id = t.worker_id
        WHERE u.role = 'WORKER'
      `;
      
      const params = [];
      let paramIndex = 1;
      
      if (workerId) {
        query += ` AND u.user_id = $${paramIndex++}`;
        params.push(workerId);
      }
      
      if (startDate) {
        query += ` AND t.created_at >= $${paramIndex++}`;
        params.push(startDate);
      }
      
      if (endDate) {
        query += ` AND t.created_at <= $${paramIndex++}`;
        params.push(endDate);
      }
      
      query += `
        GROUP BY u.user_id, u.full_name
        HAVING COUNT(t.task_id) > 0
        ORDER BY avg_score DESC NULLS LAST
        LIMIT 100
      `;
      
      const result = await pool.query(query, params);
      
      return result.rows.map(row => ({
        workerId: row.user_id,
        workerName: row.full_name,
        totalTasks: parseInt(row.total_tasks),
        completedTasks: parseInt(row.completed_tasks),
        verifiedTasks: parseInt(row.verified_tasks),
        avgScore: parseFloat(row.avg_score || 0).toFixed(2),
        avgCompletionHours: parseFloat(row.avg_completion_hours || 0).toFixed(2),
        geofenceCompliance: row.total_tasks > 0 
          ? ((parseInt(row.geofence_compliant_tasks) / parseInt(row.total_tasks)) * 100).toFixed(2)
          : 0
      }));
    } catch (error) {
      logger.error('Error getting worker analytics:', error);
      throw error;
    }
  }
}

module.exports = new AnalyticsService();
