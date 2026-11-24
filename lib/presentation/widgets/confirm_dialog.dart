import 'package:flutter/material.dart';

/// Diálogo de confirmación reutilizable. Devuelve true solo si el usuario confirma.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result == true;
}
