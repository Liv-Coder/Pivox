# Phase 4: UI and User Experience

This document outlines the UI and user experience features implemented in Phase 4 of the Pivox project.

## Overview

Phase 4 focuses on enhancing the user interface and experience of the web scraping capabilities. The key areas of improvement include:

1. **Scraping Progress Dashboard**: Real-time monitoring of scraping tasks
2. **Visual Status Indicators**: Animated status badges and progress indicators
3. **Interactive Selector Tools**: CSS selector builder and testing playground

## Features

### 1. Scraping Progress Dashboard

The `ScrapingDashboard` widget provides a comprehensive view of all scraping tasks:

- **Task Status Monitoring**: Real-time updates on task status (queued, executing, completed, failed)
- **Performance Metrics**: Statistics on task completion rates, execution times, and success rates
- **Task Management**: Cancel, retry, and view details of tasks
- **Expandable View**: Collapsible sections for different task statuses

```dart
// Create a scraping dashboard
ScrapingDashboard(
  scheduler: taskScheduler,
  onCancelTask: (taskId) => cancelTask(taskId),
  onRetryTask: (taskId) => retryTask(taskId),
  onViewTaskDetails: (task) => showTaskDetails(task),
)
```

### 2. Visual Status Indicators

#### Status Indicators and Badges

The `StatusIndicator` and `StatusBadge` widgets provide visual feedback on status:

- **Color-Coded Indicators**: Different colors for different statuses (success, warning, error, info)
- **Animated Indicators**: Animated indicators for loading and processing states
- **Status Badges**: Compact badges for displaying status in limited space

```dart
// Create a status indicator
StatusIndicator(
  type: StatusIndicatorType.success,
  label: 'Task completed',
  animate: false,
)

// Create a status badge
StatusBadge(
  type: StatusIndicatorType.warning,
  label: 'Rate limited',
  animate: true,
)
```

#### Notification System

The `NotificationSystem` provides toast notifications for important events:

- **Toast Notifications**: Popup notifications for errors, warnings, and success messages
- **Notification Queue**: Queue for managing multiple notifications
- **Automatic Dismissal**: Automatically dismiss notifications after a timeout
- **Manual Dismissal**: Allow users to manually dismiss notifications

```dart
// Show a notification
NotificationManager.instance.showSuccess(
  title: 'Task Completed',
  message: 'Successfully scraped 10 items',
)
```

### 3. Interactive Selector Tools

#### Selector Builder

The `SelectorBuilder` widget provides an interactive way to build CSS selectors:

- **Syntax Highlighting**: Highlight different parts of the selector
- **Validation**: Validate selectors as they are typed
- **Suggestions**: Suggest common selectors and attributes
- **History**: Track selector history for easy navigation

```dart
// Create a selector builder
SelectorBuilder(
  initialSelector: 'div.content',
  onSelectorChanged: (selector) => updateSelector(selector),
  onTest: (selector) => testSelector(selector),
)
```

#### Element Inspector

The `ElementInspector` widget provides a visual way to inspect HTML elements:

- **Element Tree**: Display the HTML element tree
- **Element Details**: Show element attributes and content
- **Element Selection**: Select elements to generate selectors
- **Breadcrumb Navigation**: Navigate the element hierarchy

```dart
// Create an element inspector
ElementInspector(
  html: htmlContent,
  onElementSelected: (selector, element) => selectElement(selector, element),
)
```

#### Selector Testing Playground

The `SelectorTestingPlayground` widget provides an environment for testing CSS selectors:

- **HTML Editor**: Edit HTML content
- **Selector Input**: Input and test CSS selectors
- **Results Preview**: Show elements that match the selector
- **Result Details**: Show details of matched elements

```dart
// Create a selector testing playground
SelectorTestingPlayground(
  initialHtml: htmlContent,
  initialSelector: 'div.content',
  onSelectorChanged: (selector, results) => updateResults(selector, results),
)
```

### 4. Task Management

#### Task Details Dialog

The `TaskDetailsDialog` widget provides detailed information about a task:

- **Task Status**: Show the current status of the task
- **Task Timing**: Show when the task was created, started, and completed
- **Task Result**: Show the result of the task
- **Task Error**: Show any errors that occurred during the task

```dart
// Show task details
TaskDetailsDialog.show(context, task)
```

#### Task Progress Card

The `ScrapingProgressCard` widget provides a compact view of a task's progress:

- **Status Badge**: Show the current status of the task
- **Progress Indicator**: Show the progress of the task
- **Action Buttons**: Buttons for cancelling, retrying, and viewing details
- **Task Information**: Show basic information about the task

```dart
// Create a task progress card
ScrapingProgressCard(
  task: task,
  onCancel: () => cancelTask(task.id),
  onRetry: () => retryTask(task.id),
  onViewDetails: () => viewTaskDetails(task),
)
```

## Integration with WebScraper

All UI components are integrated with the `WebScraper` class through the `WebScrapingUIPage` widget:

```dart
// Create a web scraping UI page
WebScrapingUIPage(
  webScraper: webScraper,
  scheduler: taskScheduler,
)
```

## Usage Example

See the `example/ui_example.dart` file for a complete example of how to use these features.

## Best Practices

1. **Use Status Indicators**: Provide visual feedback on the status of operations
2. **Show Progress**: Show progress indicators for long-running operations
3. **Provide Notifications**: Notify users of important events
4. **Enable Interaction**: Allow users to interact with the scraping process
5. **Show Details**: Provide detailed information about tasks and results
6. **Enable Testing**: Allow users to test selectors before using them
7. **Provide Feedback**: Give immediate feedback on user actions
