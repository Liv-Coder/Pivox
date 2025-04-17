import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';

/// Result of content detection
class ContentDetectionResult {
  /// The main content element
  final Element? mainContentElement;

  /// The main content HTML
  final String mainContentHtml;

  /// The main content text
  final String mainContentText;

  /// The content score (higher is better)
  final double contentScore;

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

  /// Creates a new [ContentDetectionResult]
  ContentDetectionResult({
    this.mainContentElement,
    required this.mainContentHtml,
    required this.mainContentText,
    required this.contentScore,
    this.title,
    this.author,
    this.publishDate,
    this.modifiedDate,
    this.readingTimeMinutes,
  });

  /// Creates an empty [ContentDetectionResult]
  factory ContentDetectionResult.empty() {
    return ContentDetectionResult(
      mainContentHtml: '',
      mainContentText: '',
      contentScore: 0.0,
    );
  }
}

/// A class for detecting the main content area of a webpage
class ContentDetector {
  /// Logger for logging operations
  final Logger? logger;

  /// Tags that are likely to contain the main content
  static const List<String> _contentTags = [
    'article',
    'main',
    'section',
    'div',
    'td',
  ];

  /// Tags that are likely to be boilerplate
  static const List<String> _boilerplateTags = [
    'header',
    'footer',
    'nav',
    'aside',
    'menu',
    'sidebar',
    'widget',
    'banner',
    'ad',
    'advertisement',
    'comment',
    'comments',
    'social',
    'share',
    'related',
    'recommended',
    'popular',
    'trending',
  ];

  /// IDs that are likely to contain the main content
  static const List<String> _contentIds = [
    'content',
    'main',
    'article',
    'post',
    'entry',
    'story',
    'body',
    'text',
  ];

  /// Classes that are likely to contain the main content
  static const List<String> _contentClasses = [
    'content',
    'main',
    'article',
    'post',
    'entry',
    'story',
    'body',
    'text',
    'page',
  ];

  /// IDs that are likely to be boilerplate
  static const List<String> _boilerplateIds = [
    'header',
    'footer',
    'nav',
    'sidebar',
    'menu',
    'widget',
    'banner',
    'ad',
    'advertisement',
    'comment',
    'comments',
    'social',
    'share',
    'related',
    'recommended',
    'popular',
    'trending',
  ];

  /// Classes that are likely to be boilerplate
  static const List<String> _boilerplateClasses = [
    'header',
    'footer',
    'nav',
    'sidebar',
    'menu',
    'widget',
    'banner',
    'ad',
    'advertisement',
    'comment',
    'comments',
    'social',
    'share',
    'related',
    'recommended',
    'popular',
    'trending',
  ];

  /// Creates a new [ContentDetector]
  ContentDetector({this.logger});

  /// Detects the main content area of a webpage
  ContentDetectionResult detectContent(String html) {
    try {
      final document = html_parser.parse(html);
      return _detectContentInDocument(document);
    } catch (e) {
      logger?.error('Error detecting content: $e');
      return ContentDetectionResult.empty();
    }
  }

  /// Detects the main content area in a document
  ContentDetectionResult _detectContentInDocument(Document document) {
    // Try to find the main content using semantic tags first
    final semanticResult = _detectSemanticContent(document);
    if (semanticResult != null) {
      logger?.info('Found main content using semantic tags');
      return semanticResult;
    }

    // Try to find the main content using content IDs and classes
    final idClassResult = _detectContentByIdClass(document);
    if (idClassResult != null) {
      logger?.info('Found main content using ID/class');
      return idClassResult;
    }

    // Try to find the main content using text density
    final densityResult = _detectContentByTextDensity(document);
    if (densityResult != null) {
      logger?.info('Found main content using text density');
      return densityResult;
    }

    // Fallback: use the body element
    logger?.warning('Could not detect main content, using body element');
    final body = document.body;
    if (body != null) {
      return ContentDetectionResult(
        mainContentElement: body,
        mainContentHtml: body.innerHtml,
        mainContentText: _extractCleanText(body),
        contentScore: 0.1,
        title: _extractTitle(document),
      );
    }

    // If all else fails, return an empty result
    logger?.error('Could not detect main content');
    return ContentDetectionResult.empty();
  }

