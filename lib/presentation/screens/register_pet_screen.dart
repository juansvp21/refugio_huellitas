import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/domain/repositories/pet_repository.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_form.dart';
import 'package:refugio_huellitas/service_locator.dart';

class RegisterPetScreen extends StatelessWidget {
  const RegisterPetScreen({super.key});

  PetRepository get _petRepository => serviceLocator.petRepository;

  /// INSERT en Supabase. Solo se muestra éxito (y se limpia el formulario)
  /// si la base de datos confirmó el registro.
  Future<bool> _savePet(BuildContext context, Pet pet) async {
    try {
      final saved = await _petRepository.addPet(pet);
      if (context.mounted) {
        AppSnackBar.success(context, '¡${saved.name} ha sido registrado exitosamente!');
      }
      return true;
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Mascota'),
        centerTitle: true,
        elevation: 0,
      ),
      body: PetForm(
        header: _buildHeaderCard(theme),
        submitText: 'Registrar Mascota',
        loadingText: 'Registrando...',
        resetOnSuccess: true,
        onSubmit: (pet) => _savePet(context, pet),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Mascota',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completa la información para registrar una mascota en adopción',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
