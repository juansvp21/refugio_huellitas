enum RequestStatus {
  pending('pendiente'),
  approved('aprobada'),
  rejected('rechazada');

  /// Valor guardado en la columna `estado` de `solicitudes_adopcion`.
  final String dbValue;
  const RequestStatus(this.dbValue);

  static RequestStatus fromDb(String value) =>
      RequestStatus.values.firstWhere((s) => s.dbValue == value, orElse: () => RequestStatus.pending);

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pendiente';
      case RequestStatus.approved:
        return 'Aprobada';
      case RequestStatus.rejected:
        return 'Rechazada';
    }
  }
}

/// Solicitud de adopción (tabla `solicitudes_adopcion`).
///
/// [petName] y [adopterName] no son columnas: vienen del join que hace el
/// datasource (`mascotas(nombre)`, `adoptantes(nombre_completo)`) para mostrar
/// nombres en la UI en vez de uuids.
class AdoptionRequest {
  final String id;
  final String petId;
  final String adopterId;
  final DateTime requestDate;
  final RequestStatus status;
  final String? notes;
  final String? petName;
  final String? adopterName;

  AdoptionRequest({
    this.id = '',
    required this.petId,
    required this.adopterId,
    DateTime? requestDate,
    this.status = RequestStatus.pending,
    this.notes,
    this.petName,
    this.adopterName,
  }) : requestDate = requestDate ?? DateTime.now();

  factory AdoptionRequest.fromMap(Map<String, dynamic> map) {
    final pet = map['mascotas'] as Map<String, dynamic>?;
    final adopter = map['adoptantes'] as Map<String, dynamic>?;
    return AdoptionRequest(
      id: map['id'] as String,
      petId: map['mascota_id'] as String,
      adopterId: map['adoptante_id'] as String,
      requestDate: DateTime.parse(map['fecha_solicitud'] as String).toLocal(),
      status: RequestStatus.fromDb(map['estado'] as String),
      notes: map['observaciones'] as String?,
      petName: pet?['nombre'] as String?,
      adopterName: adopter?['nombre_completo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mascota_id': petId,
      'adoptante_id': adopterId,
      'fecha_solicitud': requestDate.toUtc().toIso8601String(),
      'estado': status.dbValue,
      'observaciones': notes,
    };
  }
}
