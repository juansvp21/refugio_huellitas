import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_form.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Edición de una mascota: reutiliza [PetForm] precargado y hace UPDATE en Supabase.
/// Devuelve `true` al detalle cuando el cambio se guardó.
class EditPetScreen extends StatelessWidget {
  final Pet pet;

  const EditPetScreen({super.key, required this.pet});

  Future<bool> _save(BuildContext context, Pet edited) async {
    try {
      final saved = await serviceLocator.petRepository.updatePet(edited);
      if (context.mounted) {
        AppSnackBar.success(context, 'Los cambios de ${saved.name} se guardaron correctamente');
        Navigator.pop(context, true);
      }
      return true;
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar a ${pet.name}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: PetForm(
        initialPet: pet,
        submitText: 'Guardar Cambios',
        loadingText: 'Guardando...',
        showResetButton: false,
        onSubmit: (edited) => _save(context, edited),
      ),
    );
  }
}
