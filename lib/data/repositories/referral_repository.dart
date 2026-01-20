import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/utils.dart';
import '../../data/api/referral_api_service.dart';
import '../../data/models/referral_models.dart';
import '../repositories/auth_repository.dart';

/// Referral Repository - Handles all referral operations
class ReferralRepository {
  final ReferralApiService _apiService;
  final AuthRepository _authRepository;

  ReferralRepository({
  ReferralApiService? apiService,
  AuthRepository? authRepository,
  })  : _apiService = apiService ?? ReferralApiService(ApiClient().dio),
  _authRepository = authRepository ?? AuthRepository(ApiClient());

  /// Get user's referral summary
  Future<ApiResult<ReferralSummary>> getReferralSummary() async {
  try {
  final response = await _apiService.getReferralSummary();

  if (response.success && response.summary != null) {
  return ApiResult.success(response.summary!);
  } else {
  // Return mock data for demo
  return ApiResult.success(_getMockReferralSummary());
  }
  } catch (e) {
  // Return mock data for demo
  return ApiResult.success(_getMockReferralSummary());
  }
  }

  /// Get user's referral code
  Future<ApiResult<String>> getReferralCode() async {
  try {
  final response = await _apiService.getMyReferralCode();

  if (response.success && response.referralCode != null) {
  return ApiResult.success(response.referralCode!);
  } else {
  // Generate mock code for demo
  final userId = await _authRepository.getUserId();
  final mockCode = 'COOP${userId.substring(0, 6).toUpperCase()}';
  return ApiResult.success(mockCode);
  }
  } catch (e) {
  final userId = await _authRepository.getUserId();
  return ApiResult.success('COOP${userId.substring(0, 6).toUpperCase()}');
  }
  }

  /// Get all user's referrals
  Future<ApiResult<List<Referral>>> getMyReferrals() async {
  try {
  final response = await _apiService.getMyReferrals();

  if (response.success) {
  return ApiResult.success(response.referrals);
  } else {
  return ApiResult.error(response.error ?? 'Failed to fetch referrals');
  }
  } catch (e) {
  return ApiResult.success(_getMockReferrals());
  }
  }

  /// Register a new referral
  Future<ApiResult<Referral>> registerReferral({
  required String referralCode,
  required String referredUserId,
  }) async {
  try {
  // Check for self-referral
  final userId = await _authRepository.getUserId();
  if (userId == referredUserId) {
  return ApiResult.error('Self-referrals are not allowed');
  }

  final request = ReferralRegisterRequest(
  referralCode: referralCode,
  referredUserId: referredUserId,
 );

  final response = await _apiService.registerReferral(request);

  if (response.success && response.referral != null) {
  return ApiResult.success(response.referral!);
  } else {
  return ApiResult.error(response.error ?? 'Failed to register referral');
  }
  } catch (e) {
  return ApiResult.error('Failed to register referral: $e');
  }
  }

  /// Check referral status
  Future<ApiResult<ReferralStatusResponse>> checkReferralStatus({
  required String referralId,
  }) async {
  try {
  final response = await _apiService.checkReferralStatus(referralId);

  if (response.success) {
  return ApiResult.success(response);
  } else {
  return ApiResult.error(response.error ?? 'Failed to check status');
  }
  } catch (e) {
  return ApiResult.error('Failed to check status: $e');
  }
  }

  /// Confirm a referral (when qualification criteria met)
  Future<ApiResult<Referral>> confirmReferral({
  required String referralId,
  }) async {
  try {
  final response = await _apiService.confirmReferral(referralId);

  if (response.success && response.referral != null) {
  return ApiResult.success(response.referral!);
  } else {
  return ApiResult.error(response.error ?? 'Failed to confirm referral');
  }
  } catch (e) {
  return ApiResult.error('Failed to confirm referral: $e');
  }
  }

  /// Apply referral bonus to a loan
  Future<ApiResult<ApplyBonusResponse>> applyBonusToLoan({
  required String loanId,
  }) async {
  try {
  final userId = await _authRepository.getUserId();
  final request = ApplyBonusRequest(
  loanId: loanId,
  userId: userId,
 );

  final response = await _apiService.applyBonusToLoan(request);

  if (response.success) {
  return ApiResult.success(ApplyBonusResponse(
  success: true,
  bonusPercent: response.bonusPercent,
  loanId: response.loanId,
  appliedAt: response.appliedAt,
 ));
  } else {
  return ApiResult.error(response.error ?? 'Failed to apply bonus');
  }
  } catch (e) {
  return ApiResult.error('Failed to apply bonus: $e');
  }
  }

