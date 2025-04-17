import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget for building CSS selectors
class SelectorBuilder extends StatefulWidget {
  /// The initial selector
  final String initialSelector;

  /// Callback when the selector changes
  final void Function(String selector)? onSelectorChanged;

  /// Callback when the test button is pressed
  final void Function(String selector)? onTest;

  /// Creates a new [SelectorBuilder]
  const SelectorBuilder({
    super.key,
    this.initialSelector = '',
    this.onSelectorChanged,
    this.onTest,
  });

  @override
  State<SelectorBuilder> createState() => _SelectorBuilderState();
}

class _SelectorBuilderState extends State<SelectorBuilder> {
  late TextEditingController _selectorController;
  final List<String> _selectorHistory = [];
  int _historyIndex = -1;
  bool _showAdvancedOptions = false;
  String _selectedTag = 'div';
  String _selectedAttribute = 'class';
  String _attributeValue = '';
  String _selectedCombinator = ' ';
  bool _isValidSelector = true;

  final List<String> _commonTags = [
    'div',
    'span',
    'a',
    'p',
    'h1',
    'h2',
    'h3',
    'ul',
    'li',
    'table',
    'tr',
    'td',
    'img',
    'input',
    'button',
    'form',
    'section',
    'article',
    'main',
  ];

  final List<String> _commonAttributes = [
    'class',
    'id',
    'name',
    'href',
    'src',
    'alt',
    'title',
    'data-*',
    'aria-*',
  ];

  final List<String> _combinators = [
    ' ', // Descendant
    '>', // Child
    '+', // Adjacent sibling
    '~', // General sibling
  ];

  final Map<String, String> _combinatorDescriptions = {
    ' ': 'Descendant (space)',
    '>': 'Child (>)',
    '+': 'Adjacent sibling (+)',
    '~': 'General sibling (~)',
  };

  @override
  void initState() {
    super.initState();
    _selectorController = TextEditingController(text: widget.initialSelector);
    _selectorController.addListener(_onSelectorChanged);
    
    if (widget.initialSelector.isNotEmpty) {
      _selectorHistory.add(widget.initialSelector);
      _historyIndex = 0;
    }
  }

  @override
  void dispose() {
    _selectorController.removeListener(_onSelectorChanged);
    _selectorController.dispose();
    super.dispose();
  }

  void _onSelectorChanged() {
    final selector = _selectorController.text;
    
    // Validate the selector
    _isValidSelector = _validateSelector(selector);
    
    widget.onSelectorChanged?.call(selector);
  }

