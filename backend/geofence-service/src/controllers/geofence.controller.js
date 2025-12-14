const GeofenceService = require('../services/geofence.service');
const logger = require('../utils/logger');

class GeofenceController {
  async createGeofence(req, res) {
    try {
      const { name, description, polygon, geofenceType } = req.body;
      const createdById = req.user.userId;
      
      const geofence = await GeofenceService.createGeofence(
        name,
        description,
        polygon,
        geofenceType,
        createdById
      );
      
      res.status(201).json({
        success: true,
        data: geofence,
        message: 'Geofence created successfully'
      });
    } catch (error) {
      logger.error('Create geofence error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async createCircularGeofence(req, res) {
    try {
      const { name, description, latitude, longitude, radiusMeters, geofenceType } = req.body;
      const createdById = req.user.userId;
      
      const geofence = await GeofenceService.createCircularGeofence(
        name,
        description,
        latitude,
        longitude,
        radiusMeters,
        geofenceType,
        createdById
      );
      
      res.status(201).json({
        success: true,
        data: geofence,
        message: 'Circular geofence created successfully'
      });
    } catch (error) {
      logger.error('Create circular geofence error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async checkPoint(req, res) {
    try {
      const { latitude, longitude, geofenceId } = req.body;
      
      const result = await GeofenceService.checkPointInGeofence(
        latitude,
        longitude,
        geofenceId
      );
      
      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      logger.error('Check point error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getNearbyGeofences(req, res) {
    try {
      const { latitude, longitude, radiusMeters, type } = req.query;
      
      const geofences = await GeofenceService.getGeofencesNear(
        parseFloat(latitude),
        parseFloat(longitude),
        radiusMeters ? parseInt(radiusMeters) : 1000,
        type
      );
      
      res.json({
        success: true,
        data: geofences,
        count: geofences.length
      });
    } catch (error) {
      logger.error('Get nearby geofences error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async trackWorkerLocation(req, res) {
    try {
      const { workerId, taskId, latitude, longitude } = req.body;
      
      const result = await GeofenceService.trackWorkerLocation(
        workerId,
        taskId,
        latitude,
        longitude
      );
      
      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      logger.error('Track worker location error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getBreaches(req, res) {
    try {
      const { taskId } = req.params;
      
      const breaches = await GeofenceService.getGeofenceBreaches(taskId);
      
      res.json({
        success: true,
        data: breaches,
        count: breaches.length
      });
    } catch (error) {
      logger.error('Get breaches error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async updateStatus(req, res) {
    try {
      const { geofenceId } = req.params;
      const { isActive } = req.body;
      
      const geofence = await GeofenceService.updateGeofenceStatus(
        geofenceId,
        isActive
      );
      
      res.json({
        success: true,
        data: geofence,
        message: 'Geofence status updated'
      });
    } catch (error) {
      logger.error('Update geofence status error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async deleteGeofence(req, res) {
    try {
      const { geofenceId } = req.params;
      
      const result = await GeofenceService.deleteGeofence(geofenceId);
      
      res.json({
        success: true,
        data: result,
        message: 'Geofence deleted successfully'
      });
    } catch (error) {
      logger.error('Delete geofence error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getArea(req, res) {
    try {
      const { geofenceId } = req.params;
      
      const area = await GeofenceService.calculateGeofenceArea(geofenceId);
      
      res.json({
        success: true,
        data: area
      });
    } catch (error) {
      logger.error('Get geofence area error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
}

module.exports = new GeofenceController();
