import 'package:refugio_huellitas/data/datasources/pet_remote_data_source.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/domain/repositories/pet_repository.dart';

class PetRepositoryImpl implements PetRepository {
  final PetRemoteDataSource _remoteDataSource;

  PetRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Pet>> getAllPets() => _remoteDataSource.getAllPets();

  @override
  Future<List<Pet>> getAvailablePets() =>
      _remoteDataSource.getPetsByStatus(AdoptionStatus.available);

  @override
  Future<Pet> addPet(Pet pet) => _remoteDataSource.insertPet(pet);

  @override
  Future<void> removePet(String petId) => _remoteDataSource.deletePet(petId);

  @override
  Future<Pet?> getPetById(String petId) => _remoteDataSource.getPetById(petId);

  @override
  Future<Pet> updatePet(Pet pet) => _remoteDataSource.updatePet(pet);

  @override
  Stream<List<Pet>> watchPets() => _remoteDataSource.watchPets();

  @override
  Future<int> countByStatus(AdoptionStatus status) => _remoteDataSource.countByStatus(status);
}
