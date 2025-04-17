import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'selector_builder.dart';

/// A widget for testing CSS selectors on HTML content
class SelectorTestingPlayground extends StatefulWidget {
  /// The initial HTML content
  final String initialHtml;

  /// The initial CSS selector
  final String initialSelector;

  /// Callback when the selector changes
  final void Function(String selector, List<String> results)? onSelectorChanged;

  /// Creates a new [SelectorTestingPlayground]
  const SelectorTestingPlayground({
    super.key,
    this.initialHtml = '',
    this.initialSelector = '',
    this.onSelectorChanged,
  });

  @override
  State<SelectorTestingPlayground> createState() => _SelectorTestingPlaygroundState();
}

class _SelectorTestingPlaygroundState extends State<SelectorTestingPlayground> {
  late TextEditingController _htmlController;
  String _currentSelector = '';
  List<String> _selectorResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showHtmlEditor = true;

  @override
  void initState() {
    super.initState();
    _htmlController = TextEditingController(text: widget.initialHtml);
    _currentSelector = widget.initialSelector;
    
    if (widget.initialHtml.isNotEmpty && widget.initialSelector.isNotEmpty) {
      _testSelector(widget.initialSelector);
    }
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  void _testSelector(String selector) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentSelector = selector;
    });
    
    try {
      final html = _htmlController.text;
      if (html.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'HTML content is empty';
          _selectorResults = [];
        });
        return;
      }
      
      // Parse the HTML
      final document = html_parser.parse(html);
      
      // Query the selector
      final elements = document.querySelectorAll(selector);
      
      // Extract the results
      final results = elements.map(_elementToString).toList();
      
      setState(() {
        _isLoading = false;
        _selectorResults = results;
      });
      
      widget.onSelectorChanged?.call(selector, results);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
        _selectorResults = [];
      });
    }
  }

  String _elementToString(dom.Element element) {
    // Create a simplified string representation of the element
    final tag = element.localName;
    final id = element.id.isNotEmpty ? ' id="${element.id}"' : '';
    final classes = element.classes.isNotEmpty ? ' class="${element.classes.join(' ')}"' : '';
    
    // Get other attributes
    final attributes = element.attributes.entries
        .where((attr) => attr.key != 'id' && attr.key != 'class')
        .map((attr) => ' ${attr.key}="${attr.value}"')
        .join('');
    
    // Get the text content
    final text = element.text.trim();
    final textPreview = text.length > 50 ? '${text.substring(0, 47)}...' : text;
    
    // Build the element string
    final elementString = '<$tag$id$classes$attributes>${textPreview.isNotEmpty ? ' $textPreview' : ''}</$tag>';
    
    return elementString;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selector Testing Playground',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Selector builder
            SelectorBuilder(
              initialSelector: widget.initialSelector,
              onSelectorChanged: (selector) {
                setState(() {
                  _currentSelector = selector;
                });
              },
              onTest: _testSelector,
            ),
            const SizedBox(height: 16),
            
            // HTML editor toggle
            Row(
              children: [
                Text(
                  'HTML Content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(_showHtmlEditor ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showHtmlEditor ? 'Hide Editor' : 'Show Editor'),
                  onPressed: () {
                    setState(() {
                      _showHtmlEditor = !_showHtmlEditor;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // HTML editor
            if (_showHtmlEditor)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _htmlController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter HTML content here',
                    contentPadding: EdgeInsets.all(8),
                    border: InputBorder.none,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Results header
            Row(
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const Spacer(),
                Text(
                  '${_selectorResults.length} elements found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Results list
            Expanded(
              child: _selectorResults.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage != null
                            ? 'No results due to error'
                            : _currentSelector.isEmpty
                                ? 'Enter a selector and click Test'
                                : 'No elements match the selector',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectorResults.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              _selectorResults[index],
                              style: const TextStyle(fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Element ${index + 1}'),
                                  content: SelectableText(
                                    _selectorResults[index],
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
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
}
