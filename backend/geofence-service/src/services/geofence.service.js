const db = require('../config/database');
const logger = require('../utils/logger');

class GeofenceService {
  /**
   * Create a geofence with polygon boundary
   */
  async createGeofence(name, description, polygon, geofenceType, createdById) {
    try {
      // polygon should be GeoJSON format
      // { "type": "Polygon", "coordinates": [[[lon, lat], [lon, lat], ...]] }
      
      const result = await db.query(
        `INSERT INTO geofences (name, description, geofence_polygon, geofence_type, created_by_id)
         VALUES ($1, $2, ST_GeomFromGeoJSON($3), $4, $5)
         RETURNING id, name, description, geofence_type, 
                   ST_AsGeoJSON(geofence_polygon) as geometry,
                   created_at`,
        [name, description, JSON.stringify(polygon), geofenceType, createdById]
      );
      
      const geofence = result.rows[0];
      geofence.geometry = JSON.parse(geofence.geometry);
      
      logger.info(`Geofence created: ${geofence.id} - ${name}`);
      
      return geofence;
    } catch (error) {
      logger.error('Geofence creation failed:', error);
      throw error;
    }
  }

  /**
   * Create circular geofence from center point and radius
   */
  async createCircularGeofence(name, description, latitude, longitude, radiusMeters, geofenceType, createdById) {
    try {
      // Create a circular polygon using PostGIS ST_Buffer
      const result = await db.query(
        `INSERT INTO geofences (name, description, geofence_polygon, geofence_type, radius_meters, created_by_id)
         VALUES (
           $1, 
           $2, 
           ST_Buffer(
             ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
             $5
           )::geometry,
           $6,
           $5,
           $7
         )
         RETURNING id, name, description, geofence_type, radius_meters,
                   ST_AsGeoJSON(geofence_polygon) as geometry,
                   created_at`,
        [name, description, longitude, latitude, radiusMeters, geofenceType, createdById]
      );
      
      const geofence = result.rows[0];
      geofence.geometry = JSON.parse(geofence.geometry);
      
      logger.info(`Circular geofence created: ${geofence.id} - ${radiusMeters}m radius`);
      
      return geofence;
    } catch (error) {
      logger.error('Circular geofence creation failed:', error);
      throw error;
    }
  }

  /**
   * Check if a point is within a geofence
   */
  async checkPointInGeofence(latitude, longitude, geofenceId = null) {
    try {
      let query, params;
      
      if (geofenceId) {
        // Check specific geofence
        query = `
          SELECT id, name, geofence_type, radius_meters,
                 ST_Contains(
                   geofence_polygon,
                   ST_SetSRID(ST_MakePoint($1, $2), 4326)
                 ) as is_inside
          FROM geofences
          WHERE id = $3 AND is_active = true
        `;
        params = [longitude, latitude, geofenceId];
      } else {
        // Check all active geofences
        query = `
          SELECT id, name, geofence_type, radius_meters
          FROM geofences
          WHERE is_active = true
          AND ST_Contains(
            geofence_polygon,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)
          )
        `;
        params = [longitude, latitude];
      }
      
      const result = await db.query(query, params);
      
      if (geofenceId) {
        return {
          isInside: result.rows.length > 0 && result.rows[0].is_inside,
          geofence: result.rows[0] || null
        };
      } else {
        return {
          isInside: result.rows.length > 0,
          geofences: result.rows,
          count: result.rows.length
        };
      }
    } catch (error) {
      logger.error('Point-in-geofence check failed:', error);
      throw error;
    }
  }

  /**
   * Get geofences near a location
   */
  async getGeofencesNear(latitude, longitude, radiusMeters = 1000, geofenceType = null) {
    try {
      let query = `
        SELECT 
          id, 
          name, 
          description,
          geofence_type, 
          radius_meters,
          ST_AsGeoJSON(geofence_polygon) as geometry,
          ST_Distance(
            geofence_polygon,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
          ) as distance_meters
        FROM geofences
        WHERE is_active = true
        AND ST_DWithin(
          geofence_polygon,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          $3
        )
      `;
      
      const params = [longitude, latitude, radiusMeters];
      
      if (geofenceType) {
        query += ` AND geofence_type = $4`;
        params.push(geofenceType);
      }
      
      query += ` ORDER BY distance_meters ASC`;
      
      const result = await db.query(query, params);
      
      const geofences = result.rows.map(row => ({
        ...row,
        geometry: JSON.parse(row.geometry),
        distance_meters: parseFloat(row.distance_meters)
      }));
      
      return geofences;
    } catch (error) {
      logger.error('Get nearby geofences failed:', error);
      throw error;
    }
  }

