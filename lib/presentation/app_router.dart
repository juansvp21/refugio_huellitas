import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/screens/adoptions_screen.dart';
import 'package:refugio_huellitas/presentation/screens/auth_gate.dart';
import 'package:refugio_huellitas/presentation/screens/edit_pet_screen.dart';
import 'package:refugio_huellitas/presentation/screens/pet_detail_screen.dart';
import 'package:refugio_huellitas/presentation/screens/pet_list_screen.dart';
import 'package:refugio_huellitas/presentation/screens/register_pet_screen.dart';
import 'package:refugio_huellitas/service_locator.dart';

class AppRoutes {
  static const home = '/';
  static const list = '/list';
  static const register = '/register';
  static const detail = '/detail'; // argumento: String (id de la mascota)
  static const edit = '/edit'; // argumento: Pet
  static const adoptions = '/adoptions';
}

/// Única fuente de rutas de la app (ya no se duplican en `routes`).
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // '/' es el AuthGate: muestra login o inicio según la sesión.
    // Cualquier otra ruta es protegida: sin sesión se redirige al login.
    final isLoggedIn = serviceLocator.authRepository.currentUser != null;
    if (settings.name != AppRoutes.home && !isLoggedIn) {
      return _page(const AuthGate(), const RouteSettings(name: AppRoutes.home));
    }

    final args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.home:
        return _page(const AuthGate(), settings);
      case AppRoutes.list:
        return _page(const PetListScreen(), settings);
      case AppRoutes.register:
        return _page(const RegisterPetScreen(), settings);
      case AppRoutes.detail:
        if (args is String) return _page(PetDetailScreen(petId: args), settings);
        return _invalidArguments(settings);
      case AppRoutes.edit:
        if (args is Pet) return _page(EditPetScreen(pet: args), settings);
        return _invalidArguments(settings);
      case AppRoutes.adoptions:
        return _page(const AdoptionsScreen(), settings);
      default:
        return _page(const AuthGate(), const RouteSettings(name: AppRoutes.home));
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => child, settings: settings);

  static MaterialPageRoute<dynamic> _invalidArguments(RouteSettings settings) {
    return _page(
      Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se pudo abrir la pantalla: faltan datos.')),
      ),
      settings,
    );
  }
}
