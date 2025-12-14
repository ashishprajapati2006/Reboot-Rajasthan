const twilio = require('twilio');
const logger = require('../utils/logger');

// Initialize Twilio client
let twilioClient = null;

if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  twilioClient = twilio(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN
  );
  logger.info('Twilio client initialized successfully');
} else {
  logger.warn('Twilio credentials not found. OTP sending will be disabled.');
}

module.exports = twilioClient;
