import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/utils.dart';
import '../../core/utils/logger_service.dart';
import '../../data/models/loan_models.dart';
import '../repositories/auth_repository.dart';

/// Loan Repository - Handles all loan-related operations
class LoanRepository {
  final ApiClient _apiClient;
  final AuthRepository _authRepository;
  final LoggerService _logger;

  LoanRepository({
  ApiClient? apiClient,
  AuthRepository? authRepository,
  LoggerService? logger,
  })  : _apiClient = apiClient ?? ApiClient(),
  _authRepository = authRepository ?? AuthRepository(ApiClient()),
  _logger = logger ?? LoggerService();

  /// Get all loans for the current user
  Future<List<Loan>> getLoans() async {
  _logger.i('Fetching loans...');
  // Return mock data for now
  return _getMockLoans();
  }

  /// Get loan by ID
  Future<Loan?> getLoanById(String loanId) async {
  _logger.i('Fetching loan: $loanId');
  final loans = await getLoans();
  try {
  return loans.firstWhere((loan) => loan.id == loanId);
  } catch (e) {
  return null;
  }
  }

  /// Apply for a new loan
  Future<Loan> applyForLoan({
  required String loanType,
  required double amount,
  required int tenure,
  required String purpose,
  }) async {
  _logger.i('Applying for loan: $loanType, ₦$amount, $tenure months');
  
  // Create mock loan response
  final now = DateTime.now();
  return Loan(
  id: 'LOAN-${now.millisecondsSinceEpoch}',
  userId: await _authRepository.getUserId(),
  amount: amount,
  tenure: tenure,
  interestRate: _getInterestRate(loanType),
  monthlyRepayment: amount * (1 + _getInterestRate(loanType) / 100) / tenure,
  totalRepayment: amount * (1 + _getInterestRate(loanType) / 100),
  status: 'pending',
  guarantorsRequired: 3,
  guarantorsAccepted: 0,
  createdAt: now,
  updatedAt: now,
  approvedAt: null,
  disbursedAt: null,
 );
  }

  /// Get loan types
  Future<List<LoanType>> getLoanTypes() async {
  return _getMockLoanTypes();
  }

  /// Get active loans
  Future<List<Loan>> getActiveLoans() async {
  final loans = await getLoans();
  return loans.where((loan) => 
  loan.status == 'active' || loan.status == 'repaying'
 ).toList();
  }

  /// Get loan types helper
  double _getInterestRate(String loanType) {
  switch (loanType) {
  case 'Quick Loan': return 5.0;
  case 'Flexi Loan': return 6.0;
  case 'Emergency Loan': return 7.0;
  case 'Business Loan': return 8.0;
  default: return 5.0;
  }
  }

  /// Mock loans for demo
  List<Loan> _getMockLoans() {
  final now = DateTime.now();
  return [
  Loan(
  id: 'LOAN-001',
  userId: 'user-001',
  amount: 100000,
  tenure: 6,
  interestRate: 5.0,
  monthlyRepayment: 18333,
  totalRepayment: 65000,
  status: 'active',
  guarantorsRequired: 3,
  guarantorsAccepted: 3,
  createdAt: now.subtract(const Duration(days: 90)),
  updatedAt: now.subtract(const Duration(days: 60)),
  approvedAt: now.subtract(const Duration(days: 85)),
  disbursedAt: now.subtract(const Duration(days: 84)),
 ),
  Loan(
  id: 'LOAN-002',
  userId: 'user-001',
  amount: 50000,
  tenure: 3,
  interestRate: 5.0,
  monthlyRepayment: 17500,
  totalRepayment: 52500,
  status: 'completed',
  guarantorsRequired: 2,
  guarantorsAccepted: 2,
  createdAt: now.subtract(const Duration(days: 180)),
  updatedAt: now.subtract(const Duration(days: 30)),
  approvedAt: now.subtract(const Duration(days: 175)),
  disbursedAt: now.subtract(const Duration(days: 174)),
 ),
  ];
  }

  /// Mock loan types for demo
  List<LoanType> _getMockLoanTypes() {
  return [
  const LoanType(
  id: 'quick_loan',
  name: 'Quick Loan',
  description: 'Fast approval for small amounts',
  minAmount: 5000,
  maxAmount: 100000,
  minTenure: 1,
  maxTenure: 6,
  interestRate: 5.0,
  requirements: ['Active savings account', 'Minimum 3 months membership'],
 ),
  const LoanType(
  id: 'flexi_loan',
  name: 'Flexi Loan',
  description: 'Flexible repayment options',
  minAmount: 10000,
  maxAmount: 500000,
  minTenure: 3,
  maxTenure: 12,
  interestRate: 6.0,
  requirements: ['Active savings account', 'Minimum 6 months membership'],
 ),
  const LoanType(
  id: 'emergency_loan',
  name: 'Emergency Loan',
  description: 'For urgent financial needs',
  minAmount: 5000,
  maxAmount: 50000,
  minTenure: 1,
  maxTenure: 3,
  interestRate: 7.0,
  requirements: ['Active savings account', 'Good repayment history'],
 ),
  const LoanType(
  id: 'business_loan',
  name: 'Business Loan',
  description: 'Grow your business',
  minAmount: 50000,
  maxAmount: 1000000,
  minTenure: 6,
  maxTenure: 24,
  interestRate: 8.0,
  requirements: ['Active savings account', '12+ months membership', 'Business plan'],
 ),
  ];
  }
}

/// Loan Repository Provider
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoanRepository(authRepository: authRepository);
});
