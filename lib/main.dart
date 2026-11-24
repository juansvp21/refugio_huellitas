import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/supabase_config.dart';
import 'package:refugio_huellitas/presentation/app_router.dart';
import 'package:refugio_huellitas/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sin credenciales no se puede conectar: mostramos cómo ejecutar la app
  // en vez de dejar que falle.
  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigErrorApp(
      'Faltan SUPABASE_URL y SUPABASE_ANON_KEY.\n\n'
      'Ejecuta la app con:\nflutter run --dart-define-from-file=env.json',
    ));
    return;
  }

  try {
    // Conexión con Supabase. Usa solo la clave pública (anon / publishable);
    // la seguridad real la aplica Row Level Security en la base de datos.
    // En supabase_flutter 2.x el parámetro se llama publishableKey y acepta
    // tanto la clave "anon" clásica como la nueva "sb_publishable_...".
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
  } catch (e) {
    runApp(_ConfigErrorApp('No se pudo inicializar Supabase.\nRevisa los valores de env.json.\n\n$e'));
    return;
  }

  serviceLocator.initialize(Supabase.instance.client);
  runApp(const HuellitasApp());
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE91E63),
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)).onSurface,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 14),
    ),
  );
}

class HuellitasApp extends StatelessWidget {
  const HuellitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huellitas - Adopción de Mascotas',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class _ConfigErrorApp extends StatelessWidget {
  final String message;
  const _ConfigErrorApp(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
