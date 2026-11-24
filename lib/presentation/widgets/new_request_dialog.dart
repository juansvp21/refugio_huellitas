import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/domain/models/adopter.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Diálogo para crear una solicitud de adopción eligiendo una mascota
/// disponible y un adoptante. Devuelve true si el INSERT salió bien.
class NewRequestDialog extends StatefulWidget {
  const NewRequestDialog({super.key});

  @override
  State<NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<NewRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  List<Pet> _pets = [];
  List<Adopter> _adopters = [];
  String? _selectedPetId;
  String? _selectedAdopterId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      // Solo mascotas con estado_adopcion = 'disponible'.
      final results = await Future.wait([
        serviceLocator.petRepository.getAvailablePets(),
        serviceLocator.adopterRepository.getAllAdopters(),
      ]);
      if (!mounted) return;
      setState(() {
        _pets = results[0] as List<Pet>;
        _adopters = results[1] as List<Adopter>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.toMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final notes = _notesController.text.trim();
    try {
      await serviceLocator.adoptionRequestRepository.addRequest(AdoptionRequest(
        petId: _selectedPetId!,
        adopterId: _selectedAdopterId!,
        notes: notes.isEmpty ? null : notes,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = ErrorMapper.toMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva solicitud'),
      content: SizedBox(width: 420, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading || _isSaving || _pets.isEmpty || _adopters.isEmpty ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    if (_pets.isEmpty || _adopters.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null)
            Text(_errorMessage!, style: TextStyle(color: colorScheme.error))
          else ...[
            if (_pets.isEmpty) const Text('No hay mascotas disponibles para adopción.'),
            if (_adopters.isEmpty) const Text('Primero registra un adoptante en la pestaña Adoptantes.'),
          ],
        ],
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedPetId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Mascota disponible',
                prefixIcon: Icon(Icons.pets_outlined),
              ),
              items: _pets
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${p.typeDisplayName})', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPetId = v),
              validator: (v) => v == null ? 'Elige una mascota' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedAdopterId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Adoptante',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _adopters
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.fullName} · ${a.document}', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAdopterId = v),
              validator: (v) => v == null ? 'Elige un adoptante' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
