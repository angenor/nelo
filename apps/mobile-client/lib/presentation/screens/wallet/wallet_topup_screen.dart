import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';

/// Wallet top-up screen with preset amounts and payment method selection
class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  int? _selectedAmount;
  int _customAmount = 0;
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.wave;
  bool _isProcessing = false;
  final _customAmountController = TextEditingController();

  static const List<PaymentMethodType> _availableMethods = [
    PaymentMethodType.wave,
    PaymentMethodType.orangeMoney,
    PaymentMethodType.mtnMoney,
  ];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  int get _amount => _selectedAmount ?? _customAmount;

  bool get _canProceed => _amount >= 500; // Minimum 500 FCFA

  void _onAmountSelected(int amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmount = 0;
      _customAmountController.clear();
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedAmount = null;
      _customAmount = int.tryParse(value.replaceAll(' ', '')) ?? 0;
    });
  }

  void _onPaymentMethodSelected(PaymentMethodType method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _onProceed() async {
    if (!_canProceed) return;

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recharge réussie !',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_formatAmount(_amount)} FCFA ont été ajoutés à votre portefeuille.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Terminé'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Recharger'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current balance reminder
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: const Color(0xFF6B4EFF),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solde actuel',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${_formatAmount(MockData.walletBalance)} FCFA',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6B4EFF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Preset amounts
                  _buildSection(
                    title: 'Montant',
                    icon: Icons.monetization_on_outlined,
                    child: _buildAmountSelector(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Custom amount
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _selectedAmount == null && _customAmount > 0
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Montant personnalisé',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: AppTypography.titleMedium,
                            onChanged: _onCustomAmountChanged,
                          ),
                        ),
                        Text(
                          'FCFA',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Minimum 500 FCFA',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Payment method selection
                  _buildSection(
                    title: 'Mode de paiement',
                    icon: Icons.payment,
                    child: _buildPaymentMethodSelector(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with proceed button
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildAmountSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MockData.topUpAmounts.map((amount) {
        final isSelected = _selectedAmount == amount;
        return GestureDetector(
          onTap: () => _onAmountSelected(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
              ),
            ),
            child: Text(
              '${_formatAmount(amount)} FCFA',
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: _availableMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _onPaymentMethodSelected(method),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? method.color.withValues(alpha: 0.1)
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      method.icon,
                      color: isSelected ? method.color : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      method.label,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount summary
          if (_amount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Montant à recharger',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${_formatAmount(_amount)} FCFA',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Proceed button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProceed && !_isProcessing ? _onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                disabledBackgroundColor: AppColors.grey300,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_selectedPaymentMethod.icon, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Payer avec ${_selectedPaymentMethod.label}',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
