import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';
import 'content_detector.dart';

/// Options for text extraction
class TextExtractionOptions {
  /// Whether to preserve links
  final bool preserveLinks;

  /// Whether to preserve images (as alt text)
  final bool preserveImages;

  /// Whether to preserve formatting (bold, italic, etc.)
  final bool preserveFormatting;

  /// Whether to preserve headings
  final bool preserveHeadings;

  /// Whether to preserve lists
  final bool preserveLists;

  /// Whether to preserve paragraphs
  final bool preserveParagraphs;

  /// Whether to preserve tables
  final bool preserveTables;

  /// Whether to preserve line breaks
  final bool preserveLineBreaks;

  /// Whether to extract only the main content
  final bool extractMainContentOnly;

  /// Creates new [TextExtractionOptions]
  const TextExtractionOptions({
    this.preserveLinks = false,
    this.preserveImages = false,
    this.preserveFormatting = false,
    this.preserveHeadings = true,
    this.preserveLists = true,
    this.preserveParagraphs = true,
    this.preserveTables = false,
    this.preserveLineBreaks = true,
    this.extractMainContentOnly = true,
  });

  /// Creates [TextExtractionOptions] for plain text extraction
  factory TextExtractionOptions.plainText() {
    return const TextExtractionOptions(
      preserveLinks: false,
      preserveImages: false,
      preserveFormatting: false,
      preserveHeadings: false,
      preserveLists: false,
      preserveParagraphs: false,
      preserveTables: false,
      preserveLineBreaks: false,
      extractMainContentOnly: true,
    );
  }

  /// Creates [TextExtractionOptions] for readable text extraction
  factory TextExtractionOptions.readable() {
    return const TextExtractionOptions(
      preserveLinks: false,
      preserveImages: true,
      preserveFormatting: true,
      preserveHeadings: true,
      preserveLists: true,
      preserveParagraphs: true,
      preserveTables: true,
      preserveLineBreaks: true,
      extractMainContentOnly: true,
    );
  }

  /// Creates [TextExtractionOptions] for full text extraction
  factory TextExtractionOptions.full() {
    return const TextExtractionOptions(
      preserveLinks: true,
      preserveImages: true,
      preserveFormatting: true,
      preserveHeadings: true,
      preserveLists: true,
      preserveParagraphs: true,
      preserveTables: true,
      preserveLineBreaks: true,
      extractMainContentOnly: false,
    );
  }
}

/// Result of text extraction
class TextExtractionResult {
  /// The extracted text
  final String text;

  /// The title of the page
  final String? title;

  /// The author of the page
  final String? author;

  /// The publication date of the page
  final DateTime? publishDate;

  /// The last modified date of the page
  final DateTime? modifiedDate;

  /// The estimated reading time in minutes
  final int? readingTimeMinutes;

  /// Creates a new [TextExtractionResult]
  TextExtractionResult({
    required this.text,
    this.title,
    this.author,
    this.publishDate,
    this.modifiedDate,
    this.readingTimeMinutes,
  });

  /// Creates an empty [TextExtractionResult]
  factory TextExtractionResult.empty() {
    return TextExtractionResult(text: '');
  }
}

/// A class for extracting clean, readable text from HTML
class TextExtractor {
  /// Logger for logging operations
  final Logger? logger;

  /// The content detector to use
  final ContentDetector _contentDetector;

  /// Creates a new [TextExtractor]
  TextExtractor({this.logger})
    : _contentDetector = ContentDetector(logger: logger);