  /// Calculate loan interest with referral bonus
  Future<ApiResult<LoanInterestCalculation>> calculateInterestWithBonus({
  required String loanType,
  required double loanAmount,
  required int tenureMonths,
  }) async {
  try {
  // First get user's current tier bonus
  final summaryResult = await getReferralSummary();
  final bonusPercent = summaryResult.data?.currentTierBonus ?? 0;
  final isBonusAvailable = summaryResult.data?.isBonusAvailable ?? false;

  final request = InterestCalculationRequest(
  loanType: loanType,
  loanAmount: loanAmount,
  tenureMonths: tenureMonths,
 );

  final response = await _apiService.calculateInterestWithBonus(request);

  if (response.success && response.calculation != null) {
  return ApiResult.success(response.calculation!);
  } else {
  // Calculate locally
  final calculation = LoanInterestCalculation.calculate(
  loanType: loanType,
  baseInterestRate: _getBaseInterestRate(loanType),
  referralBonusPercent: isBonusAvailable ? bonusPercent : 0,
  loanAmount: loanAmount,
  tenureMonths: tenureMonths,
  bonusAvailable: isBonusAvailable,
  bonusNotAppliedReason: isBonusAvailable ? null : 'Bonus not yet available',
 );
  return ApiResult.success(calculation);
  }
  } catch (e) {
  // Calculate locally as fallback
  final summaryResult = await getReferralSummary();
  final bonusPercent = summaryResult.data?.currentTierBonus ?? 0;
  final isBonusAvailable = summaryResult.data?.isBonusAvailable ?? false;

  final calculation = LoanInterestCalculation.calculate(
  loanType: loanType,
  baseInterestRate: _getBaseInterestRate(loanType),
  referralBonusPercent: isBonusAvailable ? bonusPercent : 0,
  loanAmount: loanAmount,
  tenureMonths: tenureMonths,
  bonusAvailable: isBonusAvailable,
 );
  return ApiResult.success(calculation);
  }
  }

  /// Get share link for referral
  Future<ApiResult<ShareLinkResponse>> getShareLink() async {
  try {
  final response = await _apiService.getShareLink();

  if (response.success) {
  return ApiResult.success(ShareLinkResponse(
  success: true,
  shareLink: response.shareLink ?? 'https://coopvest.app/register?ref=${await getReferralCode()}',
  referralCode: response.referralCode ?? await getReferralCode(),
  qrCodeUrl: response.qrCodeUrl,
 ));
  } else {
  return ApiResult.error(response.error ?? 'Failed to get share link');
  }
  } catch (e) {
  final code = await getReferralCode();
  return ApiResult.success(ShareLinkResponse(
  success: true,
  shareLink: 'https://coopvest.app/register?ref=$code',
  referralCode: code,
  qrCodeUrl: null,
 ));
  }
  }

  /// Calculate tier based on confirmed referral count
  static double calculateTierBonus(int confirmedReferralCount) {
  return Referral.calculateTierBonus(confirmedReferralCount);
  }

  /// Get base interest rate for loan type
  double _getBaseInterestRate(String loanType) {
  switch (loanType) {
  case 'Quick Loan': return 5.0;
  case 'Flexi Loan': return 6.0;
  case 'Emergency Loan': return 7.0;
  case 'Business Loan': return 8.0;
  default: return 5.0;
  }
  }

  // ============== Mock Data for Demo ==============

  ReferralSummary _getMockReferralSummary() {
  final now = DateTime.now();
  return ReferralSummary(
  userId: 'user-001',
  referralCode: 'COOPUSER1',
  pendingReferrals: 3,
  confirmedReferrals: 4,
  totalReferrals: 7,
  currentTierBonus: 3.0,
  currentTierDescription: 'Silver Tier (3% OFF)',
  isBonusAvailable: true,
  nextBonusUnlockDate: null,
  recentReferrals: _getMockReferrals().take(5).toList(),
 );
  }

