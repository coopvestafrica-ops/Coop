// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_api_service.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element

/// class _LoanApiService implements LoanApiService {
class _LoanApiService implements LoanApiService {
  _LoanApiService(
  this._dio, {
  this.baseUrl,
  this.errorLogger,
  });

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<LoanResponse> applyForLoan(LoanApplicationRequest request) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<LoanResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/apply',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanResponse _value;
  try {
  _value = LoanResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoansListResponse> getUserLoans(String userId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<LoansListResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/users/${userId}/loans',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoansListResponse _value;
  try {
  _value = LoansListResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoanDetailsResponse> getLoanDetails(String loanId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<LoanDetailsResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanDetailsResponse _value;
  try {
  _value = LoanDetailsResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoanStatusResponse> getLoanStatus(String loanId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<LoanStatusResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/status',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanStatusResponse _value;
  try {
  _value = LoanStatusResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorsListResponse> getLoanGuarantors(String loanId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<GuarantorsListResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/guarantors',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorsListResponse _value;
  try {
  _value = GuarantorsListResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorConfirmResponse> confirmGuarantee(
  String loanId,
  GuarantorConfirmRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<GuarantorConfirmResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/guarantors/confirm',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorConfirmResponse _value;
  try {
  _value = GuarantorConfirmResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorDeclineResponse> declineGuarantee(
  String loanId,
  GuarantorDeclineRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<GuarantorDeclineResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/guarantors/decline',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorDeclineResponse _value;
  try {
  _value = GuarantorDeclineResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoanCancelResponse> cancelLoan(
  String loanId,
  LoanCancelRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<LoanCancelResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/cancel',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanCancelResponse _value;
  try {
  _value = LoanCancelResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<RepaymentScheduleResponse> getRepaymentSchedule(String loanId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<RepaymentScheduleResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/repayment-schedule',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RepaymentScheduleResponse _value;
  try {
  _value = RepaymentScheduleResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoanRepayResponse> makeRepayment(
  String loanId,
  LoanRepayRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<LoanRepayResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/repay',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanRepayResponse _value;
  try {
  _value = LoanRepayResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<LoanTypesResponse> getLoanTypes() async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<LoanTypesResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/types',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late LoanTypesResponse _value;
  try {
  _value = LoanTypesResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
  if (T != dynamic &&
  !(requestOptions.responseType == ResponseType.bytes ||
  requestOptions.responseType == ResponseType.stream)) {
  if (T == String) {
  requestOptions.responseType = ResponseType.plain;
  } else {
  requestOptions.responseType = ResponseType.json;
  }
  }
  return requestOptions;
  }

  String _combineBaseUrls(
  String dioBaseUrl,
  String? baseUrl,
 ) {
  if (baseUrl == null || baseUrl.trim().isEmpty) {
  return dioBaseUrl;
  }

  final url = Uri.parse(baseUrl);

  if (url.isAbsolute) {
  return url.toString();
  }

  return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
