import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/widgets/action_button.dart';
import '../../domain/entities/scraping_config.dart';

/// Scraping form widget
class ScrapingForm extends StatefulWidget {
  final Function(ScrapingConfig) onSubmit;
  final bool isLoading;

  const ScrapingForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ScrapingForm> createState() => _ScrapingFormState();
}

class _ScrapingFormState extends State<ScrapingForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _selectorsController = TextEditingController();

  bool _useProxy = true;
  bool _useHeadlessBrowser = false;
  bool _followPagination = false;
  bool _waitForSelector = false;

  final Map<String, TextEditingController> _selectorControllers = {};
  final List<String> _selectorNames = [];

  @override
  void initState() {
    super.initState();
    _addSelector();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _selectorsController.dispose();
    for (final controller in _selectorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Target URL'),
          _buildUrlField(),
          const SizedBox(height: AppSpacing.lg),

          _buildSectionTitle('Selectors'),
          _buildSelectorsSection(),
          const SizedBox(height: AppSpacing.md),

          _buildSectionTitle('Options'),
          _buildOptionsSection(),
          const SizedBox(height: AppSpacing.lg),

          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: const InputDecoration(
        labelText: 'URL',
        hintText: 'https://example.com',
        prefixIcon: Icon(Ionicons.globe_outline),
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a URL';
        }
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return 'URL must start with http:// or https://';
        }
        return null;
      },
    );
  }

  Widget _buildSelectorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildSelectorFields(),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _addSelector,
          icon: const Icon(Ionicons.add_outline),
          label: const Text('Add Selector'),
        ),
      ],
    );
  }

  List<Widget> _buildSelectorFields() {
    return List.generate(_selectorNames.length, (index) {
      final name = _selectorNames[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'title',
                  prefixIcon: const Icon(Ionicons.text_outline),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                initialValue: name,
                onChanged: (value) {
                  setState(() {
                    final oldName = _selectorNames[index];
                    final controller = _selectorControllers[oldName];
                    if (controller != null) {
                      _selectorControllers[value] = controller;
                      _selectorControllers.remove(oldName);
                      _selectorNames[index] = value;
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _selectorControllers[name],
                decoration: InputDecoration(
                  labelText: 'CSS Selector',
                  hintText: '.title, h1, #main',
                  prefixIcon: const Icon(Ionicons.code_outline),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Ionicons.trash_outline),
              onPressed:
                  _selectorNames.length > 1
                      ? () => _removeSelector(index)
                      : null,
              tooltip: 'Remove',
            ),
          ],
        ),
      );
    });
  }

  void _addSelector() {
    setState(() {
      final name = 'item${_selectorNames.length + 1}';
      _selectorNames.add(name);
      _selectorControllers[name] = TextEditingController();
    });
  }

  void _removeSelector(int index) {
    setState(() {
      final name = _selectorNames[index];
      _selectorControllers[name]?.dispose();
      _selectorControllers.remove(name);
      _selectorNames.removeAt(index);
    });
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Use Proxy'),
          subtitle: const Text('Route requests through a proxy'),
          value: _useProxy,
          onChanged: (value) {
            setState(() {
              _useProxy = value;
            });
          },
          secondary: const Icon(Ionicons.server_outline),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Use Headless Browser'),
          subtitle: const Text('For JavaScript-heavy sites'),
          value: _useHeadlessBrowser,
          onChanged: (value) {
            setState(() {
              _useHeadlessBrowser = value;
            });
          },
          secondary: const Icon(Ionicons.globe_outline),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Follow Pagination'),
          subtitle: const Text('Scrape multiple pages'),
          value: _followPagination,
          onChanged: (value) {
            setState(() {
              _followPagination = value;
            });
          },
          secondary: const Icon(Ionicons.chevron_forward_outline),
          contentPadding: EdgeInsets.zero,
        ),
        if (_followPagination) ...[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Pagination Selector',
              hintText: '.pagination a.next',
              prefixIcon: Icon(Ionicons.link_outline),
            ),
            validator:
                _followPagination
                    ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a pagination selector';
                      }
                      return null;
                    }
                    : null,
          ),
        ],
        SwitchListTile(
          title: const Text('Wait for Selector'),
          subtitle: const Text('Wait for element to load'),
          value: _waitForSelector,
          onChanged: (value) {
            setState(() {
              _waitForSelector = value;
            });
          },
          secondary: const Icon(Ionicons.time_outline),
          contentPadding: EdgeInsets.zero,
        ),
        if (_waitForSelector) ...[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Wait Selector',
              hintText: '#content, .loaded',
              prefixIcon: Icon(Ionicons.hourglass_outline),
            ),
            validator:
                _waitForSelector
                    ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a wait selector';
                      }
                      return null;
                    }
                    : null,
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ActionButton(
        text: 'Start Scraping',
        icon: Ionicons.play_outline,
        type: ActionButtonType.primary,
        isLoading: widget.isLoading,
        isFullWidth: true,
        onPressed: _submitForm,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final selectors = <String, String>{};
      for (final name in _selectorNames) {
        final controller = _selectorControllers[name];
        if (controller != null && controller.text.isNotEmpty) {
          selectors[name] = controller.text;
        }
      }

      final config = ScrapingConfig(
        url: _urlController.text,
        selectors: selectors,
        useProxy: _useProxy,
        useHeadlessBrowser: _useHeadlessBrowser,
        followPagination: _followPagination,
        waitForSelector: _waitForSelector,
      );

      widget.onSubmit(config);
    }
  }
}
