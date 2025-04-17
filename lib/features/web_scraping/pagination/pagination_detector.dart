import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';

/// Types of pagination patterns
enum PaginationType {
  /// Numbered pagination (e.g., 1, 2, 3, ...)
  numbered,

  /// Next/previous pagination
  nextPrev,

  /// Load more button
  loadMore,

  /// Infinite scroll
  infiniteScroll,

  /// Unknown pagination type
  unknown,
}

/// Result of pagination detection
class PaginationDetectionResult {
  /// The type of pagination
  final PaginationType type;

  /// The next page URL, if available
  final String? nextPageUrl;

  /// The previous page URL, if available
  final String? prevPageUrl;

  /// All page URLs, if available
  final List<String> allPageUrls;

  /// The current page number, if available
  final int? currentPage;

  /// The total number of pages, if available
  final int? totalPages;

  /// Whether this is the last page
  final bool isLastPage;

  /// The pagination element
  final Element? paginationElement;

  /// Creates a new [PaginationDetectionResult]
  PaginationDetectionResult({
    required this.type,
    this.nextPageUrl,
    this.prevPageUrl,
    this.allPageUrls = const [],
    this.currentPage,
    this.totalPages,
    this.isLastPage = false,
    this.paginationElement,
  });

  /// Creates an empty [PaginationDetectionResult]
  factory PaginationDetectionResult.empty() {
    return PaginationDetectionResult(
      type: PaginationType.unknown,
      isLastPage: true,
    );
  }
}

/// A class for detecting pagination patterns in webpages
class PaginationDetector {
  /// Logger for logging operations
  final Logger? logger;

  /// The base URL of the page
  final String baseUrl;

  /// Creates a new [PaginationDetector]
  PaginationDetector({
    required this.baseUrl,
    this.logger,
  });

  /// Detects pagination in HTML
  PaginationDetectionResult detectPagination(String html) {
    try {
      final document = html_parser.parse(html);
      
      // Try different pagination detection methods
      final numberedResult = _detectNumberedPagination(document);
      if (numberedResult != null) {
        logger?.info('Detected numbered pagination');
        return numberedResult;
      }

      final nextPrevResult = _detectNextPrevPagination(document);
      if (nextPrevResult != null) {
        logger?.info('Detected next/prev pagination');
        return nextPrevResult;
      }

      final loadMoreResult = _detectLoadMorePagination(document);
      if (loadMoreResult != null) {
        logger?.info('Detected load more pagination');
        return loadMoreResult;
      }

      final infiniteScrollResult = _detectInfiniteScrollPagination(document);
      if (infiniteScrollResult != null) {
        logger?.info('Detected infinite scroll pagination');
        return infiniteScrollResult;
      }

      logger?.warning('Could not detect pagination');
      return PaginationDetectionResult.empty();
    } catch (e) {
      logger?.error('Error detecting pagination: $e');
      return PaginationDetectionResult.empty();
    }
  }

  /// Detects numbered pagination (e.g., 1, 2, 3, ...)
  PaginationDetectionResult? _detectNumberedPagination(Document document) {
    // Common pagination container selectors
    final paginationSelectors = [
      '.pagination',
      '.pager',
      '.pages',
      '.page-numbers',
      'ul.pagination',
      'nav.pagination',
      'div.pagination',
      '[role="navigation"]',
      '.paginate',
      '.paginator',
    ];

    // Try to find a pagination container
    Element? paginationElement;
    for (final selector in paginationSelectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        // Find the element with the most links
        elements.sort((a, b) => 
          b.querySelectorAll('a').length.compareTo(a.querySelectorAll('a').length)
        );
        paginationElement = elements.first;
        break;
      }
    }

