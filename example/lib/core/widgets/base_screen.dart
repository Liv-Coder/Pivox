import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../design/app_spacing.dart';

/// Base screen widget with app bar and body
class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showDrawerButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;
  final bool centerTitle;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.showDrawerButton = true,
    this.bottomNavigationBar,
    this.bottom,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.resizeToAvoidBottomInset = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        leading: _buildLeadingIcon(context),
        actions: actions,
        bottom: bottom,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  Widget? _buildLeadingIcon(BuildContext context) {
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Ionicons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    if (showDrawerButton) {
      return IconButton(
        icon: const Icon(Ionicons.menu_outline),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    return null;
  }
}
