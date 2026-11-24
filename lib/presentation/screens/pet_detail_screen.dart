import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/core/formatters.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/domain/repositories/pet_repository.dart';
import 'package:refugio_huellitas/presentation/app_router.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/confirm_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_button.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_visuals.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Detalle de una mascota. Recibe el id por `onGenerateRoute` y consulta la
/// fila actual en Supabase (así siempre muestra los datos más recientes).
class PetDetailScreen extends StatefulWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final PetRepository _petRepository = serviceLocator.petRepository;
  Pet? _pet;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    setState(() {
      _isLoading = _pet == null;
      _errorMessage = null;
    });
    try {
      final pet = await _petRepository.getPetById(widget.petId);
      if (!mounted) return;
      setState(() {
        _pet = pet;
        _isLoading = false;
        if (pet == null) _errorMessage = 'Esta mascota ya no existe o fue eliminada.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.toMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.edit, arguments: _pet);
    if (updated == true && mounted) _loadPet();
  }

  Future<void> _delete() async {
    final pet = _pet;
    if (pet == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar mascota',
      message: '¿Estás seguro de que deseas eliminar a "${pet.name}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _petRepository.removePet(pet.id);
      if (!mounted) return;
      AppSnackBar.warning(context, '${pet.name} ha sido eliminado');
      Navigator.pop(context, true);
    } catch (e) {
      // Ej.: tiene solicitudes de adopción (ON DELETE RESTRICT → error 23503).
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackBar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet?.name ?? 'Detalle'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadPet, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final pet = _pet;
    if (pet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 72, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Error desconocido', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Reintentar',
                icon: const Icon(Icons.refresh),
                onPressed: _loadPet,
                width: double.infinity,
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = petTypeColor(pet.type);

    return RefreshIndicator(
      onRefresh: _loadPet,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(petTypeIcon(pet.type), color: typeColor, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${pet.typeDisplayName} • ${pet.breed}',
                      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: pet.adoptionStatus.displayName,
                      color: adoptionStatusColor(pet.adoptionStatus),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailSection(theme, 'Información General', [
            _buildDetailRow('Edad', '${pet.age} ${pet.age == 1 ? 'año' : 'años'}'),
            _buildDetailRow('Tipo', pet.typeDisplayName),
            _buildDetailRow('Raza', pet.breed),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection(theme, 'Estado de Salud', [
            _buildDetailRow(
              'Vacunación',
              pet.vaccinationStatusDisplayName,
              valueColor: vaccinationColor(colorScheme, pet.vaccinationStatus),
            ),
          ]),
          if (pet.description != null && pet.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailSection(theme, 'Descripción', [
              _buildDetailRow('', pet.description!, isFullWidth: true),
            ]),
          ],
          const SizedBox(height: 16),
          _buildDetailSection(theme, 'Registro', [
            _buildDetailRow('Fecha de registro', formatDate(pet.registrationDate)),
            _buildDetailRow(
              'Adopción',
              pet.adoptionStatus.displayName,
              valueColor: adoptionStatusColor(pet.adoptionStatus),
            ),
          ]),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _isDeleting ? null : _edit,
            width: double.infinity,
          ),
          const SizedBox(height: 12),
          CustomOutlineButton(
            text: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
            isLoading: _isDeleting,
            borderColor: colorScheme.error,
            foregroundColor: colorScheme.error,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isFullWidth = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isFullWidth
          ? Text(value, style: TextStyle(fontSize: 16, color: valueColor, height: 1.5))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 16, color: valueColor ?? colorScheme.onSurface),
                  ),
                ),
              ],
            ),
    );
  }
}