  bool _validateSelector(String selector) {
    if (selector.isEmpty) {
      return true;
    }
    
    // This is a simple validation - in a real app, you would use a more robust method
    try {
      // Check for unbalanced brackets
      int openBrackets = 0;
      for (int i = 0; i < selector.length; i++) {
        if (selector[i] == '[') openBrackets++;
        if (selector[i] == ']') openBrackets--;
        if (openBrackets < 0) return false;
      }
      if (openBrackets != 0) return false;
      
      // Check for unbalanced parentheses
      int openParens = 0;
      for (int i = 0; i < selector.length; i++) {
        if (selector[i] == '(') openParens++;
        if (selector[i] == ')') openParens--;
        if (openParens < 0) return false;
      }
      if (openParens != 0) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  void _addToHistory(String selector) {
    if (selector.isEmpty) {
      return;
    }
    if (_selectorHistory.isNotEmpty && _selectorHistory.last == selector) {
      return;
    }
    
    setState(() {
      // Remove any forward history
      if (_historyIndex < _selectorHistory.length - 1) {
        _selectorHistory.removeRange(_historyIndex + 1, _selectorHistory.length);
      }
      
      _selectorHistory.add(selector);
      _historyIndex = _selectorHistory.length - 1;
      
      // Limit history size
      if (_selectorHistory.length > 20) {
        _selectorHistory.removeAt(0);
        _historyIndex--;
      }
    });
  }

  void _navigateHistory(int direction) {
    final newIndex = _historyIndex + direction;
    if (newIndex < 0 || newIndex >= _selectorHistory.length) return;
    
    setState(() {
      _historyIndex = newIndex;
      _selectorController.text = _selectorHistory[_historyIndex];
    });
  }

  void _addTagToSelector() {
    final currentSelector = _selectorController.text;
    String newSelector;
    
    if (_attributeValue.isNotEmpty) {
      // Add tag with attribute
      if (_selectedAttribute == 'id') {
        newSelector = '$currentSelector$_selectedCombinator$_selectedTag#$_attributeValue';
      } else if (_selectedAttribute == 'class') {
        newSelector = '$currentSelector$_selectedCombinator$_selectedTag.$_attributeValue';
      } else {
        newSelector = '$currentSelector$_selectedCombinator$_selectedTag[$_selectedAttribute="$_attributeValue"]';
      }
    } else {
      // Add just the tag
      newSelector = '$currentSelector$_selectedCombinator$_selectedTag';
    }
    
    _selectorController.text = newSelector;
    _addToHistory(newSelector);
  }

  void _addAttributeToSelector() {
    if (_attributeValue.isEmpty) return;
    
    final currentSelector = _selectorController.text;
    String attributeSelector;
    
    if (_selectedAttribute == 'id') {
      attributeSelector = '#$_attributeValue';
    } else if (_selectedAttribute == 'class') {
      attributeSelector = '.$_attributeValue';
    } else {
      attributeSelector = '[$_selectedAttribute="$_attributeValue"]';
    }
    
    _selectorController.text = '$currentSelector$attributeSelector';
    _addToHistory(_selectorController.text);
  }

  void _addPseudoClass(String pseudoClass) {
    final currentSelector = _selectorController.text;
    if (currentSelector.isEmpty) return;
    
    _selectorController.text = '$currentSelector:$pseudoClass';
    _addToHistory(_selectorController.text);
  }

  void _addPseudoElement(String pseudoElement) {
    final currentSelector = _selectorController.text;
    if (currentSelector.isEmpty) return;
    
    _selectorController.text = '$currentSelector::$pseudoElement';
    _addToHistory(_selectorController.text);
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
              'CSS Selector Builder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Selector input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _selectorController,
                    decoration: InputDecoration(
                      labelText: 'CSS Selector',
                      hintText: 'Enter a CSS selector',
                      errorText: _isValidSelector ? null : 'Invalid selector',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.code),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            tooltip: 'Copy to clipboard',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _selectorController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selector copied to clipboard')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () {
                              _selectorController.clear();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Previous selector',
                  onPressed: _historyIndex > 0 ? () => _navigateHistory(-1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Next selector',
                  onPressed: _historyIndex < _selectorHistory.length - 1 ? () => _navigateHistory(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Selector'),
                  onPressed: _isValidSelector && _selectorController.text.isNotEmpty
                      ? () => widget.onTest?.call(_selectorController.text)
                      : null,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(_showAdvancedOptions ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showAdvancedOptions ? 'Hide Options' : 'Show Options'),
                  onPressed: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                ),
              ],
            ),
            
            // Advanced options
            if (_showAdvancedOptions) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              // Tag and attribute selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'HTML Tag',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTag,
                      items: _commonTags.map((tag) {
                        return DropdownMenuItem<String>(
                          value: tag,
                          child: Text(tag),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTag = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Attribute',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedAttribute,
                      items: _commonAttributes.map((attr) {
                        return DropdownMenuItem<String>(
                          value: attr,
                          child: Text(attr),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAttribute = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Attribute value and combinator
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Attribute Value',
                        hintText: 'Enter attribute value',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _attributeValue = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Combinator',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCombinator,
                      items: _combinators.map((combinator) {
                        return DropdownMenuItem<String>(
                          value: combinator,
                          child: Text(_combinatorDescriptions[combinator] ?? combinator),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCombinator = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Add buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _addTagToSelector,
                    child: const Text('Add Tag'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _attributeValue.isNotEmpty ? _addAttributeToSelector : null,
                    child: const Text('Add Attribute'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Pseudo-classes and pseudo-elements
              Text(
                'Pseudo-classes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'hover',
                  'active',
                  'focus',
                  'first-child',
                  'last-child',
                  'nth-child(n)',
                  'not()',
                ].map((pseudo) {
                  return ActionChip(
                    label: Text(pseudo),
                    onPressed: () => _addPseudoClass(pseudo),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Pseudo-elements',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'before',
                  'after',
                  'first-line',
                  'first-letter',
                  'selection',
                  'placeholder',
                ].map((pseudo) {
                  return ActionChip(
                    label: Text(pseudo),
                    onPressed: () => _addPseudoElement(pseudo),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
