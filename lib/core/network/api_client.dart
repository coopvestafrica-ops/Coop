import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/utils.dart';
import '../../config/app_config.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// API Client Implementation
class ApiClient {
  late final Dio _dio;
  bool _initialized = false;

  ApiClient() {
    _initialize();
  }

  void _initialize() {
    if (_initialized) return;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
    _dio.interceptors.add(AuthInterceptor());
    
    _initialized = true;
  }

  /// GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(DioException error) {
    logger.e('API Error: ${error.message}', error: error, stackTrace: error.stackTrace);
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      switch (statusCode) {
        case 400: return ValidationException(data['message'] ?? 'Bad request');
        case 401: return AuthException('Unauthorized. Please login again.');
        case 403: return AuthException('Access forbidden');
        case 404: return ServerException('Resource not found', statusCode: statusCode);
        case 500: return ServerException('Server error. Please try again later.', statusCode: statusCode);
        default: return ServerException(data['message'] ?? 'An error occurred', statusCode: statusCode);
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return NetworkException('Connection timeout. Please check your internet.');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Request timeout. Please try again.');
    }
    return NetworkException(error.message ?? 'An error occurred');
  }

  /// Set authorization token
  void setAuthToken(String token) {
    _initialize();
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization token
  void clearAuthToken() {
    _initialize();
    _dio.options.headers.remove('Authorization');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException({required this.message, this.statusCode});
  @override String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  ApiResult({this.data, this.error, required this.isSuccess});
  factory ApiResult.success(T data) => ApiResult(data: data, isSuccess: true);
  factory ApiResult.error(String error) => ApiResult(error: error, isSuccess: false);
}

class LoggingInterceptor extends Interceptor {
  @override void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.enableRequestLogging) {
      logger.i('API Request: ${options.method} ${options.path}');
    }
    handler.next(options);
  }
  @override void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.enableResponseLogging) {
      logger.i('API Response: ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }
  @override void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('API Error: ${err.message}');
    handler.next(err);
  }
}

class AuthInterceptor extends Interceptor {
  @override void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