  /// Detects the main content using semantic tags
  ContentDetectionResult? _detectSemanticContent(Document document) {
    // Look for <article> tags
    final articles = document.getElementsByTagName('article');
    if (articles.isNotEmpty) {
      // If there are multiple articles, find the one with the most text
      Element bestArticle = articles.first;
      int maxLength = _extractCleanText(bestArticle).length;

      for (final article in articles) {
        final text = _extractCleanText(article);
        if (text.length > maxLength) {
          maxLength = text.length;
          bestArticle = article;
        }
      }

      return ContentDetectionResult(
        mainContentElement: bestArticle,
        mainContentHtml: bestArticle.innerHtml,
        mainContentText: _extractCleanText(bestArticle),
        contentScore: 0.9,
        title: _extractTitle(document),
        author: _extractAuthor(document),
        publishDate: _extractPublishDate(document),
        modifiedDate: _extractModifiedDate(document),
        readingTimeMinutes: _calculateReadingTime(
          _extractCleanText(bestArticle),
        ),
      );
    }

    // Look for <main> tag
    final mains = document.getElementsByTagName('main');
    if (mains.isNotEmpty) {
      final main = mains.first;
      return ContentDetectionResult(
        mainContentElement: main,
        mainContentHtml: main.innerHtml,
        mainContentText: _extractCleanText(main),
        contentScore: 0.8,
        title: _extractTitle(document),
        author: _extractAuthor(document),
        publishDate: _extractPublishDate(document),
        modifiedDate: _extractModifiedDate(document),
        readingTimeMinutes: _calculateReadingTime(_extractCleanText(main)),
      );
    }

    // Look for <section> tags with content-like classes or IDs
    final sections = document.getElementsByTagName('section');
    for (final section in sections) {
      final id = section.id.toLowerCase();
      final classes = section.classes.map((c) => c.toLowerCase()).toList();

      if (_contentIds.any((contentId) => id.contains(contentId)) ||
          _contentClasses.any(
            (contentClass) => classes.any((c) => c.contains(contentClass)),
          )) {
        return ContentDetectionResult(
          mainContentElement: section,
          mainContentHtml: section.innerHtml,
          mainContentText: _extractCleanText(section),
          contentScore: 0.7,
          title: _extractTitle(document),
          author: _extractAuthor(document),
          publishDate: _extractPublishDate(document),
          modifiedDate: _extractModifiedDate(document),
          readingTimeMinutes: _calculateReadingTime(_extractCleanText(section)),
        );
      }
    }

    return null;
  }

  /// Detects the main content using ID and class attributes
  ContentDetectionResult? _detectContentByIdClass(Document document) {
    // Score elements based on their ID and class attributes
    final candidates = <Element, double>{};

    void scoreElement(Element element) {
      double score = 0.0;

      // Score based on tag name
      if (_contentTags.contains(element.localName)) {
        score += 1.0;
      }
      if (_boilerplateTags.contains(element.localName)) {
        score -= 2.0;
      }

      // Score based on ID
      final id = element.id.toLowerCase();
      if (id.isNotEmpty) {
        if (_contentIds.any((contentId) => id.contains(contentId))) {
          score += 2.0;
        }
        if (_boilerplateIds.any(
          (boilerplateId) => id.contains(boilerplateId),
        )) {
          score -= 3.0;
        }
      }

      // Score based on class
      final classes = element.classes.map((c) => c.toLowerCase()).toList();
      if (classes.isNotEmpty) {
        if (_contentClasses.any(
          (contentClass) => classes.any((c) => c.contains(contentClass)),
        )) {
          score += 2.0;
        }
        if (_boilerplateClasses.any(
          (boilerplateClass) =>
              classes.any((c) => c.contains(boilerplateClass)),
        )) {
          score -= 3.0;
        }
      }

      // Only consider elements with positive scores and some content
      final text = _extractCleanText(element);
      if (score > 0 && text.length > 100) {
        // Adjust score based on text length
        score += text.length / 1000;
        candidates[element] = score;
      }
    }

    // Score all divs and other potential content containers
    for (final tag in _contentTags) {
      for (final element in document.getElementsByTagName(tag)) {
        scoreElement(element);
      }
    }

    // Find the element with the highest score
    if (candidates.isNotEmpty) {
      final bestElement =
          candidates.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return ContentDetectionResult(
        mainContentElement: bestElement,
        mainContentHtml: bestElement.innerHtml,
        mainContentText: _extractCleanText(bestElement),
        contentScore: candidates[bestElement]!,
        title: _extractTitle(document),
        author: _extractAuthor(document),
        publishDate: _extractPublishDate(document),
        modifiedDate: _extractModifiedDate(document),
        readingTimeMinutes: _calculateReadingTime(
          _extractCleanText(bestElement),
        ),
      );
    }

    return null;
  }

