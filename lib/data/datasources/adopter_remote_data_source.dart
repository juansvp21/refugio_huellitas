import 'package:refugio_huellitas/domain/models/adopter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a la tabla `adoptantes` de Supabase (filtrado por RLS).
class AdopterRemoteDataSource {
  static const _table = 'adoptantes';

  final SupabaseClient _client;
  AdopterRemoteDataSource(this._client);

  Future<List<Adopter>> getAllAdopters() async {
    final rows = await _client.from(_table).select().order('nombre_completo');
    return rows.map(Adopter.fromMap).toList();
  }

  Future<Adopter> insertAdopter(Adopter adopter) async {
    final row = await _client.from(_table).insert(adopter.toMap()).select().single();
    return Adopter.fromMap(row);
  }

  Future<Adopter> updateAdopter(Adopter adopter) async {
    final row =
        await _client.from(_table).update(adopter.toMap()).eq('id', adopter.id).select().single();
    return Adopter.fromMap(row);
  }

  Future<void> deleteAdopter(String id) async {
    final deleted = await _client.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw const PostgrestException(message: 'Registro no encontrado', code: 'PGRST116');
    }
  }
}