  /// Extracts text from HTML
  TextExtractionResult extractText(
    String html, {
    TextExtractionOptions options = const TextExtractionOptions(),
  }) {
    try {
      final document = html_parser.parse(html);

      // If extracting only the main content, use the content detector
      if (options.extractMainContentOnly) {
        final contentResult = _contentDetector.detectContent(html);
        if (contentResult.mainContentText.isNotEmpty) {
          // If preserving formatting, extract formatted text from the main content element
          if (options.preserveFormatting ||
              options.preserveHeadings ||
              options.preserveLists ||
              options.preserveParagraphs ||
              options.preserveTables ||
              options.preserveLineBreaks) {
            final mainContentElement = contentResult.mainContentElement;
            if (mainContentElement != null) {
              final formattedText = _extractFormattedText(
                mainContentElement,
                options,
              );
              return TextExtractionResult(
                text: formattedText,
                title: contentResult.title,
                author: contentResult.author,
                publishDate: contentResult.publishDate,
                modifiedDate: contentResult.modifiedDate,
                readingTimeMinutes: contentResult.readingTimeMinutes,
              );
            }
          }

          // Otherwise, use the plain text from the content detector
          return TextExtractionResult(
            text: contentResult.mainContentText,
            title: contentResult.title,
            author: contentResult.author,
            publishDate: contentResult.publishDate,
            modifiedDate: contentResult.modifiedDate,
            readingTimeMinutes: contentResult.readingTimeMinutes,
          );
        }
      }

      // If not extracting only the main content or if main content detection failed,
      // extract text from the entire document
      final body = document.body;
      if (body != null) {
        final text =
            options.preserveFormatting ||
                    options.preserveHeadings ||
                    options.preserveLists ||
                    options.preserveParagraphs ||
                    options.preserveTables ||
                    options.preserveLineBreaks
                ? _extractFormattedText(body, options)
                : _extractPlainText(body);

        // Extract metadata from the document
        String? title;
        String? author;
        DateTime? publishDate;
        DateTime? modifiedDate;
        int? readingTimeMinutes;

        // Try to find the title
        final ogTitle = document.querySelector('meta[property="og:title"]');
        if (ogTitle != null && ogTitle.attributes.containsKey('content')) {
          title = ogTitle.attributes['content'];
        } else {
          final titleElement = document.querySelector('title');
          if (titleElement != null) {
            title = titleElement.text.trim();
          }
        }

        // Try to find the author
        final ogAuthor = document.querySelector('meta[property="og:author"]');
        if (ogAuthor != null && ogAuthor.attributes.containsKey('content')) {
          author = ogAuthor.attributes['content'];
        } else {
          final metaAuthor = document.querySelector('meta[name="author"]');
          if (metaAuthor != null &&
              metaAuthor.attributes.containsKey('content')) {
            author = metaAuthor.attributes['content'];
          }
        }

        // Try to find the publish date
        final ogPublishedTime = document.querySelector(
          'meta[property="article:published_time"]',
        );
        if (ogPublishedTime != null &&
            ogPublishedTime.attributes.containsKey('content')) {
          try {
            publishDate = DateTime.parse(
              ogPublishedTime.attributes['content']!,
            );
          } catch (_) {}
        }

        // Try to find the modified date
        final ogModifiedTime = document.querySelector(
          'meta[property="article:modified_time"]',
        );
        if (ogModifiedTime != null &&
            ogModifiedTime.attributes.containsKey('content')) {
          try {
            modifiedDate = DateTime.parse(
              ogModifiedTime.attributes['content']!,
            );
          } catch (_) {}
        }

        // Calculate reading time
        const wordsPerMinute = 225;
        final wordCount = text.split(RegExp(r'\s+')).length;
        readingTimeMinutes = (wordCount / wordsPerMinute).ceil();
        if (readingTimeMinutes < 1) readingTimeMinutes = 1;

        return TextExtractionResult(
          text: text,
          title: title,
          author: author,
          publishDate: publishDate,
          modifiedDate: modifiedDate,
          readingTimeMinutes: readingTimeMinutes,
        );
      }

      // If all else fails, return an empty result
      logger?.error('Could not extract text');
      return TextExtractionResult.empty();
    } catch (e) {
      logger?.error('Error extracting text: $e');
      return TextExtractionResult.empty();
    }
  }

  /// Extracts plain text from an element
  String _extractPlainText(Element element) {
    // Clone the element to avoid modifying the original
    final clone = element.clone(true);

    // Remove script, style, and other non-content elements
    clone
        .querySelectorAll(
          'script, style, noscript, iframe, form, button, input, select, textarea',
        )
        .forEach((e) => e.remove());

    // Get the text content
    String text = clone.text;

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Extracts formatted text from an element
  String _extractFormattedText(Element element, TextExtractionOptions options) {
    // Clone the element to avoid modifying the original
    final clone = element.clone(true);

    // Remove script, style, and other non-content elements
    clone
        .querySelectorAll(
          'script, style, noscript, iframe, form, button, input, select, textarea',
        )
        .forEach((e) => e.remove());

    // Process the element recursively
    final buffer = StringBuffer();
    _processElement(clone, buffer, options);

    // Normalize whitespace
    String text = buffer.toString();
    text = text.replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    ); // Max 2 consecutive newlines
    text = text.trim();

    return text;
  }

