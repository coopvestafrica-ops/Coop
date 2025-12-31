import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/wallet_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/wallet_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../loan/loan_dashboard_screen.dart';
import '../wallet/wallet_dashboard_screen.dart';
import '../savings/savings_goals_screen.dart';

/// Main Home Dashboard Screen
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final wallet = walletState.wallet;
    final savingsGoals = walletState.savingsGoals.where((g) => g.status == 'active').toList();
    final recentTransactions = walletState.transactions.take(3).toList();
    
    // Mock user data - in production, get from auth provider
    const userName = 'John';
    const userId = 'user_123';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, color: CoopvestColors.darkGray),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: CoopvestColors.darkGray),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Text(
                'Welcome back,',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              Text(
                userName,
                style: CoopvestTypography.headlineLarge.copyWith(
                  color: CoopvestColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Savings',
                      '₦${(wallet?.balance ?? 0).formatNumber()}',
                      Icons.savings,
                      CoopvestColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Loans',
                      '1',
                      Icons.account_balance,
                      CoopvestColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Savings Goals',
                      '${savingsGoals.length}',
                      Icons.flag,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      '₦${(wallet?.pendingContributions ?? 0).formatNumber()}',
                      Icons.pending,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Quick Actions Grid
              _buildQuickActionsGrid(context),

              const SizedBox(height: 32),

              // Active Savings Goals
              if (savingsGoals.isNotEmpty) ...[
                _buildSectionHeader('Savings Goals', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SavingsGoalsScreen(userId: userId),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ...savingsGoals.take(2).map((goal) => _buildGoalProgressCard(context, goal)),
                const SizedBox(height: 32),
              ],

              // Recent Activity
              _buildSectionHeader('Recent Activity', () {
                // View all transactions
              }),
              const SizedBox(height: 16),
              if (recentTransactions.isEmpty)
                _buildEmptyActivityCard()
              else
                ...recentTransactions.map((txn) => _buildActivityItem(context, txn)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      backgroundColor: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: CoopvestTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: CoopvestTypography.bodySmall.copyWith(
              color: CoopvestColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    const userId = 'user_123';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletDashboardScreen(userId: userId, userName: 'John'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.savings,
                label: 'Save',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SavingsGoalsScreen(userId: userId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.request_quote,
                label: 'Loans',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoanDashboardScreen(userId: userId, userName: 'John', userPhone: '+2340000000000'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CoopvestColors.veryLightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: CoopvestColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: CoopvestTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildGoalProgressCard(BuildContext context, SavingsGoal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${goal.progressPercentage.toStringAsFixed(0)}%', style: TextStyle(color: CoopvestColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressPercentage / 100,
                minHeight: 8,
                backgroundColor: CoopvestColors.veryLightGray,
                valueColor: const AlwaysStoppedAnimation<Color>(CoopvestColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${goal.currentAmount.formatNumber()} of ₦${goal.targetAmount.formatNumber()}',
              style: TextStyle(color: CoopvestColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityCard() {
    return AppCard(
      backgroundColor: CoopvestColors.veryLightGray,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, color: CoopvestColors.mediumGray, size: 48),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: TextStyle(color: CoopvestColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Transaction txn) {
    final isCredit = txn.type == 'contribution' || txn.type == 'loan_disbursement' || txn.type == 'refund';
    
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? CoopvestColors.success.withOpacity(0.1) : CoopvestColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? CoopvestColors.success : CoopvestColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description ?? txn.type.replaceAll('_', ' ').capitalize()),
                Text(
                  '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                  style: TextStyle(color: CoopvestColors.mediumGray, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${txn.amount.formatNumber()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? CoopvestColors.success : CoopvestColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
