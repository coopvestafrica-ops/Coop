/**
 * Models Index
 * 
 * Export all models from a single entry point
 */

const Referral = require('./Referral');
const User = require('./User');
const AuditLog = require('./AuditLog');
const LoanQR = require('./LoanQR');

module.exports = {
  Referral,
  User,
  AuditLog,
  LoanQR
};