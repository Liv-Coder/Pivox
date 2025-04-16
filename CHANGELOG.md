# Changelog

## 1.0.1 - Bug Fixes and Improvements (2025-05-10)

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
