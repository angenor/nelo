import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import 'quantity_edit_sheet.dart';
import 'shopping_item_row.dart';
import 'voice_player_widget.dart';
import 'voice_record_button.dart';

/// Widget containing the shopping list with add button and voice recording
class ShoppingListWidget extends StatelessWidget {
  const ShoppingListWidget({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onUpdateItem,
    required this.isRecording,
    required this.hasRecording,
    required this.onVoiceRecordTap,
    required this.onVoiceRecordDelete,
    this.recordingUrl,
  });

  /// List of shopping items
  final List<ErrandsItem> items;

  /// Called to add a new item (opens bottom sheet)
  final VoidCallback onAddItem;

  /// Called when an item is deleted
  final void Function(int index) onDeleteItem;

  /// Called when an item is updated (quantity/price changed)
  final void Function(int index, ErrandsItem updatedItem) onUpdateItem;

  /// Whether voice is currently recording
  final bool isRecording;

  /// Whether a voice recording exists
  final bool hasRecording;

  /// URL of the voice recording (for playback)
  final String? recordingUrl;

  /// Called when voice button is tapped
  final VoidCallback onVoiceRecordTap;

  /// Called to delete voice recording
  final VoidCallback onVoiceRecordDelete;

  void _openQuantityEditor(BuildContext context, int index, ErrandsItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuantityEditSheet(
          item: item,
          onSave: (updatedItem) => onUpdateItem(index, updatedItem),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_cart,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Ma liste de courses',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Shopping list container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              // Items list
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aucun article',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Ajoutez des articles à votre liste',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Column(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return ShoppingItemRow(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => _openQuantityEditor(context, index, item),
                        onDelete: () => onDeleteItem(index),
                      );
                    }),
                  ),
                ),

              // Add button + voice record
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    // Add item button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter un article'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // Voice record button (discrete)
                    VoiceRecordButton(
                      isRecording: isRecording,
                      hasRecording: hasRecording,
                      onTap: onVoiceRecordTap,
                      onDelete: onVoiceRecordDelete,
                    ),
                  ],
                ),
              ),

              // Voice player (when recording exists)
              if (hasRecording && !isRecording && recordingUrl != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  child: VoicePlayerWidget(
                    recordingUrl: recordingUrl!,
                    onDelete: onVoiceRecordDelete,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
