import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a la tabla `solicitudes_adopcion` de Supabase (filtrado por RLS).
class AdoptionRequestRemoteDataSource {
  static const _table = 'solicitudes_adopcion';

  /// Join con las tablas relacionadas para traer los nombres en la misma consulta.
  static const _selectWithNames = '*, mascotas(nombre), adoptantes(nombre_completo)';

  final SupabaseClient _client;
  AdoptionRequestRemoteDataSource(this._client);

  Future<List<AdoptionRequest>> getAllRequests() async {
    final rows = await _client
        .from(_table)
        .select(_selectWithNames)
        .order('fecha_solicitud', ascending: false);
    return rows.map(AdoptionRequest.fromMap).toList();
  }

  Future<AdoptionRequest> insertRequest(AdoptionRequest request) async {
    final row =
        await _client.from(_table).insert(request.toMap()).select(_selectWithNames).single();
    return AdoptionRequest.fromMap(row);
  }

  Future<AdoptionRequest> updateStatus(String id, RequestStatus status) async {
    final row = await _client
        .from(_table)
        .update({'estado': status.dbValue})
        .eq('id', id)
        .select(_selectWithNames)
        .single();
    return AdoptionRequest.fromMap(row);
  }

  Future<void> deleteRequest(String id) async {
    final deleted = await _client.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw const PostgrestException(message: 'Registro no encontrado', code: 'PGRST116');
    }
  }

  Future<int> countByStatus(RequestStatus status) {
    return _client.from(_table).count(CountOption.exact).eq('estado', status.dbValue);
  }
}