    // If no pagination container found, try to find a group of numbered links
    if (paginationElement == null) {
      final links = document.querySelectorAll('a');
      final pageLinks = <Element>[];

      // Find links that look like page numbers
      for (final link in links) {
        final text = link.text.trim();
        if (RegExp(r'^\d+$').hasMatch(text)) {
          pageLinks.add(link);
        }
      }

      // If we found at least 3 numbered links, consider it pagination
      if (pageLinks.length >= 3) {
        // Find a common parent
        final parents = <Element, int>{};
        for (final link in pageLinks) {
          var parent = link.parent;
          while (parent != null) {
            parents[parent] = (parents[parent] ?? 0) + 1;
            parent = parent.parent;
          }
        }

        // Find the closest common parent that contains all page links
        final commonParent = parents.entries
            .where((entry) => entry.value == pageLinks.length)
            .map((entry) => entry.key)
            .toList();

        if (commonParent.isNotEmpty) {
          // Sort by depth (prefer the deepest element)
          commonParent.sort((a, b) {
            int depthA = 0;
            int depthB = 0;
            var parent = a.parent;
            while (parent != null) {
              depthA++;
              parent = parent.parent;
            }
            parent = b.parent;
            while (parent != null) {
              depthB++;
              parent = parent.parent;
            }
            return depthB.compareTo(depthA);
          });
          paginationElement = commonParent.first;
        }
      }
    }

    // If we found a pagination container, extract pagination information
    if (paginationElement != null) {
      final links = paginationElement.querySelectorAll('a');
      final pageUrls = <String>[];
      String? nextPageUrl;
      String? prevPageUrl;
      int? currentPage;
      int? totalPages;
      bool isLastPage = false;

      // Find the current page
      final currentPageElement = paginationElement.querySelector('.current, .active, [aria-current="page"]');
      if (currentPageElement != null) {
        final text = currentPageElement.text.trim();
        if (RegExp(r'^\d+$').hasMatch(text)) {
          currentPage = int.tryParse(text);
        }
      }

      // Extract page URLs and find next/prev links
      for (final link in links) {
        final href = link.attributes['href'];
        if (href == null || href.isEmpty || href == '#') continue;

        final absoluteUrl = _resolveUrl(href);
        if (absoluteUrl != null) {
          pageUrls.add(absoluteUrl);

          // Check if this is a next/prev link
          final rel = link.attributes['rel'];
          final text = link.text.trim().toLowerCase();
          final classes = link.classes.map((c) => c.toLowerCase()).toList();
          final ariaLabel = link.attributes['aria-label']?.toLowerCase();

          if (rel == 'next' || 
              text == 'next' || 
              text == '>' || 
              text == '›' || 
              text == '»' ||
              classes.contains('next') ||
              ariaLabel == 'next') {
            nextPageUrl = absoluteUrl;
          } else if (rel == 'prev' || 
                    text == 'prev' || 
                    text == 'previous' || 
                    text == '<' || 
                    text == '‹' || 
                    text == '«' ||
                    classes.contains('prev') ||
                    classes.contains('previous') ||
                    ariaLabel == 'previous') {
            prevPageUrl = absoluteUrl;
          }
        }
      }

      // Try to determine the total number of pages
      final pageTexts = paginationElement.querySelectorAll('a, span')
          .map((e) => e.text.trim())
          .where((text) => RegExp(r'^\d+$').hasMatch(text))
          .map((text) => int.parse(text))
          .toList();

      if (pageTexts.isNotEmpty) {
        totalPages = pageTexts.reduce((a, b) => a > b ? a : b);
      }

      // Check if this is the last page
      isLastPage = nextPageUrl == null || (currentPage != null && totalPages != null && currentPage >= totalPages);

      return PaginationDetectionResult(
        type: PaginationType.numbered,
        nextPageUrl: nextPageUrl,
        prevPageUrl: prevPageUrl,
        allPageUrls: pageUrls,
        currentPage: currentPage,
        totalPages: totalPages,
        isLastPage: isLastPage,
        paginationElement: paginationElement,
      );
    }

