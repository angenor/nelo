import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/widgets.dart';

/// Wallet screen showing balance and transaction history
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<WalletTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    // Convert mock data to WalletTransaction entities
    _transactions = MockData.walletTransactions.map((data) {
      final typeStr = data['type'] as String;
      final type = TransactionType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => TransactionType.payment,
      );

      final statusStr = data['status'] as String;
      final status = TransactionStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => TransactionStatus.completed,
      );

      PaymentMethodType? paymentMethod;
      if (data['paymentMethod'] != null) {
        final methodStr = data['paymentMethod'] as String;
        paymentMethod = PaymentMethodType.values.firstWhere(
          (m) => m.name == methodStr,
          orElse: () => PaymentMethodType.wallet,
        );
      }

      return WalletTransaction(
        id: data['id'] as String,
        type: type,
        amount: data['amount'] as int,
        status: status,
        createdAt: data['createdAt'] as DateTime,
        description: data['description'] as String?,
        reference: data['reference'] as String?,
        paymentMethod: paymentMethod,
        orderId: data['orderId'] as String?,
      );
    }).toList();
  }

  void _onTopUp() {
    context.push('/wallet/topup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Portefeuille'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Balance card
          WalletBalanceCard(
            balance: MockData.walletBalance,
            onTopUp: _onTopUp,
          ),

          // Transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'Historique des transactions',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Show all transactions
                  },
                  child: Text(
                    'Voir tout',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xl,
                    ),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: AppSpacing.md + 44 + AppSpacing.md,
                    ),
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return TransactionListItem(
                        transaction: transaction,
                        onTap: () => _showTransactionDetails(transaction),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aucune transaction',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vos transactions apparaîtront ici',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(WalletTransaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailSheet(transaction: transaction),
    );
  }
}

/// Bottom sheet showing transaction details
class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Icon and type
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: transaction.type.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transaction.type.icon,
                    color: transaction.type.color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  transaction.type.label,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  transaction.formattedAmount,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.type.isCredit
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Details
                _buildDetailRow('Date', transaction.formattedDate),
                if (transaction.description != null)
                  _buildDetailRow('Description', transaction.description!),
                if (transaction.reference != null)
                  _buildDetailRow('Référence', transaction.reference!),
                _buildDetailRow('Statut', transaction.status.label),

                const SizedBox(height: AppSpacing.lg),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