  /**
   * Monitor and log geofence breach
   */
  async monitorGeofenceBreach(taskId, latitude, longitude, geofenceId) {
    const client = await db.connect();
    
    try {
      await client.query('BEGIN');
      
      // Check if point is within geofence
      const checkResult = await this.checkPointInGeofence(latitude, longitude, geofenceId);
      
      if (!checkResult.isInside) {
        // Log breach
        await client.query(
          `INSERT INTO geofence_breaches 
           (task_id, geofence_id, breach_type, latitude, longitude, is_flagged)
           VALUES ($1, $2, 'LOCATION_MISMATCH', $3, $4, true)`,
          [taskId, geofenceId, latitude, longitude]
        );
        
        logger.warn(`Geofence breach detected - Task: ${taskId}, Geofence: ${geofenceId}`);
        
        // Send alert (implement notification service call)
        await this.sendGeofenceAlert(taskId, geofenceId, latitude, longitude);
        
        await client.query('COMMIT');
        
        return {
          isBreached: true,
          geofenceId,
          breachType: 'LOCATION_MISMATCH',
          coordinates: { latitude, longitude }
        };
      }
      
      await client.query('COMMIT');
      
      return {
        isBreached: false,
        geofenceId
      };
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Geofence breach monitoring failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Track worker location within geofence
   */
  async trackWorkerLocation(workerId, taskId, latitude, longitude) {
    try {
      // Get task's geofence
      const taskResult = await db.query(
        `SELECT 
         t.id,
         i.latitude as issue_lat,
         i.longitude as issue_lon
         FROM tasks t
         JOIN issues i ON t.issue_id = i.id
         WHERE t.id = $1`,
        [taskId]
      );
      
      if (taskResult.rows.length === 0) {
        throw new Error('Task not found');
      }
      
      const task = taskResult.rows[0];
      
      // Check if worker is within 100m of issue location
      const distanceResult = await db.query(
        `SELECT ST_Distance(
           ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
           ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
         ) as distance`,
        [longitude, latitude, task.issue_lon, task.issue_lat]
      );
      
      const distance = parseFloat(distanceResult.rows[0].distance);
      const isWithinGeofence = distance <= 100;
      
      // Store location history
      await db.query(
        `INSERT INTO worker_locations 
         (worker_id, task_id, latitude, longitude, is_within_geofence, recorded_at)
         VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)`,
        [workerId, taskId, latitude, longitude, isWithinGeofence]
      );
      
      return {
        isWithinGeofence,
        distanceMeters: Math.round(distance),
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Worker location tracking failed:', error);
      throw error;
    }
  }

  /**
   * Get geofence breach history for a task
   */
  async getGeofenceBreaches(taskId) {
    try {
      const result = await db.query(
        `SELECT 
         gb.*,
         g.name as geofence_name,
         g.geofence_type
         FROM geofence_breaches gb
         JOIN geofences g ON gb.geofence_id = g.id
         WHERE gb.task_id = $1
         ORDER BY gb.breach_timestamp DESC`,
        [taskId]
      );
      
      return result.rows;
    } catch (error) {
      logger.error('Get geofence breaches failed:', error);
      throw error;
    }
  }

  /**
   * Update geofence status
   */
  async updateGeofenceStatus(geofenceId, isActive) {
    try {
      const result = await db.query(
        `UPDATE geofences 
         SET is_active = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2
         RETURNING id, name, is_active`,
        [isActive, geofenceId]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Geofence not found');
      }
      
      logger.info(`Geofence ${geofenceId} status updated: ${isActive}`);
      
      return result.rows[0];
    } catch (error) {
      logger.error('Geofence status update failed:', error);
      throw error;
    }
  }

  /**
   * Delete geofence
   */
  async deleteGeofence(geofenceId) {
    try {
      const result = await db.query(
        `DELETE FROM geofences WHERE id = $1 RETURNING id, name`,
        [geofenceId]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Geofence not found');
      }
      
      logger.info(`Geofence deleted: ${geofenceId}`);
      
      return result.rows[0];
    } catch (error) {
      logger.error('Geofence deletion failed:', error);
      throw error;
    }
  }

  /**
   * Send geofence breach alert
   */
  async sendGeofenceAlert(taskId, geofenceId, latitude, longitude) {
    try {
      // Implement notification service integration
      // This would send SMS/push notification to worker and supervisor
      logger.info(`Geofence alert sent for task ${taskId}`);
    } catch (error) {
      logger.error('Failed to send geofence alert:', error);
    }
  }

  /**
   * Calculate geofence coverage area
   */
  async calculateGeofenceArea(geofenceId) {
    try {
      const result = await db.query(
        `SELECT 
         id,
         name,
         ST_Area(geofence_polygon::geography) as area_square_meters
         FROM geofences
         WHERE id = $1`,
        [geofenceId]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Geofence not found');
      }
      
      const area = parseFloat(result.rows[0].area_square_meters);
      
      return {
        geofenceId: result.rows[0].id,
        name: result.rows[0].name,
        areaSquareMeters: Math.round(area),
        areaSquareKilometers: (area / 1000000).toFixed(3)
      };
    } catch (error) {
      logger.error('Geofence area calculation failed:', error);
      throw error;
    }
  }
}

module.exports = new GeofenceService();
