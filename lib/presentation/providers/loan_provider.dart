import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/utils.dart';
import '../models/loan_models.dart';

/// Loan Repository Provider
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoanRepository(apiClient);
});

/// Loan Repository
class LoanRepository {
  final ApiClient _apiClient;

  LoanRepository(this._apiClient);

  /// Get loans
  Future<List<Loan>> getLoans({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        '/loans',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status,
        },
      );

      final data = response as Map<String, dynamic>;
      final loans = (data['data'] as List)
          .map((item) => Loan.fromJson(item as Map<String, dynamic>))
          .toList();

      return loans;
    } catch (e) {
      logger.e('Get loans error: $e');
      rethrow;
    }
  }

  /// Get loan details
  Future<Loan> getLoanDetails(String loanId) async {
    try {
      final response = await _apiClient.get('/loans/$loanId');
      return Loan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.e('Get loan details error: $e');
      rethrow;
    }
  }

  /// Apply for loan
  Future<Loan> applyLoan({
    required double amount,
    required int tenure,
    String? purpose,
  }) async {
    try {
      final response = await _apiClient.post(
        '/loans/apply',
        data: {
          'amount': amount,
          'tenure': tenure,
          'purpose': purpose,
        },
      );

      return Loan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.e('Apply loan error: $e');
      rethrow;
    }
  }

  /// Get guarantors for loan
  Future<List<Guarantor>> getGuarantors(String loanId) async {
    try {
      final response = await _apiClient.get('/loans/$loanId/guarantors');

      final data = response as Map<String, dynamic>;
      final guarantors = (data['data'] as List)
          .map((item) => Guarantor.fromJson(item as Map<String, dynamic>))
          .toList();

      return guarantors;
    } catch (e) {
      logger.e('Get guarantors error: $e');
      rethrow;
    }
  }

  /// Get guarantor requests (for current user as guarantor)
  Future<List<Map<String, dynamic>>> getGuarantorRequests() async {
    try {
      final response = await _apiClient.get('/loans/guarantor-requests');

      final data = response as Map<String, dynamic>;
      final requests = (data['data'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return requests;
    } catch (e) {
      logger.e('Get guarantor requests error: $e');
      rethrow;
    }
  }

  /// Approve as guarantor
  Future<void> approveAsGuarantor(String loanId) async {
    try {
      await _apiClient.post(
        '/loans/$loanId/approve-guarantor',
      );
    } catch (e) {
      logger.e('Approve as guarantor error: $e');
      rethrow;
    }
  }

  /// Decline as guarantor
  Future<void> declineAsGuarantor(String loanId) async {
    try {
      await _apiClient.post(
        '/loans/$loanId/decline-guarantor',
      );
    } catch (e) {
      logger.e('Decline as guarantor error: $e');
      rethrow;
    }
  }

  /// Get repayment schedule
  Future<List<Map<String, dynamic>>> getRepaymentSchedule(String loanId) async {
    try {
      final response = await _apiClient.get('/loans/$loanId/repayment-schedule');

      final data = response as Map<String, dynamic>;
      final schedule = (data['data'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return schedule;
    } catch (e) {
      logger.e('Get repayment schedule error: $e');
      rethrow;
    }
  }

  /// Make repayment
  Future<void> makeRepayment({
    required String loanId,
    required double amount,
  }) async {
    try {
      await _apiClient.post(
        '/loans/$loanId/repay',
        data: {'amount': amount},
      );
    } catch (e) {
      logger.e('Make repayment error: $e');
      rethrow;
    }
  }

  /// Generate QR code for loan
  Future<String> generateQRCode(String loanId) async {
    try {
      final response = await _apiClient.get('/loans/$loanId/qr-code');
      return response['qr_code'] as String;
    } catch (e) {
      logger.e('Generate QR code error: $e');
      rethrow;
    }
  }
}

/// Loan Notifier
class LoanNotifier extends StateNotifier<LoansState> {
  final LoanRepository _loanRepository;

  LoanNotifier(this._loanRepository) : super(const LoansState());

  /// Load loans
  Future<void> loadLoans({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    state = state.copyWith(status: LoanStatus.loading);
    try {
      final loans = await _loanRepository.getLoans(
        page: page,
        pageSize: pageSize,
        status: status,
      );

      state = state.copyWith(
        status: LoanStatus.loaded,
        loans: loans,
      );
    } catch (e) {
      logger.e('Load loans error: $e');
      state = state.copyWith(
        status: LoanStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Load loan details
  Future<void> loadLoanDetails(String loanId) async {
    state = state.copyWith(status: LoanStatus.loading);
    try {
      final loan = await _loanRepository.getLoanDetails(loanId);
      final guarantors = await _loanRepository.getGuarantors(loanId);

      state = state.copyWith(
        status: LoanStatus.loaded,
        selectedLoan: loan,
        guarantors: guarantors,
      );
    } catch (e) {
      logger.e('Load loan details error: $e');
      state = state.copyWith(
        status: LoanStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Apply for loan
  Future<void> applyLoan({
    required double amount,
    required int tenure,
    String? purpose,
  }) async {
    state = state.copyWith(status: LoanStatus.loading);
    try {
      final loan = await _loanRepository.applyLoan(
        amount: amount,
        tenure: tenure,
        purpose: purpose,
      );

      state = state.copyWith(
        status: LoanStatus.loaded,
        selectedLoan: loan,
        loans: [loan, ...state.loans],
      );
    } catch (e) {
      logger.e('Apply loan error: $e');
      state = state.copyWith(
        status: LoanStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Approve as guarantor
  Future<void> approveAsGuarantor(String loanId) async {
    state = state.copyWith(status: LoanStatus.loading);
    try {
      await _loanRepository.approveAsGuarantor(loanId);

      // Reload loan details
      await loadLoanDetails(loanId);
    } catch (e) {
      logger.e('Approve as guarantor error: $e');
      state = state.copyWith(
        status: LoanStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Decline as guarantor
  Future<void> declineAsGuarantor(String loanId) async {
    state = state.copyWith(status: LoanStatus.loading);
    try {
      await _loanRepository.declineAsGuarantor(loanId);

      // Reload loan details
      await loadLoanDetails(loanId);
    } catch (e) {
      logger.e('Decline as guarantor error: $e');
      state = state.copyWith(
        status: LoanStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Loan Provider
final loanProvider = StateNotifierProvider<LoanNotifier, LoansState>((ref) {
  final loanRepository = ref.watch(loanRepositoryProvider);
  return LoanNotifier(loanRepository);
});

/// Active loans provider
final activeLoansProvider = Provider<List<Loan>>((ref) {
  final loansState = ref.watch(loanProvider);
  return loansState.loans.where((loan) => loan.status == 'active').toList();
});

/// Pending loans provider
final pendingLoansProvider = Provider<List<Loan>>((ref) {
  final loansState = ref.watch(loanProvider);
  return loansState.loans
      .where((loan) => loan.status == 'pending_guarantors')
      .toList();
});

/// Selected loan provider
final selectedLoanProvider = Provider<Loan?>((ref) {
  final loansState = ref.watch(loanProvider);
  return loansState.selectedLoan;
});

/// Guarantors provider
final guarantorsProvider = Provider<List<Guarantor>>((ref) {
  final loansState = ref.watch(loanProvider);
  return loansState.guarantors;
});

/// Loan error provider
final loanErrorProvider = Provider<String?>((ref) {
  final loansState = ref.watch(loanProvider);
  return loansState.error;
});
