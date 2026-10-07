import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

Future<T?> showConstrainedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.dialogMaxWidth,
        ),
        child: builder(ctx),
      ),
    ),
  );
}
