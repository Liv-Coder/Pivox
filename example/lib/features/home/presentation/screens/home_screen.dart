import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../ui_example.dart' as ui_example;
import '../controllers/home_controller.dart';
import '../widgets/actions_section.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/overview_section.dart';
import '../widgets/proxy_list_section.dart';
import '../widgets/status_section.dart';
import '../widgets/test_section.dart';

/// Home screen for the Pivox example app
class HomeScreen extends StatefulWidget {
  /// Creates a new [HomeScreen]
  const HomeScreen({super.key, required this.title});

  /// Title of the screen
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<HomeController>();
    _controller.addListener(_onControllerUpdate);
    _controller.fetchProxies();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _controller.fetchProxies,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview metrics
            DashboardSection(
              title: 'Overview',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout
                  final isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: OverviewSection(metrics: _controller.metrics),
                        ),
                        const SizedBox(width: DesignTokens.spacingMedium),
                        Expanded(
                          child: StatusSection(
                            isLoading: _controller.isLoading,
                            responseText: _controller.responseText,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        OverviewSection(metrics: _controller.metrics),
                        const SizedBox(height: DesignTokens.spacingMedium),
                        StatusSection(
                          isLoading: _controller.isLoading,
                          responseText: _controller.responseText,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: DesignTokens.spacingLarge),

            // Proxy list
            DashboardSection(
              title: 'Available Proxies',
              child: ProxyListSection(
                proxies: _controller.proxies,
                isLoading: _controller.isLoading,
                onRefresh: _controller.fetchProxies,
              ),
            ),

            const SizedBox(height: DesignTokens.spacingLarge),

            // Quick actions
            DashboardSection(
              title: 'Quick Actions',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout
                  final isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: ActionsSection(
                            isLoading: _controller.isLoading,
                            onRefresh: _controller.fetchProxies,
                            onValidate: () {},
                            onClearCache: () {},
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingMedium),
                        Expanded(
                          child: TestSection(
                            isLoading: _controller.isLoading,
                            onTest: _controller.testProxy,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        ActionsSection(
                          isLoading: _controller.isLoading,
                          onRefresh: _controller.fetchProxies,
                          onValidate: () {},
                          onClearCache: () {},
                        ),
                        const SizedBox(height: DesignTokens.spacingMedium),
                        TestSection(
                          isLoading: _controller.isLoading,
                          onTest: _controller.testProxy,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: DesignTokens.spacingLarge),

            // UI Example
            DashboardSection(
              title: 'UI Examples',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Try our new UI components for web scraping',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: DesignTokens.spacingSmall),
                      const Text(
                        'Explore our new UI components for web scraping, including a scraping progress dashboard, visual status indicators, and interactive selector tools.',
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const ui_example.UIExample(),
                            ),
                          );
                        },
                        child: const Text('Launch UI Example'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.spacingMedium),
          ],
        ),
      ),
    );
  }
}