  /// Detects the main content using text density
  ContentDetectionResult? _detectContentByTextDensity(Document document) {
    // Calculate text density for each element
    final candidates = <Element, double>{};

    void calculateDensity(Element element) {
      // Skip small elements and known boilerplate
      if (element.text.length < 100) return;
      if (_isBoilerplate(element)) return;

      // Calculate text density (text length / HTML length)
      final text = _extractCleanText(element);
      final html = element.outerHtml;

      if (html.isEmpty) return;

      final density = text.length / html.length;

      // Calculate link density (link text length / total text length)
      final links = element.getElementsByTagName('a');
      int linkTextLength = 0;
      for (final link in links) {
        linkTextLength += link.text.length;
      }

      final linkDensity = text.isEmpty ? 1.0 : linkTextLength / text.length;

      // Calculate paragraph density (number of paragraphs / total length)
      final paragraphs = element.getElementsByTagName('p');
      final paragraphDensity =
          text.isEmpty ? 0.0 : paragraphs.length / (text.length / 500);

      // Calculate final score
      double score = density * 10;
      score -= linkDensity * 5; // Penalize high link density
      score += paragraphDensity * 2; // Reward high paragraph density

      // Bonus for longer text
      score += text.length / 2000;

      candidates[element] = score;
    }

    // Calculate density for all potential content elements
    for (final tag in _contentTags) {
      for (final element in document.getElementsByTagName(tag)) {
        calculateDensity(element);
      }
    }

    // Find the element with the highest score
    if (candidates.isNotEmpty) {
      final bestElement =
          candidates.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return ContentDetectionResult(
        mainContentElement: bestElement,
        mainContentHtml: bestElement.innerHtml,
        mainContentText: _extractCleanText(bestElement),
        contentScore: candidates[bestElement]!,
        title: _extractTitle(document),
        author: _extractAuthor(document),
        publishDate: _extractPublishDate(document),
        modifiedDate: _extractModifiedDate(document),
        readingTimeMinutes: _calculateReadingTime(
          _extractCleanText(bestElement),
        ),
      );
    }

    return null;
  }

  /// Checks if an element is likely to be boilerplate
  bool _isBoilerplate(Element element) {
    final id = element.id.toLowerCase();
    final classes = element.classes.map((c) => c.toLowerCase()).toList();
    final tag = element.localName;

    // Check tag name
    if (_boilerplateTags.contains(tag)) {
      return true;
    }

    // Check ID
    if (id.isNotEmpty &&
        _boilerplateIds.any((boilerplateId) => id.contains(boilerplateId))) {
      return true;
    }

    // Check classes
    if (classes.isNotEmpty &&
        _boilerplateClasses.any(
          (boilerplateClass) =>
              classes.any((c) => c.contains(boilerplateClass)),
        )) {
      return true;
    }

    return false;
  }

  /// Extracts clean text from an element
  String _extractCleanText(Element element) {
    // Clone the element to avoid modifying the original
    final clone = element.clone(true);

    // Remove script and style elements
    clone
        .querySelectorAll('script, style, noscript')
        .forEach((e) => e.remove());

    // Get the text content
    String text = clone.text;

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Extracts the title from a document
  String? _extractTitle(Document document) {
    // Try to find the title in meta tags first
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null && ogTitle.attributes.containsKey('content')) {
      return ogTitle.attributes['content'];
    }

    final twitterTitle = document.querySelector('meta[name="twitter:title"]');
    if (twitterTitle != null &&
        twitterTitle.attributes.containsKey('content')) {
      return twitterTitle.attributes['content'];
    }

    // Try to find the title in schema.org metadata
    final schemaTitle = document.querySelector('[itemprop="headline"]');
    if (schemaTitle != null) {
      return schemaTitle.text.trim();
    }

    // Fall back to the title element
    final titleElement = document.querySelector('title');
    if (titleElement != null) {
      return titleElement.text.trim();
    }

    // Try to find an h1 element
    final h1 = document.querySelector('h1');
    if (h1 != null) {
      return h1.text.trim();
    }

    return null;
  }

