import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/theme_config.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/loan_models.dart';
import '../../../presentation/providers/loan_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../../../presentation/widgets/common/inputs.dart';

/// Loan Application Screen with 6 Loan Types and QR-based 3-Guarantor System
class LoanApplicationScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhone;

  const LoanApplicationScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _monthlySavingsController = TextEditingController();

  // Loan Types Configuration
  final Map<String, Map<String, dynamic>> _loanTypes = {
    'Quick Loan': {
      'duration': 4,
      'interest': 7.5,
      'minAmount': 5000,
      'maxAmount': 50000,
      'description': 'Short-term emergency cash for members in urgent need',
    },
    'Flexi Loan': {
      'duration': 6,
      'interest': 7.0,
      'minAmount': 10000,
      'maxAmount': 100000,
      'description': 'Flexible repayment plan for personal or business needs',
    },
    'Stable Loan (12 months)': {
      'duration': 12,
      'interest': 5.0,
      'minAmount': 20000,
      'maxAmount': 200000,
      'description': 'Long-term stability with the lowest interest rate',
    },
    'Stable Loan (18 months)': {
      'duration': 18,
      'interest': 7.0,
      'minAmount': 30000,
      'maxAmount': 300000,
      'description': 'Extended repayment for larger projects or investments',
    },
    'Premium Loan': {
      'duration': 24,
      'interest': 14.0,
      'minAmount': 50000,
      'maxAmount': 500000,
      'description': 'Premium access for established members with higher limits',
    },
    'Maxi Loan': {
      'duration': 36,
      'interest': 19.0,
      'minAmount': 100000,
      'maxAmount': 1000000,
      'description': 'Maximum loan for major investments and business expansion',
    },
  };

  String _selectedLoanType = 'Quick Loan';
  String _loanStatus = '';
  String _loanId = '';
  String? _rejectionReason;
  bool _showQrCode = false;
  bool _isSubmitting = false;

  // Calculate monthly repayment
  double _calculateMonthlyRepayment(double amount, double interestRate, int tenure) {
    final principal = amount;
    final rate = interestRate / 100 / 12;
    final months = tenure;
    
    // EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
    final emi = principal * rate * pow(1 + rate, months) / (pow(1 + rate, months) - 1);
    return emi;
  }

  // Calculate total repayment
  double _calculateTotalRepayment(double amount, double interestRate) {
    return amount + (amount * interestRate / 100);
  }

  String get _formattedLoanId => 'COOP-${_loanId}';

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _loanStatus = 'Processing';
      _rejectionReason = null;
    });

    try {
      final loanInfo = _loanTypes[_selectedLoanType]!;
      final requestedAmount = double.parse(_amountController.text.replaceAll(',', ''));
      final monthlySavings = double.tryParse(_monthlySavingsController.text) ?? 0.0;

      // Validate amount range
      if (requestedAmount < loanInfo['minAmount'] as double) {
        setState(() {
          _loanStatus = 'Rejected';
          _rejectionReason = 'Minimum amount for ${_selectedLoanType} is ₦${loanInfo['minAmount']}';
          _isSubmitting = false;
        });
        return;
      }

      if (requestedAmount > loanInfo['maxAmount'] as double) {
        setState(() {
          _loanStatus = 'Rejected';
          _rejectionReason = 'Maximum amount for ${_selectedLoanType} is ₦${loanInfo['maxAmount']}';
          _isSubmitting = false;
        });
        return;
      }

      // Validate monthly savings (must be at least 10% of loan amount)
      if (monthlySavings < requestedAmount * 0.1) {
        setState(() {
          _loanStatus = 'Rejected';
          _rejectionReason = 'Monthly savings commitment must be at least 10% of loan amount (₦${(requestedAmount * 0.1).toStringAsFixed(2)})';
          _isSubmitting = false;
        });
        return;
      }

      // Generate unique loan ID
      final loanId = '${widget.userId}-LOAN-${DateTime.now().millisecondsSinceEpoch}';
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simple approval logic (in production, this would be based on credit score, etc.)
      if (monthlySavings >= requestedAmount * 0.15) {
        // 15% or higher = Approved
        setState(() {
          _loanId = loanId;
          _loanStatus = 'Approved';
          _rejectionReason = null;
          _showQrCode = true;
          _isSubmitting = false;
        });

        // Show success dialog
        _showSuccessDialog();
      } else if (monthlySavings >= requestedAmount * 0.1) {
        // 10-15% = Pending Review
        setState(() {
          _loanId = loanId;
          _loanStatus = 'Pending Review';
          _rejectionReason = null;
          _showQrCode = true;
          _isSubmitting = false;
        });

        _showPendingDialog();
      } else {
        setState(() {
          _loanStatus = 'Rejected';
          _rejectionReason = 'Monthly savings commitment is too low. Minimum 10% required.';
          _isSubmitting = false;
        });
      }

    } catch (e) {
      setState(() {
        _loanStatus = 'Error';
        _rejectionReason = 'Failed to process application: $e';
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: CoopvestColors.success),
            SizedBox(width: 8),
            Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your ${_selectedLoanType} application has been APPROVED!'),
            const SizedBox(height: 16),
            const Text(
              'Please share the QR code with your 3 guarantors. They need to scan it to confirm their guarantee.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.hourglass_top, color: Colors.orange),
            SizedBox(width: 8),
            Text('Under Review'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your ${_selectedLoanType} application is now under review.'),
            const SizedBox(height: 16),
            const Text(
              'Please share the QR code with your 3 guarantors. Once all 3 guarantors confirm, your loan will be processed.',
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
    _amountController.dispose();
    _purposeController.dispose();
    _monthlySavingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanInfo = _loanTypes[_selectedLoanType]!;
    final minAmount = loanInfo['minAmount'] as double;
    final maxAmount = loanInfo['maxAmount'] as double;

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
          'Apply for Loan',
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
              // Loan Type Selection Card
              AppCard(
                backgroundColor: CoopvestColors.primary.withOpacity(0.05),
                border: Border.all(color: CoopvestColors.primary.withOpacity(0.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: CoopvestColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Select Loan Type',
                          style: CoopvestTypography.labelLarge.copyWith(
                            color: CoopvestColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: CoopvestColors.lightGray),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedLoanType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _loanTypes.entries.map((entry) {
                          final key = entry.key;
                          final value = entry.value;
                          return DropdownMenuItem(
                            value: key,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  key,
                                  style: CoopvestTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${value['duration']} months @ ${value['interest']}% interest',
                                  style: CoopvestTypography.bodySmall.copyWith(
                                    color: CoopvestColors.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLoanType = value!;
                            _amountController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loanInfo['description'] as String,
                      style: CoopvestTypography.bodySmall.copyWith(
                        color: CoopvestColors.mediumGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: CoopvestColors.veryLightGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Min: ₦${minAmount.toStringAsFixed(0)}',
                              style: CoopvestTypography.bodySmall,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: CoopvestColors.veryLightGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Max: ₦${maxAmount.toStringAsFixed(0)}',
                              style: CoopvestTypography.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Loan Amount
              AppTextField(
                label: 'Loan Amount (₦) *',
                hint: 'Enter amount between ₦${minAmount.toStringAsFixed(0)} - ₦${maxAmount.toStringAsFixed(0)}',
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixText: '₦ ',
                onChanged: (value) {
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter loan amount';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount < minAmount) {
                    return 'Minimum amount is ₦${minAmount.toStringAsFixed(0)}';
                  }
                  if (amount > maxAmount) {
                    return 'Maximum amount is ₦${maxAmount.toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Monthly Savings While on Loan
              AppTextField(
                label: 'Monthly Savings While On Loan (₦) *',
                hint: 'Minimum 10% of loan amount required',
                controller: _monthlySavingsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixText: '₦ ',
                onChanged: (value) {
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter monthly savings amount';
                  }
                  final savings = double.tryParse(value);
                  if (savings == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // Show calculated values
              if (_amountController.text.isNotEmpty && _monthlySavingsController.text.isNotEmpty)
                ...[
                  const SizedBox(height: 16),
                  _buildLoanSummary(loanInfo),
                ],

              const SizedBox(height: 16),

              // Loan Purpose
              AppTextField(
                label: 'Loan Purpose *',
                hint: 'Briefly describe why you need this loan',
                controller: _purposeController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter loan purpose';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Important Notice Card
              AppCard(
                backgroundColor: CoopvestColors.warning.withOpacity(0.1),
                border: Border.all(color: CoopvestColors.warning.withOpacity(0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: CoopvestColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Important Requirements',
                          style: CoopvestTypography.labelLarge.copyWith(
                            color: CoopvestColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('• You need 3 guarantors to approve this loan'),
                    _buildInfoRow('• Guarantors must be existing members'),
                    _buildInfoRow('• Monthly savings must be at least 10% of loan amount'),
                    _buildInfoRow('• Defaulting loans will be inherited by guarantors'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              _isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: CoopvestColors.primary,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Submit Application',
                      onPressed: _submitApplication,
                      width: double.infinity,
                    ),

              const SizedBox(height: 16),

              // Back Button
              SecondaryButton(
                label: 'Go Back',
                onPressed: _goBack,
                width: double.infinity,
              ),

              // QR Code and Status Section
              if (_showQrCode) ...[
                const SizedBox(height: 32),
                _buildStatusSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: CoopvestTypography.bodySmall.copyWith(
          color: CoopvestColors.darkGray,
        ),
      ),
    );
  }

  Widget _buildLoanSummary(Map<String, dynamic> loanInfo) {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final savings = double.tryParse(_monthlySavingsController.text) ?? 0;
    final interestRate = loanInfo['interest'] as double;
    final tenure = loanInfo['duration'] as int;
    
    final monthlyRepayment = _calculateMonthlyRepayment(amount, interestRate, tenure);
    final totalRepayment = _calculateTotalRepayment(amount, interestRate);

    final isValidSavings = savings >= amount * 0.1;
    final savingsPercentage = amount > 0 ? (savings / amount * 100) : 0;

    return AppCard(
      backgroundColor: isValidSavings 
          ? CoopvestColors.success.withOpacity(0.05)
          : CoopvestColors.error.withOpacity(0.05),
      border: Border.all(
        color: isValidSavings 
            ? CoopvestColors.success 
            : CoopvestColors.error,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Summary',
            style: CoopvestTypography.labelLarge.copyWith(
              color: CoopvestColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Loan Amount:', '₦${amount.toStringAsFixed(2)}'),
          _buildSummaryRow('Interest Rate:', '${interestRate}%'),
          _buildSummaryRow('Duration:', '$tenure months'),
          _buildSummaryRow('Monthly Repayment:', '₦${monthlyRepayment.toStringAsFixed(2)}'),
          _buildSummaryRow('Total Repayment:', '₦${totalRepayment.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isValidSavings 
                  ? CoopvestColors.success.withOpacity(0.1)
                  : CoopvestColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isValidSavings ? Icons.check_circle : Icons.warning,
                  color: isValidSavings ? CoopvestColors.success : CoopvestColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isValidSavings 
                      ? 'Savings: ${savingsPercentage.toStringAsFixed(1)}% of loan ✓'
                      : 'Savings: ${savingsPercentage.toStringAsFixed(1)}% of loan (Min 10% required)',
                  style: CoopvestTypography.bodySmall.copyWith(
                    color: isValidSavings ? CoopvestColors.success : CoopvestColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

  Widget _buildStatusSection() {
    final isApproved = _loanStatus == 'Approved';
    final isPending = _loanStatus == 'Pending Review';
    final isRejected = _loanStatus == 'Rejected' || _loanStatus == 'Error';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card
        AppCard(
          backgroundColor: isApproved 
              ? CoopvestColors.success.withOpacity(0.1)
              : isPending 
                  ? Colors.yellow[50]
                  : CoopvestColors.error.withOpacity(0.1),
          border: Border.all(
            color: isApproved 
                ? CoopvestColors.success
                : isPending 
                    ? Colors.yellow
                    : CoopvestColors.error,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isApproved 
                        ? Icons.check_circle
                        : isPending 
                            ? Icons.hourglass_top
                            : Icons.cancel,
                    color: isApproved 
                        ? CoopvestColors.success
                        : isPending 
                            ? Colors.orange
                            : CoopvestColors.error,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application Status: $_loanStatus',
                          style: CoopvestTypography.titleMedium.copyWith(
                            color: isApproved 
                                ? CoopvestColors.success
                                : isPending 
                                    ? Colors.orange
                                    : CoopvestColors.error,
                          ),
                        ),
                        if (isPending)
                          Text(
                            'Waiting for guarantor confirmation',
                            style: CoopvestTypography.bodySmall.copyWith(
                              color: CoopvestColors.mediumGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isRejected && _rejectionReason != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Reason: $_rejectionReason',
                  style: CoopvestTypography.bodySmall.copyWith(
                    color: CoopvestColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // QR Code Section
        if (_showQrCode)
          Center(
            child: Column(
              children: [
                Text(
                  'Share this QR code with your 3 guarantors:',
                  style: CoopvestTypography.titleMedium.copyWith(
                    color: CoopvestColors.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CoopvestColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _formattedLoanId,
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loan ID: $_formattedLoanId',
                  style: CoopvestTypography.bodyMedium.copyWith(
                    color: CoopvestColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  backgroundColor: CoopvestColors.info.withOpacity(0.1),
                  border: Border.all(color: CoopvestColors.info.withOpacity(0.3)),
                  child: Text(
                    'Guarantors should scan this code to confirm their guarantee. If the borrower defaults, the loan is inherited by the 3 guarantors equally.',
                    style: CoopvestTypography.bodySmall.copyWith(
                      color: CoopvestColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
