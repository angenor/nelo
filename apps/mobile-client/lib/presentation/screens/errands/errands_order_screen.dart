import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/datasources/local/article_history_datasource.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'widgets/widgets.dart';

/// Errands ordering screen - simplified interface for grocery shopping
class ErrandsOrderScreen extends StatefulWidget {
  const ErrandsOrderScreen({super.key});

  @override
  State<ErrandsOrderScreen> createState() => _ErrandsOrderScreenState();
}

class _ErrandsOrderScreenState extends State<ErrandsOrderScreen> {
  // Delivery address
  Map<String, dynamic>? _selectedAddress;

  // Shopping list items
  List<ErrandsItem> _shoppingItems = [];

  // Voice recording state
  String? _voiceRecordingUrl;
  bool _isRecording = false;

  // Form processing state
  bool _isProcessing = false;

  // Article history
  List<String> _articleHistory = [];
  late final ArticleHistoryDataSource _historyDataSource;

  @override
  void initState() {
    super.initState();
    _historyDataSource = ArticleHistoryDataSource(const FlutterSecureStorage());
    _loadDefaultAddress();
    _loadArticleHistory();
  }

  void _loadDefaultAddress() {
    // Select default address from mock data
    final defaultAddr = MockData.userAddresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => MockData.userAddresses.first,
    );
    _selectedAddress = defaultAddr;
  }

  Future<void> _loadArticleHistory() async {
    final history = await _historyDataSource.getHistory();
    if (mounted) {
      setState(() {
        _articleHistory = history;
      });
    }
  }

  void _onAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _selectedAddress = address;
    });
  }

  void _onAddItem() {
    // Open the article input bottom sheet
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
          builder: (context, scrollController) => ArticleInputSheet(
            recentArticles: _articleHistory,
            onArticleAdded: _onArticleAdded,
            onHistoryCleared: _onHistoryCleared,
          ),
        ),
      ),
    );
  }

  void _onArticleAdded(ErrandsItem item) {
    setState(() {
      _shoppingItems = [..._shoppingItems, item];
    });

    // Add to history
    _historyDataSource.addToHistory(item.name);
    _loadArticleHistory();
  }

  void _onHistoryCleared() {
    _historyDataSource.clearHistory();
    setState(() {
      _articleHistory = [];
    });
  }

  void _onDeleteItem(int index) {
    setState(() {
      _shoppingItems = [
        ..._shoppingItems.sublist(0, index),
        ..._shoppingItems.sublist(index + 1),
      ];
    });
  }

  void _onUpdateItem(int index, ErrandsItem updatedItem) {
    setState(() {
      _shoppingItems = [
        ..._shoppingItems.sublist(0, index),
        updatedItem,
        ..._shoppingItems.sublist(index + 1),
      ];
    });
  }

  void _onVoiceRecordTap() {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        // Mock: set a fake recording URL
        _voiceRecordingUrl =
            'mock://voice-recording-${DateTime.now().millisecondsSinceEpoch}.m4a';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note vocale enregistrée'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
        _voiceRecordingUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Enregistrement en cours... Appuyez pour arrêter'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  void _onVoiceRecordDelete() {
    setState(() {
      _voiceRecordingUrl = null;
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note vocale supprimée'),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _totalBudget {
    return _shoppingItems.fold(0, (sum, item) => sum + item.estimatedPrice);
  }

  Future<void> _onSubmit() async {
    // Validate address
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Veuillez sélectionner une adresse de livraison'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final validItems = _shoppingItems.where((item) => item.isValid).toList();

    // Accept if has valid items OR has a voice recording
    if (validItems.isEmpty && _voiceRecordingUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoutez des articles ou une note vocale'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate order processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OrderSuccessDialog(
        itemCount: validItems.length,
        totalBudget: _totalBudget,
        hasVoiceNote: _voiceRecordingUrl != null,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Faire mes courses',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ErrandsOrderSheet(
        addresses: MockData.userAddresses,
        selectedAddress: _selectedAddress,
        onAddressChanged: _onAddressChanged,
        shoppingItems: _shoppingItems,
        onAddItem: _onAddItem,
        onDeleteItem: _onDeleteItem,
        onUpdateItem: _onUpdateItem,
        isRecording: _isRecording,
        hasRecording: _voiceRecordingUrl != null,
        recordingUrl: _voiceRecordingUrl,
        onVoiceRecordTap: _onVoiceRecordTap,
        onVoiceRecordDelete: _onVoiceRecordDelete,
        totalBudget: _totalBudget,
        onSubmit: _onSubmit,
        isProcessing: _isProcessing,
      ),
    );
  }
}

/// Success dialog after order confirmation
class _OrderSuccessDialog extends StatelessWidget {
  const _OrderSuccessDialog({
    required this.itemCount,
    required this.totalBudget,
    required this.hasVoiceNote,
    required this.onDone,
  });

  final int itemCount;
  final int totalBudget;
  final bool hasVoiceNote;
  final VoidCallback onDone;

  String _formatBudget(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    // Build summary text based on what's included
    String summaryText;
    if (itemCount > 0 && totalBudget > 0) {
      summaryText =
          '$itemCount article${itemCount > 1 ? 's' : ''} - Budget: ${_formatBudget(totalBudget)} FCFA';
    } else if (itemCount > 0) {
      summaryText = '$itemCount article${itemCount > 1 ? 's' : ''}';
    } else {
      summaryText = 'Note vocale uniquement';
    }

    return Dialog(
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
              'Commande envoyée !',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summaryText,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasVoiceNote && itemCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Note vocale incluse',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Un coursier sera bientôt assigné et vous appellera pour confirmer les articles et prix.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
