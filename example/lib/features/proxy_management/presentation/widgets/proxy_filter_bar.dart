import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/design/app_spacing.dart';

/// Proxy filter options
enum ProxyFilterOption { all, valid, invalid, http, https, socks4, socks5 }

/// Proxy sort options
enum ProxySortOption {
  newest,
  oldest,
  fastest,
  slowest,
  highestScore,
  lowestScore,
}

/// Proxy filter bar widget
class ProxyFilterBar extends StatelessWidget {
  final ProxyFilterOption selectedFilter;
  final ProxySortOption selectedSort;
  final Function(ProxyFilterOption) onFilterChanged;
  final Function(ProxySortOption) onSortChanged;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearch;
  final TextEditingController searchController;

  const ProxyFilterBar({
    super.key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.searchController,
    this.onRefresh,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        const SizedBox(height: AppSpacing.md),
        _buildFilterChips(context),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search proxies...',
              prefixIcon: const Icon(Ionicons.search_outline),
              suffixIcon:
                  searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Ionicons.close_outline),
                        onPressed: () {
                          searchController.clear();
                          if (onSearch != null) onSearch!();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onSubmitted: (_) {
              if (onSearch != null) onSearch!();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Ionicons.refresh_outline),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(25),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: 'All',
            option: ProxyFilterOption.all,
          ),
          _buildFilterChip(
            context,
            label: 'Valid',
            option: ProxyFilterOption.valid,
          ),
          _buildFilterChip(
            context,
            label: 'Invalid',
            option: ProxyFilterOption.invalid,
          ),
          _buildFilterChip(
            context,
            label: 'HTTP',
            option: ProxyFilterOption.http,
          ),
          _buildFilterChip(
            context,
            label: 'HTTPS',
            option: ProxyFilterOption.https,
          ),
          _buildFilterChip(
            context,
            label: 'SOCKS4',
            option: ProxyFilterOption.socks4,
          ),
          _buildFilterChip(
            context,
            label: 'SOCKS5',
            option: ProxyFilterOption.socks5,
          ),
          const SizedBox(width: AppSpacing.md),
          const VerticalDivider(width: 1, thickness: 1),
          const SizedBox(width: AppSpacing.md),
          _buildSortDropdown(context),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required ProxyFilterOption option,
  }) {
    final isSelected = selectedFilter == option;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onFilterChanged(option),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          side: BorderSide(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Row(
      children: [
        const Icon(Ionicons.funnel_outline, size: 16),
        const SizedBox(width: AppSpacing.xs),
        const Text('Sort by:'),
        const SizedBox(width: AppSpacing.sm),
        DropdownButton<ProxySortOption>(
          value: selectedSort,
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
          items: [
            _buildDropdownItem('Newest', ProxySortOption.newest),
            _buildDropdownItem('Oldest', ProxySortOption.oldest),
            _buildDropdownItem('Fastest', ProxySortOption.fastest),
            _buildDropdownItem('Slowest', ProxySortOption.slowest),
            _buildDropdownItem('Highest Score', ProxySortOption.highestScore),
            _buildDropdownItem('Lowest Score', ProxySortOption.lowestScore),
          ],
          underline: Container(
            height: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<ProxySortOption> _buildDropdownItem(
    String label,
    ProxySortOption option,
  ) {
    return DropdownMenuItem<ProxySortOption>(value: option, child: Text(label));
  }
}
