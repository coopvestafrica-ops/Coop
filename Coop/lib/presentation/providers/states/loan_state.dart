import 'package:freezed_annotation/freezed_annotation.dart';

part 'loan_state.freezed.dart';

enum LoanStatus { initial, loading, success, error }

@freezed
class LoanState with _$LoanState {
  const factory LoanState({
    @Default(LoanStatus.initial) LoanStatus status,
    @Default([]) List<dynamic> loans,
    String? error,
  }) = _LoanState;
}
