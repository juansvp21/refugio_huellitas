enum PetType {
  dog('perro'),
  cat('gato'),
  bird('ave'),
  rabbit('conejo'),
  other('otro');

  /// Valor guardado en la columna `tipo` de la tabla `mascotas`.
  final String dbValue;
  const PetType(this.dbValue);

  static PetType fromDb(String value) =>
      PetType.values.firstWhere((t) => t.dbValue == value, orElse: () => PetType.other);

  String get displayName {
    switch (this) {
      case PetType.dog:
        return 'Perro';
      case PetType.cat:
        return 'Gato';
      case PetType.bird:
        return 'Ave';
      case PetType.rabbit:
        return 'Conejo';
      case PetType.other:
        return 'Otro';
    }
  }
}

enum VaccinationStatus {
  vaccinated('vacunado'),
  notVaccinated('no_vacunado'),
  partiallyVaccinated('parcial');

  /// Valor guardado en la columna `estado_vacunacion`.
  final String dbValue;
  const VaccinationStatus(this.dbValue);

  static VaccinationStatus fromDb(String value) => VaccinationStatus.values
      .firstWhere((v) => v.dbValue == value, orElse: () => VaccinationStatus.notVaccinated);
}

enum AdoptionStatus {
  available('disponible'),
  inProcess('en_proceso'),
  adopted('adoptada');

  /// Valor guardado en la columna `estado_adopcion`.
  final String dbValue;
  const AdoptionStatus(this.dbValue);

  static AdoptionStatus fromDb(String value) => AdoptionStatus.values
      .firstWhere((s) => s.dbValue == value, orElse: () => AdoptionStatus.available);

  String get displayName {
    switch (this) {
      case AdoptionStatus.available:
        return 'Disponible';
      case AdoptionStatus.inProcess:
        return 'En proceso';
      case AdoptionStatus.adopted:
        return 'Adoptada';
    }
  }
}

class Pet {
  /// uuid generado por Supabase. Vacío ('') mientras la mascota no se ha guardado.
  final String id;
  final String name;
  final int age;
  final PetType type;
  final String breed;
  final VaccinationStatus vaccinationStatus;
  final String? description;
  final DateTime registrationDate;
  final AdoptionStatus adoptionStatus;

  Pet({
    this.id = '',
    required this.name,
    required this.age,
    required this.type,
    required this.breed,
    required this.vaccinationStatus,
    this.description,
    DateTime? registrationDate,
    this.adoptionStatus = AdoptionStatus.available,
  }) : registrationDate = registrationDate ?? DateTime.now();

  /// Construye una mascota a partir de una fila de la tabla `mascotas`.
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String,
      name: map['nombre'] as String,
      age: (map['edad'] as num).toInt(),
      type: PetType.fromDb(map['tipo'] as String),
      breed: map['raza'] as String,
      vaccinationStatus: VaccinationStatus.fromDb(map['estado_vacunacion'] as String),
      description: map['descripcion'] as String?,
      registrationDate: DateTime.parse(map['fecha_registro'] as String).toLocal(),
      adoptionStatus: AdoptionStatus.fromDb(map['estado_adopcion'] as String),
    );
  }

  /// Columnas que la app envía en insert/update. No incluye `id`, `user_id`
  /// ni `created_at`: los genera la base de datos (default auth.uid(), now()...).
  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'edad': age,
      'tipo': type.dbValue,
      'raza': breed,
      'estado_vacunacion': vaccinationStatus.dbValue,
      'descripcion': description,
      'fecha_registro': registrationDate.toUtc().toIso8601String(),
      'estado_adopcion': adoptionStatus.dbValue,
    };
  }

  Pet copyWith({
    String? id,
    String? name,
    int? age,
    PetType? type,
    String? breed,
    VaccinationStatus? vaccinationStatus,
    String? description,
    DateTime? registrationDate,
    AdoptionStatus? adoptionStatus,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      description: description ?? this.description,
      registrationDate: registrationDate ?? this.registrationDate,
      adoptionStatus: adoptionStatus ?? this.adoptionStatus,
    );
  }

  String get typeDisplayName => type.displayName;

  String get vaccinationStatusDisplayName {
    switch (vaccinationStatus) {
      case VaccinationStatus.vaccinated:
        return 'Vacunado';
      case VaccinationStatus.notVaccinated:
        return 'No vacunado';
      case VaccinationStatus.partiallyVaccinated:
        return 'Parcialmente vacunado';
    }
  }

  @override
  String toString() {
    return 'Pet(id: $id, name: $name, age: $age, type: $type, breed: $breed, vaccinationStatus: $vaccinationStatus, adoptionStatus: $adoptionStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
