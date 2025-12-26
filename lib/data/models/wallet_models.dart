import 'package:equatable/equatable.dart';

/// Wallet Model
class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final double totalContributions;
  final double pendingContributions;
  final double availableForWithdrawal;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalContributions,
    required this.pendingContributions,
    required this.availableForWithdrawal,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      totalContributions: (json['total_contributions'] as num).toDouble(),
      pendingContributions: (json['pending_contributions'] as num).toDouble(),
      availableForWithdrawal: (json['available_for_withdrawal'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'total_contributions': totalContributions,
      'pending_contributions': pendingContributions,
      'available_for_withdrawal': availableForWithdrawal,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    double? totalContributions,
    double? pendingContributions,
    double? availableForWithdrawal,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalContributions: totalContributions ?? this.totalContributions,
      pendingContributions: pendingContributions ?? this.pendingContributions,
      availableForWithdrawal: availableForWithdrawal ?? this.availableForWithdrawal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    balance,
    totalContributions,
    pendingContributions,
    availableForWithdrawal,
    updatedAt,
  ];
}

/// Transaction Model
class Transaction extends Equatable {
  final String id;
  final String walletId;
  final String type; // contribution, withdrawal, interest, loan_repayment
  final double amount;
  final String status; // pending, completed, failed
  final String? description;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    this.referenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'status': status,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    type,
    amount,
    status,
    description,
    referenceId,
    createdAt,
    updatedAt,
  ];
}

/// Contribution Model
class Contribution extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final String status; // pending, completed, failed
  final String? paymentMethod;
  final DateTime dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Contribution({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    required this.dueDate,
    this.completedAt,
    required this.createdAt,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'due_date': dueDate.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    amount,
    status,
    paymentMethod,
    dueDate,
    completedAt,
    createdAt,
  ];
}

/// Wallet State
enum WalletStatus {
  initial,
  loading,
  loaded,
  error,
}

class WalletState extends Equatable {
  final WalletStatus status;
  final Wallet? wallet;
  final List<Transaction> transactions;
  final String? error;

  const WalletState({
    this.status = WalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.error,
  });

  bool get isLoading => status == WalletStatus.loading;
  bool get isLoaded => status == WalletStatus.loaded;

  WalletState copyWith({
    WalletStatus? status,
    Wallet? wallet,
    List<Transaction>? transactions,
    String? error,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, wallet, transactions, error];
}
