import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  /// Devuelve true si la cuenta quedó con sesión iniciada, false si Supabase
  /// exige confirmar el correo antes de entrar.
  Future<bool> signUp({required String email, required String password});
  Future<void> signOut();
  User? get currentUser;
  Stream<AuthState> get authStateChanges;
}
