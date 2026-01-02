import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/network/api_client.dart';
import 'rollover_models.dart';

part 'rollover_api_service.g.dart';

/// API Service for Loan Rollover Operations
@RestApi()
abstract class RolloverApiService {
  factory RolloverApiService(Dio dio, {String baseUrl = '/api/v1'}) =
      _RolloverApiService;

  /// Check eligibility for a loan rollover
  @GET('/loans/{loanId}/rollover/eligibility')
  Future<RolloverEligibilityResponse> checkEligibility(
    @Path() String loanId,
  );

  /// Create a new rollover request
  @POST('/loans/{loanId}/rollover/request')
  Future<RolloverRequestResponse> createRolloverRequest(
    @Path() String loanId,
    @Body() RolloverRequest request,
  );

  /// Get rollover details by ID
  @GET('/rollover/{rolloverId}')
  Future<RolloverDetailsResponse> getRolloverDetails(
    @Path() String rolloverId,
  );

  /// Get all rollover requests for a member
  @GET('/members/{memberId}/rollovers')
  Future<RolloverListResponse> getMemberRollovers(
    @Path() String memberId,
  );

  /// Get rollover requests for admin review
  @GET('/admin/rollover/pending')
  Future<RolloverListResponse> getPendingRollovers();

  /// Get all rollover requests for admin
  @GET('/admin/rollover/all')
  Future<RolloverListResponse> getAllAdminRollovers();

  /// Invite a guarantor for rollover
  @POST('/rollover/{rolloverId}/guarantors/invite')
  Future<GuarantorInviteResponse> inviteGuarantor(
    @Path() String rolloverId,
    @Body() GuarantorInviteRequest request,
  );

  /// Get guarantors for a rollover
  @GET('/rollover/{rolloverId}/guarantors')
  Future<GuarantorListResponse> getRolloverGuarantors(
    @Path() String rolloverId,
  );

  /// Guarantor responds to rollover consent request
  @POST('/rollover/{rolloverId}/guarantors/{guarantorId}/respond')
  Future<GuarantorConsentResponse> guarantorRespond(
    @Path() String rolloverId,
    @Path() String guarantorId,
    @Body() GuarantorRespondRequest request,
  );

  /// Admin approves rollover request
  @POST('/admin/rollover/{rolloverId}/approve')
  Future<RolloverActionResponse> approveRollover(
    @Path() String rolloverId,
    @Body() AdminActionRequest request,
  );

  /// Admin rejects rollover request
  @POST('/admin/rollover/{rolloverId}/reject')
  Future<RolloverActionResponse> rejectRollover(
    @Path() String rolloverId,
    @Body() AdminRejectRequest request,
  );

  /// Member cancels rollover request
  @POST('/rollover/{rolloverId}/cancel')
  Future<RolloverActionResponse> cancelRollover(
    @Path() String rolloverId,
    @Body() CancelRequest request,
  );

  /// Replace a guarantor who declined
  @POST('/rollover/{rolloverId}/guarantors/{guarantorId}/replace')
  Future<GuarantorReplaceResponse> replaceGuarantor(
    @Path() String rolloverId,
    @Path() String guarantorId,
    @Body() GuarantorInviteRequest request,
  );
}

/// Rollover API Service Provider
final rolloverApiServiceProvider = Provider<RolloverApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RolloverApiService(apiClient.dio);
});

// ============== Request Models ==============

class RolloverRequest {
  final String loanId;
  final String memberId;
  final int newTenure;
  final List<GuarantorInfo> guarantors;

  RolloverRequest({
    required this.loanId,
    required this.memberId,
    required this.newTenure,
    required this.guarantors,
  });

  Map<String, dynamic> toJson() => {
        'loan_id': loanId,
        'member_id': memberId,
        'new_tenure': newTenure,
        'guarantors': guarantors.map((e) => e.toJson()).toList(),
      };
}

class GuarantorInfo {
  final String guarantorId;
  final String guarantorName;
  final String guarantorPhone;

  GuarantorInfo({
    required this.guarantorId,
    required this.guarantorName,
    required this.guarantorPhone,
  });

  Map<String, dynamic> toJson() => {
        'guarantor_id': guarantorId,
        'guarantor_name': guarantorName,
        'guarantor_phone': guarantorPhone,
      };
}

class GuarantorInviteRequest {
  final String guarantorId;
  final String guarantorName;
  final String guarantorPhone;

  GuarantorInviteRequest({
    required this.guarantorId,
    required this.guarantorName,
    required this.guarantorPhone,
  });

  Map<String, dynamic> toJson() => {
        'guarantor_id': guarantorId,
        'guarantor_name': guarantorName,
        'guarantor_phone': guarantorPhone,
      };
}

class GuarantorRespondRequest {
  final String guarantorId;
  final bool accepted;
  final String? reason;

  GuarantorRespondRequest({
    required this.guarantorId,
    required this.accepted,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'guarantor_id': guarantorId,
        'accepted': accepted,
        'if': accepted,
        'reason': reason,
      };
}

class AdminActionRequest {
  final String adminId;
  final String? notes;

  AdminActionRequest({
    required this.adminId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'admin_id': adminId,
        'notes': notes,
      };
}

class AdminRejectRequest {
  final String adminId;
  final String reason;