    return null;
  }

  /// Detects next/previous pagination
  PaginationDetectionResult? _detectNextPrevPagination(Document document) {
    // Look for next/prev links
    String? nextPageUrl;
    String? prevPageUrl;
    Element? paginationElement;

    // Check link elements with rel="next" or rel="prev"
    final relLinks = document.querySelectorAll('link[rel="next"], link[rel="prev"]');
    for (final link in relLinks) {
      final rel = link.attributes['rel'];
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final absoluteUrl = _resolveUrl(href);
      if (absoluteUrl != null) {
        if (rel == 'next') {
          nextPageUrl = absoluteUrl;
        } else if (rel == 'prev') {
          prevPageUrl = absoluteUrl;
        }
      }
    }

    // If we found rel links, return the result
    if (nextPageUrl != null || prevPageUrl != null) {
      return PaginationDetectionResult(
        type: PaginationType.nextPrev,
        nextPageUrl: nextPageUrl,
        prevPageUrl: prevPageUrl,
        isLastPage: nextPageUrl == null,
      );
    }

    // Check for anchor links with next/prev text or classes
    final nextSelectors = [
      'a[rel="next"]',
      'a.next',
      'a.pagination-next',
      'a[aria-label="Next"]',
      'a:has(span.next)',
      'a:contains("Next")',
      'a:contains("next")',
      'a:contains(">")',
      'a:contains("›")',
      'a:contains("»")',
    ];

    final prevSelectors = [
      'a[rel="prev"]',
      'a.prev',
      'a.previous',
      'a.pagination-prev',
      'a[aria-label="Previous"]',
      'a:has(span.prev)',
      'a:contains("Previous")',
      'a:contains("Prev")',
      'a:contains("prev")',
      'a:contains("<")',
      'a:contains("‹")',
      'a:contains("«")',
    ];

    // Find next link
    for (final selector in nextSelectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          final href = element.attributes['href'];
          if (href == null || href.isEmpty || href == '#') continue;

          final absoluteUrl = _resolveUrl(href);
          if (absoluteUrl != null) {
            nextPageUrl = absoluteUrl;
            paginationElement = element.parent;
            break;
          }
        }
        if (nextPageUrl != null) break;
      } catch (e) {
        // Some selectors might not be supported by the parser
        continue;
      }
    }

    // Find prev link
    for (final selector in prevSelectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          final href = element.attributes['href'];
          if (href == null || href.isEmpty || href == '#') continue;

          final absoluteUrl = _resolveUrl(href);
          if (absoluteUrl != null) {
            prevPageUrl = absoluteUrl;
            paginationElement ??= element.parent;
            break;
          }
        }
        if (prevPageUrl != null) break;
      } catch (e) {
        // Some selectors might not be supported by the parser
        continue;
      }
    }

    // If we found next/prev links, return the result
    if (nextPageUrl != null || prevPageUrl != null) {
      return PaginationDetectionResult(
        type: PaginationType.nextPrev,
        nextPageUrl: nextPageUrl,
        prevPageUrl: prevPageUrl,
        isLastPage: nextPageUrl == null,
        paginationElement: paginationElement,
      );
    }

    return null;
  }

  /// Detects "load more" pagination
  PaginationDetectionResult? _detectLoadMorePagination(Document document) {
    // Look for "load more" buttons
    final loadMoreSelectors = [
      'a:contains("Load More")',
      'a:contains("load more")',
      'a:contains("Show More")',
      'a:contains("show more")',
      'a:contains("View More")',
      'a:contains("view more")',
      'button:contains("Load More")',
      'button:contains("load more")',
      'button:contains("Show More")',
      'button:contains("show more")',
      'button:contains("View More")',
      'button:contains("view more")',
      '.load-more',
      '.loadmore',
      '.show-more',
      '.showmore',
      '.view-more',
      '.viewmore',
    ];

    for (final selector in loadMoreSelectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          // For anchor elements, check the href
          if (element.localName == 'a') {
            final href = element.attributes['href'];
            if (href == null || href.isEmpty || href == '#') continue;

            final absoluteUrl = _resolveUrl(href);
            if (absoluteUrl != null) {
              return PaginationDetectionResult(
                type: PaginationType.loadMore,
                nextPageUrl: absoluteUrl,
                isLastPage: false,
                paginationElement: element,
              );
            }
          }
          
          // For button elements, check for data attributes
          final dataUrl = element.attributes['data-url'] ?? 
                         element.attributes['data-href'] ?? 
                         element.attributes['data-link'];
          if (dataUrl != null && dataUrl.isNotEmpty) {
            final absoluteUrl = _resolveUrl(dataUrl);
            if (absoluteUrl != null) {
              return PaginationDetectionResult(
                type: PaginationType.loadMore,
                nextPageUrl: absoluteUrl,
                isLastPage: false,
                paginationElement: element,
              );
            }
          }
          
          // Check for other common attributes
          final dataPage = element.attributes['data-page'] ?? 
                          element.attributes['data-next-page'];
          if (dataPage != null && dataPage.isNotEmpty) {
            // This is likely a load more button with AJAX pagination
            return PaginationDetectionResult(
              type: PaginationType.loadMore,
              isLastPage: false,
              paginationElement: element,
            );
          }
        }
      } catch (e) {
        // Some selectors might not be supported by the parser
        continue;
      }
    }

    return null;
  }

  /// Detects infinite scroll pagination
  PaginationDetectionResult? _detectInfiniteScrollPagination(Document document) {
    // Look for common infinite scroll indicators in the page's JavaScript
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptText = script.text.toLowerCase();
      
      // Check for common infinite scroll libraries and patterns
      if (scriptText.contains('infinite scroll') || 
          scriptText.contains('infinitescroll') || 
          scriptText.contains('endless scroll') || 
          scriptText.contains('lazy load') ||
          scriptText.contains('load on scroll')) {
        
        // Try to extract the next page URL from the script
        String? nextPageUrl;
        
        // Try to find double-quoted next URL pattern
        if (scriptText.contains('"next"')) {
          final doubleQuotePattern = RegExp('"next"\\s*:\\s*"([^"]+)"');
          final doubleQuoteMatches = doubleQuotePattern.allMatches(scriptText);
          if (doubleQuoteMatches.isNotEmpty && doubleQuoteMatches.first.groupCount >= 1) {
            nextPageUrl = doubleQuoteMatches.first.group(1);
          }
        }
        
        // Try to find single-quoted next URL pattern
        if (nextPageUrl == null && scriptText.contains("'next'")) {
          final singleQuotePattern = RegExp("'next'\\s*:\\s*'([^']+)'");
          final singleQuoteMatches = singleQuotePattern.allMatches(scriptText);
          if (singleQuoteMatches.isNotEmpty && singleQuoteMatches.first.groupCount >= 1) {
            nextPageUrl = singleQuoteMatches.first.group(1);
          }
        }
        
        if (nextPageUrl != null) {
          final absoluteUrl = _resolveUrl(nextPageUrl);
          if (absoluteUrl != null) {
            return PaginationDetectionResult(
              type: PaginationType.infiniteScroll,
              nextPageUrl: absoluteUrl,
              isLastPage: false,
            );
          }
        }
        
        // If we found infinite scroll indicators but no URL, still return a result
        return PaginationDetectionResult(
          type: PaginationType.infiniteScroll,
          isLastPage: false,
        );
      }
    }

    // Check for common infinite scroll data attributes
    final elements = document.querySelectorAll('[data-infinite-scroll], [data-infinite], [data-endless-scroll]');
    if (elements.isNotEmpty) {
      // Try to extract the next page URL from data attributes
      for (final element in elements) {
        final dataNext = element.attributes['data-next'] ?? 
                        element.attributes['data-next-page'] ?? 
                        element.attributes['data-next-url'];
        if (dataNext != null && dataNext.isNotEmpty) {
          final absoluteUrl = _resolveUrl(dataNext);
          if (absoluteUrl != null) {
            return PaginationDetectionResult(
              type: PaginationType.infiniteScroll,
              nextPageUrl: absoluteUrl,
              isLastPage: false,
              paginationElement: element,
            );
          }
        }
      }
      
      // If we found infinite scroll indicators but no URL, still return a result
      return PaginationDetectionResult(
        type: PaginationType.infiniteScroll,
        isLastPage: false,
        paginationElement: elements.first,
      );
    }

    return null;
  }

  /// Resolves a relative URL to an absolute URL
  String? _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    try {
      final baseUri = Uri.parse(baseUrl);
      if (url.startsWith('/')) {
        // Absolute path
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: url,
        ).toString();
      } else {
        // Relative path
        final basePath = baseUri.path.endsWith('/')
            ? baseUri.path
            : baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: basePath + url,
        ).toString();
      }
    } catch (e) {
      return null;
    }
  }
}
