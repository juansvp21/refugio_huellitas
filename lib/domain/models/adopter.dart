/// Persona interesada en adoptar (tabla `adoptantes`).
class Adopter {
  final String id;
  final String fullName;
  final String document;
  final String phone;
  final String email;
  final String address;
  final DateTime registrationDate;

  Adopter({
    this.id = '',
    required this.fullName,
    required this.document,
    required this.phone,
    required this.email,
    required this.address,
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();

  factory Adopter.fromMap(Map<String, dynamic> map) {
    return Adopter(
      id: map['id'] as String,
      fullName: map['nombre_completo'] as String,
      document: map['documento'] as String,
      phone: map['telefono'] as String,
      email: map['correo'] as String,
      address: map['direccion'] as String,
      registrationDate: DateTime.parse(map['fecha_registro'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_completo': fullName,
      'documento': document,
      'telefono': phone,
      'correo': email,
      'direccion': address,
      'fecha_registro': registrationDate.toUtc().toIso8601String(),
    };
  }

  Adopter copyWith({
    String? id,
    String? fullName,
    String? document,
    String? phone,
    String? email,
    String? address,
    DateTime? registrationDate,
  }) {
    return Adopter(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  @override
  bool operator ==(Object other) => other is Adopter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
