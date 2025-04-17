import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/base_screen.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/app_animations.dart';
import '../widgets/proxy_card.dart';
import '../widgets/proxy_filter_bar.dart';
import '../widgets/proxy_stats_card.dart';
import '../../domain/entities/proxy_entity.dart';

/// Proxy management screen
class ProxyManagementScreen extends StatefulWidget {
  const ProxyManagementScreen({super.key});

  @override
  State<ProxyManagementScreen> createState() => _ProxyManagementScreenState();
}

class _ProxyManagementScreenState extends State<ProxyManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProxyFilterOption _selectedFilter = ProxyFilterOption.all;
  ProxySortOption _selectedSort = ProxySortOption.newest;
  bool _isLoading = false;

  // Mock data for demonstration
  final List<ProxyEntity> _mockProxies = [
    ProxyEntity(
      ip: '192.168.1.1',
      port: 8080,
      country: 'United States',
      city: 'New York',
      isAnonymous: true,
      isHttps: true,
      type: 'HTTP',
      speed: 150.5,
      lastChecked: DateTime.now().subtract(const Duration(minutes: 30)),
      isValid: true,
      successCount: 45,
      failureCount: 5,
      score: 0.9,
      lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ProxyEntity(
      ip: '10.0.0.1',
      port: 3128,
      country: 'Germany',
      city: 'Berlin',
      isAnonymous: false,
      isHttps: false,
      type: 'HTTP',
      speed: 200.3,
      lastChecked: DateTime.now().subtract(const Duration(hours: 1)),
      isValid: true,
      successCount: 30,
      failureCount: 10,
      score: 0.75,
      lastUsed: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ProxyEntity(
      ip: '172.16.0.1',
      port: 1080,
      country: 'Japan',
      city: 'Tokyo',
      isAnonymous: true,
      isHttps: false,
      type: 'SOCKS5',
      speed: 300.8,
      lastChecked: DateTime.now().subtract(const Duration(hours: 2)),
      isValid: false,
      successCount: 10,
      failureCount: 20,
      score: 0.33,
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProxyEntity(
      ip: '203.0.113.1',
      port: 8888,
      country: 'Canada',
      city: 'Toronto',
      isAnonymous: true,
      isHttps: true,
      type: 'HTTPS',
      speed: 120.1,
      lastChecked: DateTime.now().subtract(const Duration(minutes: 45)),
      isValid: true,
      successCount: 50,
      failureCount: 2,
      score: 0.96,
      lastUsed: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ProxyEntity(
      ip: '198.51.100.1',
      port: 4145,
      country: 'Brazil',
      city: 'Sao Paulo',
      isAnonymous: false,
      isHttps: false,
      type: 'SOCKS4',
      speed: 250.6,
      lastChecked: DateTime.now().subtract(const Duration(hours: 3)),
      isValid: false,
      successCount: 5,
      failureCount: 15,
      score: 0.25,
      lastUsed: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<ProxyEntity> get _filteredProxies {
    List<ProxyEntity> result = List.from(_mockProxies);

    // Apply filter
    switch (_selectedFilter) {
      case ProxyFilterOption.valid:
        result = result.where((proxy) => proxy.isValid).toList();
        break;
      case ProxyFilterOption.invalid:
        result = result.where((proxy) => !proxy.isValid).toList();
        break;
      case ProxyFilterOption.http:
        result = result.where((proxy) => proxy.type == 'HTTP').toList();
        break;
      case ProxyFilterOption.https:
        result = result.where((proxy) => proxy.type == 'HTTPS').toList();
        break;
      case ProxyFilterOption.socks4:
        result = result.where((proxy) => proxy.type == 'SOCKS4').toList();
        break;
      case ProxyFilterOption.socks5:
        result = result.where((proxy) => proxy.type == 'SOCKS5').toList();
        break;
      case ProxyFilterOption.all:
        // No filtering
        break;
    }

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      result =
          result.where((proxy) {
            return proxy.ip.toLowerCase().contains(searchTerm) ||
                proxy.port.toString().contains(searchTerm) ||
                (proxy.country?.toLowerCase().contains(searchTerm) ?? false) ||
                (proxy.city?.toLowerCase().contains(searchTerm) ?? false) ||
                (proxy.type?.toLowerCase().contains(searchTerm) ?? false);
          }).toList();
    }

    // Apply sort
    switch (_selectedSort) {
      case ProxySortOption.newest:
        result.sort(
          (a, b) => (b.lastChecked ?? DateTime(1970)).compareTo(
            a.lastChecked ?? DateTime(1970),
          ),
        );
        break;
      case ProxySortOption.oldest:
        result.sort(
          (a, b) => (a.lastChecked ?? DateTime(1970)).compareTo(
            b.lastChecked ?? DateTime(1970),
          ),
        );
        break;
      case ProxySortOption.fastest:
        result.sort(
          (a, b) => (a.speed ?? double.infinity).compareTo(
            b.speed ?? double.infinity,
          ),
        );
        break;
      case ProxySortOption.slowest:
        result.sort((a, b) => (b.speed ?? 0).compareTo(a.speed ?? 0));
        break;
      case ProxySortOption.highestScore:
        result.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
        break;
      case ProxySortOption.lowestScore:
        result.sort((a, b) => (a.score ?? 0).compareTo(b.score ?? 0));
        break;
    }

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Proxy Management',
      actions: [
        IconButton(
          icon: const Icon(Ionicons.add_outline),
          onPressed: _showAddProxyDialog,
          tooltip: 'Add Proxy',
        ),
        IconButton(
          icon: const Icon(Ionicons.options_outline),
          onPressed: _showSettingsDialog,
          tooltip: 'Settings',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchProxies,
        tooltip: 'Fetch Proxies',
        child: const Icon(Ionicons.download_outline),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProxies,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProxyFilterBar(
              selectedFilter: _selectedFilter,
              selectedSort: _selectedSort,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              onSortChanged: (sort) {
                setState(() {
                  _selectedSort = sort;
                });
              },
              searchController: _searchController,
              onRefresh: () => _refreshProxies(),
              onSearch: () {
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ProxyStatsCard(
              totalProxies: _mockProxies.length,
              validProxies: _mockProxies.where((p) => p.isValid).length,
              invalidProxies: _mockProxies.where((p) => !p.isValid).length,
              averageSpeed:
                  _mockProxies.fold(0.0, (sum, p) => sum + (p.speed ?? 0)) /
                  (_mockProxies.where((p) => p.speed != null).length),
              successRate:
                  _mockProxies.fold(0, (sum, p) => sum + p.successCount) /
                  _mockProxies.fold(
                    0,
                    (sum, p) => sum + p.successCount + p.failureCount,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProxies.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: _filteredProxies.length,
                        itemBuilder: (context, index) {
                          final proxy = _filteredProxies[index];
                          return AppAnimations.fadeSlideIn(
                            animate: true,
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            child: ProxyCard(
                              proxy: proxy,
                              onTap: () => _showProxyDetails(proxy),
                              onTest: () => _testProxy(proxy),
                              onCopy: () => _copyProxyToClipboard(proxy),
                              onDelete: () => _deleteProxy(proxy),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Ionicons.server_outline,
            size: 64,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Proxies Found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try changing filters or fetch new proxies',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ActionButton(
            text: 'Fetch Proxies',
            icon: Ionicons.download_outline,
            onPressed: _fetchProxies,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProxies() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proxies refreshed successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _fetchProxies() {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proxies fetched successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _showProxyDetails(ProxyEntity proxy) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Proxy Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('IP', proxy.ip),
                _buildDetailRow('Port', proxy.port.toString()),
                if (proxy.country != null)
                  _buildDetailRow('Country', proxy.country!),
                if (proxy.city != null) _buildDetailRow('City', proxy.city!),
                _buildDetailRow('Type', proxy.type ?? 'Unknown'),
                _buildDetailRow('Anonymous', proxy.isAnonymous ? 'Yes' : 'No'),
                _buildDetailRow('HTTPS', proxy.isHttps ? 'Yes' : 'No'),
                if (proxy.speed != null)
                  _buildDetailRow(
                    'Speed',
                    '${proxy.speed!.toStringAsFixed(2)} ms',
                  ),
                _buildDetailRow('Valid', proxy.isValid ? 'Yes' : 'No'),
                _buildDetailRow(
                  'Success Rate',
                  '${(proxy.successRate * 100).toStringAsFixed(1)}%',
                ),
                if (proxy.score != null)
                  _buildDetailRow('Score', proxy.score!.toStringAsFixed(2)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _testProxy(proxy);
                },
                child: const Text('Test'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _testProxy(ProxyEntity proxy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing proxy ${proxy.ip}:${proxy.port}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyProxyToClipboard(ProxyEntity proxy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proxy ${proxy.ip}:${proxy.port} copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _deleteProxy(ProxyEntity proxy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proxy ${proxy.ip}:${proxy.port} deleted'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddProxyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Proxy'),
            content: const Text('This feature will be implemented soon.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Proxy Settings'),
            content: const Text('This feature will be implemented soon.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
