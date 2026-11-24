import 'package:refugio_huellitas/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Autenticación con correo y contraseña usando Supabase Auth.
/// supabase_flutter guarda la sesión en el dispositivo, así que persiste
/// al cerrar y reabrir la app.
class AuthRepositoryImpl implements AuthRepository {
  final GoTrueClient _auth;

  AuthRepositoryImpl(this._auth);

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _auth.signUp(email: email, password: password);
    return response.session != null;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
