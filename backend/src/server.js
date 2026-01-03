/**
 * Coopvest Africa - Referral System Backend API
 * 
 * Main entry point for the Express server with WebSocket support
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const http = require('http');
const connectDB = require('./config/database');
const logger = require('./utils/logger');

// Import services
const websocketService = require('./services/websocketService');

// Import routes
const authRoutes = require('./routes/auth');
const emailVerificationRoutes = require('./routes/emailVerification');
const referralRoutes = require('./routes/referrals');
const adminRoutes = require('./routes/admin');
const loanRoutes = require('./routes/loans');

// Import error handler
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 8080;

// Create HTTP server
const server = http.createServer(app);

// Connect to MongoDB
connectDB();

// Initialize WebSocket server
websocketService.initialize(server);

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    error: 'Too many requests, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api/', limiter);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
  app.use(morgan('combined', {
    stream: { write: message => logger.info(message.trim()) }
  }));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Coopvest API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// WebSocket stats endpoint
app.get('/ws/stats', (req, res) => {
  const stats = websocketService.getStats();
  res.json({
    success: true,
    websocket: stats
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/auth', emailVerificationRoutes);
app.use('/api/v1/referrals', referralRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/loans', loanRoutes);

// 404 handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Error handler
app.use(errorHandler);

// Start server
server.listen(PORT, () => {
  logger.info(`🚀 Coopvest Referral API running on port ${PORT}`);
  logger.info(`🌐 WebSocket endpoint: ws://localhost:${PORT}/ws`);
  logger.info(`📡 Health check: http://localhost:${PORT}/health`);
  logger.info(`📊 WebSocket stats: http://localhost:${PORT}/ws/stats`);
  logger.info(`📁 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  server.close(() => {
    process.exit(1);
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received. Shutting down gracefully...');
  websocketService.shutdown();
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

module.exports = app;
