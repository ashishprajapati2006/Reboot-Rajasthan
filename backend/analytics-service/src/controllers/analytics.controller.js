const AnalyticsService = require('../services/analytics.service');
const logger = require('../utils/logger');

class AnalyticsController {
  async generateHeatmap(req, res) {
    try {
      const { issueType, north, south, east, west, startDate, endDate } = req.query;
      
      const regionBounds = (north && south && east && west) ? {
        north: parseFloat(north),
        south: parseFloat(south),
        east: parseFloat(east),
        west: parseFloat(west)
      } : null;
      
      const heatmapData = await AnalyticsService.generateHeatmap(
        issueType || null,
        regionBounds,
        startDate ? new Date(startDate) : null,
        endDate ? new Date(endDate) : null
      );
      
      res.json({
        success: true,
        data: heatmapData,
        count: heatmapData.length
      });
    } catch (error) {
      logger.error('Error in generateHeatmap controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getCivicHealthScore(req, res) {
    try {
      const { region, startDate, endDate } = req.query;
      
      const scoreData = await AnalyticsService.generateCivicHealthScore(
        region || null,
        startDate ? new Date(startDate) : null,
        endDate ? new Date(endDate) : null
      );
      
      res.json({
        success: true,
        data: scoreData
      });
    } catch (error) {
      logger.error('Error in getCivicHealthScore controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getTrends(req, res) {
    try {
      const { months } = req.query;
      
      const trendsData = await AnalyticsService.getTrends(
        months ? parseInt(months) : 3
      );
      
      res.json({
        success: true,
        data: trendsData
      });
    } catch (error) {
      logger.error('Error in getTrends controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async provisionAPIData(req, res) {
    try {
      const { customerId, dataType, params } = req.body;
      
      // Check if user has permission to provision data
      if (req.user.role !== 'ADMIN' && req.user.userId !== customerId) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized to provision data for this customer'
        });
      }
      
      const provisionedData = await AnalyticsService.provisionAPIData(
        customerId,
        dataType,
        params || {}
      );
      
      res.json({
        success: true,
        data: provisionedData
      });
    } catch (error) {
      logger.error('Error in provisionAPIData controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getWorkerAnalytics(req, res) {
    try {
      const { workerId, startDate, endDate } = req.query;
      
      const analyticsData = await AnalyticsService.getWorkerAnalytics(
        workerId || null,
        startDate ? new Date(startDate) : null,
        endDate ? new Date(endDate) : null
      );
      
      res.json({
        success: true,
        data: analyticsData,
        count: analyticsData.length
      });
    } catch (error) {
      logger.error('Error in getWorkerAnalytics controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getDashboardSummary(req, res) {
    try {
      const now = new Date();
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      
      // Get multiple analytics in parallel
      const [civicHealth, trends, workerStats] = await Promise.all([
        AnalyticsService.generateCivicHealthScore(null, thirtyDaysAgo, now),
        AnalyticsService.getTrends(1),
        AnalyticsService.getWorkerAnalytics(null, thirtyDaysAgo, now)
      ]);
      
      res.json({
        success: true,
        data: {
          civicHealth,
          recentTrends: trends,
          topWorkers: workerStats.slice(0, 10),
          period: {
            startDate: thirtyDaysAgo,
            endDate: now
          }
        }
      });
    } catch (error) {
      logger.error('Error in getDashboardSummary controller:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
}

module.exports = new AnalyticsController();