  List<Referral> _getMockReferrals() {
  final now = DateTime.now();
  return [
  Referral(
  id: 'ref-001',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-002',
  referredName: 'Jane Smith',
  referralCode: 'COOPUSER1',
  confirmed: true,
  confirmationDate: now.subtract(const Duration(days: 45)),
  lockInEndDate: now.subtract(const Duration(days: 15)),
  tierBonusPercent: 2.0,
  bonusConsumed: false,
  kycVerified: true,
  savingsCriteriaMet: true,
  consecutiveSavingsMonths: 4,
  totalSavingsAmount: 25000,
  createdAt: now.subtract(const Duration(days: 120)),
  updatedAt: now.subtract(const Duration(days: 45)),
 ),
  Referral(
  id: 'ref-002',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-003',
  referredName: 'Bob Wilson',
  referralCode: 'COOPUSER1',
  confirmed: true,
  confirmationDate: now.subtract(const Duration(days: 60)),
  lockInEndDate: now.subtract(const Duration(days: 30)),
  tierBonusPercent: 3.0,
  bonusConsumed: false,
  kycVerified: true,
  savingsCriteriaMet: true,
  consecutiveSavingsMonths: 5,
  totalSavingsAmount: 30000,
  createdAt: now.subtract(const Duration(days: 150)),
  updatedAt: now.subtract(const Duration(days: 60)),
 ),
  Referral(
  id: 'ref-003',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-004',
  referredName: 'Alice Brown',
  referralCode: 'COOPUSER1',
  confirmed: true,
  confirmationDate: now.subtract(const Duration(days: 90)),
  lockInEndDate: now.subtract(const Duration(days: 60)),
  tierBonusPercent: 4.0,
  bonusConsumed: true,
  bonusUsedLoanId: 'LOAN-001',
  kycVerified: true,
  savingsCriteriaMet: true,
  consecutiveSavingsMonths: 6,
  totalSavingsAmount: 45000,
  createdAt: now.subtract(const Duration(days: 180)),
  updatedAt: now.subtract(const Duration(days: 90)),
 ),
  Referral(
  id: 'ref-004',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-005',
  referredName: 'Charlie Davis',
  referralCode: 'COOPUSER1',
  confirmed: true,
  confirmationDate: now.subtract(const Duration(days: 75)),
  lockInEndDate: now.subtract(const Duration(days: 45)),
  tierBonusPercent: 4.0,
  bonusConsumed: false,
  kycVerified: true,
  savingsCriteriaMet: true,
  consecutiveSavingsMonths: 4,
  totalSavingsAmount: 20000,
  createdAt: now.subtract(const Duration(days: 165)),
  updatedAt: now.subtract(const Duration(days: 75)),
 ),
  Referral(
  id: 'ref-005',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-006',
  referredName: 'Eve Foster',
  referralCode: 'COOPUSER1',
  confirmed: false,
  kycVerified: true,
  savingsCriteriaMet: false,
  consecutiveSavingsMonths: 1,
  totalSavingsAmount: 5000,
  createdAt: now.subtract(const Duration(days: 30)),
  updatedAt: now.subtract(const Duration(days: 30)),
 ),
  Referral(
  id: 'ref-006',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-007',
  referredName: 'George Hall',
  referralCode: 'COOPUSER1',
  confirmed: false,
  kycVerified: false,
  savingsCriteriaMet: false,
  consecutiveSavingsMonths: 0,
  totalSavingsAmount: 0,
  createdAt: now.subtract(const Duration(days: 15)),
  updatedAt: now.subtract(const Duration(days: 15)),
 ),
  Referral(
  id: 'ref-007',
  referrerId: 'user-001',
  referrerName: 'John Doe',
  referredId: 'user-008',
  referredName: 'Ivy Johnson',
  referralCode: 'COOPUSER1',
  confirmed: false,
  isFlagged: true,
  flaggedReason: 'Duplicate device detected',
  kycVerified: true,
  savingsCriteriaMet: false,
  consecutiveSavingsMonths: 0,
  totalSavingsAmount: 0,
  createdAt: now.subtract(const Duration(days: 10)),
  updatedAt: now.subtract(const Duration(days: 10)),
 ),
  ];
  }
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

/// Apply Bonus Response for local use
class ApplyBonusResponse {
  final bool success;
  final String? error;
  final double bonusPercent;
  final String loanId;
  final DateTime? appliedAt;

  ApplyBonusResponse({
  required this.success,
  this.error,
  required this.bonusPercent,
  required this.loanId,
  this.appliedAt,
  });
}

/// Share Link Response for local use
class ShareLinkResponse {
  final bool success;
  final String? error;
  final String? shareLink;
  final String? referralCode;
  final String? qrCodeUrl;

  ShareLinkResponse({
  required this.success,
  this.error,
  this.shareLink,
  this.referralCode,
  this.qrCodeUrl,
  });
}

/// Referral Repository Provider
final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ReferralRepository(authRepository: authRepository);
});