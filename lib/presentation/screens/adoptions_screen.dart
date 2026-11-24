import 'package:flutter/material.dart';
import 'package:refugio_huellitas/core/error_mapper.dart';
import 'package:refugio_huellitas/core/formatters.dart';
import 'package:refugio_huellitas/domain/models/adopter.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/presentation/widgets/adopter_form_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/app_snackbar.dart';
import 'package:refugio_huellitas/presentation/widgets/confirm_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/new_request_dialog.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_visuals.dart';
import 'package:refugio_huellitas/service_locator.dart';

/// Gestión de adopciones: pestaña de Adoptantes (CRUD) y pestaña de
/// Solicitudes (crear, aprobar, rechazar, eliminar).
/// Al cambiar de pestaña se vuelve a consultar Supabase.
class AdoptionsScreen extends StatelessWidget {
  const AdoptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Adopciones'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Adoptantes'),
              Tab(icon: Icon(Icons.assignment_outlined), text: 'Solicitudes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AdoptersTab(), _RequestsTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña Adoptantes
// ---------------------------------------------------------------------------

class _AdoptersTab extends StatefulWidget {
  const _AdoptersTab();

  @override
  State<_AdoptersTab> createState() => _AdoptersTabState();
}

class _AdoptersTabState extends State<_AdoptersTab> {
  final _repository = serviceLocator.adopterRepository;
  List<Adopter> _adopters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final adopters = await _repository.getAllAdopters();
      if (!mounted) return;
      setState(() {
        _adopters = adopters;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMapper.toMessage(e);
      });
    }
  }

  Future<void> _openForm([Adopter? adopter]) async {
    final saved = await showDialog<Adopter>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdopterFormDialog(initialAdopter: adopter),
    );
    if (saved == null || !mounted) return;
    AppSnackBar.success(
      context,
      adopter == null ? '${saved.fullName} fue registrado' : 'Datos de ${saved.fullName} actualizados',
    );
    _load();
  }

  Future<void> _delete(Adopter adopter) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar adoptante',
      message: '¿Deseas eliminar a "${adopter.fullName}"?',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _repository.removeAdopter(adopter.id);
      if (!mounted) return;
      setState(() => _adopters.removeWhere((a) => a.id == adopter.id));
      AppSnackBar.warning(context, '${adopter.fullName} fue eliminado');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_adopters',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Adoptante'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _errorMessage != null
          ? _MessageList(icon: Icons.error_outline, message: _errorMessage!, isError: true)
          : _adopters.isEmpty
              ? const _MessageList(
                  icon: Icons.people_outline,
                  message: 'Aún no hay adoptantes registrados.\nToca "Adoptante" para agregar uno.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: _adopters.length,
                  itemBuilder: (context, index) {
                    final a = _adopters[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _openForm(a),
                        leading: CircleAvatar(
                          child: Text(a.fullName.isNotEmpty ? a.fullName[0].toUpperCase() : '?'),
                        ),
                        title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Doc. ${a.document}\n${a.phone} · ${a.email}\n${a.address}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          tooltip: 'Eliminar adoptante',
                          onPressed: () => _delete(a),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña Solicitudes
// ---------------------------------------------------------------------------

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _repository = serviceLocator.adoptionRequestRepository;
  List<AdoptionRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final requests = await _repository.getAllRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMapper.toMessage(e);
      });
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NewRequestDialog(),
    );
    if (created == true && mounted) {
      AppSnackBar.success(context, 'Solicitud creada. La mascota quedó "En proceso".');
      _load();
    }
  }

  /// UPDATE del estado. El trigger de la BD actualiza el estado de la mascota.
  Future<void> _changeStatus(AdoptionRequest request, RequestStatus status) async {
    final approving = status == RequestStatus.approved;
    final petName = request.petName ?? 'la mascota';
    final confirmed = await showConfirmDialog(
      context,
      title: approving ? 'Aprobar solicitud' : 'Rechazar solicitud',
      message: approving
          ? 'Al aprobar, $petName quedará como adoptada por ${request.adopterName ?? 'el adoptante'}.'
          : '¿Deseas rechazar la solicitud de ${request.adopterName ?? 'este adoptante'} para $petName?',
      confirmText: approving ? 'Aprobar' : 'Rechazar',
      destructive: !approving,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyIds.add(request.id));
    try {
      await _repository.updateStatus(request.id, status);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        approving ? '¡$petName fue adoptada!' : 'Solicitud rechazada',
      );
      await _load();
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _delete(AdoptionRequest request) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar solicitud',
      message: '¿Deseas eliminar la solicitud de ${request.adopterName ?? 'este adoptante'} '
          'para ${request.petName ?? 'la mascota'}?',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyIds.add(request.id));
    try {
      await _repository.removeRequest(request.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      AppSnackBar.warning(context, 'Solicitud eliminada');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_requests',
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Solicitud'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: _errorMessage != null
          ? _MessageList(icon: Icons.error_outline, message: _errorMessage!, isError: true)
          : _requests.isEmpty
              ? const _MessageList(
                  icon: Icons.assignment_outlined,
                  message: 'No hay solicitudes de adopción.\nToca "Solicitud" para crear una.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                ),
    );
  }

  Widget _buildRequestCard(AdoptionRequest r) {
    final theme = Theme.of(context);
    final busy = _busyIds.contains(r.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.petName ?? 'Mascota',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(label: r.status.displayName, color: requestStatusColor(r.status)),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  tooltip: 'Eliminar solicitud',
                  onPressed: busy ? null : () => _delete(r),
                ),
              ],
            ),
            Text('Adoptante: ${r.adopterName ?? '-'}'),
            Text(
              'Fecha: ${formatDate(r.requestDate)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (r.status == RequestStatus.pending) ...[
              const SizedBox(height: 12),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _changeStatus(r, RequestStatus.rejected),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _changeStatus(r, RequestStatus.approved),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensaje centrado dentro de un ListView (para que funcione el pull-to-refresh).
class _MessageList extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;

  const _MessageList({required this.icon, required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(icon, size: 72, color: isError ? colorScheme.error : colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
        if (isError) ...[
          const SizedBox(height: 8),
          Text(
            'Desliza hacia abajo para reintentar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
