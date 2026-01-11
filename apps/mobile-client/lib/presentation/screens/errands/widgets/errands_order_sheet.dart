import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../gas/widgets/address_picker_sheet.dart';
import 'shopping_list_widget.dart';

/// Main form container for errands order
class ErrandsOrderSheet extends StatelessWidget {
  const ErrandsOrderSheet({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.onAddressChanged,
    required this.shoppingItems,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onUpdateItem,
    required this.isRecording,
    required this.hasRecording,
    required this.onVoiceRecordTap,
    required this.onVoiceRecordDelete,
    required this.totalBudget,
    required this.onBudgetChanged,
    required this.onSubmit,
    required this.isProcessing,
    this.recordingUrl,
    this.isAutoCalculated = false,
    this.minimumBudget = 0,
  });

  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ValueChanged<Map<String, dynamic>> onAddressChanged;
  final List<ErrandsItem> shoppingItems;
  final VoidCallback onAddItem;
  final void Function(int index) onDeleteItem;
  final void Function(int index, ErrandsItem updatedItem) onUpdateItem;
  final bool isRecording;
  final bool hasRecording;
  final String? recordingUrl;
  final VoidCallback onVoiceRecordTap;
  final VoidCallback onVoiceRecordDelete;
  final int totalBudget;
  final bool isAutoCalculated;
  final int minimumBudget;
  final ValueChanged<int> onBudgetChanged;
  final VoidCallback onSubmit;
  final bool isProcessing;

  bool get _canSubmit {
    if (selectedAddress == null) return false;

    final validItems = shoppingItems.where((item) => item.isValid).toList();

    // Accept if has valid items OR has a voice recording
    if (validItems.isEmpty && !hasRecording) return false;

    // If has items, all must have quantity
    if (validItems.isNotEmpty) {
      final allHaveQuantity = validItems.every((item) => item.hasQuantity);
      if (!allHaveQuantity) return false;
    }

    // In manual mode, budget must be specified and >= minimum FCFA prices
    if (!isAutoCalculated) {
      // If there are FCFA prices, budget must cover them
      if (minimumBudget > 0 && totalBudget < minimumBudget) return false;
      // Budget must be specified (> 0) if there are items
      if (validItems.isNotEmpty && totalBudget <= 0) return false;
    }

    return true;
  }


  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
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

          const SizedBox(height: AppSpacing.md),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Delivery address
                  _buildSectionTitle('Livrer à', Icons.location_on),
                  const SizedBox(height: AppSpacing.xs),
                  _AddressSelector(
                    addresses: addresses,
                    selectedAddress: selectedAddress,
                    onChanged: onAddressChanged,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section: Shopping list
                  ShoppingListWidget(
                    items: shoppingItems,
                    onAddItem: onAddItem,
                    onDeleteItem: onDeleteItem,
                    onUpdateItem: onUpdateItem,
                    isRecording: isRecording,
                    hasRecording: hasRecording,
                    recordingUrl: recordingUrl,
                    onVoiceRecordTap: onVoiceRecordTap,
                    onVoiceRecordDelete: onVoiceRecordDelete,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Fixed bottom section - Budget total + Submit button
          Container(
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
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              bottomPadding + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Budget total input
                _BudgetInputField(
                  value: totalBudget,
                  isAutoCalculated: isAutoCalculated,
                  minimumBudget: minimumBudget,
                  onChanged: onBudgetChanged,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Helper text
                Text(
                  'Le coursier vous appellera si le budget est dépassé',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !isProcessing ? onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      disabledBackgroundColor: AppColors.grey300,
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Envoyer ma commande',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Address selector that opens a bottom sheet picker
/// (Adapted from gas_order_sheet.dart)
class _AddressSelector extends StatelessWidget {
  const _AddressSelector({
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ValueChanged<Map<String, dynamic>> onChanged;

  void _openAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => AddressPickerSheet(
            savedAddresses: addresses,
            onAddressSelected: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = selectedAddress;
    final isCurrent = address?['isCurrent'] == true;

    IconData icon;
    switch (address?['label']) {
      case 'Maison':
        icon = Icons.home;
        break;
      case 'Bureau':
        icon = Icons.work;
        break;
      case 'Position actuelle':
        icon = Icons.my_location;
        break;
      default:
        icon = Icons.location_on;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: InkWell(
        onTap: () => _openAddressPicker(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isCurrent ? AppColors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: address != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address['label'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            address['address'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text(
                        'Sélectionner une adresse',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Budget input field - auto-calculated or manual
class _BudgetInputField extends StatefulWidget {
  const _BudgetInputField({
    required this.value,
    required this.isAutoCalculated,
    required this.onChanged,
    this.minimumBudget = 0,
  });

  final int value;
  final bool isAutoCalculated;
  final int minimumBudget;
  final ValueChanged<int> onChanged;

  @override
  State<_BudgetInputField> createState() => _BudgetInputFieldState();
}

class _BudgetInputFieldState extends State<_BudgetInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toString() : '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_BudgetInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text if value changed externally and field is not focused
    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      _controller.text = widget.value > 0 ? widget.value.toString() : '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Parse and notify on focus lost
      final value = int.tryParse(_controller.text) ?? 0;
      widget.onChanged(value);
    }
  }

  void _onSubmitted(String text) {
    final value = int.tryParse(text) ?? 0;
    widget.onChanged(value);
    _focusNode.unfocus();
  }

  String _formatBudget(int amount) {
    if (amount <= 0) return '0';
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    // Budget is too low if:
    // - Not auto-calculated AND (budget < minimum OR budget is 0 when minimum exists)
    final isBudgetTooLow = !widget.isAutoCalculated &&
        (widget.value < widget.minimumBudget ||
            (widget.minimumBudget > 0 && widget.value <= 0));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isBudgetTooLow
            ? AppColors.error.withValues(alpha: 0.05)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isBudgetTooLow
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: isBudgetTooLow ? AppColors.error : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.isAutoCalculated)
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Calculé auto',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const Spacer(),
              // Auto-calculated: read-only display, Manual: editable field
              if (widget.isAutoCalculated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_formatBudget(widget.value)} F',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBudgetTooLow ? AppColors.error : AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: AppTypography.titleMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      suffixText: ' F',
                      suffixStyle: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isBudgetTooLow ? AppColors.error : AppColors.primary,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                            color: isBudgetTooLow
                                ? AppColors.error
                                : AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                            color: isBudgetTooLow
                                ? AppColors.error
                                : AppColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                            color: isBudgetTooLow
                                ? AppColors.error
                                : AppColors.primary,
                            width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (text) {
                      // Update budget in real-time as user types
                      final value = int.tryParse(text) ?? 0;
                      widget.onChanged(value);
                    },
                    onSubmitted: _onSubmitted,
                  ),
                ),
            ],
          ),
          // Show minimum budget hint in manual mode
          if (!widget.isAutoCalculated && widget.minimumBudget > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Min: ${_formatBudget(widget.minimumBudget)} F (somme des prix)',
              style: AppTypography.labelSmall.copyWith(
                color: isBudgetTooLow ? AppColors.error : AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
