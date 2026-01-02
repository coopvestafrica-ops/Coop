import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme_config.dart';
import '../../../../core/utils/utils.dart';
import '../../../../data/models/rollover_models.dart';
import '../../providers/rollover_provider.dart';
import '../widgets/common/buttons.dart';
import '../widgets/common/cards.dart';
import '../widgets/rollover/rollover_common_widgets.dart';

/// Admin Rollover List Screen
/// Shows all pending rollover requests for admin review
class AdminRolloverListScreen extends ConsumerWidget {
  const AdminRolloverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolloverProvider);
    final rollovers = state.rolloverHistory;
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Rollover Requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(rolloverProvider.notifier).getPendingRollovers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(rolloverProvider.notifier).getPendingRollovers(),
        child: isLoading && rollovers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : rollovers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rollovers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rollover = rollovers[index];
                      return AdminRolloverCard(
                        rollover: rollover,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminRolloverDetailScreen(
                                rolloverId: rollover.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: 16),
          Text(
            'No Rollover Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All rollover requests have been processed.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin Rollover Card
class AdminRolloverCard extends StatelessWidget {
  final LoanRollover rollover;
  final VoidCallback onTap;

  const AdminRolloverCard({
    super.key,
    required this.rollover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rollover.memberName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          rollover.memberPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RolloverStatusBadge(status: rollover.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow('Original Loan', rollover.originalLoanId),
              _buildInfoRow('Outstanding Balance',
                  AppCurrencyFormatter.format(rollover.outstandingBalance)),
              _buildInfoRow(
                  'Repayment %', '${rollover.repaymentPercentage.toStringAsFixed(1)}%'),
              _buildInfoRow('Requested',
                  AppDateFormatter.formatDate(rollover.requestedAt)),
              if (rollover.status == RolloverStatus.pending)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info, color: AppColors.warning, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Awaiting guarantor consent',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              if (rollover.status == RolloverStatus.awaitingAdminApproval)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: AppColors.info, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ready for admin review',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin Rollover Detail Screen
/// Shows full details and allows admin to approve/reject
class AdminRolloverDetailScreen extends ConsumerWidget {
  final String rolloverId;

  const AdminRolloverDetailScreen({super.key, required this.rolloverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolloverProvider);
    final rollover = state.currentRollover;
    final guarantors = state.guarantors;
    final isLoading = state.isLoading;

    // Load rollover details on screen load
    ref.listen<RolloverState>(rolloverProvider, (previous, current) {
      if (previous?.currentRollover?.id != rolloverId &&
          current.currentRollover?.id == rolloverId) {
        // Data loaded
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Rollover Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading && rollover == null
          ? const Center(child: CircularProgressIndicator())
          : rollover == null
              ? const Center(child: Text('Rollover not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member Info
                      _buildMemberInfo(rollover),
                      const SizedBox(height: 16),

                      // Loan Details
                      _buildLoanDetails(rollover),
                      const SizedBox(height: 16),

                      // Eligibility Status
                      _buildEligibilityStatus(rollover),
                      const SizedBox(height: 16),

                      // Guarantors Section
                      _buildGuarantorsSection(guarantors),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (rollover.status ==
                          RolloverStatus.awaitingAdminApproval)
                        _buildAdminActions(context, ref),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberInfo(LoanRollover rollover) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Member Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Name', rollover.memberName),
          _buildInfoRow('Phone', rollover.memberPhone),
          _buildInfoRow('Member ID', rollover.memberId),
        ],
      ),
    );
  }

  Widget _buildLoanDetails(LoanRollover rollover) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Loan Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionHeader('Original Loan'),
          _buildInfoRow('Original Principal',
              AppCurrencyFormatter.format(rollover.originalPrincipal)),
          _buildInfoRow('Total Repaid',
              AppCurrencyFormatter.format(rollover.totalRepaid)),
          _buildInfoRow('Outstanding Balance',
              AppCurrencyFormatter.format(rollover.outstandingBalance)),
          _buildInfoRow('Repayment %',
              '${rollover.repaymentPercentage.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildSectionHeader('New Loan (After Rollover)'),
          _buildInfoRow('New Tenure', '${rollover.newTenure} months'),
          _buildInfoRow('Interest Rate', '${rollover.newInterestRate}%'),
          _buildInfoRow('Monthly Repayment',
              AppCurrencyFormatter.format(rollover.newMonthlyRepayment)),
          _buildInfoRow('Total Repayment',
              AppCurrencyFormatter.format(rollover.newTotalRepayment)),
        ],
      ),
    );
  }

  Widget _buildEligibilityStatus(LoanRollover rollover) {
    final isEligible = rollover.repaymentPercentage >= 50;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEligible ? Icons.check_circle : Icons.warning,
                color: isEligible ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              const Text(
                'Eligibility Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EligibilityCheckItem(
            isMet: isEligible,
            title: '50% Principal Repayment',
            subtitle: isEligible
                ? 'Met (${rollover.repaymentPercentage.toStringAsFixed(1)}%)'
                : 'Not met (${rollover.repaymentPercentage.toStringAsFixed(1)}%)',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Note: All 3 guarantors must consent before approval.',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  'Loan amount remains the same - no top-up allowed.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorsSection(List<RolloverGuarantor> guarantors) {
    final accepted = guarantors
        .where((g) => g.status == GuarantorConsentStatus.accepted)
        .length;
    final declined = guarantors
        .where((g) => g.status == GuarantorConsentStatus.declined)
        .length;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Guarantors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$accepted/3 Accepted',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: accepted == 3 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...guarantors.map((guarantor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminGuarantorCard(guarantor: guarantor),
            );
          }).toList(),
          if (declined > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '$declined guarantor(s) declined. Member must replace them.',
                    style: TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, WidgetRef ref) {
    final state = ref.read(rolloverProvider);
    final guarantors = state.guarantors;
    final allConsented =
        guarantors.every((g) => g.status == GuarantorConsentStatus.accepted);
    final hasDeclined =
        guarantors.any((g) => g.status == GuarantorConsentStatus.declined);

    return Column(
      children: [
        if (!allConsented || hasDeclined)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cannot approve until all 3 guarantors have consented.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Reject',
                onPressed: () => _showRejectDialog(context, ref),
                isRed: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Approve Rollover',
                onPressed: allConsented && !hasDeclined
                    ? () => _showApproveDialog(context, ref)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Rollover?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Are you sure you want to approve this rollover request?',
            ),
            SizedBox(height: 12),
            Text(
              'This will create a new loan record with the same interest rate but new repayment terms.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(rolloverProvider.notifier)
                  .approveRollover(rolloverId: rolloverId);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rollover approved successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Rollover'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: reasonController.text.isNotEmpty
                ? () async {
                    final success = await ref
                        .read(rolloverProvider.notifier)
                        .rejectRollover(
                          rolloverId: rolloverId,
                          reason: reasonController.text,
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rollover rejected'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  }
                : null,
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

/// Admin Guarantor Card
class AdminGuarantorCard extends StatelessWidget {
  final RolloverGuarantor guarantor;

  const AdminGuarantorCard({super.key, required this.guarantor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _getBorderColor()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(),
              child: Text(
                guarantor.guarantorName[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guarantor.guarantorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    guarantor.guarantorPhone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GuarantorStatusBadge(status: guarantor.status),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    switch (guarantor.status) {
      case GuarantorConsentStatus.accepted:
        return AppColors.success.withOpacity(0.2);
      case GuarantorConsentStatus.declined:
        return AppColors.error.withOpacity(0.2);
      default:
        return AppColors.lightGrey;
    }
  }

  Color _getBorderColor() {
    switch (guarantor.status) {
      case GuarantorConsentStatus.accepted:
        return AppColors.success.withOpacity(0.3);
      case GuarantorConsentStatus.declined:
        return AppColors.error.withOpacity(0.3);
      default:
        return AppColors.lightGrey;
    }
  }
}
