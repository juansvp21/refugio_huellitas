import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/domain/repositories/pet_repository.dart';
import 'package:refugio_huellitas/presentation/app_router.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/confirm_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_button.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_pet_card.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Listado de mascotas leído de Supabase.
///
/// Sincronización BD → App:
///  * Realtime: nos suscribimos a `watchPets()` (`.stream(primaryKey: ['id'])`),
///    así un cambio hecho desde el panel de Supabase aparece solo.
///  * Pull-to-refresh y botón de recargar: vuelven a consultar con un SELECT y
///    rehacen la suscripción (útil si Realtime se cortó o no está activado).
class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final PetRepository _petRepository = serviceLocator.petRepository;
  StreamSubscription<List<Pet>>? _subscription;
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _petRepository.watchPets().listen(
      (pets) {
        if (!mounted) return;
        setState(() {
          _pets = pets;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        // Si ya teníamos datos, no tapamos la lista: solo avisamos.
        if (_pets.isNotEmpty) {
          AppSnackBar.warning(context, 'Se perdió la actualización en tiempo real. Desliza para recargar.');
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _errorMessage = ErrorMapper.toMessage(e);
            _isLoading = false;
          });
        }
      },
    );
  }

  /// SELECT explícito a Supabase (pull-to-refresh / botón recargar).
  Future<void> _loadPets() async {
    if (_pets.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final pets = await _petRepository.getAllPets();
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _isLoading = false;
        _errorMessage = null;
      });
      _subscribe();
    } catch (e) {
      if (!mounted) return;
      if (_pets.isEmpty) {
        setState(() {
          _errorMessage = ErrorMapper.toMessage(e);
          _isLoading = false;
        });
      } else {
        AppSnackBar.error(context, e);
      }
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar mascota',
      message: '¿Estás seguro de que deseas eliminar a "${pet.name}"?',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      // DELETE en Supabase: la lista se actualiza solo si salió bien.
      await _petRepository.removePet(pet.id);
      if (!mounted) return;
      setState(() => _pets.removeWhere((p) => p.id == pet.id));
      AppSnackBar.warning(context, '${pet.name} ha sido eliminado');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    }
  }

  Future<void> _openDetail(Pet pet) async {
    await Navigator.pushNamed(context, AppRoutes.detail, arguments: pet.id);
    // Al volver se consulta de nuevo (por si se editó o eliminó en el detalle).
    if (mounted) _loadPets();
  }

  Future<void> _openRegister() async {
    await Navigator.pushNamed(context, AppRoutes.register);
    if (mounted) _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas Registradas'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPets,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegister,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando mascotas...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadPets,
      child: _pets.isEmpty
          // Un ListView para que el pull-to-refresh funcione también sin datos.
          ? ListView(children: [_buildEmptyState()])
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return CustomPetCard(
                  pet: pet,
                  showDeleteButton: true,
                  onTap: () => _openDetail(pet),
                  onDelete: () => _deletePet(pet),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.pets_outlined, size: 60, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay mascotas registradas',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Comienza registrando tu primera mascota para que pueda encontrar un hogar lleno de amor.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Registrar Primera Mascota',
            icon: const Icon(Icons.add_circle_outline, size: 24),
            onPressed: _openRegister,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Reintentar',
              icon: const Icon(Icons.refresh),
              onPressed: _loadPets,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
