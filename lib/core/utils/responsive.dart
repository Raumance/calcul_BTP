import 'package:flutter/material.dart';

/// Breakpoints et helpers responsive (mobile ↔ desktop).
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isCompact => screenSize.width < Breakpoints.compact;
  bool get isMedium =>
      screenSize.width >= Breakpoints.compact &&
      screenSize.width < Breakpoints.expanded;
  bool get isExpanded => screenSize.width >= Breakpoints.expanded;

  /// Navigation latérale (rail / sidebar) à partir de 900 px.
  bool get useSideNav => screenSize.width >= Breakpoints.medium;

  double get pageMaxWidth {
    if (isExpanded) return 1100;
    if (isMedium) return 820;
    return double.infinity;
  }

  EdgeInsets get pagePadding {
    if (isExpanded) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    if (isMedium) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  int get moduleGridCount {
    if (screenSize.width >= Breakpoints.expanded) return 3;
    if (screenSize.width >= Breakpoints.compact) return 2;
    return 1;
  }
}

/// Centre le contenu avec largeur max sur grand écran.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.pageMaxWidth),
        child: Padding(
          padding: padding ?? context.pagePadding,
          child: child,
        ),
      ),
    );
  }
}
