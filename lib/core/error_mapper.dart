import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce las excepciones de Supabase y de red a mensajes en español
/// que se puedan mostrar directamente en un SnackBar.
class ErrorMapper {
  static String toMessage(Object error) {
    if (error is AuthException) return _auth(error);
    if (error is PostgrestException) return _postgrest(error);
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
    }
    // Errores de red (SocketException en móvil, ClientException del paquete
    // http en web). Se detectan por texto para no importar dart:io, que no
    // existe en Flutter web.
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection')) {
      return 'Sin conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  static String _auth(AuthException e) {
    // Supabase Auth envuelve los fallos de red en esta subclase.
    if (e is AuthRetryableFetchException) {
      return 'Sin conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (msg.contains('password')) {
      return 'La contraseña no cumple los requisitos (mínimo 6 caracteres).';
    }
    if (msg.contains('rate limit') || e.statusCode == '429') {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }
    return 'Error de autenticación: ${e.message}';
  }

  static String _postgrest(PostgrestException e) {
    switch (e.code) {
      case 'P0001': // raise exception de nuestros triggers: el mensaje ya está en español
        return e.message;
      case '23503': // foreign_key_violation (ON DELETE RESTRICT)
        return 'No se puede eliminar: el registro tiene solicitudes de adopción asociadas.';
      case '23505': // unique_violation
        return 'Ya existe un registro con esos datos (por ejemplo, el mismo documento).';
      case '23514': // check_violation
        return 'Algún valor no es válido para la base de datos.';
      case '42501': // insufficient_privilege (RLS)
        return 'No tienes permiso para realizar esta operación. Inicia sesión de nuevo.';
      case 'PGRST116':
        return 'El registro no existe o ya fue eliminado.';
      case 'PGRST301':
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    if (e.message.contains('JWT')) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    return 'Error de base de datos: ${e.message}';
  }
}
