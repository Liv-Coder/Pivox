import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// A widget for inspecting HTML elements
class ElementInspector extends StatefulWidget {
  /// The HTML content to inspect
  final String html;

  /// Callback when an element is selected
  final void Function(String selector, dom.Element element)? onElementSelected;

  /// Creates a new [ElementInspector]
  const ElementInspector({
    super.key,
    required this.html,
    this.onElementSelected,
  });

  @override
  State<ElementInspector> createState() => _ElementInspectorState();
}

class _ElementInspectorState extends State<ElementInspector> {
  dom.Element? _rootElement;
  dom.Element? _selectedElement;
  List<dom.Element> _breadcrumbs = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAttributes = true;

  @override
  void initState() {
    super.initState();
    _parseHtml();
  }

  @override
  void didUpdateWidget(ElementInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.html != oldWidget.html) {
      _parseHtml();
    }
  }

  void _parseHtml() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.html.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'HTML content is empty';
          _rootElement = null;
          _selectedElement = null;
          _breadcrumbs = [];
        });
        return;
      }

      // Parse the HTML
      final document = html_parser.parse(widget.html);

      setState(() {
        _isLoading = false;
        _rootElement = document.documentElement;
        _selectedElement = null;
        _breadcrumbs = [document.documentElement!];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error parsing HTML: ${e.toString()}';
        _rootElement = null;
        _selectedElement = null;
        _breadcrumbs = [];
      });
    }
  }

  void _selectElement(dom.Element element) {
    setState(() {
      _selectedElement = element;

      // Update breadcrumbs
      _breadcrumbs = [];
      dom.Element? current = element;
      while (current != null) {
        _breadcrumbs.insert(0, current);
        current = current.parent;
      }
    });

    // Generate a selector for the element
    final selector = _generateSelector(element);

    // Notify the callback
    widget.onElementSelected?.call(selector, element);
  }

  void _navigateToBreadcrumb(int index) {
    if (index < 0 || index >= _breadcrumbs.length) return;

    setState(() {
      _selectedElement = _breadcrumbs[index];
      _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
    });

    // Generate a selector for the element
    final selector = _generateSelector(_selectedElement!);

    // Notify the callback
    widget.onElementSelected?.call(selector, _selectedElement!);
  }

  String _generateSelector(dom.Element element) {
    // Generate a CSS selector for the element
    if (element.id.isNotEmpty) {
      return '#${element.id}';
    }

    if (element.classes.isNotEmpty) {
      return '.${element.classes.join('.')}';
    }

    // Use the tag name and position
    final tag = element.localName ?? 'div';
    final parent = element.parent;
    if (parent == null) return tag;

    final siblings = parent.children.where((e) => e.localName == tag).toList();
    if (siblings.length == 1) return tag;

    final index = siblings.indexOf(element) + 1;
    return '$tag:nth-of-type($index)';
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
              'Element Inspector',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Breadcrumbs
            if (_breadcrumbs.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _breadcrumbs.length; i++) ...[
                      if (i > 0) const Icon(Icons.chevron_right, size: 16),
                      InkWell(
                        onTap: () => _navigateToBreadcrumb(i),
                        child: Chip(
                          label: Text(_breadcrumbs[i].localName ?? 'unknown'),
                          backgroundColor:
                              i == _breadcrumbs.length - 1
                                  ? Colors.blue.shade100
                                  : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading indicator or error message
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
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
              )
            else if (_rootElement == null)
              const Center(child: Text('No HTML content'))
            else ...[
              // Element details
              if (_selectedElement != null) ...[
                Row(
                  children: [
                    Text(
                      'Selected Element',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(
                        _showAttributes
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        _showAttributes ? 'Hide Attributes' : 'Show Attributes',
                      ),
                      onPressed: () {
                        setState(() {
                          _showAttributes = !_showAttributes;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Element tag and attributes
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '<${_selectedElement!.localName}${_showAttributes ? '' : ' ...'}${_selectedElement!.children.isEmpty ? ' /' : ''}>',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_showAttributes &&
                          _selectedElement!.attributes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...(_selectedElement!.attributes.entries.map((attr) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              '${attr.key}="${attr.value}"',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          );
                        })),
                      ],
                      if (_selectedElement!.children.isEmpty &&
                          _selectedElement!.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedElement!.text.trim(),
                          style: const TextStyle(fontFamily: 'monospace'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (_selectedElement!.children.isNotEmpty)
                        Text(
                          '...',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (_selectedElement!.children.isNotEmpty)
                        Text(
                          '</${_selectedElement!.localName}>',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Child elements
                Text(
                  'Child Elements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
              ],

              // Element tree
              Expanded(
                child:
                    _selectedElement == null
                        ? _buildElementTree(_rootElement!)
                        : _selectedElement!.children.isEmpty
                        ? Center(
                          child: Text(
                            'No child elements',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                        : _buildElementTree(_selectedElement!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildElementTree(dom.Element element) {
    return ListView.builder(
      itemCount: element.children.length,
      itemBuilder: (context, index) {
        final child = element.children[index];
        return _buildElementItem(child);
      },
    );
  }

  Widget _buildElementItem(dom.Element element) {
    final hasChildren = element.children.isNotEmpty;
    final hasText = element.text.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          hasChildren ? Icons.folder : Icons.insert_drive_file,
          color: hasChildren ? Colors.amber : Colors.blue,
        ),
        title: Text(
          element.localName ?? 'unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (element.id.isNotEmpty) Text('id: ${element.id}'),
            if (element.classes.isNotEmpty)
              Text('class: ${element.classes.join(' ')}'),
            if (hasText && !hasChildren)
              Text(
                element.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Text(
          hasChildren ? '${element.children.length} children' : '',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        onTap: () => _selectElement(element),
      ),
    );
  }
}
