import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../common/map_location_picker.dart';

/// Bottom sheet for address selection with autocomplete
class AddressPickerSheet extends StatefulWidget {
  const AddressPickerSheet({
    super.key,
    required this.savedAddresses,
    required this.onAddressSelected,
  });

  final List<Map<String, dynamic>> savedAddresses;
  final ValueChanged<Map<String, dynamic>> onAddressSelected;

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isKeyboardVisible = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _searchFocus.hasFocus;
    });
  }

  // Mock search suggestions (would be replaced with real geocoding API)
  static const List<Map<String, dynamic>> _mockSuggestions = [
    {
      'id': 'search_1',
      'label': 'Marché Central',
      'address': 'Marché Central, Tiassalé',
      'latitude': 5.8985,
      'longitude': -4.8230,
      'isDefault': false,
    },
    {
      'id': 'search_2',
      'label': 'Gare Routière',
      'address': 'Gare Routière, Tiassalé',
      'latitude': 5.8960,
      'longitude': -4.8210,
      'isDefault': false,
    },
    {
      'id': 'search_3',
      'label': 'Hôpital Général',
      'address': 'Centre Hospitalier, Tiassalé',
      'latitude': 5.8970,
      'longitude': -4.8215,
      'isDefault': false,
    },
    {
      'id': 'search_4',
      'label': 'École Primaire',
      'address': 'Quartier École, Tiassalé',
      'latitude': 5.8990,
      'longitude': -4.8240,
      'isDefault': false,
    },
    {
      'id': 'search_5',
      'label': 'Mosquée Centrale',
      'address': 'Centre-ville, Tiassalé',
      'latitude': 5.8978,
      'longitude': -4.8225,
      'isDefault': false,
    },
  ];

  @override
  void dispose() {
    _searchFocus.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final results = _mockSuggestions
          .where((s) =>
              (s['label'] as String).toLowerCase().contains(query.toLowerCase()) ||
              (s['address'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // Simulate getting current location
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final currentLocation = {
      'id': 'current_location',
      'label': 'Position actuelle',
      'address': 'Quartier Commerce, Tiassalé',
      'latitude': 5.8983,
      'longitude': -4.8228,
      'isDefault': false,
      'isCurrent': true,
    };

    Navigator.of(context).pop();
    widget.onAddressSelected(currentLocation);
  }

  void _selectAddress(Map<String, dynamic> address) {
    Navigator.of(context).pop();
    widget.onAddressSelected(address);
  }

  void _openMapPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          onLocationSelected: (address) {
            Navigator.of(context).pop(); // Close the address picker sheet
            widget.onAddressSelected(address);
          },
        ),
      ),
    );
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

          // Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'Adresse de livraison',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              style: AppTypography.bodyLarge,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher une adresse, un lieu...',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                        color: AppColors.textSecondary,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Use current location button (hidden when keyboard visible)
          if (!_isKeyboardVisible) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: InkWell(
                onTap: _isLoadingLocation ? null : _useCurrentLocation,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isLoadingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: AppColors.white,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Utiliser ma position actuelle',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Détection automatique par GPS',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Choose on map button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.grey300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir sur la carte',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sélectionner un point précis',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Search results or saved addresses - takes remaining space
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildSavedAddresses(),
          ),

          // Bottom safe area padding only
          SizedBox(height: bottomPadding + AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.grey300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune adresse trouvée',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Essayez avec un autre terme',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _AddressTile(
          address: result,
          icon: Icons.location_on_outlined,
          onTap: () => _selectAddress(result),
        );
      },
    );
  }

  Widget _buildSavedAddresses() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Adresses enregistrées',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Saved addresses
        ...widget.savedAddresses.map((address) {
          IconData icon;
          switch (address['label']) {
            case 'Maison':
              icon = Icons.home;
              break;
            case 'Bureau':
              icon = Icons.work;
              break;
            default:
              icon = Icons.location_on;
          }

          return _AddressTile(
            address: address,
            icon: icon,
            isDefault: address['isDefault'] == true,
            onTap: () => _selectAddress(address),
          );
        }),
      ],
    );
  }
}

/// Address tile widget
class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.icon,
    required this.onTap,
    this.isDefault = false,
  });

  final Map<String, dynamic> address;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address['label'] as String,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Par défaut',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
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
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
