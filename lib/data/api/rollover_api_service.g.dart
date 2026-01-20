// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rollover_api_service.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element

/// class _RolloverApiService implements RolloverApiService {
class _RolloverApiService implements RolloverApiService {
  _RolloverApiService(
  this._dio, {
  this.baseUrl,
  this.errorLogger,
  });

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<RolloverEligibilityResponse> checkEligibility(String loanId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<RolloverEligibilityResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/rollover/eligibility',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RolloverEligibilityResponse _value;
  try {
  _value = RolloverEligibilityResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<RolloverRequestResponse> createRolloverRequest(
  String loanId,
  RolloverRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<RolloverRequestResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/loans/${loanId}/rollover/request',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RolloverRequestResponse _value;
  try {
  _value = RolloverRequestResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<RolloverDetailsResponse> getRolloverDetails(String rolloverId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<RolloverDetailsResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RolloverDetailsResponse _value;
  try {
  _value = RolloverDetailsResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<RolloverListResponse> getMemberRollovers(String memberId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<RolloverListResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/members/${memberId}/rollovers',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RolloverListResponse _value;
  try {
  _value = RolloverListResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorInviteResponse> inviteGuarantor(
  String rolloverId,
  GuarantorInviteRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<GuarantorInviteResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}/guarantors/invite',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorInviteResponse _value;
  try {
  _value = GuarantorInviteResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorListResponse> getRolloverGuarantors(String rolloverId) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  const Map<String, dynamic>? _data = null;
  final _options = _setStreamType<GuarantorListResponse>(Options(
  method: 'GET',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}/guarantors',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorListResponse _value;
  try {
  _value = GuarantorListResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorConsentResponse> guarantorRespond(
  String rolloverId,
  String guarantorId,
  GuarantorRespondRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<GuarantorConsentResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}/guarantors/${guarantorId}/respond',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorConsentResponse _value;
  try {
  _value = GuarantorConsentResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<RolloverActionResponse> cancelRollover(
  String rolloverId,
  CancelRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<RolloverActionResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}/cancel',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late RolloverActionResponse _value;
  try {
  _value = RolloverActionResponse.fromJson(_result.data!);
  } on Object catch (e, s) {
  errorLogger?.logError(e, s, _options);
  rethrow;
  }
  return _value;
  }

  @override
  Future<GuarantorReplaceResponse> replaceGuarantor(
  String rolloverId,
  String guarantorId,
  GuarantorInviteRequest request,
 ) async {
  final _extra = <String, dynamic>{};
  final queryParameters = <String, dynamic>{};
  final _headers = <String, dynamic>{};
  final _data = <String, dynamic>{};
  _data.addAll(request.toJson());
  final _options = _setStreamType<GuarantorReplaceResponse>(Options(
  method: 'POST',
  headers: _headers,
  extra: _extra,
 )
  .compose(
  _dio.options,
  '/rollover/${rolloverId}/guarantors/${guarantorId}/replace',
  queryParameters: queryParameters,
  data: _data,
 )
  .copyWith(
  baseUrl: _combineBaseUrls(
  _dio.options.baseUrl,
  baseUrl,
 )));
  final _result = await _dio.fetch<Map<String, dynamic>>(_options);
  late GuarantorReplaceResponse _value;
  try {
  _value = GuarantorReplaceResponse.fromJson(_result.data!);
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
