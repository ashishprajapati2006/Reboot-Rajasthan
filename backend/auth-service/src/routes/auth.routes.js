const express = require('express');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const authService = require('../services/auth.service');
const authMiddleware = require('../middleware/auth.middleware');
const logger = require('../utils/logger');

const router = express.Router();

// Rate limiter for login attempts (5 attempts per 15 minutes)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: 'Too many login attempts, please try again after 15 minutes',
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for OTP requests (3 attempts per 5 minutes)
const otpLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 3,
  message: 'Too many OTP requests, please try again after 5 minutes',
  standardHeaders: true,
  legacyHeaders: false,
});

// Validation middleware
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }
  next();
};

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post(
  '/register',
  [
    body('phoneNumber')
      .matches(/^\+?[1-9]\d{1,14}$/)
      .withMessage('Invalid phone number format'),
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Invalid email address'),
    body('fullName')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .withMessage('Password must contain uppercase, lowercase, number, and special character'),
    body('role')
      .optional()
      .isIn(['CITIZEN', 'WORKER', 'AUTHORITY'])
      .withMessage('Invalid role')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { phoneNumber, email, fullName, password, role } = req.body;

      const result = await authService.registerUser(
        phoneNumber,
        email,
        fullName,
        password,
        role
      );

      res.status(201).json({
        success: true,
        message: 'User registered successfully. Please verify your phone number.',
        data: result
      });
    } catch (error) {
      logger.error(`Registration error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/request-otp
 * @desc    Request OTP for phone verification
 * @access  Public
 */
router.post(
  '/request-otp',
  otpLimiter,
  [
    body('phoneNumber')
      .matches(/^\+?[1-9]\d{1,14}$/)
      .withMessage('Invalid phone number format')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { phoneNumber } = req.body;

      await authService.sendOTP(phoneNumber);

      res.status(200).json({
        success: true,
        message: 'OTP sent successfully'
      });
    } catch (error) {
      logger.error(`OTP request error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/verify-otp
 * @desc    Verify OTP code
 * @access  Public
 */
router.post(
  '/verify-otp',
  [
    body('phoneNumber')
      .matches(/^\+?[1-9]\d{1,14}$/)
      .withMessage('Invalid phone number format'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('OTP must be 6 digits')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { phoneNumber, otp } = req.body;

      await authService.verifyOTP(phoneNumber, otp);

      res.status(200).json({
        success: true,
        message: 'Phone number verified successfully'
      });
    } catch (error) {
      logger.error(`OTP verification error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post(
  '/login',
  loginLimiter,
  [
    body('phoneNumber')
      .matches(/^\+?[1-9]\d{1,14}$/)
      .withMessage('Invalid phone number format'),
    body('password')
      .notEmpty()
      .withMessage('Password is required')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { phoneNumber, password } = req.body;

      const result = await authService.login(phoneNumber, password);

      res.status(200).json({
        success: true,
        message: result.requires2FA ? result.message : 'Login successful',
        data: result
      });
    } catch (error) {
      logger.error(`Login error: ${error.message}`);
      res.status(401).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/verify-2fa
 * @desc    Verify 2FA token during login
 * @access  Public
 */
router.post(
  '/verify-2fa',
  [
    body('tempToken')
      .notEmpty()
      .withMessage('Temporary token is required'),
    body('token')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('2FA token must be 6 digits')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { tempToken, token } = req.body;

      const result = await authService.verify2FAToken(tempToken, token);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: result
      });
    } catch (error) {
      logger.error(`2FA verification error: ${error.message}`);
      res.status(401).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/refresh-token
 * @desc    Refresh access token
 * @access  Public
 */
router.post(
  '/refresh-token',
  [
    body('refreshToken')
      .notEmpty()
      .withMessage('Refresh token is required')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { refreshToken } = req.body;

      const result = await authService.refreshAccessToken(refreshToken);

      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: result
      });
    } catch (error) {
      logger.error(`Token refresh error: ${error.message}`);
      res.status(401).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/setup-2fa
 * @desc    Setup 2FA for user account
 * @access  Private
 */
router.post(
  '/setup-2fa',
  authMiddleware,
  async (req, res) => {
    try {
      const userId = req.user.userId;

      const result = await authService.setup2FA(userId);

      res.status(200).json({
        success: true,
        message: '2FA setup initiated. Scan QR code with authenticator app.',
        data: result
      });
    } catch (error) {
      logger.error(`2FA setup error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/confirm-2fa
 * @desc    Confirm 2FA setup with verification token
 * @access  Private
 */
router.post(
  '/confirm-2fa',
  authMiddleware,
  [
    body('token')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('2FA token must be 6 digits')
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const userId = req.user.userId;
      const { token } = req.body;

      await authService.confirm2FA(userId, token);

      res.status(200).json({
        success: true,
        message: '2FA enabled successfully'
      });
    } catch (error) {
      logger.error(`2FA confirmation error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout user and invalidate tokens
 * @access  Private
 */
router.post(
  '/logout',
  authMiddleware,
  async (req, res) => {
    try {
      const userId = req.user.userId;

      await authService.logout(userId);

      res.status(200).json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      logger.error(`Logout error: ${error.message}`);
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
);

module.exports = router;
