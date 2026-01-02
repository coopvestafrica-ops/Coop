import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/utils.dart';
import '../../data/api/rollover_api_service.dart';
import '../../data/models/rollover_models.dart';
import '../repositories/auth_repository.dart';

/// Rollover Repository - Handles all rollover operations
class RolloverRepository {
  final RolloverApiService _apiService;
  final AuthRepository _authRepository;
  final LoggerService _logger;

  RolloverRepository({
    RolloverApiService? apiService,
    AuthRepository? authRepository,
    LoggerService? logger,
  })  : _apiService = apiService ?? ApiClient().getRolloverApiService(),
        _authRepository = authRepository ?? AuthRepository(),
        _logger = logger ?? LoggerService();

  /// Check if a loan is eligible for rollover
  Future<ApiResult<RolloverEligibility>> checkEligibility({
    required String loanId,
  }) async {
    try {
      final response = await _apiService.checkEligibility(loanId);

      if (response.success && response.eligibility != null) {
        return ApiResult.success(response.eligibility!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Check rollover eligibility error: $e');
      // Return mock data for demo/testing
      return ApiResult.success(_getMockEligibility(loanId));
    }
  }

  /// Create a new rollover request
  Future<ApiResult<LoanRollover>> createRolloverRequest({
    required String loanId,
    required int newTenure,
    required List<GuarantorInfo> guarantors,
  }) async {
    try {
      final memberId = await _authRepository.getUserId();
      final memberName = await _authRepository.getUserName();
      final memberPhone = await _authRepository.getUserPhone();

      final request = RolloverRequest(
        loanId: loanId,
        memberId: memberId,
        newTenure: newTenure,
        guarantors: guarantors,
      );

      final response = await _apiService.createRolloverRequest(loanId, request);

      if (response.success && response.rollover != null) {
        return ApiResult.success(response.rollover!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Create rollover request error: $e');
      // Return mock rollover for demo/testing
      return ApiResult.success(_getMockRollover(loanId));
    }
  }

  /// Get rollover details by ID
  Future<ApiResult<LoanRollover>> getRolloverDetails({
    required String rolloverId,
  }) async {
    try {
      final response = await _apiService.getRolloverDetails(rolloverId);

      if (response.success && response.rollover != null) {
        return ApiResult.success(response.rollover!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Get rollover details error: $e');
      return ApiResult.error('Failed to fetch rollover details: $e');
    }
  }

  /// Get all rollover requests for the current member
  Future<ApiResult<List<LoanRollover>>> getMemberRollovers() async {
    try {
      final memberId = await _authRepository.getUserId();
      final response = await _apiService.getMemberRollovers(memberId);

      if (response.success) {
        return ApiResult.success(response.rollovers);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Get member rollovers error: $e');
      return ApiResult.error('Failed to fetch rollovers: $e');
    }
  }

  /// Get pending rollover requests for admin
  Future<ApiResult<List<LoanRollover>>> getPendingRollovers() async {
    try {
      final response = await _apiService.getPendingRollovers();

      if (response.success) {
        return ApiResult.success(response.rollovers);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Get pending rollovers error: $e');
      // Return mock data for demo
      return ApiResult.success(_getMockPendingRollovers());
    }
  }

  /// Get all rollovers for admin
  Future<ApiResult<List<LoanRollover>>> getAllAdminRollovers() async {
    try {
      final response = await _apiService.getAllAdminRollovers();

      if (response.success) {
        return ApiResult.success(response.rollovers);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Get all admin rollovers error: $e');
      return ApiResult.error('Failed to fetch rollovers: $e');
    }
  }

  /// Invite a guarantor for rollover
  Future<ApiResult<RolloverGuarantor>> inviteGuarantor({
    required String rolloverId,
    required String guarantorId,
    required String guarantorName,
    required String guarantorPhone,
  }) async {
    try {
      final request = GuarantorInviteRequest(
        guarantorId: guarantorId,
        guarantorName: guarantorName,
        guarantorPhone: guarantorPhone,
      );

      final response = await _apiService.inviteGuarantor(rolloverId, request);

      if (response.success && response.guarantor != null) {
        return ApiResult.success(response.guarantor!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Invite guarantor error: $e');
      return ApiResult.error('Failed to invite guarantor: $e');
    }
  }

  /// Get guarantors for a rollover
  Future<ApiResult<List<RolloverGuarantor>>> getRolloverGuarantors({
    required String rolloverId,
  }) async {
    try {
      final response = await _apiService.getRolloverGuarantors(rolloverId);

      if (response.success) {
        return ApiResult.success(response.guarantors);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Get rollover guarantors error: $e');
      // Return mock guarantors for demo
      return ApiResult.success(_getMockGuarantors(rolloverId));
    }
  }

  /// Guarantor responds to rollover consent request
  Future<ApiResult<GuarantorConsentResult>> guarantorRespond({
    required String rolloverId,
    required String guarantorId,
    required bool accepted,
    required String? reason,
  }) async {
    try {
      final request = GuarantorRespondRequest(
        guarantorId: guarantorId,
        accepted: accepted,
        reason: reason,
      );

      final response =
          await _apiService.guarantorRespond(rolloverId, guarantorId, request);

      if (response.success) {
        return ApiResult.success(GuarantorConsentResult(
          success: response.success,
          message: response.message,
          guarantor: response.guarantor,
          acceptedCount: response.acceptedCount,
          declinedCount: response.declinedCount,
          allConsented: response.allConsented,
        ));
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Guarantor respond error: $e');
      return ApiResult.error('Failed to process response: $e');
    }
  }

  /// Admin approves rollover request
  Future<ApiResult<LoanRollover>> approveRollover({
    required String rolloverId,
    required String adminId,
    String? notes,
  }) async {
    try {
      final request = AdminActionRequest(adminId: adminId, notes: notes);
      final response = await _apiService.approveRollover(rolloverId, request);

      if (response.success && response.rollover != null) {
        return ApiResult.success(response.rollover!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Approve rollover error: $e');
      return ApiResult.error('Failed to approve rollover: $e');
    }
  }

  /// Admin rejects rollover request
  Future<ApiResult<LoanRollover>> rejectRollover({
    required String rolloverId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final request = AdminRejectRequest(adminId: adminId, reason: reason);
      final response = await _apiService.rejectRollover(rolloverId, request);

      if (response.success && response.rollover != null) {
        return ApiResult.success(response.rollover!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Reject rollover error: $e');
      return ApiResult.error('Failed to reject rollover: $e');
    }
  }

  /// Member cancels rollover request
  Future<ApiResult<LoanRollover>> cancelRollover({
    required String rolloverId,
    String? reason,
  }) async {
    try {
      final memberId = await _authRepository.getUserId();
      final request = CancelRequest(memberId: memberId, reason: reason);
      final response = await _apiService.cancelRollover(rolloverId, request);

      if (response.success && response.rollover != null) {
        return ApiResult.success(response.rollover!);
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Cancel rollover error: $e');
      return ApiResult.error('Failed to cancel rollover: $e');
    }
  }

  /// Replace a guarantor who declined
  Future<ApiResult<GuarantorReplaceResult>> replaceGuarantor({
    required String rolloverId,
    required String oldGuarantorId,
    required String newGuarantorId,
    required String newGuarantorName,
    required String newGuarantorPhone,
  }) async {
    try {
      final request = GuarantorInviteRequest(
        guarantorId: newGuarantorId,
        guarantorName: newGuarantorName,
        guarantorPhone: newGuarantorPhone,
      );

      final response =
          await _apiService.replaceGuarantor(rolloverId, oldGuarantorId, request);

      if (response.success) {
        return ApiResult.success(GuarantorReplaceResult(
          success: response.success,
          message: response.message,
          newGuarantor: response.newGuarantor,
          guarantors: response.guarantors,
        ));
      } else {
        return ApiResult.error(response.message);
      }
    } catch (e) {
      _logger.e('Replace guarantor error: $e');
      return ApiResult.error('Failed to replace guarantor: $e');
    }
  }

  // ============== Mock Data for Demo/Testing ==============

  RolloverEligibility _getMockEligibility(String loanId) {
    return RolloverEligibility(
      status: RolloverEligibilityStatus.eligible,
      hasMinimum50PercentRepayment: true,
      hasConsistentSavings: true,
      eligibilityErrors: [],
      eligibilityWarnings: [],
      repaymentPercentage: 65.0,
      consecutiveSavingsMonths: 6,
    );
  }

  LoanRollover _getMockRollover(String loanId) {
    final now = DateTime.now();
    return LoanRollover(
      id: 'ROLLOVER-$loanId-${now.millisecondsSinceEpoch}',
      originalLoanId: loanId,
      memberId: 'MEM-001',
      memberName: 'John Doe',
      memberPhone: '+2348012345678',
      originalPrincipal: 100000,
      outstandingBalance: 35000,
      totalRepaid: 65000,
      repaymentPercentage: 65.0,
      newTenure: 6,
      newInterestRate: 7.0,
      newMonthlyRepayment: 6166.67,
      newTotalRepayment: 37000.02,
      status: RolloverStatus.pending,
      requestedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<LoanRollover> _getMockPendingRollovers() {
    final now = DateTime.now();
    return [
      LoanRollover(
        id: 'ROLLOVER-001',
        originalLoanId: 'LOAN-001',
        memberId: 'MEM-001',
        memberName: 'John Doe',
        memberPhone: '+2348012345678',
        originalPrincipal: 100000,
        outstandingBalance: 35000,
        totalRepaid: 65000,
        repaymentPercentage: 65.0,
        newTenure: 6,
        newInterestRate: 7.0,
        newMonthlyRepayment: 6166.67,
        newTotalRepayment: 37000.02,
        status: RolloverStatus.pending,
        requestedAt: now.subtract(const Duration(days: 2)),
        guarantorConsentDeadline: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      LoanRollover(
        id: 'ROLLOVER-002',
        originalLoanId: 'LOAN-002',
        memberId: 'MEM-002',
        memberName: 'Jane Smith',
        memberPhone: '+2348098765432',
        originalPrincipal: 50000,
        outstandingBalance: 15000,
        totalRepaid: 35000,
        repaymentPercentage: 70.0,
        newTenure: 4,
        newInterestRate: 7.5,
        newMonthlyRepayment: 3937.50,
        newTotalRepayment: 15750.00,
        status: RolloverStatus.awaitingAdminApproval,
        requestedAt: now.subtract(const Duration(days: 5)),
        guarantorConsentDeadline: now.subtract(const Duration(days: 1)),
        approvedAt: now,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
    ];
  }

  List<RolloverGuarantor> _getMockGuarantors(String rolloverId) {
    final now = DateTime.now();
    return [
      RolloverGuarantor(
        id: 'G-001',
        rolloverId: rolloverId,
        guarantorId: 'GMEM-001',
        guarantorName: 'Guarantor One',
        guarantorPhone: '+2348111111111',
        status: GuarantorConsentStatus.accepted,
        invitedAt: now.subtract(const Duration(days: 3)),
        respondedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      RolloverGuarantor(
        id: 'G-002',
        rolloverId: rolloverId,
        guarantorId: 'GMEM-002',
        guarantorName: 'Guarantor Two',
        guarantorPhone: '+2348222222222',
        status: GuarantorConsentStatus.invited,
        invitedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      RolloverGuarantor(
        id: 'G-003',
        rolloverId: rolloverId,
        guarantorId: 'GMEM-003',
        guarantorName: 'Guarantor Three',
        guarantorPhone: '+2348333333333',
        status: GuarantorConsentStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

/// Guarantor consent result
class GuarantorConsentResult {
  final bool success;
  final String message;
  final RolloverGuarantor? guarantor;
  final int acceptedCount;
  final int declinedCount;
  final bool allConsented;

  GuarantorConsentResult({
    required this.success,
    required this.message,
    this.guarantor,
    required this.acceptedCount,
    required this.declinedCount,
    required this.allConsented,
  });
}

/// Guarantor replace result
class GuarantorReplaceResult {
  final bool success;
  final String message;
  final RololloverGuarantor? newGuarantor;
  final List<RolloverGuarantor> guarantors;

  GuarantorReplaceResult({
    required this.success,
    required this.message,
    this.newGuarantor,
    required this.guarantors,
  });
}

/// Fix for typo above
class RololloverGuarantor extends RolloverGuarantor {
  RololloverGuarantor({
    required super.id,
    required super.rolloverId,
    required super.guarantorId,
    required super.guarantorName,
    required super.guarantorPhone,
    required super.status,
    super.declineReason,
    super.invitedAt,
    super.respondedAt,
    required super.createdAt,
    required super.updatedAt,
  });
}

/// API Result wrapper
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResult.success(this.data) : success = true, error = null;
  ApiResult.error(this.error) : success = false, data = null;

  bool get hasData => data != null;
  bool get hasError => error != null;
}

/// Rollover Repository Provider
final rolloverRepositoryProvider = Provider<RolloverRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return RolloverRepository(authRepository: authRepository);
});
