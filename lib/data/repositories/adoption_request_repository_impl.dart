import 'package:refugio_huellitas/data/datasources/adoption_request_remote_data_source.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/domain/repositories/adoption_request_repository.dart';

class AdoptionRequestRepositoryImpl implements AdoptionRequestRepository {
  final AdoptionRequestRemoteDataSource _remoteDataSource;

  AdoptionRequestRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AdoptionRequest>> getAllRequests() => _remoteDataSource.getAllRequests();

  @override
  Future<AdoptionRequest> addRequest(AdoptionRequest request) =>
      _remoteDataSource.insertRequest(request);

  @override
  Future<AdoptionRequest> updateStatus(String requestId, RequestStatus status) =>
      _remoteDataSource.updateStatus(requestId, status);

  @override
  Future<void> removeRequest(String requestId) => _remoteDataSource.deleteRequest(requestId);

  @override
  Future<int> countByStatus(RequestStatus status) => _remoteDataSource.countByStatus(status);
}
