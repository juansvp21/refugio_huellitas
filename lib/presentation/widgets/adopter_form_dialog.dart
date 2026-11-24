import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/domain/models/adopter.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Diálogo para crear o editar un adoptante. Hace el INSERT/UPDATE en Supabase
/// y solo se cierra (devolviendo el adoptante guardado) si la operación salió bien.
class AdopterFormDialog extends StatefulWidget {
  final Adopter? initialAdopter;

  const AdopterFormDialog({super.key, this.initialAdopter});

  @override
  State<AdopterFormDialog> createState() => _AdopterFormDialogState();
}

class _AdopterFormDialogState extends State<AdopterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _documentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _isSaving = false;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _digitsRegex = RegExp(r'^[0-9]+$');

  bool get _isEditing => widget.initialAdopter != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAdopter;
    _nameController = TextEditingController(text: a?.fullName ?? '');
    _documentController = TextEditingController(text: a?.document ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _emailController = TextEditingController(text: a?.email ?? '');
    _addressController = TextEditingController(text: a?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field, {int min = 1}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    if (value.trim().length < min) return '$field debe tener al menos $min caracteres';
    return null;
  }

  String? _validateDigits(String? value, String field, {required int min, required int max}) {
    final base = _required(value, field);
    if (base != null) return base;
    final v = value!.trim();
    if (!_digitsRegex.hasMatch(v)) return 'Solo se permiten números';
    if (v.length < min || v.length > max) return '$field debe tener entre $min y $max dígitos';
    return null;
  }

  String? _validateEmail(String? value) {
    final base = _required(value, 'El correo');
    if (base != null) return base;
    if (!_emailRegex.hasMatch(value!.trim())) return 'Ingresa un correo válido';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repo = serviceLocator.adopterRepository;
    final adopter = Adopter(
      id: widget.initialAdopter?.id ?? '',
      fullName: _nameController.text.trim(),
      document: _documentController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      registrationDate: widget.initialAdopter?.registrationDate,
    );

    try {
      final saved = _isEditing ? await repo.updateAdopter(adopter) : await repo.addAdopter(adopter);
      if (mounted) Navigator.pop(context, saved);
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? 'Editar adoptante' : 'Nuevo adoptante'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _required(v, 'El nombre', min: 3),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentController,
                  decoration: const InputDecoration(
                    labelText: 'Documento',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => _validateDigits(v, 'El documento', min: 5, max: 15),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => _validateDigits(v, 'El teléfono', min: 7, max: 15),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (v) => _required(v, 'La dirección', min: 5),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
