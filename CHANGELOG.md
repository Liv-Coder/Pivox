# Changelog

## 1.1.0 - Performance and Reliability Improvements (2025-05-10)

### New Features

- **Streaming HTML Parser**: Process HTML incrementally to reduce memory usage for large documents
- **Concurrency Control**: New `ScrapingTaskQueue` and `ConcurrentWebScraper` for parallel processing
- **Memory-Efficient Parsing**: Chunking strategies for handling large HTML documents
- **Factory Methods**: New `PivoxFactory` class with simplified component creation
- **Standardized Error Handling**: Comprehensive `ScrapingException` hierarchy for better error management

### Performance Improvements

- **Reduced Memory Footprint**: Process large HTML documents without loading entirely into memory
- **Parallel Processing**: Extract data from multiple URLs simultaneously
- **Priority-Based Scheduling**: Prioritize important requests in the scraping queue
- **Batch Processing**: Efficient bulk scraping with progress tracking
- **Improved Resource Management**: Better control over CPU and memory usage during intensive operations

### Ethical Improvements

- **Robots.txt Compliance**: Enhanced support for respecting robots.txt directives
- **Rate Limiting**: Domain-specific rate limiting with exponential backoff
- **Respectful Crawling**: Automatic crawl delays based on site reputation

### Bug Fixes

- **Fixed Proxy Validation**: Resolved issues with parallel proxy validation using isolates
- **Enhanced Error Handling**: Improved error handling throughout the web scraping process
- **Robust Data Extraction**: Added safeguards against empty or malformed data during extraction
- **Improved ProxyHttpClient**: Enhanced error handling and fallback mechanisms in the HTTP client
- **UI Improvements**: Fixed issues with displaying scraped data in the example app

### Improvements

- **Enhanced Logging**: Added detailed logging throughout the scraping process
- **Better Fallback Mechanisms**: Implemented fallbacks when proxies or data extraction fails
- **Structured Data Handling**: Improved handling of structured data extraction
- **Performance Optimizations**: Optimized proxy validation and rotation

## 1.0.0 - Initial Release (2025-04-15)

### Core Features

- **Dynamic Free Proxy Sourcing**: Automatically fetch and update proxies from trusted free sources
- **Smart Proxy Rotation**: Multiple rotation strategies with intelligent proxy scoring
- **Parallel Proxy Health Validation**: Built-in proxy verification system with parallel processing
- **Advanced Filtering**: Powerful filtering options for proxies based on country, region, ISP, etc.
- **Performance Tracking**: Comprehensive proxy performance tracking with detailed analytics
- **HTTP Client Integration**: Seamless integration with http and dio packages

### Web Scraping Features

- **Dynamic User Agent Management**: Automatically rotate through modern, realistic user agents
- **Specialized Site Handlers**: Custom handlers for problematic websites with anti-scraping measures
- **Structured Data Extraction**: Extract structured data from HTML content using CSS selectors
- **Rate Limiting**: Respect website rate limits to avoid blocking
- **Cookie Management**: Handle cookies for authenticated scraping
- **Adaptive Scraping Strategies**: Adjust scraping behavior based on site reputation

### Specialized Site Handlers

- **OnlineKhabarHandler**: Custom handler for onlinekhabar.com
- **VegaMoviesHandler**: Custom handler for vegamovies sites

### Documentation

- Comprehensive API documentation
- Detailed web scraping guide
- Example applications
