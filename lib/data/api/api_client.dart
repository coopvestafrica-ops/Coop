import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'loan_api_service.dart';

/// API Client Configuration and Factory
class ApiClient {
  static const String baseUrl = 'https://api.coopvest.africa/v1';
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Dio instance
  Dio? _dio;
  LoanApiService? _loanApiService;

  // Get Dio instance
  Dio getDio() {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(milliseconds: connectTimeout),
          receiveTimeout: Duration(milliseconds: receiveTimeout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add interceptors
      _dio!.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
        ),
      );
    }

    return _dio!;
  }

  // Get Loan API Service
  LoanApiService getLoanApiService() {
    if (_loanApiService == null) {
      _loanApiService = LoanApiService(
        getDio(),
        baseUrl: baseUrl,
      );
    }

    return _loanApiService!;
  }

  // Set Auth Token
  void setAuthToken(String token) {
    getDio().options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear Auth Token
  void clearAuthToken() {
    getDio().options.headers.remove('Authorization');
  }

  // Set Custom Headers
  void setHeaders(Map<String, String> headers) {
    getDio().options.headers.addAll(headers);
  }

  // Reset Client
  void reset() {
    _dio = null;
    _loanApiService = null;
  }
}

/// API Error Handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

/// Result wrapper for API responses
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) {
    return ApiResult(data: data, isSuccess: true);
  }

  factory ApiResult.error(String error) {
    return ApiResult(error: error, isSuccess: false);
  }

  bool get hasData => data != null;
  bool get hasError => error != null;
}

/// Extension for handling Dio errors
extension DioErrorExtension on DioException {
  ApiException toApiException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Send timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Security certificate error.',
          statusCode: 495,
        );
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final errorMessage = response?.data?['message'] ?? 'Request failed';
        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: -1,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          statusCode: -1,
        );
      case DioExceptionType.unknown:
        return ApiException(
          message: 'An unexpected error occurred. Please try again.',
        );
    }
  }
}

/// API Repository for Loans
class LoanRepository {
  final LoanApiService _apiService;

  LoanRepository({LoanApiService? apiService})
      : _apiService = apiService ?? ApiClient().getLoanApiService();

  /// Apply for a new loan
  Future<ApiResult<LoanData>> applyForLoan({
    required String userId,
    required String loanType,
    required double amount,
    required String purpose,
    required double monthlySavings,
  }) async {
    try {
      final response = await _apiService.applyForLoan(
        LoanApplicationRequest(
          userId: userId,
          loanType: loanType,
          amount: amount,
          purpose: purpose,
          monthlySavings: monthlySavings,
        ),
      );

      if (response.success && response.loan != null) {
        return ApiResult.success(response.loan!);
      } else {
        return ApiResult.error(response.message);
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to apply for loan: $e');
    }
  }

  /// Get all loans for a user
  Future<ApiResult<List<LoanData>>> getUserLoans(String userId) async {
    try {
      final response = await _apiService.getUserLoans(userId);

      if (response.success) {
        return ApiResult.success(response.loans);
      } else {
        return ApiResult.error('Failed to fetch loans');
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to fetch loans: $e');
    }
  }

  /// Get loan details
  Future<ApiResult<LoanDetailsResponse>> getLoanDetails(String loanId) async {
    try {
      final response = await _apiService.getLoanDetails(loanId);

      if (response.success) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error('Failed to fetch loan details');
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to fetch loan details: $e');
    }
  }

  /// Get loan status
  Future<ApiResult<LoanStatusResponse>> getLoanStatus(String loanId) async {
    try {
      final response = await _apiService.getLoanStatus(loanId);

      if (response.success) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error('Failed to fetch loan status');
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to fetch loan status: $e');
    }
  }

  /// Confirm guarantee
  Future<ApiResult<GuarantorConfirmResponse>> confirmGuarantee({
    required String loanId,
    required String guarantorId,
    required String guarantorName,
    required String guarantorPhone,
    required double savingsBalance,
  }) async {
    try {
      final response = await _apiService.confirmGuarantee(
        loanId,
        GuarantorConfirmRequest(
          guarantorId: guarantorId,
          guarantorName: guarantorName,
          guarantorPhone: guarantorPhone,
          savingsBalance: savingsBalance,
        ),
      );

      if (response.success) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error(response.message);
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to confirm guarantee: $e');
    }
  }

  /// Decline guarantee
  Future<ApiResult<GuarantorDeclineResponse>> declineGuarantee({
    required String loanId,
    required String guarantorId,
    required String reason,
  }) async {
    try {
      final response = await _apiService.declineGuarantee(
        loanId,
        GuarantorDeclineRequest(
          guarantorId: guarantorId,
          reason: reason,
        ),
      );

      if (response.success) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error(response.message);
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to decline guarantee: $e');
    }
  }

  /// Get repayment schedule
  Future<ApiResult<RepaymentScheduleData>> getRepaymentSchedule(
      String loanId) async {
    try {
      final response = await _apiService.getRepaymentSchedule(loanId);

      if (response.success && response.schedule != null) {
        return ApiResult.success(response.schedule!);
      } else {
        return ApiResult.error('Failed to fetch repayment schedule');
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to fetch repayment schedule: $e');
    }
  }

  /// Make repayment
  Future<ApiResult<LoanRepayResponse>> makeRepayment({
    required String loanId,
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.makeRepayment(
        loanId,
        LoanRepayRequest(
          userId: userId,
          amount: amount,
          paymentMethod: paymentMethod,
        ),
      );

      if (response.success) {
        return ApiResult.success(response);
      } else {
        return ApiResult.error(response.message);
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to make repayment: $e');
    }
  }

  /// Get available loan types
  Future<ApiResult<List<LoanTypeData>>> getLoanTypes() async {
    try {
      final response = await _apiService.getLoanTypes();

      if (response.success) {
        return ApiResult.success(response.loanTypes);
      } else {
        return ApiResult.error('Failed to fetch loan types');
      }
    } on DioException catch (e) {
      return ApiResult.error(e.toApiException().message);
    } catch (e) {
      return ApiResult.error('Failed to fetch loan types: $e');
    }
  }
}
