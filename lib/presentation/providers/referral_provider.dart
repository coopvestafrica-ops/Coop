import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/utils.dart';
import '../../core/services/logger_service.dart';
import '../../data/api/referral_api_service.dart';
import '../../data/models/referral_models.dart';
import '../../data/repositories/referral_repository.dart' hide ShareLinkResponse;

/// Referral State
class ReferralState {
  final ReferralStatus status;
  final ReferralSummary? summary;
  final List<Referral> referrals;
  final LoanInterestCalculation? interestCalculation;
  final String? referralCode;
  final ShareLinkResponse? shareLink;
  final String? error;

  const ReferralState({
  this.status = ReferralStatus.initial,
  this.summary,
  this.referrals = [],
  this.interestCalculation,
  this.referralCode,
  this.shareLink,
  this.error,
  });

  bool get isLoading => status == ReferralStatus.loading;
  bool get isLoaded => status == ReferralStatus.loaded;
  bool get hasError => status == ReferralStatus.error;

  // Computed values
  int get confirmedCount => summary?.confirmedReferrals ?? 0;
  int get pendingCount => summary?.pendingReferrals ?? 0;
  double get currentBonus => summary?.currentTierBonus ?? 0;
  bool get isBonusAvailable => summary?.isBonusAvailable ?? false;
  String get tierDescription => summary?.currentTierDescription ?? 'No Bonus Yet';

  ReferralState copyWith({
  ReferralStatus? status,
  ReferralSummary? summary,
  List<Referral>? referrals,
  LoanInterestCalculation? interestCalculation,
  String? referralCode,
  ShareLinkResponse? shareLink,
  String? error,
  }) {
  return ReferralState(
  status: status ?? this.status,
  summary: summary ?? this.summary,
  referrals: referrals ?? this.referrals,
  interestCalculation: interestCalculation ?? this.interestCalculation,
  referralCode: referralCode ?? this.referralCode,
  shareLink: shareLink ?? this.shareLink,
  error: error ?? this.error,
 );
  }
}

/// Referral Status
enum ReferralStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Referral Notifier
class ReferralNotifier extends StateNotifier<ReferralState> {
  final ReferralRepository _repository;
  final LoggerService _logger;

  ReferralNotifier(this._repository) : _logger = LoggerService(), super(const ReferralState());

  /// Load referral summary
  Future<void> loadReferralSummary() async {
  state = state.copyWith(status: ReferralStatus.loading, error: null);
  try {
  final result = await _repository.getReferralSummary();
  if (result.success && result.data != null) {
  state = state.copyWith(
  status: ReferralStatus.loaded,
  summary: result.data,
 );
  } else {
  state = state.copyWith(
  status: ReferralStatus.error,
  error: result.error ?? 'Failed to load referral summary',
 );
  }
  } catch (e) {
  _logger.e('Load referral summary error: $e');
  state = state.copyWith(
  status: ReferralStatus.error,
  error: e.toString(),
 );
  }
  }

  /// Load user's referral code
  Future<void> loadReferralCode() async {
  try {
  final result = await _repository.getReferralCode();
  if (result.success && result.data != null) {
  state = state.copyWith(referralCode: result.data);
  }
  } catch (e) {
  _logger.e('Load referral code error: $e');
  }
  }

  /// Load all referrals
  Future<void> loadReferrals() async {
  state = state.copyWith(status: ReferralStatus.loading, error: null);
  try {
  final result = await _repository.getMyReferrals();
  if (result.success && result.data != null) {
  state = state.copyWith(
  status: ReferralStatus.loaded,
  referrals: result.data,
 );
  } else {
  state = state.copyWith(
  status: ReferralStatus.error,
  error: result.error ?? 'Failed to load referrals',
 );
  }
  } catch (e) {
  _logger.e('Load referrals error: $e');
  state = state.copyWith(
  status: ReferralStatus.error,
  error: e.toString(),
 );
  }
  }

  /// Calculate interest with bonus
  Future<void> calculateInterest({
  required String loanType,
  required double loanAmount,
  required int tenureMonths,
  }) async {
  try {
  final result = await _repository.calculateInterestWithBonus(
  loanType: loanType,
  loanAmount: loanAmount,
  tenureMonths: tenureMonths,
 );
  if (result.success && result.data != null) {
  state = state.copyWith(interestCalculation: result.data);
  }
  } catch (e) {
  _logger.e('Calculate interest error: $e');
  }
  }

  /// Get share link
  Future<void> loadShareLink() async {
  try {
  final result = await _repository.getShareLink();
  if (result.success && result.data != null) {
  state = state.copyWith(shareLink: result.data);
  }
  } catch (e) {
  _logger.e('Load share link error: $e');
  }
  }

  /// Register a new referral
  Future<bool> registerReferral({
  required String referralCode,
  required String referredUserId,
  }) async {
  state = state.copyWith(status: ReferralStatus.loading, error: null);
  try {
  final result = await _repository.registerReferral(
  referralCode: referralCode,
  referredUserId: referredUserId,
 );
  if (result.success) {
  await loadReferrals();
  await loadReferralSummary();
  return true;
  } else {
  state = state.copyWith(
  status: ReferralStatus.error,
  error: result.error,
 );
  return false;
  }
  } catch (e) {
  _logger.e('Register referral error: $e');
  state = state.copyWith(
  status: ReferralStatus.error,
  error: e.toString(),
 );
  return false;
  }
  }

  /// Apply bonus to loan
  Future<bool> applyBonusToLoan({required String loanId}) async {
  try {
  final result = await _repository.applyBonusToLoan(loanId: loanId);
  if (result.success) {
  await loadReferralSummary();
  return true;
  } else {
  state = state.copyWith(error: result.error);
  return false;
  }
  } catch (e) {
  _logger.e('Apply bonus error: $e');
  state = state.copyWith(error: e.toString());
  return false;
  }
  }

  /// Get tier progress info
  TierProgress getTierProgress() {
  final confirmed = confirmedCount;
  final currentBonus = currentBonus;

  if (currentBonus >= 4.0) {
  return TierProgress(
  currentTier: 4.0,
  tierName: 'Gold',
  nextTier: null,
  referralsToNext: 0,
  progress: 1.0,
  isMaxTier: true,
 );
  }

  if (currentBonus >= 3.0) {
  return TierProgress(
  currentTier: 3.0,
  tierName: 'Silver',
  nextTier: 4.0,
  referralsToNext: 6 - confirmed,
  progress: confirmed / 6,
  isMaxTier: false,
 );
  }

  if (currentBonus >= 2.0) {
  return TierProgress(
  currentTier: 2.0,
  tierName: 'Bronze',
  nextTier: 3.0,
  referralsToNext: 4 - confirmed,
  progress: confirmed / 4,
  isMaxTier: false,
 );
  }

  // Starting tier
  return TierProgress(
  currentTier: 0,
  tierName: 'None',
  nextTier: 2.0,
  referralsToNext: 2 - confirmed,
  progress: confirmed / 2,
  isMaxTier: false,
 );
  }

  /// Clear error
  void clearError() {
  state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
  state = const ReferralState();
  }
}

/// Tier Progress Info
class TierProgress {
  final double currentTier;
  final String tierName;
  final double? nextTier;
  final int referralsToNext;
  final double progress;
  final bool isMaxTier;

  TierProgress({
  required this.currentTier,
  required this.tierName,
  this.nextTier,
  required this.referralsToNext,
  required this.progress,
  required this.isMaxTier,
  });
}

/// Referral Provider
final referralProvider = StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final repository = ref.watch(referralRepositoryProvider);
  return ReferralNotifier(repository);
});
