import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/app_router.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/confirm_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_button.dart';
import 'package:refugio_huellitas/service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = serviceLocator.authRepository;
  int? _availablePets;
  int? _pendingRequests;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  /// Contadores consultados a Supabase (COUNT exacto, filtrado por RLS).
  Future<void> _loadCounters() async {
    try {
      final results = await Future.wait([
        serviceLocator.petRepository.countByStatus(AdoptionStatus.available),
        serviceLocator.adoptionRequestRepository.countByStatus(RequestStatus.pending),
      ]);
      if (!mounted) return;
      setState(() {
        _availablePets = results[0];
        _pendingRequests = results[1];
      });
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    }
  }

  /// Abre una pantalla y, al volver, refresca los contadores.
  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) _loadCounters();
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Cerrar sesión',
    );
    if (!confirmed) return;
    try {
      // AuthGate escucha el evento signedOut y muestra el login.
      await _authRepository.signOut();
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huellitas'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadCounters,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildLogoSection(theme),
                  const SizedBox(height: 32),
                  _buildWelcomeSection(theme),
                  const SizedBox(height: 16),
                  _buildCounters(theme),
                  const SizedBox(height: 32),
                  _buildNavigationButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.pets, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Huellitas',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Plataforma comunitaria de adopción de mascotas',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    final email = _authRepository.currentUser?.email ?? '';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.favorite_outline, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido a Huellitas!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Conecta con mascotas que buscan un hogar lleno de amor. Registra nuevas mascotas, consulta las que ya están esperando y gestiona sus adopciones.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounters(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _CounterCard(
            icon: Icons.pets,
            color: Colors.green,
            value: _availablePets,
            label: 'Mascotas disponibles',
          ),
        ),
        Expanded(
          child: _CounterCard(
            icon: Icons.assignment_outlined,
            color: Colors.orange,
            value: _pendingRequests,
            label: 'Solicitudes pendientes',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CustomButton(
          text: 'Registrar Mascota',
          icon: const Icon(Icons.add_circle_outline, size: 24),
          onPressed: () => _open(AppRoutes.register),
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Consultar Mascotas',
          icon: const Icon(Icons.list_alt_outlined, size: 24),
          onPressed: () => _open(AppRoutes.list),
          width: double.infinity,
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
        const SizedBox(height: 16),
        CustomOutlineButton(
          text: 'Gestión de Adopciones',
          icon: const Icon(Icons.volunteer_activism_outlined, size: 24),
          onPressed: () => _open(AppRoutes.adoptions),
          width: double.infinity,
        ),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? value;
  final String label;

  const _CounterCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value?.toString() ?? '—',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
