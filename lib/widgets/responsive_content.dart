import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

/// Ограничивает ширину контента на очень широких мониторах (1920+).
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.constrainPageWidth(context)) {
      return child;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
