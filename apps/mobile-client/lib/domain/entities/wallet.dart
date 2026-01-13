import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Transaction type enum
enum TransactionType {
  topUp,
  payment,
  refund,
  cashback,
  transfer;

  String get label {
    switch (this) {
      case TransactionType.topUp:
        return 'Recharge';
      case TransactionType.payment:
        return 'Paiement';
      case TransactionType.refund:
        return 'Remboursement';
      case TransactionType.cashback:
        return 'Cashback';
      case TransactionType.transfer:
        return 'Transfert';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.topUp:
        return Icons.add_circle;
      case TransactionType.payment:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.cashback:
        return Icons.card_giftcard;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.topUp:
        return const Color(0xFF4CAF50);
      case TransactionType.payment:
        return const Color(0xFFF44336);
      case TransactionType.refund:
        return const Color(0xFF4CAF50);
      case TransactionType.cashback:
        return const Color(0xFF9C27B0);
      case TransactionType.transfer:
        return const Color(0xFF2196F3);
    }
  }

  bool get isCredit => this == TransactionType.topUp ||
                       this == TransactionType.refund ||
                       this == TransactionType.cashback;
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled;

  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'En cours';
      case TransactionStatus.completed:
        return 'Terminé';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.pending:
        return const Color(0xFFFFA000);
      case TransactionStatus.completed:
        return const Color(0xFF4CAF50);
      case TransactionStatus.failed:
        return const Color(0xFFF44336);
      case TransactionStatus.cancelled:
        return const Color(0xFF607D8B);
    }
  }
}

/// Payment method type
enum PaymentMethodType {
  wave,
  orangeMoney,
  mtnMoney,
  cash,
  wallet;

  String get label {
    switch (this) {
      case PaymentMethodType.wave:
        return 'Wave';
      case PaymentMethodType.orangeMoney:
        return 'Orange Money';
      case PaymentMethodType.mtnMoney:
        return 'MTN Money';
      case PaymentMethodType.cash:
        return 'Espèces';
      case PaymentMethodType.wallet:
        return 'Portefeuille NELO';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.wave:
        return Icons.waves;
      case PaymentMethodType.orangeMoney:
        return Icons.phone_android;
      case PaymentMethodType.mtnMoney:
        return Icons.phone_android;
      case PaymentMethodType.cash:
        return Icons.payments_outlined;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethodType.wave:
        return const Color(0xFF1DA1F2);
      case PaymentMethodType.orangeMoney:
        return const Color(0xFFFF6600);
      case PaymentMethodType.mtnMoney:
        return const Color(0xFFFFCC00);
      case PaymentMethodType.cash:
        return const Color(0xFF4CAF50);
      case PaymentMethodType.wallet:
        return const Color(0xFF6B4EFF);
    }
  }
}

/// Wallet transaction entity
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.description,
    this.reference,
    this.paymentMethod,
    this.orderId,
  });

  final String id;
  final TransactionType type;
  final int amount;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? description;
  final String? reference;
  final PaymentMethodType? paymentMethod;
  final String? orderId;

  /// Formatted amount with sign
  String get formattedAmount {
    final sign = type.isCredit ? '+' : '-';
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$sign$formatted FCFA';
  }

  /// Formatted date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      return '${days[createdAt.weekday % 7]} ${createdAt.day}/${createdAt.month}';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        status,
        createdAt,
        description,
        reference,
        paymentMethod,
        orderId,
      ];
}

/// User wallet entity
class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'XOF',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final int balance;
  final String currency;
  final bool isActive;
  final DateTime? createdAt;

  /// Formatted balance
  String get formattedBalance {
    return balance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  List<Object?> get props => [id, userId, balance, currency, isActive, createdAt];
}
