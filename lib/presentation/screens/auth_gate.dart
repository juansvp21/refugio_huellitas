import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refugio_huellitas/presentation/screens/home_screen.dart';
import 'package:refugio_huellitas/presentation/screens/login_screen.dart';
import 'package:refugio_huellitas/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Decide qué mostrar según la sesión: sin sesión → [LoginScreen],
/// con sesión → [HomeScreen]. Escucha `onAuthStateChange`, así que reacciona
/// al iniciar sesión, al cerrarla y cuando la sesión expira.
/// supabase_flutter guarda la sesión, por eso al reabrir la app se entra directo.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = serviceLocator.authRepository;
  late final StreamSubscription<AuthState> _subscription;
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _authRepository.currentUser != null;
    _subscription = _authRepository.authStateChanges.listen((state) {
      if (!mounted) return;
      final loggedIn = state.session != null;
      if (state.event == AuthChangeEvent.signedOut) {
        // Cierra cualquier pantalla abierta encima (detalle, edición...) para
        // que no quede una ruta protegida visible sin sesión.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      if (loggedIn != _isLoggedIn) setState(() => _isLoggedIn = loggedIn);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
