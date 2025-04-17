import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/base_screen.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/app_animations.dart';

/// Headless browser screen
class HeadlessBrowserScreen extends StatefulWidget {
  const HeadlessBrowserScreen({super.key});

  @override
  State<HeadlessBrowserScreen> createState() => _HeadlessBrowserScreenState();
}

class _HeadlessBrowserScreenState extends State<HeadlessBrowserScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://example.com';
    _scriptController.text = 'document.querySelector("h1").textContent';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Headless Browser',
      actions: [
        IconButton(
          icon: const Icon(Ionicons.information_circle_outline),
          onPressed: _showInfo,
          tooltip: 'Information',
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildUrlInput(),
            const SizedBox(height: AppSpacing.md),
            _buildScriptInput(),
            const SizedBox(height: AppSpacing.lg),
            _buildActionButtons(),
            const SizedBox(height: AppSpacing.lg),
            if (_result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppAnimations.fadeSlideIn(
      child: AnimatedCard(
        onTap: null,
        enableHover: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(25),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: const Icon(
                    Ionicons.globe_outline,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Headless Browser',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'For JavaScript-heavy websites',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The headless browser allows you to scrape JavaScript-rendered content, interact with elements, and execute custom scripts on web pages.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return AppAnimations.fadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target URL',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
              prefixIcon: Icon(Ionicons.globe_outline),
            ),
            keyboardType: TextInputType.url,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildScriptInput() {
    return AppAnimations.fadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JavaScript to Execute',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _scriptController,
            decoration: const InputDecoration(
              labelText: 'JavaScript',
              hintText: 'document.querySelector("h1").textContent',
              prefixIcon: Icon(Ionicons.code_slash_outline),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return AppAnimations.fadeSlideIn(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ActionButton(
              text: 'Launch Browser',
              icon: Ionicons.rocket_outline,
              type: ActionButtonType.primary,
              isLoading: _isLoading,
              onPressed: _launchBrowser,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ActionButton(
              text: 'Execute Script',
              icon: Ionicons.code_outline,
              type: ActionButtonType.secondary,
              isLoading: _isLoading,
              onPressed: _executeScript,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return AppAnimations.fadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedCard(
            onTap: null,
            enableHover: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Ionicons.code_download_outline,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Script Output',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Ionicons.copy_outline, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Result copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: 'Copy',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(128),
                    ),
                  ),
                  child: Text(
                    _result!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchBrowser() {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    // Simulate browser launch
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _result =
              'Browser launched successfully. Loaded ${_urlController.text}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Browser launched successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _executeScript() {
    if (_scriptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a script'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    // Simulate script execution
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _result =
              'Example Domain\nThis domain is for use in illustrative examples in documents.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Script executed successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Headless Browser'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The headless browser feature allows you to:'),
                  SizedBox(height: AppSpacing.sm),
                  Text('\u2022 Scrape JavaScript-rendered content'),
                  Text('\u2022 Interact with elements on the page'),
                  Text('\u2022 Execute custom JavaScript code'),
                  Text('\u2022 Handle authentication and cookies'),
                  Text('\u2022 Navigate through multiple pages'),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'This is particularly useful for modern websites that load content dynamically with JavaScript.',
                  ),
                ],
              ),
            ),
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
