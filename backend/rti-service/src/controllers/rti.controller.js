const RTIService = require('../services/rti.service');
const logger = require('../utils/logger');

class RTIController {
  async generateDraft(req, res) {
    try {
      const { complaintId, authorityName } = req.body;
      
      const rtiDraft = await RTIService.generateRTIDraft(complaintId, authorityName);
      
      res.status(201).json({
        success: true,
        data: rtiDraft,
        message: 'RTI draft generated successfully'
      });
    } catch (error) {
      logger.error('Generate RTI draft error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async fileRTI(req, res) {
    try {
      const { rtiId } = req.params;
      const { emailTo } = req.body;
      
      const result = await RTIService.fileRTI(rtiId, emailTo);
      
      res.json({
        success: true,
        data: result,
        message: 'RTI filed successfully'
      });
    } catch (error) {
      logger.error('File RTI error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async socialMediaEscalate(req, res) {
    try {
      const { complaintId, includePhoto } = req.body;
      
      const result = await RTIService.escalateOnSocialMedia(complaintId, includePhoto);
      
      res.json({
        success: true,
        data: result,
        message: 'Issue escalated on social media'
      });
    } catch (error) {
      logger.error('Social media escalation error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async monitorSLA(req, res) {
    try {
      const { complaintId } = req.params;
      
      const slaStatus = await RTIService.monitorSLA(complaintId);
      
      res.json({
        success: true,
        data: slaStatus
      });
    } catch (error) {
      logger.error('Monitor SLA error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async escalateComplaint(req, res) {
    try {
      const { complaintId } = req.params;
      const { escalationLevel } = req.body;
      
      const result = await RTIService.escalateComplaint(complaintId, escalationLevel);
      
      res.json({
        success: true,
        data: result,
        message: `Complaint escalated to level ${escalationLevel}`
      });
    } catch (error) {
      logger.error('Escalate complaint error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getRTIStatus(req, res) {
    try {
      const { rtiId } = req.params;
      
      // Implement get RTI status
      res.json({
        success: true,
        message: 'Get RTI status - to be implemented'
      });
    } catch (error) {
      logger.error('Get RTI status error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  async getEscalationHistory(req, res) {
    try {
      const { complaintId } = req.params;
      
      // Implement get escalation history
      res.json({
        success: true,
        message: 'Get escalation history - to be implemented'
      });
    } catch (error) {
      logger.error('Get escalation history error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
}

module.exports = new RTIController();
