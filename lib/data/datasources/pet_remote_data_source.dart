import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a la tabla `mascotas` de Supabase.
///
/// No filtramos por user_id en las consultas: lo hace Row Level Security en
/// el servidor (política `user_id = auth.uid()`), así que cada usuario solo
/// recibe sus filas aunque la consulta pida "todas".
class PetRemoteDataSource {
  static const _table = 'mascotas';

  final SupabaseClient _client;
  PetRemoteDataSource(this._client);

  // SELECT
  Future<List<Pet>> getAllPets() async {
    final rows = await _client.from(_table).select().order('fecha_registro', ascending: false);
    return rows.map(Pet.fromMap).toList();
  }

  Future<List<Pet>> getPetsByStatus(AdoptionStatus status) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('estado_adopcion', status.dbValue)
        .order('nombre');
    return rows.map(Pet.fromMap).toList();
  }

  Future<Pet?> getPetById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : Pet.fromMap(row);
  }

  // INSERT: .select().single() devuelve la fila creada (con id y user_id).
  Future<Pet> insertPet(Pet pet) async {
    final row = await _client.from(_table).insert(pet.toMap()).select().single();
    return Pet.fromMap(row);
  }

  // UPDATE: si RLS oculta la fila o no existe, .single() lanza PGRST116.
  // No enviamos estado_adopcion: ese campo lo controla el trigger de solicitudes.
  Future<Pet> updatePet(Pet pet) async {
    final data = pet.toMap()..remove('estado_adopcion');
    final row = await _client.from(_table).update(data).eq('id', pet.id).select().single();
    return Pet.fromMap(row);
  }

  // DELETE: pedimos las filas borradas para saber si realmente se borró algo.
  Future<void> deletePet(String id) async {
    final deleted = await _client.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw const PostgrestException(message: 'Registro no encontrado', code: 'PGRST116');
    }
  }

  // REALTIME: requiere que la tabla esté en la publicación supabase_realtime.
  // Primero emite la lista actual y luego una nueva lista con cada cambio.
  Stream<List<Pet>> watchPets() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('fecha_registro', ascending: false)
        .map((rows) => rows.map(Pet.fromMap).toList());
  }

  Future<int> countByStatus(AdoptionStatus status) {
    return _client.from(_table).count(CountOption.exact).eq('estado_adopcion', status.dbValue);
  }
}
