import 'package:refugio_huellitas/data/datasources/adopter_remote_data_source.dart';
import 'package:refugio_huellitas/domain/models/adopter.dart';
import 'package:refugio_huellitas/domain/repositories/adopter_repository.dart';

class AdopterRepositoryImpl implements AdopterRepository {
  final AdopterRemoteDataSource _remoteDataSource;

  AdopterRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Adopter>> getAllAdopters() => _remoteDataSource.getAllAdopters();

  @override
  Future<Adopter> addAdopter(Adopter adopter) => _remoteDataSource.insertAdopter(adopter);

  @override
  Future<Adopter> updateAdopter(Adopter adopter) => _remoteDataSource.updateAdopter(adopter);

  @override
  Future<void> removeAdopter(String adopterId) => _remoteDataSource.deleteAdopter(adopterId);
}
