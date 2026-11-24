import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/widgets/custom_button.dart';

/// Formulario de mascota compartido por Registro y Edición.
///
/// La pantalla que lo usa decide qué hacer con la mascota en [onSubmit]
/// (insert o update en Supabase) y devuelve true si se guardó bien.
class PetForm extends StatefulWidget {
  final Pet? initialPet;
  final String submitText;
  final String loadingText;
  final Future<bool> Function(Pet pet) onSubmit;
  final bool resetOnSuccess;
  final bool showResetButton;
  final Widget? header;

  const PetForm({
    super.key,
    this.initialPet,
    required this.submitText,
    required this.loadingText,
    required this.onSubmit,
    this.resetOnSuccess = false,
    this.showResetButton = true,
    this.header,
  });

  @override
  State<PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<PetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _breedController;
  late final TextEditingController _descriptionController;

  late PetType _selectedType;
  late VaccinationStatus _selectedVaccinationStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Precarga los valores si estamos editando.
    final pet = widget.initialPet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _ageController = TextEditingController(text: pet?.age.toString() ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _descriptionController = TextEditingController(text: pet?.description ?? '');
    _selectedType = pet?.type ?? PetType.dog;
    _selectedVaccinationStatus = pet?.vaccinationStatus ?? VaccinationStatus.notVaccinated;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La edad es obligatoria';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Ingrese un número válido';
    }
    if (age < 0) {
      return 'La edad no puede ser negativa';
    }
    if (age > 30) {
      return 'Edad máxima permitida: 30 años';
    }
    return null;
  }

  String? _validateBreed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La raza es obligatoria';
    }
    if (value.trim().length < 2) {
      return 'La raza debe tener al menos 2 caracteres';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final initial = widget.initialPet;
    final description = _descriptionController.text.trim();
    // Al editar se conservan id, fecha de registro y estado de adopción.
    final pet = Pet(
      id: initial?.id ?? '',
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      type: _selectedType,
      breed: _breedController.text.trim(),
      vaccinationStatus: _selectedVaccinationStatus,
      description: description.isEmpty ? null : description,
      registrationDate: initial?.registrationDate,
      adoptionStatus: initial?.adoptionStatus ?? AdoptionStatus.available,
    );

    final saved = await widget.onSubmit(pet);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (saved && widget.resetOnSuccess) _resetForm();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _breedController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = PetType.dog;
      _selectedVaccinationStatus = VaccinationStatus.notVaccinated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: 24),
            ],
            _buildBasicInfoSection(theme),
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(theme),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la mascota',
                hintText: 'Ej: Luna, Max, Rocky...',
                prefixIcon: const Icon(Icons.pets_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              validator: _validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Edad (años)',
                hintText: 'Ej: 2',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              validator: _validateAge,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PetType>(
              // key con el valor: así el reset del formulario refleja el tipo actual.
              key: ValueKey(_selectedType),
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo de mascota',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: PetType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.displayName));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedController,
              decoration: InputDecoration(
                labelText: 'Raza',
                hintText: 'Ej: Labrador, Siamés, Canario...',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              validator: _validateBreed,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Estado de Vacunación',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<VaccinationStatus>(
              groupValue: _selectedVaccinationStatus,
              onChanged: (value) {
                if (value != null) setState(() => _selectedVaccinationStatus = value);
              },
              child: Column(
                children: VaccinationStatus.values.map((status) {
                  return RadioListTile<VaccinationStatus>(
                    title: Text(_getVaccinationLabel(status)),
                    subtitle: Text(_getVaccinationDescription(status)),
                    value: status,
                    activeColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Características, personalidad, cuidados especiales...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  String _getVaccinationLabel(VaccinationStatus status) {
    switch (status) {
      case VaccinationStatus.vaccinated:
        return 'Completamente vacunado';
      case VaccinationStatus.partiallyVaccinated:
        return 'Parcialmente vacunado';
      case VaccinationStatus.notVaccinated:
        return 'No vacunado';
    }
  }

  String _getVaccinationDescription(VaccinationStatus status) {
    switch (status) {
      case VaccinationStatus.vaccinated:
        return 'Todas las vacunas al día';
      case VaccinationStatus.partiallyVaccinated:
        return 'Algunas vacunas pendientes';
      case VaccinationStatus.notVaccinated:
        return 'Sin vacunas aplicadas';
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: _isLoading ? widget.loadingText : widget.submitText,
          icon: _isLoading ? null : const Icon(Icons.save_outlined, size: 24),
          onPressed: _isLoading ? null : _submitForm,
          isLoading: _isLoading,
          width: double.infinity,
          height: 56,
        ),
        if (widget.showResetButton) ...[
          const SizedBox(height: 12),
          CustomOutlineButton(
            text: 'Limpiar Formulario',
            icon: const Icon(Icons.clear_all_outlined, size: 24),
            onPressed: _isLoading ? null : _resetForm,
            width: double.infinity,
            height: 56,
          ),
        ],
      ],
    );
  }
}
