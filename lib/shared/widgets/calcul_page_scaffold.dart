import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Scaffold commun pour les écrans de calcul / plan (hors shell).
class CalculPageScaffold extends StatelessWidget {
  const CalculPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: ResponsiveBody(child: child),
    );
  }
}