  AdminRejectRequest({
    required this.adminId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'admin_id': adminId,
        'reason': reason,
      };
}

class CancelRequest {
  final String memberId;
  final String? reason;

  CancelRequest({
    required this.memberId,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'reason': reason,
      };
}

// ============== Response Models ==============

class RolloverEligibilityResponse {
  final bool success;
  final String message;
  final RolloverEligibility? eligibility;

  RolloverEligibilityResponse({
    required this.success,
    required this.message,
    this.eligibility,
  });

  factory RolloverEligibilityResponse.fromJson(Map<String, dynamic> json) {
    return RolloverEligibilityResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      eligibility: json['eligibility'] != null
          ? RolloverEligibility.fromJson(json['eligibility'])
          : null,
    );
  }
}

class RolloverRequestResponse {
  final bool success;
  final String message;
  final LoanRollover? rollover;

  RolloverRequestResponse({
    required this.success,
    required this.message,
    this.rollover,
  });

  factory RolloverRequestResponse.fromJson(Map<String, dynamic> json) {
    return RolloverRequestResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      rollover: json['rollover'] != null
          ? LoanRollover.fromJson(json['rollover'])
          : null,
    );
  }
}

class RolloverDetailsResponse {
  final bool success;
  final String message;
  final LoanRollover? rollover;
  final List<RolloverGuarantor>? guarantors;

  RolloverDetailsResponse({
    required this.success,
    required this.message,
    this.rollover,
    this.guarantors,
  });

  factory RolloverDetailsResponse.fromJson(Map<String, dynamic> json) {
    return RolloverDetailsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      rollover: json['rollover'] != null
          ? LoanRollover.fromJson(json['rollover'])
          : null,
      guarantors: json['guarantors'] != null
          ? (json['guarantors'] as List<dynamic>)
              .map((e) => RolloverGuarantor.fromJson(e))
              .toList()
          : null,
    );
  }
}

class RolloverListResponse {
  final bool success;
  final String message;
  final List<LoanRollover> rollovers;

  RolloverListResponse({
    required this.success,
    required this.message,
    required this.rollovers,
  });

  factory RolloverListResponse.fromJson(Map<String, dynamic> json) {
    return RolloverListResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      rollovers: (json['rollovers'] as List<dynamic>)
          .map((e) => LoanRollover.fromJson(e))
          .toList(),
    );
  }
}

class GuarantorInviteResponse {
  final bool success;
  final String message;
  final RolloverGuarantor? guarantor;

  GuarantorInviteResponse({
    required this.success,
    required this.message,
    this.guarantor,
  });

  factory GuarantorInviteResponse.fromJson(Map<String, dynamic> json) {
    return GuarantorInviteResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      guarantor: json['guarantor'] != null
          ? RolloverGuarantor.fromJson(json['guarantor'])
          : null,
    );
  }
}

class GuarantorListResponse {
  final bool success;
  final String message;
  final List<RolloverGuarantor> guarantors;

  GuarantorListResponse({
    required this.success,
    required this.message,
    required this.guarantors,
  });

  factory GuarantorListResponse.fromJson(Map<String, dynamic> json) {
    return GuarantorListResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      guarantors: (json['guarantors'] as List<dynamic>)
          .map((e) => RolloverGuarantor.fromJson(e))
          .toList(),
    );
  }
}

class GuarantorConsentResponse {
  final bool success;
  final String message;
  final RolloverGuarantor? guarantor;
  final int acceptedCount;
  final int declinedCount;
  final bool allConsented;

  GuarantorConsentResponse({
    required this.success,
    required this.message,
    this.guarantor,
    required this.acceptedCount,
    required this.declinedCount,
    required this.allConsented,
  });

  factory GuarantorConsentResponse.fromJson(Map<String, dynamic> json) {
    return GuarantorConsentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      guarantor: json['guarantor'] != null
          ? RolloverGuarantor.fromJson(json['guarantor'])
          : null,
      acceptedCount: json['accepted_count'] as int,
      declinedCount: json['declined_count'] as int,
      allConsented: json['all_consented'] as bool,
    );
  }
}

class RolloverActionResponse {
  final bool success;
  final String message;
  final LoanRollover? rollover;

  RolloverActionResponse({
    required this.success,
    required this.message,
    this.rollover,
  });

  factory RolloverActionResponse.fromJson(Map<String, dynamic> json) {
    return RolloverActionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      rollover: json['rollover'] != null
          ? LoanRollover.fromJson(json['rollover'])
          : null,
    );
  }
}

class GuarantorReplaceResponse {
  final bool success;
  final String message;
  final RolloverGuarantor? newGuarantor;
  final List<RolloverGuarantor> guarantors;

  GuarantorReplaceResponse({
    required this.success,
    required this.message,
    this.newGuarantor,
    required this.guarantors,
  });

  factory GuarantorReplaceResponse.fromJson(Map<String, dynamic> json) {
    return GuarantorReplaceResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      newGuarantor: json['new_guarantor'] != null
          ? RolloverGuarantor.fromJson(json['new_guarantor'])
          : null,
      guarantors: (json['guarantors'] as List<dynamic>)
          .map((e) => RolloverGuarantor.fromJson(e))
          .toList(),
    );
  }
}
