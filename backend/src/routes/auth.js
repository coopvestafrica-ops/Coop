/**
 * Auth Routes (Placeholder)
 * 
 * Authentication endpoints for the referral system
 */

const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const logger = require('../utils/logger');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET || 'default-secret-key',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

/**
 * POST /api/v1/auth/register
 * Register a new user with optional referral code
 */
router.post('/register', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('name').notEmpty().withMessage('Name is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('referralCode').optional().isString()
], validate, async (req, res) => {
  try {
    const { email, phone, name, password, referralCode } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ 
      $or: [{ email }, { phone }] 
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'User with this email or phone already exists'
      });
    }

    // Generate user ID
    const userId = `USR-${Date.now().toString(36).toUpperCase()}`;

    // Create user
    const user = new User({
      userId,
      email,
      phone,
      name,
      password,
      referral: {
        myReferralCode: User.generateReferralCode(userId)
      }
    });

    await user.save();

    // Process referral if code provided
    if (referralCode) {
      try {
        const { referralService } = require('../services/referralService');
        await referralService.registerReferral(referralCode, userId, name);
      } catch (refError) {
        logger.warn('Referral registration failed:', refError.message);
        // Don't fail registration if referral fails
      }
    }

    const token = generateToken(userId);

    res.status(201).json({
      success: true,
      user: {
        userId: user.userId,
        email: user.email,
        name: user.name,
        referralCode: user.referral.myReferralCode
      },
      token,
      message: 'User registered successfully'
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/login
 * Login user
 */
router.post('/login', [
  body('email').isEmail(),
  body('password').notEmpty()
], validate, async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        error: 'Account is deactivated'
      });
    }

    const token = generateToken(user.userId);

    res.json({
      success: true,
      user: {
        userId: user.userId,
        email: user.email,
        name: user.name,
        referralCode: user.referral.myReferralCode,
        kycVerified: user.kyc.verified
      },
      token
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
