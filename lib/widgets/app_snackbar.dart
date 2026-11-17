import 'package:material_ui/material_ui.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  _displayAppSnackBar(
    ScaffoldMessenger.of(context),
    Theme.of(context).colorScheme,
    message,
    isError: isError,
  );
}

void showGlobalAppSnackBar(String message, {bool isError = true}) {
  final messenger = appScaffoldMessengerKey.currentState;
  final context = appScaffoldMessengerKey.currentContext;
  if (messenger == null || context == null) return;
  _displayAppSnackBar(
    messenger,
    Theme.of(context).colorScheme,
    message,
    isError: isError,
  );
}

void _displayAppSnackBar(
  ScaffoldMessengerState messenger,
  ColorScheme colorScheme,
  String message, {
  required bool isError,
}) {
  final backgroundColor = isError ? colorScheme.error : colorScheme.primary;
  final foregroundColor = isError ? colorScheme.onError : colorScheme.onPrimary;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foregroundColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foregroundColor)),
            ),
          ],
        ),
      ),
    );
}
