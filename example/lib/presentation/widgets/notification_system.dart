import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

/// Types of notifications
enum NotificationType {
  /// Information notification
  info,

  /// Success notification
  success,

  /// Warning notification
  warning,

  /// Error notification
  error,
}

/// A notification message
class NotificationMessage {
  /// The unique ID of the notification
  final String id;

  /// The title of the notification
  final String title;

  /// The message of the notification
  final String message;

  /// The type of notification
  final NotificationType type;

  /// The time when the notification was created
  final DateTime createdAt;

  /// Whether the notification has been read
  bool isRead;

  /// Whether the notification has been dismissed
  bool isDismissed;

  /// Creates a new [NotificationMessage]
  NotificationMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    DateTime? createdAt,
    this.isRead = false,
    this.isDismissed = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// A manager for notifications
class NotificationManager {
  /// The singleton instance
  static final NotificationManager _instance = NotificationManager._internal();

  /// Gets the singleton instance
  static NotificationManager get instance => _instance;

  /// The queue of notifications
  final Queue<NotificationMessage> _notifications =
      Queue<NotificationMessage>();

  /// The stream controller for notification events
  final StreamController<NotificationMessage> _controller =
      StreamController<NotificationMessage>.broadcast();

  /// The stream of notification events
  Stream<NotificationMessage> get stream => _controller.stream;

  /// Creates a new [NotificationManager]
  NotificationManager._internal();

  /// Shows an information notification
  void showInfo({required String title, required String message, String? id}) {
    _showNotification(
      id: id ?? _generateId(),
      title: title,
      message: message,
      type: NotificationType.info,
    );
  }

  /// Shows a success notification
  void showSuccess({
    required String title,
    required String message,
    String? id,
  }) {
    _showNotification(
      id: id ?? _generateId(),
      title: title,
      message: message,
      type: NotificationType.success,
    );
  }

  /// Shows a warning notification
  void showWarning({
    required String title,
    required String message,
    String? id,
  }) {
    _showNotification(
      id: id ?? _generateId(),
      title: title,
      message: message,
      type: NotificationType.warning,
    );
  }

  /// Shows an error notification
  void showError({required String title, required String message, String? id}) {
    _showNotification(
      id: id ?? _generateId(),
      title: title,
      message: message,
      type: NotificationType.error,
    );
  }

  /// Shows a notification
  void _showNotification({
    required String id,
    required String title,
    required String message,
    required NotificationType type,
  }) {
    final notification = NotificationMessage(
      id: id,
      title: title,
      message: message,
      type: type,
    );

    _notifications.add(notification);
    _controller.add(notification);
  }

  /// Marks a notification as read
  void markAsRead(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found: $id'),
    );

    notification.isRead = true;
    _controller.add(notification);
  }

  /// Dismisses a notification
  void dismiss(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found: $id'),
    );

    notification.isDismissed = true;
    _controller.add(notification);
  }

  /// Gets all notifications
  List<NotificationMessage> getAll() {
    return _notifications.toList();
  }

  /// Gets unread notifications
  List<NotificationMessage> getUnread() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Gets undismissed notifications
  List<NotificationMessage> getUndismissed() {
    return _notifications.where((n) => !n.isDismissed).toList();
  }

  /// Clears all notifications
  void clearAll() {
    _notifications.clear();
    _controller.add(
      NotificationMessage(
        id: 'clear-all',
        title: 'Clear All',
        message: 'All notifications cleared',
        type: NotificationType.info,
        isDismissed: true,
      ),
    );
  }

  /// Generates a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Disposes the manager
  void dispose() {
    _controller.close();
  }
}

/// A widget that displays a notification
class NotificationToast extends StatelessWidget {
  /// The notification to display
  final NotificationMessage notification;

  /// Callback when the notification is dismissed
  final VoidCallback? onDismiss;

  /// Creates a new [NotificationToast]
  const NotificationToast({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (notification.type) {
      case NotificationType.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case NotificationType.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case NotificationType.error:
        color = Colors.red;
        icon = Icons.error;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification.message),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDismiss,
        ),
      ),
    );
  }
}

/// A widget that displays a list of notifications
class NotificationList extends StatelessWidget {
  /// The notifications to display
  final List<NotificationMessage> notifications;

  /// Callback when a notification is dismissed
  final void Function(String id)? onDismiss;

  /// Callback when a notification is tapped
  final void Function(NotificationMessage notification)? onTap;

  /// Creates a new [NotificationList]
  const NotificationList({
    super.key,
    required this.notifications,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications'));
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationToast(
          notification: notification,
          onDismiss:
              onDismiss != null ? () => onDismiss!(notification.id) : null,
        );
      },
    );
  }
}

/// A widget that displays a notification overlay
class NotificationOverlay extends StatefulWidget {
  /// The child widget
  final Widget child;

  /// Creates a new [NotificationOverlay]
  const NotificationOverlay({super.key, required this.child});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  final List<NotificationMessage> _activeNotifications = [];
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    NotificationManager.instance.stream.listen(_handleNotification);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleNotification(NotificationMessage notification) {
    if (notification.isDismissed) {
      setState(() {
        _activeNotifications.removeWhere((n) => n.id == notification.id);
      });
      return;
    }

    setState(() {
      _activeNotifications.add(notification);
    });

    _animationController.forward(from: 0);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _activeNotifications.removeWhere((n) => n.id == notification.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_activeNotifications.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            width: 300,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children:
                    _activeNotifications.map((notification) {
                      return NotificationToast(
                        notification: notification,
                        onDismiss: () {
                          NotificationManager.instance.dismiss(notification.id);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
