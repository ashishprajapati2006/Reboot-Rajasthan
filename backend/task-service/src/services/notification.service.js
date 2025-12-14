const amqp = require('amqplib');
const logger = require('../utils/logger');

class NotificationService {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.init();
  }

  async init() {
    try {
      const rabbitmqUrl = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
      this.connection = await amqp.connect(rabbitmqUrl);
      this.channel = await this.connection.createChannel();
      
      // Declare exchanges
      await this.channel.assertExchange('notifications', 'topic', { durable: true });
      
      logger.info('Notification service initialized');
    } catch (error) {
      logger.error('Failed to initialize notification service:', error);
    }
  }

  async sendWorkerNotification(workerId, message, type, metadata = {}) {
    try {
      if (!this.channel) {
        await this.init();
      }
      
      const notification = {
        userId: workerId,
        message,
        type,
        metadata,
        timestamp: new Date().toISOString()
      };
      
      this.channel.publish(
        'notifications',
        `worker.${type.toLowerCase()}`,
        Buffer.from(JSON.stringify(notification)),
        { persistent: true }
      );
      
      logger.info(`Notification sent to worker ${workerId}: ${type}`);
    } catch (error) {
      logger.error('Failed to send worker notification:', error);
    }
  }

  async sendVotingNotification(userId, taskId, message) {
    try {
      if (!this.channel) {
        await this.init();
      }
      
      const notification = {
        userId,
        taskId,
        message,
        type: 'VOTING_REQUEST',
        timestamp: new Date().toISOString()
      };
      
      this.channel.publish(
        'notifications',
        'citizen.voting',
        Buffer.from(JSON.stringify(notification)),
        { persistent: true }
      );
    } catch (error) {
      logger.error('Failed to send voting notification:', error);
    }
  }
}

module.exports = new NotificationService();
