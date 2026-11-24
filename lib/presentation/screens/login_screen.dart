import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/domain/repositories/auth_repository.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_button.dart';
import 'package:refugio_huellitas/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicio de sesión y creación de cuenta (correo + contraseña) con Supabase Auth.
/// No navega por sí misma: cuando hay sesión, el [AuthGate] muestra el inicio.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = serviceLocator.authRepository;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(value.trim())) return 'Ingresa un correo válido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final hasSession = await _authRepository.signUp(email: email, password: password);
        if (!hasSession && mounted) {
          // El proyecto exige confirmar el correo antes de iniciar sesión.
          AppSnackBar.success(
            context,
            'Cuenta creada. Revisa tu correo para confirmarla y luego inicia sesión.',
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await _authRepository.signIn(email: email, password: password);
      }
      // Si hay sesión, AuthGate reemplaza esta pantalla por el inicio.
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = ErrorMapper.toMessage(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = ErrorMapper.toMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primaryContainer.withValues(alpha: 0.3), colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.pets, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Huellitas',
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Crea tu cuenta del refugio' : 'Inicia sesión para continuar',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              validator: _validateEmail,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              enabled: !_isLoading,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: colorScheme.onErrorContainer),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            CustomButton(
                              text: _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
                              icon: Icon(_isSignUp ? Icons.person_add_alt : Icons.login, size: 22),
                              onPressed: _submit,
                              isLoading: _isLoading,
                              width: double.infinity,
                              height: 54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = null;
                            }),
                    child: Text(_isSignUp
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
