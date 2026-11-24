/// Configuración de Supabase.
///
/// Las credenciales NO se escriben en el código: se inyectan al compilar con
/// `flutter run --dart-define-from-file=env.json`.
/// Solo se usa la clave pública `anon`; nunca la `service_role`.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
