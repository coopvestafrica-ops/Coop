/**
 * Email Verification Service
 * 
 * Handles email verification token generation and sending
 */

const nodemailer = require('nodemailer');
const { User } = require('../models');
const logger = require('../utils/logger');

// Create transporter (configure with your email provider)
const createTransporter = () => {
  // For development/testing, use ethereal.email
  // In production, configure with actual SMTP settings
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.ethereal.email',
    port: process.env.SMTP_PORT || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER || 'ethereal_user@ethereal.email',
      pass: process.env.SMTP_PASS || 'ethereal_pass'
    }
  });
};

// Email templates
const getVerificationEmailTemplate = (user, token, frontendUrl) => ({
  subject: 'Verify Your Coopvest Africa Account',
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1B5E20; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .button { display: inline-block; background: #1B5E20; color: white; padding: 14px 28px; 
                  text-decoration: none; border-radius: 6px; font-weight: 600; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .code { background: #e8f5e9; padding: 15px; text-align: center; font-size: 24px; 
                letter-spacing: 4px; font-weight: bold; border-radius: 6px; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Coopvest Africa</h1>
          <p>Verify Your Email Address</p>
        </div>
        <div class="content">
          <p>Hi ${user.name},</p>
          <p>Thank you for registering with Coopvest Africa. To complete your account setup, 
             please verify your email address.</p>
          <p style="text-align: center;">
            <a href="${frontendUrl}/verify-email?token=${token}&email=${user.email}" 
               class="button">Verify Email Address</a>
          </p>
          <p>Or copy and paste this verification link into your browser:</p>
          <p style="word-break: break-all; color: #1B5E20;">${frontendUrl}/verify-email?token=${token}&email=${user.email}</p>
          <p><strong>This link will expire in 24 hours.</strong></p>
          <p>If you didn't create an account with Coopvest Africa, please ignore this email.</p>
        </div>
        <div class="footer">
          <p>&copy; ${new Date().getFullYear()} Coopvest Africa. All rights reserved.</p>
          <p>This is an automated message, please do not reply.</p>
        </div>
      </div>
    </body>
    </html>
  `,
  text: `
    Hi ${user.name},
    
    Thank you for registering with Coopvest Africa. To complete your account setup, 
    please verify your email address.
    
    Click the link below or copy and paste it into your browser:
    ${frontendUrl}/verify-email?token=${token}&email=${user.email}
    
    This link will expire in 24 hours.
    
    If you didn't create an account with Coopvest Africa, please ignore this email.
    
    © ${new Date().getFullYear()} Coopvest Africa. All rights reserved.
  `
});

class EmailVerificationService {
  constructor() {
    this.transporter = null;
  }

  async getTransporter() {
    if (!this.transporter) {
      this.transporter = createTransporter();
    }
    return this.transporter;
  }

  /**
   * Send verification email to user
   */
  async sendVerificationEmail(user, frontendUrl = process.env.FRONTEND_URL) {
    try {
      // Generate verification token
      const token = user.generateEmailVerificationToken();
      await user.save();

      const templates = getVerificationEmailTemplate(user, token, frontendUrl);

      // In development, log the verification link instead of sending
      if (process.env.NODE_ENV === 'development' || !process.env.SMTP_HOST) {
        logger.info('📧 [DEV MODE] Email verification link:', {
          email: user.email,
          verificationLink: `${frontendUrl}/verify-email?token=${token}&email=${user.email}`
        });
        return { 
          success: true, 
          message: 'Verification link generated (development mode)',
          devLink: `${frontendUrl}/verify-email?token=${token}&email=${user.email}`
        };
      }

      const transporter = await this.getTransporter();
      
      await transporter.sendMail({
        from: `"Coopvest Africa" <${process.env.SMTP_FROM || 'noreply@coopvest.com'}>`,
        to: user.email,
        subject: templates.subject,
        html: templates.html,
        text: templates.text
      });

      logger.info(`Verification email sent to: ${user.email}`);
      
      return { 
        success: true, 
        message: 'Verification email sent successfully' 
      };
    } catch (error) {
      logger.error('Failed to send verification email:', error);
      throw error;
    }
  }

  /**
   * Verify email with token
   */
  async verifyEmail(email, token) {
    try {
      const user = await User.findOne({ email: email.toLowerCase() });

      if (!user) {
        return { success: false, error: 'User not found' };
      }

      if (user.emailVerification.isVerified) {
        return { success: false, error: 'Email already verified' };
      }

      if (!user.isEmailVerificationTokenValid(token)) {
        return { success: false, error: 'Invalid or expired verification token' };
      }

      await user.verifyEmail();
      
      logger.info(`Email verified successfully for: ${email}`);
      
      return { 
        success: true, 
        message: 'Email verified successfully',
        user: {
          userId: user.userId,
          email: user.email,
          name: user.name
        }
      };
    } catch (error) {
      logger.error('Email verification failed:', error);
      throw error;
    }
  }

  /**
   * Resend verification email
   */
  async resendVerificationEmail(email, frontendUrl = process.env.FRONTEND_URL) {
    try {
      const user = await User.findOne({ email: email.toLowerCase() });

      if (!user) {
        return { success: false, error: 'User not found' };
      }

      if (user.emailVerification.isVerified) {
        return { success: false, error: 'Email already verified' };
      }

      // Generate new token (overwrites old one)
      const token = user.generateEmailVerificationToken();
      await user.save();

      // Send verification email
      return await this.sendVerificationEmail(user, frontendUrl);
    } catch (error) {
      logger.error('Resend verification email failed:', error);
      throw error;
    }
  }

  /**
   * Check if email is verified
   */
  async isEmailVerified(email) {
    try {
      const user = await User.findOne({ email: email.toLowerCase() });
      if (!user) {
        return { success: false, error: 'User not found' };
      }
      return { 
        success: true, 
        isVerified: user.emailVerification.isVerified 
      };
    } catch (error) {
      logger.error('Check email verification status failed:', error);
      throw error;
    }
  }
}

module.exports = new EmailVerificationService();
