/**
 * Email Verification Routes
 * 
 * Endpoints for email verification functionality
 */

const express = require('express');
const router = express.Router();
const { query, validationResult } = require('express-validator');
const emailVerificationService = require('../services/emailVerificationService');
const logger = require('../utils/logger');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

/**
 * POST /api/v1/auth/send-verification-email
 * Send verification email to user's email address
 */
router.post('/send-verification-email', [
  query('email').isEmail().withMessage('Valid email is required')
], validate, async (req, res) => {
  try {
    const { email } = req.query;
    const frontendUrl = req.body.frontendUrl || process.env.FRONTEND_URL || 'http://localhost:3000';

    const result = await emailVerificationService.sendVerificationEmail(
      { email },
      frontendUrl
    );

    // In development, return the verification link
    if (result.devLink) {
      return res.json({
        success: true,
        message: result.message,
        devLink: result.devLink,
        note: 'This link is only visible in development mode'
      });
    }

    res.json({
      success: true,
      message: 'Verification email sent successfully'
    });
  } catch (error) {
    logger.error('Send verification email error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/auth/verify-email
 * Verify email with token
 */
router.get('/verify-email', [
  query('email').isEmail().withMessage('Valid email is required'),
  query('token').notEmpty().withMessage('Verification token is required')
], validate, async (req, res) => {
  try {
    const { email, token } = req.query;

    const result = await emailVerificationService.verifyEmail(email, token);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: result.error
      });
    }

    res.json({
      success: true,
      message: result.message,
      user: result.user
    });
  } catch (error) {
    logger.error('Verify email error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/resend-verification-email
 * Resend verification email
 */
router.post('/resend-verification-email', [
  query('email').isEmail().withMessage('Valid email is required')
], validate, async (req, res) => {
  try {
    const { email } = req.query;
    const frontendUrl = req.body.frontendUrl || process.env.FRONTEND_URL || 'http://localhost:3000';

    const result = await emailVerificationService.resendVerificationEmail(email, frontendUrl);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: result.error
      });
    }

    // In development, return the verification link
    if (result.devLink) {
      return res.json({
        success: true,
        message: result.message,
        devLink: result.devLink,
        note: 'This link is only visible in development mode'
      });
    }

    res.json({
      success: true,
      message: 'Verification email sent successfully'
    });
  } catch (error) {
    logger.error('Resend verification email error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/auth/check-email-verification
 * Check if email is verified
 */
router.get('/check-email-verification', [
  query('email').isEmail().withMessage('Valid email is required')
], validate, async (req, res) => {
  try {
    const { email } = req.query;

    const result = await emailVerificationService.isEmailVerified(email);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: result.error
      });
    }

    res.json({
      success: true,
      isVerified: result.isVerified
    });
  } catch (error) {
    logger.error('Check email verification error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
