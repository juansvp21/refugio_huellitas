import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';

/// SnackBars con el mismo estilo que ya usaba la app (icono + texto, flotante).
class AppSnackBar {
  static void success(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle, Colors.green);

  static void warning(BuildContext context, String message) =>
      _show(context, message, Icons.info_outline, Colors.orange);

  /// Acepta un texto o cualquier excepción (se traduce con [ErrorMapper]).
  static void error(BuildContext context, Object error) {
    final message = error is String ? error : ErrorMapper.toMessage(error);
    _show(context, message, Icons.error, Colors.red, seconds: 4);
  }

  static void _show(BuildContext context, String message, IconData icon, Color color,
      {int seconds = 3}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: seconds),
      ),
    );
  }
}
