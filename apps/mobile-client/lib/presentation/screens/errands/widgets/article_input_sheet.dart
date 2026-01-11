import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../domain/entities/entities.dart';

/// Bottom sheet for adding multiple articles
/// Simple interface: type name + add, or tap suggestions
class ArticleInputSheet extends StatefulWidget {
  const ArticleInputSheet({
    super.key,
    required this.recentArticles,
    required this.onArticlesAdded,
    required this.onHistoryCleared,
  });

  /// Recent articles from history
  final List<String> recentArticles;

  /// Called when articles are added (can be multiple)
  final void Function(List<ErrandsItem> items) onArticlesAdded;

  /// Called when history is cleared
  final VoidCallback onHistoryCleared;

  @override
  State<ArticleInputSheet> createState() => _ArticleInputSheetState();
}

class _ArticleInputSheetState extends State<ArticleInputSheet> {
  final TextEditingController _articleController = TextEditingController();
  final FocusNode _articleFocusNode = FocusNode();

  /// List of articles pending to be added
  List<ErrandsItem> _pendingArticles = [];

  @override
  void initState() {
    super.initState();
    // Auto-focus article field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _articleController.dispose();
    _articleFocusNode.dispose();
    super.dispose();
  }

  /// Quick add article from suggestion or history
  void _quickAddArticle(String name) {
    // Check if already added
    if (_pendingArticles.any((item) => item.name == name)) {
      return;
    }

    final item = ErrandsItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: 0,
      unit: ArticleUnit.fcfa,
    );

    setState(() {
      _pendingArticles = [..._pendingArticles, item];
    });
  }

  /// Add article from text input
  void _addCurrentArticle() {
    final name = _articleController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final item = ErrandsItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: 0,
      unit: ArticleUnit.fcfa,
    );

    setState(() {
      _pendingArticles = [..._pendingArticles, item];
      _articleController.clear();
    });

    // Re-focus for next article
    _articleFocusNode.requestFocus();
  }

  void _removePendingArticle(int index) {
    setState(() {
      _pendingArticles = [
        ..._pendingArticles.sublist(0, index),
        ..._pendingArticles.sublist(index + 1),
      ];
    });
  }

  void _finishAdding() {
    if (_pendingArticles.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    widget.onArticlesAdded(_pendingArticles);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Title bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Ajouter des articles',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_pendingArticles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${_pendingArticles.length}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Article input field with add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _articleController,
                    focusNode: _articleFocusNode,
                    onSubmitted: (_) => _addCurrentArticle(),
                    style: AppTypography.bodyLarge,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Nom de l\'article...',
                      hintStyle: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textHint,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Icon(
                          Icons.edit,
                          color: AppColors.primary,
                          size: 22,
                        ),
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
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addCurrentArticle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 24),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Pending articles list (if any)
          if (_pendingArticles.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Articles à ajouter',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: List.generate(_pendingArticles.length, (index) {
                      final item = _pendingArticles[index];
                      return Chip(
                        label: Text(item.name),
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.error,
                        ),
                        onDeleted: () => _removePendingArticle(index),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.grey300),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                  ),
                ],
              ),
            ),

          if (_pendingArticles.isNotEmpty) const SizedBox(height: AppSpacing.sm),

          // Content area - scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent articles section
                  if (widget.recentArticles.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Récents',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onHistoryCleared,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Effacer',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: widget.recentArticles.take(8).map((article) {
                        final isAlreadyAdded =
                            _pendingArticles.any((item) => item.name == article);
                        return ActionChip(
                          avatar: Icon(
                            Icons.history,
                            size: 16,
                            color: isAlreadyAdded
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(article),
                              if (isAlreadyAdded) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                          onPressed:
                              isAlreadyAdded ? null : () => _quickAddArticle(article),
                          backgroundColor: isAlreadyAdded
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.grey100,
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: isAlreadyAdded
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          side: isAlreadyAdded
                              ? BorderSide(color: AppColors.success)
                              : BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Suggestions section
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Suggestions',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Suggestion chips - tappable to add directly
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: MockData.grocerySuggestions.map((suggestion) {
                      final isAlreadyAdded =
                          _pendingArticles.any((item) => item.name == suggestion);
                      return ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(suggestion),
                            if (isAlreadyAdded) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.success,
                              ),
                            ],
                          ],
                        ),
                        onPressed:
                            isAlreadyAdded ? null : () => _quickAddArticle(suggestion),
                        backgroundColor: isAlreadyAdded
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.grey100,
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: isAlreadyAdded
                              ? AppColors.success
                              : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        side: isAlreadyAdded
                            ? BorderSide(color: AppColors.success)
                            : BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bottom button - fixed at bottom
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              bottomPadding + AppSpacing.md,
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _finishAdding,
                icon: Icon(
                  _pendingArticles.isEmpty ? Icons.close : Icons.check,
                  size: 20,
                ),
                label: Text(
                  _pendingArticles.isEmpty
                      ? 'Fermer'
                      : 'Ajouter ${_pendingArticles.length} article${_pendingArticles.length > 1 ? 's' : ''} à la liste',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pendingArticles.isEmpty
                      ? AppColors.grey300
                      : AppColors.primary,
                  foregroundColor: _pendingArticles.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
