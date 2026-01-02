/**
 * Loans Routes (Placeholder)
 * 
 * Loan-related endpoints with referral bonus integration and WebSocket support
 */

const express = require('express');
const router = express.Router();
const { body, param, query, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const { User, Referral, AuditLog, LoanQR } = require('../models');
const referralService = require('../services/referralService');
const qrCodeService = require('../services/qrCodeService');
const websocketService = require('../services/websocketService');
const logger = require('../utils/logger');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

/**
 * POST /api/v1/loans/apply
 * Apply for a loan with optional referral bonus
 */
router.post('/apply', [
  body('loanType').notEmpty(),
  body('loanAmount').isNumeric(),
  body('tenureMonths').isInt({ min: 1 }),
  body('purpose').notEmpty()
], validate, async (req, res) => {
  try {
    const { loanType, loanAmount, tenureMonths, purpose } = req.body;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // Get user's referral bonus
    let bonusResult = null;
    try {
      bonusResult = await referralService.applyBonusToLoan(userId, null, loanType);
    } catch (e) {
      // No bonus available
    }

    // Calculate interest with bonus
    const bonusPercent = bonusResult?.bonusPercent || 0;
    const calculation = referralService.calculateInterestWithBonus(
      loanType,
      loanAmount,
      tenureMonths,
      bonusPercent
    );

    // Generate loan ID
    const loanId = `LOAN-${uuidv4().substring(0, 8).toUpperCase()}`;

    // In production, save loan to database
    const loan = {
      loanId,
      userId,
      loanType,
      amount: loanAmount,
      tenureMonths,
      purpose,
      baseInterestRate: calculation.baseInterestRate,
      referralBonusPercent: bonusPercent,
      effectiveInterestRate: calculation.effectiveInterestRate,
      monthlyRepayment: calculation.monthlyRepaymentAfterBonus,
      totalRepayment: calculation.monthlyRepaymentAfterBonus * tenureMonths,
      savingsFromBonus: calculation.totalSavingsFromBonus,
      status: 'pending',
      createdAt: new Date()
    };

    // Log the application
    if (bonusResult?.success) {
      await AuditLog.log({
        action: 'LOAN_APPLIED_WITH_BONUS',
        userId,
        loanId,
        details: `Loan applied with ${bonusPercent}% referral bonus. Savings: ₦${calculation.totalSavingsFromBonus.toFixed(2)}`
      });
    }

    res.status(201).json({
      success: true,
      loan,
      calculation,
      bonusApplied: bonusResult?.success || false,
      message: bonusResult?.success 
        ? `Loan application submitted with ${bonusPercent}% referral discount!`
        : 'Loan application submitted'
    });
  } catch (error) {
    logger.error('Loan application error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/loans/:loanId/generate-qr
 * Generate QR code for loan guarantor request
 * Creates a signed, time-limited QR code with full loan details
 */
router.post('/:loanId/generate-qr', [
  param('loanId').notEmpty(),
  body('applicantName').notEmpty(),
  body('applicantPhone').notEmpty(),
  body('loanAmount').isNumeric(),
  body('loanTenure').isInt({ min: 1, max: 60 }),
  body('interestRate').isNumeric(),
  body('monthlyRepayment').isNumeric(),
  body('totalRepayment').isNumeric(),
  body('purpose').notEmpty()
], validate, async (req, res) => {
  try {
    const { loanId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const {
      applicantName,
      applicantPhone,
      loanAmount,
      loanTenure,
      interestRate,
      monthlyRepayment,
      totalRepayment,
      purpose,
      options
    } = req.body;

    // Validate loan belongs to user (in production)
    // const loan = await Loan.findOne({ loanId, userId });
    // if (!loan) {
    //   return res.status(404).json({
    //     success: false,
    //     error: 'Loan not found'
    //   });
    // }

    // Generate loan QR code
    const qrResult = await qrCodeService.generateLoanQRCode({
      loanId,
      applicantId: userId,
      applicantName,
      applicantPhone,
      loanAmount,
      loanCurrency: 'NGN',
      loanTenure,
      interestRate,
      monthlyRepayment,
      totalRepayment,
      purpose
    }, options);

    // Create QR record
    const loanQR = new LoanQR({
      qrId: qrResult.qrData.qrId,
      loanId,
      applicantId: userId,
      applicantName,
      applicantPhone,
      loanAmount,
      loanCurrency: 'NGN',
      loanTenure,
      interestRate,
      monthlyRepayment,
      totalRepayment,
      purpose,
      qrData: qrResult.qrData,
      qrCode: qrResult.qrCode,
      signature: qrResult.qrData.signature,
      createdBy: userId
    });

    // In production, save to database:
    // await LoanQR.create(loanQR.toStorage());

    // Log the QR generation
    await AuditLog.log({
      action: 'LOAN_QR_GENERATED',
      userId,
      loanId,
      qrId: qrResult.qrData.qrId,
      details: `Generated guarantor QR for loan ${loanId}`
    });

    res.status(201).json({
      success: true,
      message: qrResult.message,
      qr: {
        id: qrResult.qrData.qrId,
        loanId: loanId,
        expiresAt: qrResult.qrData.expiresAt,
        qrCode: qrResult.qrCode,
        data: qrResult.qrData
      },
      progress: {
        found: 0,
        required: 3,
        percentage: 0
      }
    });
  } catch (error) {
    logger.error('QR generation error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/:loanId/qr
 * Get QR code details for a loan
 */
router.get('/:loanId/qr', [
  param('loanId').notEmpty()
], validate, async (req, res) => {
  try {
    const { loanId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // In production, fetch from database:
    // const loanQR = await LoanQR.findOne({ loanId, applicantId: userId });
    
    // Mock response for demo
    const mockQR = {
      qrId: `QR_${Date.now()}_mock`,
      loanId,
      applicantName: 'John Doe',
      applicantPhone: '+2348012345678',
      loanAmount: 500000,
      loanCurrency: 'NGN',
      loanTenure: 12,
      interestRate: 10,
      monthlyRepayment: 45833,
      totalRepayment: 550000,
      purpose: 'Business expansion',
      status: 'active',
      scanCount: 5,
      guarantorsFound: 2,
      guarantorsRequired: 3,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      createdAt: new Date()
    };

    res.json({
      success: true,
      qr: mockQR,
      progress: {
        found: mockQR.guarantorsFound,
        required: mockQR.guarantorsRequired,
        percentage: Math.round((mockQR.guarantorsFound / mockQR.guarantorsRequired) * 100),
        remaining: mockQR.guarantorsRequired - mockQR.guarantorsFound
      }
    });
  } catch (error) {
    logger.error('Error getting QR:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/loans/validate-qr
 * Validate a loan QR code (for scanning app)
 */
router.post('/validate-qr', [
  body('qrData').isObject()
], validate, async (req, res) => {
  try {
    const { qrData } = req.body;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    // Validate the QR code
    const validation = qrCodeService.validateLoanQRData(qrData);

    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        error: validation.error,
        valid: false
      });
    }

    // Log the validation
    if (userId) {
      await AuditLog.log({
        action: 'LOAN_QR_VALIDATED',
        userId,
        loanId: validation.loanId,
        details: `Validated QR for loan ${validation.loanId}`
      });
    }

    res.json({
      success: true,
      valid: true,
      loan: {
        loanId: validation.loanId,
        applicantName: validation.applicantName,
        applicantPhone: validation.applicantPhone,
        loanAmount: validation.loanAmount,
        loanTenure: validation.loanTenure,
        interestRate: validation.interestRate,
        monthlyRepayment: validation.monthlyRepayment,
        totalRepayment: validation.totalRepayment,
        purpose: validation.purpose,
        expiresAt: validation.expiresAt
      }
    });
  } catch (error) {
    logger.error('QR validation error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/qr-stats
 * Get QR code service statistics
 */
router.get('/qr-stats', async (req, res) => {
  try {
    const stats = qrCodeService.getLoanQRStats();
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    logger.error('Error getting QR stats:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/qr-codes
 * List all QR codes for the authenticated user
 * Query params: status (active, expired, all), page, limit
 */
router.get('/qr-codes', [
  query('status').optional().isIn(['active', 'expired', 'all']),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], validate, async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.user?.userId;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const status = req.query.status || 'all';
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // In production, query from database:
    // const filter = { applicantId: userId };
    // if (status !== 'all') filter.status = status;
    // const qrCodes = await LoanQR.find(filter).skip(skip).limit(limit);
    // const total = await LoanQR.countDocuments(filter);

    // Mock response for demo
    const mockQRCodes = [
      {
        qrId: 'QR_001',
        loanId: 'LOAN-ABC123',
        applicantName: 'John Doe',
        loanAmount: 500000,
        loanCurrency: 'NGN',
        loanTenure: 12,
        interestRate: 10,
        monthlyRepayment: 45833,
        totalRepayment: 550000,
        purpose: 'Business expansion',
        status: 'active',
        scanCount: 5,
        guarantorsFound: 2,
        guarantorsRequired: 3,
        expiresAt: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
      },
      {
        qrId: 'QR_002',
        loanId: 'LOAN-DEF456',
        applicantName: 'John Doe',
        loanAmount: 250000,
        loanCurrency: 'NGN',
        loanTenure: 6,
        interestRate: 8,
        monthlyRepayment: 44167,
        totalRepayment: 265000,
        purpose: 'Equipment purchase',
        status: 'active',
        scanCount: 3,
        guarantorsFound: 3,
        guarantorsRequired: 3,
        expiresAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        createdAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000)
      },
      {
        qrId: 'QR_003',
        loanId: 'LOAN-GHI789',
        applicantName: 'John Doe',
        loanAmount: 100000,
        loanCurrency: 'NGN',
        loanTenure: 3,
        interestRate: 7.5,
        monthlyRepayment: 34500,
        totalRepayment: 103500,
        purpose: 'Emergency funds',
        status: 'expired',
        scanCount: 1,
        guarantorsFound: 0,
        guarantorsRequired: 3,
        expiresAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)
      }
    ];

    // Filter by status if not 'all'
    let filteredQRCodes = mockQRCodes;
    if (status !== 'all') {
      filteredQRCodes = mockQRCodes.filter(qr => qr.status === status);
    }

    // Apply pagination
    const paginatedQRCodes = filteredQRCodes.slice(skip, skip + limit);
    const total = filteredQRCodes.length;

    // Add progress to each QR code
    const qrCodesWithProgress = paginatedQRCodes.map(qr => ({
      ...qr,
      progress: {
        found: qr.guarantorsFound,
        required: qr.guarantorsRequired,
        percentage: Math.round((qr.guarantorsFound / qr.guarantorsRequired) * 100),
        remaining: qr.guarantorsRequired - qr.guarantorsFound
      },
      isExpired: new Date() > new Date(qr.expiresAt)
    }));

    res.json({
      success: true,
      qrCodes: qrCodesWithProgress,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasMore: skip + limit < total
      }
    });
  } catch (error) {
    logger.error('Error listing QR codes:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/qr-codes/:qrId
 * Get detailed view of a specific QR code
 */
router.get('/qr-codes/:qrId', [
  param('qrId').notEmpty()
], validate, async (req, res) => {
  try {
    const { qrId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // In production, fetch from database:
    // const loanQR = await LoanQR.findOne({ qrId, applicantId: userId });

    // Mock response
    const mockQR = {
      qrId,
      loanId: 'LOAN-ABC123',
      applicantId: userId,
      applicantName: 'John Doe',
      applicantPhone: '+2348012345678',
      loanAmount: 500000,
      loanCurrency: 'NGN',
      loanTenure: 12,
      interestRate: 10,
      monthlyRepayment: 45833,
      totalRepayment: 550000,
      purpose: 'Business expansion',
      status: 'active',
      scanCount: 5,
      guarantorsFound: 2,
      guarantorsRequired: 3,
      signature: 'mock_signature_for_demo',
      expiresAt: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
      scans: [
        {
          scanId: 'scan_001',
          scannedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
          scannerName: 'Jane Smith',
          action: 'viewed',
          deviceId: 'device_001'
        },
        {
          scanId: 'scan_002',
          scannedAt: new Date(Date.now() - 0.5 * 24 * 60 * 60 * 1000),
          scannerName: 'Mike Johnson',
          action: 'approved',
          deviceId: 'device_002'
        }
      ]
    };

    res.json({
      success: true,
      qr: {
        ...mockQR,
        progress: {
          found: mockQR.guarantorsFound,
          required: mockQR.guarantorsRequired,
          percentage: Math.round((mockQR.guarantorsFound / mockQR.guarantorsRequired) * 100),
          remaining: mockQR.guarantorsRequired - mockQR.guarantorsFound
        },
        isExpired: new Date() > new Date(mockQR.expiresAt)
      },
      auditTrail: mockQR.scans.map(scan => ({
        action: scan.action,
        user: scan.scannerName,
        timestamp: scan.scannedAt,
        device: scan.deviceId
      }))
    });
  } catch (error) {
    logger.error('Error getting QR details:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * DELETE /api/v1/loans/qr-codes/:qrId
 * Invalidate/delete a QR code
 */
router.delete('/qr-codes/:qrId', [
  param('qrId').notEmpty()
], validate, async (req, res) => {
  try {
    const { qrId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // In production, update database:
    // await LoanQR.updateOne({ qrId, applicantId: userId }, { status: 'invalidated' });

    // Log the invalidation
    await AuditLog.log({
      action: 'LOAN_QR_INVALIDATED',
      userId,
      qrId,
      details: `Invalidated QR code ${qrId}`
    });

    res.json({
      success: true,
      message: 'QR code invalidated successfully',
      qrId
    });
  } catch (error) {
    logger.error('Error invalidating QR code:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans
 * Get user's loans
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.user?.userId;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // Mock loan data for demo
    const loans = [
      {
        loanId: 'LOAN-ABC123',
        loanType: 'Quick Loan',
        amount: 50000,
        tenure: 4,
        monthlyRepayment: 13125,
        status: 'active',
        effectiveInterestRate: 7.5,
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      }
    ];

    res.json({
      success: true,
      loans,
      total: loans.length
    });
  } catch (error) {
    logger.error('Error getting loans:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/:loanId
 * Get loan details
 */
router.get('/:loanId', async (req, res) => {
  try {
    const { loanId } = req.params;
    
    // Mock loan detail
    const loan = {
      loanId,
      loanType: 'Quick Loan',
      amount: 50000,
      tenure: 4,
      monthlyRepayment: 13125,
      totalRepayment: 52500,
      paidRepayments: 1,
      remainingRepayments: 3,
      status: 'active',
      effectiveInterestRate: 7.5,
      createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      nextDueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    };

    res.json({
      success: true,
      loan
    });
  } catch (error) {
    logger.error('Error getting loan details:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

// ==================== WEBSOCKET REAL-TIME ENDPOINTS ====================

/**
 * POST /api/v1/loans/:loanId/progress
 * Update loan progress and broadcast to WebSocket subscribers
 */
router.post('/:loanId/progress', [
  param('loanId').notEmpty(),
  body('guarantorsFound').isInt({ min: 0 }),
  body('guarantorsRequired').isInt({ min: 1 }),
  body('guarantors').isArray()
], validate, async (req, res) => {
  try {
    const { loanId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const { guarantorsFound, guarantorsRequired, guarantors } = req.body;

    // Calculate progress
    const progress = {
      guarantorsFound,
      guarantorsRequired,
      percentage: Math.round((guarantorsFound / guarantorsRequired) * 100),
      remaining: guarantorsRequired - guarantorsFound,
      guarantors
    };

    // Broadcast progress update to all WebSocket subscribers
    websocketService.broadcastLoanProgress(loanId, progress);

    // Log the progress update
    await AuditLog.log({
      action: 'LOAN_PROGRESS_UPDATED',
      userId,
      loanId,
      details: `Loan progress updated: ${guarantorsFound}/${guarantorsRequired} guarantors`
    });

    res.json({
      success: true,
      loanId,
      progress,
      message: 'Progress updated and broadcast to subscribers'
    });
  } catch (error) {
    logger.error('Error updating loan progress:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/loans/:loanId/guarantor-action
 * Record a guarantor action and notify loan owner
 */
router.post('/:loanId/guarantor-action', [
  param('loanId').notEmpty(),
  body('action').isIn(['viewed', 'approved', 'declined']),
  body('guarantor').isObject()
], validate, async (req, res) => {
  try {
    const { loanId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const { action, guarantor } = req.body;

    // Notify loan owner via WebSocket
    websocketService.notifyGuarantorAction(loanId, {
      action,
      guarantor: {
        name: guarantor.name,
        phone: guarantor.phone,
        timestamp: new Date().toISOString()
      }
    });

    // Log the action
    await AuditLog.log({
      action: 'GUARANTOR_ACTION',
      userId,
      loanId,
      details: `Guarantor ${guarantor.name} ${action} the loan request`
    });

    res.json({
      success: true,
      loanId,
      action,
      message: `Guarantor action "${action}" recorded and loan owner notified`
    });
  } catch (error) {
    logger.error('Error recording guarantor action:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/:loanId/subscribe
 * Get WebSocket subscription info for a loan
 */
router.get('/:loanId/subscribe', [
  param('loanId').notEmpty()
], validate, async (req, res) => {
  try {
    const { loanId } = req.params;
    const userId = req.headers['x-user-id'] || req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // Get WebSocket stats for this loan
    const stats = websocketService.getStats();
    
    res.json({
      success: true,
      loanId,
      websocketEndpoint: `ws://localhost:8080/ws`,
      subscriptionInstructions: {
        step1: `Connect to WebSocket at ws://localhost:8080/ws`,
        step2: `Authenticate by sending: { "type": "authenticate", "token": "YOUR_JWT_TOKEN" }`,
        step3: `Subscribe to loan updates: { "type": "subscribe_loan", "loanId": "${loanId}" }`,
        step4: 'Receive real-time progress updates'
      },
      serverStats: stats
    });
  } catch (error) {
    logger.error('Error getting subscription info:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/loans/ws-stats
 * Get WebSocket server statistics
 */
router.get('/ws-stats', async (req, res) => {
  try {
    const stats = websocketService.getStats();
    res.json({
      success: true,
      websocket: stats,
      endpoints: {
        connection: 'ws://localhost:8080/ws',
        stats: 'http://localhost:8080/ws/stats'
      },
      message: 'WebSocket server is running. Connect and authenticate to receive real-time updates.'
    });
  } catch (error) {
    logger.error('Error getting WebSocket stats:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});