  /// Processes an element recursively
  void _processElement(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    // Skip hidden elements
    if (_isHidden(element)) {
      return;
    }

    // Process different element types
    switch (element.localName) {
      case 'p':
        _processTextElement(element, buffer, options);
        if (options.preserveParagraphs) {
          buffer.write('\n\n');
        }
        break;

      case 'br':
        if (options.preserveLineBreaks) {
          buffer.write('\n');
        }
        break;

      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        if (options.preserveHeadings) {
          buffer.write('\n\n');
          _processTextElement(element, buffer, options);
          buffer.write('\n\n');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'ul':
      case 'ol':
        if (options.preserveLists) {
          buffer.write('\n\n');
          _processList(element, buffer, options);
          buffer.write('\n\n');
        } else {
          _processChildren(element, buffer, options);
        }
        break;

      case 'li':
        if (options.preserveLists) {
          buffer.write('• ');
          _processTextElement(element, buffer, options);
          buffer.write('\n');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'table':
        if (options.preserveTables) {
          buffer.write('\n\n');
          _processTable(element, buffer, options);
          buffer.write('\n\n');
        } else {
          _processChildren(element, buffer, options);
        }
        break;

      case 'a':
        if (options.preserveLinks) {
          _processLink(element, buffer, options);
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'img':
        if (options.preserveImages) {
          _processImage(element, buffer);
        }
        break;

      case 'b':
      case 'strong':
        if (options.preserveFormatting) {
          buffer.write('**');
          _processTextElement(element, buffer, options);
          buffer.write('**');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'i':
      case 'em':
        if (options.preserveFormatting) {
          buffer.write('_');
          _processTextElement(element, buffer, options);
          buffer.write('_');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'pre':
      case 'code':
        if (options.preserveFormatting) {
          buffer.write('\n\n```\n');
          buffer.write(element.text.trim());
          buffer.write('\n```\n\n');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'blockquote':
        if (options.preserveFormatting) {
          buffer.write('\n\n> ');
          final text = _extractPlainText(element);
          buffer.write(text.replaceAll('\n', '\n> '));
          buffer.write('\n\n');
        } else {
          _processTextElement(element, buffer, options);
        }
        break;

      case 'div':
      case 'section':
      case 'article':
      case 'main':
      case 'aside':
      case 'header':
      case 'footer':
      case 'nav':
        // For block elements, process children and add a newline if needed
        _processChildren(element, buffer, options);
        if (options.preserveLineBreaks &&
            buffer.isNotEmpty &&
            !_endsWithNewline(buffer)) {
          buffer.write('\n');
        }
        break;

      default:
        // For other elements, just process children
        _processChildren(element, buffer, options);
        break;
    }
  }

  /// Processes a text element
  void _processTextElement(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    // If the element has children, process them
    if (element.nodes.isNotEmpty) {
      _processChildren(element, buffer, options);
    } else {
      // Otherwise, add the text content
      final text = element.text.trim();
      if (text.isNotEmpty) {
        buffer.write(text);
      }
    }
  }

  /// Processes a link element
  void _processLink(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    final text = element.text.trim();
    final href = element.attributes['href'];

    if (text.isNotEmpty && href != null) {
      buffer.write('[');
      _processTextElement(element, buffer, options);
      buffer.write('](');
      buffer.write(href);
      buffer.write(')');
    } else {
      _processTextElement(element, buffer, options);
    }
  }

  /// Processes an image element
  void _processImage(Element element, StringBuffer buffer) {
    final alt = element.attributes['alt'];
    final src = element.attributes['src'];

    if (alt != null && alt.isNotEmpty) {
      buffer.write('[Image: $alt]');
    } else if (src != null) {
      buffer.write('[Image]');
    }
  }

  /// Processes a list element
  void _processList(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    final items = element.getElementsByTagName('li');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (element.localName == 'ol') {
        buffer.write('${i + 1}. ');
      } else {
        buffer.write('• ');
      }
      _processTextElement(item, buffer, options);
      buffer.write('\n');
    }
  }

  /// Processes a table element
  void _processTable(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    // Extract table headers
    final headers = element.querySelectorAll('th');
    if (headers.isNotEmpty) {
      for (final header in headers) {
        buffer.write('| ');
        buffer.write(header.text.trim());
        buffer.write(' ');
      }
      buffer.write('|\n');

      // Add separator row
      for (int i = 0; i < headers.length; i++) {
        buffer.write('| --- ');
      }
      buffer.write('|\n');
    }

    // Extract table rows
    final rows = element.querySelectorAll('tr');
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue; // Skip header row

      for (final cell in cells) {
        buffer.write('| ');
        buffer.write(cell.text.trim());
        buffer.write(' ');
      }
      buffer.write('|\n');
    }
  }

  /// Processes the children of an element
  void _processChildren(
    Element element,
    StringBuffer buffer,
    TextExtractionOptions options,
  ) {
    for (final node in element.nodes) {
      if (node is Element) {
        _processElement(node, buffer, options);
      } else if (node is Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          buffer.write(text);
          buffer.write(' ');
        }
      }
    }
  }

  /// Checks if an element is hidden
  bool _isHidden(Element element) {
    final style = element.attributes['style'] ?? '';
    final classes = element.classes;

    // Check inline style
    if (style.contains('display: none') ||
        style.contains('visibility: hidden')) {
      return true;
    }

    // Check classes
    if (classes.contains('hidden') ||
        classes.contains('hide') ||
        classes.contains('invisible')) {
      return true;
    }

    // Check aria attributes
    if (element.attributes['aria-hidden'] == 'true') {
      return true;
    }

    return false;
  }

  /// Checks if a buffer ends with a newline
  bool _endsWithNewline(StringBuffer buffer) {
    final str = buffer.toString();
    return str.isNotEmpty && str[str.length - 1] == '\n';
  }
}
