import 'package:refugio_huellitas/data/datasources/adopter_remote_data_source.dart';
import 'package:refugio_huellitas/data/datasources/adoption_request_remote_data_source.dart';
import 'package:refugio_huellitas/data/datasources/pet_remote_data_source.dart';
import 'package:refugio_huellitas/data/repositories/adopter_repository_impl.dart';
import 'package:refugio_huellitas/data/repositories/adoption_request_repository_impl.dart';
import 'package:refugio_huellitas/data/repositories/auth_repository_impl.dart';
import 'package:refugio_huellitas/data/repositories/pet_repository_impl.dart';
import 'package:refugio_huellitas/domain/repositories/adopter_repository.dart';
import 'package:refugio_huellitas/domain/repositories/adoption_request_repository.dart';
import 'package:refugio_huellitas/domain/repositories/auth_repository.dart';
import 'package:refugio_huellitas/domain/repositories/pet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AuthRepository _authRepository;
  late final PetRepository _petRepository;
  late final AdopterRepository _adopterRepository;
  late final AdoptionRequestRepository _adoptionRequestRepository;

  /// Se llama después de `Supabase.initialize()` en main.dart.
  void initialize(SupabaseClient client) {
    _authRepository = AuthRepositoryImpl(client.auth);
    _petRepository = PetRepositoryImpl(PetRemoteDataSource(client));
    _adopterRepository = AdopterRepositoryImpl(AdopterRemoteDataSource(client));
    _adoptionRequestRepository =
        AdoptionRequestRepositoryImpl(AdoptionRequestRemoteDataSource(client));
  }

  AuthRepository get authRepository => _authRepository;
  PetRepository get petRepository => _petRepository;
  AdopterRepository get adopterRepository => _adopterRepository;
  AdoptionRequestRepository get adoptionRequestRepository => _adoptionRequestRepository;
}

final serviceLocator = ServiceLocator();
