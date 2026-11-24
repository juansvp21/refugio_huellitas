import 'package:refugio_huellitas/domain/models/pet.dart';

abstract class PetRepository {
  Future<List<Pet>> getAllPets();
  Future<List<Pet>> getAvailablePets();

  /// Devuelve la mascota creada, con el id generado por la base de datos.
  Future<Pet> addPet(Pet pet);
  Future<void> removePet(String petId);
  Future<Pet?> getPetById(String petId);
  Future<Pet> updatePet(Pet pet);

  /// Lista en tiempo real (Supabase Realtime): emite cada vez que cambia la tabla.
  Stream<List<Pet>> watchPets();
  Future<int> countByStatus(AdoptionStatus status);
}