  /// Extracts the author from a document
  String? _extractAuthor(Document document) {
    // Try to find the author in meta tags
    final ogAuthor = document.querySelector('meta[property="og:author"]');
    if (ogAuthor != null && ogAuthor.attributes.containsKey('content')) {
      return ogAuthor.attributes['content'];
    }

    final metaAuthor = document.querySelector('meta[name="author"]');
    if (metaAuthor != null && metaAuthor.attributes.containsKey('content')) {
      return metaAuthor.attributes['content'];
    }

    // Try to find the author in schema.org metadata
    final schemaAuthor = document.querySelector('[itemprop="author"]');
    if (schemaAuthor != null) {
      final authorName = schemaAuthor.querySelector('[itemprop="name"]');
      if (authorName != null) {
        return authorName.text.trim();
      }
      return schemaAuthor.text.trim();
    }

    // Try to find the author in common author elements
    final authorElements = document.querySelectorAll(
      '.author, .byline, .meta-author, [rel="author"]',
    );
    if (authorElements.isNotEmpty) {
      return authorElements.first.text.trim();
    }

    return null;
  }

  /// Extracts the publish date from a document
  DateTime? _extractPublishDate(Document document) {
    // Try to find the publish date in meta tags
    final ogPublishedTime = document.querySelector(
      'meta[property="article:published_time"]',
    );
    if (ogPublishedTime != null &&
        ogPublishedTime.attributes.containsKey('content')) {
      try {
        return DateTime.parse(ogPublishedTime.attributes['content']!);
      } catch (_) {}
    }

    // Try to find the publish date in schema.org metadata
    final schemaPublishDate = document.querySelector(
      '[itemprop="datePublished"]',
    );
    if (schemaPublishDate != null) {
      if (schemaPublishDate.attributes.containsKey('content')) {
        try {
          return DateTime.parse(schemaPublishDate.attributes['content']!);
        } catch (_) {}
      }
      try {
        return DateTime.parse(schemaPublishDate.text.trim());
      } catch (_) {}
    }

    // Try to find the publish date in common date elements
    final dateElements = document.querySelectorAll(
      '.date, .published, .publish-date, .post-date, time',
    );
    for (final element in dateElements) {
      if (element.attributes.containsKey('datetime')) {
        try {
          return DateTime.parse(element.attributes['datetime']!);
        } catch (_) {}
      }

      // Try to parse the text as a date
      try {
        return DateTime.parse(element.text.trim());
      } catch (_) {}
    }

    return null;
  }

  /// Extracts the modified date from a document
  DateTime? _extractModifiedDate(Document document) {
    // Try to find the modified date in meta tags
    final ogModifiedTime = document.querySelector(
      'meta[property="article:modified_time"]',
    );
    if (ogModifiedTime != null &&
        ogModifiedTime.attributes.containsKey('content')) {
      try {
        return DateTime.parse(ogModifiedTime.attributes['content']!);
      } catch (_) {}
    }

    // Try to find the modified date in schema.org metadata
    final schemaModifiedDate = document.querySelector(
      '[itemprop="dateModified"]',
    );
    if (schemaModifiedDate != null) {
      if (schemaModifiedDate.attributes.containsKey('content')) {
        try {
          return DateTime.parse(schemaModifiedDate.attributes['content']!);
        } catch (_) {}
      }
      try {
        return DateTime.parse(schemaModifiedDate.text.trim());
      } catch (_) {}
    }

    return null;
  }

  /// Calculates the estimated reading time in minutes
  int _calculateReadingTime(String text) {
    // Average reading speed is about 200-250 words per minute
    const wordsPerMinute = 225;

    // Count words (roughly)
    final wordCount = text.split(RegExp(r'\s+')).length;

    // Calculate reading time
    final readingTime = (wordCount / wordsPerMinute).ceil();

    // Return at least 1 minute
    return readingTime > 0 ? readingTime : 1;
  }
}
