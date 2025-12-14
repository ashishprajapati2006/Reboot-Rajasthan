const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');
const redisClient = require('../config/redis');
const twilioClient = require('../config/twilio');
const logger = require('../utils/logger');

class AuthService {
  /**
   * Register a new user with phone number, email, and password
   * @param {string} phoneNumber - User's phone number
   * @param {string} email - User's email address
   * @param {string} fullName - User's full name
   * @param {string} password - User's password
   * @param {string} role - User role (CITIZEN, WORKER, AUTHORITY)
   * @returns {Promise<Object>} - User data with JWT tokens
   */
  async registerUser(phoneNumber, email, fullName, password, role = 'CITIZEN') {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      // Check if user already exists
      const existingUser = await client.query(
        'SELECT id FROM users WHERE phone_number = $1 OR email = $2',
        [phoneNumber, email]
      );

      if (existingUser.rows.length > 0) {
        throw new Error('User with this phone number or email already exists');
      }

      // Hash password
      const saltRounds = 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Generate user ID
      const userId = uuidv4();

      // Insert user into database
      const result = await client.query(
        `INSERT INTO users 
        (id, phone_number, email, full_name, password_hash, role, is_verified, created_at) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) 
        RETURNING id, phone_number, email, full_name, role, is_verified, created_at`,
        [userId, phoneNumber, email, fullName, hashedPassword, role, false]
      );

      await client.query('COMMIT');

      const user = result.rows[0];

      // Generate OTP and send
      await this.sendOTP(phoneNumber);

      // Generate tokens
      const tokens = await this.generateTokens(user.id, user.role);

      logger.info(`User registered successfully: ${userId}`);

      return {
        user: {
          id: user.id,
          phoneNumber: user.phone_number,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          isVerified: user.is_verified,
          createdAt: user.created_at
        },
        ...tokens
      };
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error(`Registration error: ${error.message}`);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Send OTP to user's phone number
   * @param {string} phoneNumber - User's phone number
   * @returns {Promise<boolean>} - Success status
   */
  async sendOTP(phoneNumber) {
    try {
      // Generate 6-digit OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // Store OTP in Redis with 5-minute expiry
      const otpKey = `otp:${phoneNumber}`;
      await redisClient.setEx(otpKey, 300, otp);

      // Send OTP via Twilio
      if (process.env.NODE_ENV === 'production') {
        await twilioClient.messages.create({
          body: `Your SAAF-SURKSHA verification code is: ${otp}. Valid for 5 minutes.`,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phoneNumber
        });
      } else {
        // In development, log OTP to console
        logger.info(`OTP for ${phoneNumber}: ${otp}`);
      }

      logger.info(`OTP sent to ${phoneNumber}`);
      return true;
    } catch (error) {
      logger.error(`Error sending OTP: ${error.message}`);
      throw new Error('Failed to send OTP');
    }
  }

  /**
   * Verify OTP code
   * @param {string} phoneNumber - User's phone number
   * @param {string} otp - OTP code to verify
   * @returns {Promise<boolean>} - Verification result
   */
  async verifyOTP(phoneNumber, otp) {
    try {
      const otpKey = `otp:${phoneNumber}`;
      const storedOTP = await redisClient.get(otpKey);

      if (!storedOTP) {
        throw new Error('OTP expired or not found');
      }

      if (storedOTP !== otp) {
        throw new Error('Invalid OTP');
      }

      // Mark user as verified
      await pool.query(
        'UPDATE users SET is_verified = true WHERE phone_number = $1',
        [phoneNumber]
      );

      // Delete OTP from Redis
      await redisClient.del(otpKey);

      logger.info(`OTP verified for ${phoneNumber}`);
      return true;
    } catch (error) {
      logger.error(`OTP verification error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Login user with phone number and password
   * @param {string} phoneNumber - User's phone number
   * @param {string} password - User's password
   * @returns {Promise<Object>} - User data with tokens
   */
  async login(phoneNumber, password) {
    try {
      // Fetch user from database
      const result = await pool.query(
        `SELECT id, phone_number, email, full_name, password_hash, role, 
        is_verified, two_fa_enabled, two_fa_secret 
        FROM users WHERE phone_number = $1`,
        [phoneNumber]
      );

      if (result.rows.length === 0) {
        throw new Error('Invalid credentials');
      }

      const user = result.rows[0];

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        throw new Error('Invalid credentials');
      }

      // Check if user is verified
      if (!user.is_verified) {
        throw new Error('Please verify your phone number first');
      }

      // If 2FA is enabled, return pending status
      if (user.two_fa_enabled) {
        // Store temporary session for 2FA
        const tempToken = uuidv4();
        await redisClient.setEx(`2fa:${tempToken}`, 300, user.id);
        
        return {
          requires2FA: true,
          tempToken,
          message: 'Please provide 2FA token'
        };
      }

      // Generate tokens
      const tokens = await this.generateTokens(user.id, user.role);

      // Update last login
      await pool.query(
        'UPDATE users SET last_login = NOW() WHERE id = $1',
        [user.id]
      );

      logger.info(`User logged in: ${user.id}`);

      return {
        user: {
          id: user.id,
          phoneNumber: user.phone_number,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          isVerified: user.is_verified,
          twoFAEnabled: user.two_fa_enabled
        },
        ...tokens
      };
    } catch (error) {
      logger.error(`Login error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Generate JWT access and refresh tokens
   * @param {string} userId - User's ID
   * @param {string} userRole - User's role
   * @returns {Promise<Object>} - Access and refresh tokens
   */
  async generateTokens(userId, userRole) {
    try {
      const accessToken = jwt.sign(
        { userId, role: userRole },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRY || '15m' }
      );

      const refreshToken = jwt.sign(
        { userId, role: userRole, type: 'refresh' },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' }
      );

      // Store refresh token in Redis
      const refreshTokenKey = `refresh:${userId}`;
      await redisClient.setEx(refreshTokenKey, 7 * 24 * 60 * 60, refreshToken);

      return {
        accessToken,
        refreshToken,
        expiresIn: process.env.JWT_EXPIRY || '15m'
      };
    } catch (error) {
      logger.error(`Token generation error: ${error.message}`);
      throw new Error('Failed to generate tokens');
    }
  }

  /**
   * Setup 2FA for user
   * @param {string} userId - User's ID
   * @returns {Promise<Object>} - QR code and secret
   */
  async setup2FA(userId) {
    try {
      // Fetch user
      const result = await pool.query(
        'SELECT email, full_name FROM users WHERE id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      const user = result.rows[0];

      // Generate secret
      const secret = speakeasy.generateSecret({
        name: `${process.env.TWO_FA_ISSUER || 'SAAF-SURKSHA'} (${user.email})`,
        issuer: process.env.TWO_FA_ISSUER || 'SAAF-SURKSHA'
      });

      // Store temporary secret in Redis (valid for 10 minutes)
      await redisClient.setEx(`2fa-setup:${userId}`, 600, secret.base32);

      // Generate QR code
      const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

      logger.info(`2FA setup initiated for user: ${userId}`);

      return {
        secret: secret.base32,
        qrCode: qrCodeUrl,
        manualEntryKey: secret.base32
      };
    } catch (error) {
      logger.error(`2FA setup error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Verify and confirm 2FA setup
   * @param {string} userId - User's ID
   * @param {string} token - 2FA token from authenticator app
   * @returns {Promise<boolean>} - Verification result
   */
  async confirm2FA(userId, token) {
    try {
      // Get temporary secret from Redis
      const secret = await redisClient.get(`2fa-setup:${userId}`);

      if (!secret) {
        throw new Error('2FA setup expired or not found');
      }

      // Verify token
      const isValid = speakeasy.totp.verify({
        secret,
        encoding: 'base32',
        token,
        window: 2
      });

      if (!isValid) {
        throw new Error('Invalid 2FA token');
      }

      // Save secret to database and enable 2FA
      await pool.query(
        'UPDATE users SET two_fa_secret = $1, two_fa_enabled = true WHERE id = $2',
        [secret, userId]
      );

      // Delete temporary secret
      await redisClient.del(`2fa-setup:${userId}`);

      logger.info(`2FA enabled for user: ${userId}`);
      return true;
    } catch (error) {
      logger.error(`2FA confirmation error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Verify 2FA token during login
   * @param {string} tempToken - Temporary token from login
   * @param {string} token - 2FA token from authenticator app
   * @returns {Promise<Object>} - User data with tokens
   */
  async verify2FAToken(tempToken, token) {
    try {
      // Get user ID from temp token
      const userId = await redisClient.get(`2fa:${tempToken}`);

      if (!userId) {
        throw new Error('2FA session expired');
      }

      // Fetch user
      const result = await pool.query(
        `SELECT id, phone_number, email, full_name, role, 
        two_fa_secret FROM users WHERE id = $1`,
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      const user = result.rows[0];

      // Verify 2FA token
      const isValid = speakeasy.totp.verify({
        secret: user.two_fa_secret,
        encoding: 'base32',
        token,
        window: 2
      });

      if (!isValid) {
        throw new Error('Invalid 2FA token');
      }

      // Delete temp session
      await redisClient.del(`2fa:${tempToken}`);

      // Generate tokens
      const tokens = await this.generateTokens(user.id, user.role);

      // Update last login
      await pool.query(
        'UPDATE users SET last_login = NOW() WHERE id = $1',
        [user.id]
      );

      logger.info(`User logged in with 2FA: ${user.id}`);

      return {
        user: {
          id: user.id,
          phoneNumber: user.phone_number,
          email: user.email,
          fullName: user.full_name,
          role: user.role
        },
        ...tokens
      };
    } catch (error) {
      logger.error(`2FA verification error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Refresh access token using refresh token
   * @param {string} refreshToken - Refresh token
   * @returns {Promise<Object>} - New access token
   */
  async refreshAccessToken(refreshToken) {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

      if (decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }

      // Check if refresh token exists in Redis
      const storedToken = await redisClient.get(`refresh:${decoded.userId}`);

      if (storedToken !== refreshToken) {
        throw new Error('Invalid refresh token');
      }

      // Generate new access token
      const accessToken = jwt.sign(
        { userId: decoded.userId, role: decoded.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRY || '15m' }
      );

      return {
        accessToken,
        expiresIn: process.env.JWT_EXPIRY || '15m'
      };
    } catch (error) {
      logger.error(`Token refresh error: ${error.message}`);
      throw new Error('Invalid or expired refresh token');
    }
  }

  /**
   * Logout user and invalidate tokens
   * @param {string} userId - User's ID
   * @returns {Promise<boolean>} - Success status
   */
  async logout(userId) {
    try {
      // Delete refresh token from Redis
      await redisClient.del(`refresh:${userId}`);

      logger.info(`User logged out: ${userId}`);
      return true;
    } catch (error) {
      logger.error(`Logout error: ${error.message}`);
      throw error;
    }
  }
}

module.exports = new AuthService();
