import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Search suggestions and recent searches
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.recentSearches,
    this.onSuggestionTap,
    this.onRecentTap,
    this.onClearRecent,
  });

  final List<String> suggestions;
  final List<String> recentSearches;
  final ValueChanged<String>? onSuggestionTap;
  final ValueChanged<String>? onRecentTap;
  final VoidCallback? onClearRecent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recherches recentes',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onClearRecent != null)
                  TextButton(
                    onPressed: onClearRecent,
                    child: Text(
                      'Effacer',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...recentSearches.map((search) => _SearchItem(
                  text: search,
                  icon: Icons.history,
                  onTap: () => onRecentTap?.call(search),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Popular searches
          Text(
            'Suggestions',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: suggestions.map((suggestion) {
              return _SuggestionChip(
                text: suggestion,
                onTap: () => onSuggestionTap?.call(suggestion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  const _SearchItem({
    required this.text,
    required this.icon,
    this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium,
              ),
            ),
            const Icon(
              Icons.north_west,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          text,
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
