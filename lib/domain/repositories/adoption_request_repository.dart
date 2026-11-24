import 'package:refugio_huellitas/domain/models/adoption_request.dart';

abstract class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> getAllRequests();
  Future<AdoptionRequest> addRequest(AdoptionRequest request);

  /// Aprobar o rechazar. El cambio de estado de la mascota lo hace el trigger
  /// `solicitud_actualiza_mascota` en la base de datos.
  Future<AdoptionRequest> updateStatus(String requestId, RequestStatus status);
  Future<void> removeRequest(String requestId);
  Future<int> countByStatus(RequestStatus status);
}
