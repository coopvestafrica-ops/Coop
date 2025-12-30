import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/theme_config.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/loan_models.dart';
import '../../../presentation/providers/loan_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../../../presentation/widgets/common/inputs.dart';

/// Guarantor Verification Screen - For guarantors to confirm loan guarantees
class GuarantorVerificationScreen extends StatefulWidget {
  final String loanId;
  final String borrowerName;
  final double loanAmount;
  final String guarantorId;
  final String guarantorName;

  const GuarantorVerificationScreen({
    super.key,
    required this.loanId,
    required this.borrowerName,
    required this.loanAmount,
    required this.guarantorId,
    required this.guarantorName,
  });

  @override
  State<GuarantorVerificationScreen> createState() => _GuarantorVerificationScreenState();
}

class _GuarantorVerificationScreenState extends State<GuarantorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();
  
  String _verificationStatus = ''; // '', 'pending', 'accepted', 'declined'
  bool _isProcessing = false;
  int _guarantorsNeeded = 3;
  int _guarantorsConfirmed = 0;

  // Mock data - in production, this would come from API
  final Map<String, dynamic> _loanDetails = {
    'borrowerName': 'John Doe',
    'loanAmount': 50000.0,
    'monthlyRepayment': 12500.0,
    'duration': 4,
    'purpose': 'Business expansion',
    'interestRate': 7.5,
  };

  Future<void> _confirmGuarantee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _verificationStatus = 'pending';
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final savings = double.tryParse(_savingsController.text) ?? 0;
      final loanAmount = widget.loanAmount;
      final minimumSavings = loanAmount * 0.1;

      // Check if guarantor has sufficient savings
      if (savings >= minimumSavings) {
        setState(() {
          _verificationStatus = 'accepted';
          _guarantorsConfirmed = 1; // This guarantor
          _isProcessing = false;
        });
        
        _showAcceptDialog();
      } else {
        setState(() {
          _verificationStatus = 'declined';
          _isProcessing = false;
        });
        
        _showDeclineDialog();
      }

    } catch (e) {
      setState(() {
        _verificationStatus = 'declined';
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    }
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: CoopvestColors.success),
            SizedBox(width: 8),
            Text('Guarantee Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have successfully confirmed your guarantee for this loan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoopvestColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'IMPORTANT: If the borrower defaults on this loan, you will be responsible for ${(widget.loanAmount / 3).toStringAsFixed(2)} (1/3 of the loan amount).',
                style: CoopvestTypography.bodySmall.copyWith(
                  color: CoopvestColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.cancel, color: CoopvestColors.error),
            SizedBox(width: 8),
            Text('Cannot Confirm Guarantee'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your savings balance (₦${_savingsController.text}) is below the required minimum (₦${(widget.loanAmount * 0.1).toStringAsFixed(2)}) to guarantee this loan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please ensure you have sufficient savings before attempting to guarantee a loan.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoopvestColors.darkGray),
          onPressed: _goBack,
        ),
        title: Text(
          'Guarantee Loan',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Details Card
              AppCard(
                backgroundColor: CoopvestColors.primary.withOpacity(0.05),
                border: Border.all(color: CoopvestColors.primary.withOpacity(0.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: CoopvestColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Loan Details',
                          style: CoopvestTypography.labelLarge.copyWith(
                            color: CoopvestColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Borrower:', widget.borrowerName),
                    _buildDetailRow('Loan Amount:', '₦${widget.loanAmount.toStringAsFixed(2)}'),
                    _buildDetailRow('Purpose:', _loanDetails['purpose'] as String),
                    _buildDetailRow('Monthly Repayment:', '₦${_loanDetails['monthlyRepayment'].toStringAsFixed(2)}'),
                    _buildDetailRow('Duration:', '${_loanDetails['duration']} months'),
                    _buildDetailRow('Interest:', '${_loanDetails['interestRate']}%'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Warning Card
              AppCard(
                backgroundColor: CoopvestColors.warning.withOpacity(0.1),
                border: Border.all(color: CoopvestColors.warning.withOpacity(0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: CoopvestColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Responsibility Notice',
                          style: CoopvestTypography.labelLarge.copyWith(
                            color: CoopvestColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By confirming this guarantee, you are agreeing to be responsible for ${(widget.loanAmount / 3).toStringAsFixed(2)} (1/3 of the total loan amount) if the borrower defaults on their payments.',
                      style: CoopvestTypography.bodyMedium.copyWith(
                        color: CoopvestColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Verification Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Your Information
                    Text(
                      'Your Information',
                      style: CoopvestTypography.titleMedium.copyWith(
                        color: CoopvestColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guarantor Name (Read-only)
                    AppTextField(
                      label: 'Your Name',
                      initialValue: widget.guarantorName,
                      enabled: false,
                      filledColor: CoopvestColors.veryLightGray,
                    ),

                    const SizedBox(height: 16),

                    // Phone Number
                    AppTextField(
                      label: 'Phone Number *',
                      hint: 'Enter your phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixText: '+234 ',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Current Savings Balance
                    AppTextField(
                      label: 'Current Savings Balance (₦) *',
                      hint: 'Minimum ${(widget.loanAmount * 0.1).toStringAsFixed(2)} required',
                      controller: _savingsController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      prefixText: '₦ ',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Savings balance is required';
                        }
                        final savings = double.tryParse(value);
                        if (savings == null) {
                          return 'Please enter a valid number';
                        }
                        if (savings < widget.loanAmount * 0.1) {
                          return 'Minimum ₦${(widget.loanAmount * 0.1).toStringAsFixed(2)} required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Button
              _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: CoopvestColors.primary,
                      ),
                    )
                  : Column(
                      children: [
                        PrimaryButton(
                          label: 'Confirm Guarantee',
                          onPressed: _confirmGuarantee,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Decline',
                          onPressed: _goBack,
                          width: double.infinity,
                        ),
                      ],
                    ),

              // Status Display
              if (_verificationStatus.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildStatusDisplay(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CoopvestTypography.bodyMedium.copyWith(
              color: CoopvestColors.mediumGray,
            ),
          ),
          Text(
            value,
            style: CoopvestTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: CoopvestColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    final isAccepted = _verificationStatus == 'accepted';
    final isDeclined = _verificationStatus == 'declined';

    return AppCard(
      backgroundColor: isAccepted 
          ? CoopvestColors.success.withOpacity(0.1)
          : CoopvestColors.error.withOpacity(0.1),
      border: Border.all(
        color: isAccepted ? CoopvestColors.success : CoopvestColors.error,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: isAccepted ? CoopvestColors.success : CoopvestColors.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAccepted 
                      ? 'Your guarantee has been confirmed!' 
                      : 'Could not confirm guarantee',
                  style: CoopvestTypography.titleMedium.copyWith(
                    color: isAccepted ? CoopvestColors.success : CoopvestColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Thank you for supporting your fellow member. You will be notified if the borrower defaults on their payments.',
              style: CoopvestTypography.bodyMedium.copyWith(
                color: CoopvestColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
