import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Compact bottom sheet for editing quantity/price of an article
class QuantityEditSheet extends StatefulWidget {
  const QuantityEditSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  final ErrandsItem item;
  final void Function(ErrandsItem updatedItem) onSave;

  @override
  State<QuantityEditSheet> createState() => _QuantityEditSheetState();
}

class _QuantityEditSheetState extends State<QuantityEditSheet> {
  late TextEditingController _quantityController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity > 0
          ? (widget.item.quantity == widget.item.quantity.toInt()
              ? widget.item.quantity.toInt().toString()
              : widget.item.quantity.toString())
          : '',
    );
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onSave() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final updatedItem = widget.item.copyWith(
      quantity: quantity,
      unit: _selectedUnit,
    );
    widget.onSave(updatedItem);
    Navigator.of(context).pop();
  }

  void _onClear() {
    final updatedItem = widget.item.copyWith(
      quantity: 0,
      unit: ArticleUnit.fcfa,
    );
    widget.onSave(updatedItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomPadding + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Title with article name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier quantité/prix',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Quantity input + Unit selector
          Row(
            children: [
              // Quantity input
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTypography.titleLarge.copyWith(
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  autofocus: true,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Unit dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                      ),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                      items: ArticleUnit.all.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Quick value buttons (for FCFA)
          if (_selectedUnit == ArticleUnit.fcfa) ...[
            Text(
              'Valeurs rapides',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [500, 1000, 2000, 5000, 10000].map((value) {
                return ActionChip(
                  label: Text('$value F'),
                  labelStyle: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  onPressed: () {
                    _quantityController.text = value.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Action buttons
          Row(
            children: [
              // Clear button
              Expanded(
                child: OutlinedButton(
                  onPressed: _onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.grey300),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Effacer'),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Save button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
