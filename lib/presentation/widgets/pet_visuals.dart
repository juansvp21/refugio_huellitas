import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/adoption_request.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';

/// Colores e iconos compartidos por las pantallas nuevas.
IconData petTypeIcon(PetType type) => type == PetType.bird ? Icons.air : Icons.pets;

Color petTypeColor(PetType type) {
  switch (type) {
    case PetType.dog:
      return Colors.brown;
    case PetType.cat:
      return Colors.orange;
    case PetType.bird:
      return Colors.blue;
    case PetType.rabbit:
      return Colors.pink;
    case PetType.other:
      return Colors.grey;
  }
}

Color vaccinationColor(ColorScheme colorScheme, VaccinationStatus status) {
  switch (status) {
    case VaccinationStatus.vaccinated:
      return Colors.green;
    case VaccinationStatus.notVaccinated:
      return colorScheme.error;
    case VaccinationStatus.partiallyVaccinated:
      return Colors.orange;
  }
}

Color adoptionStatusColor(AdoptionStatus status) {
  switch (status) {
    case AdoptionStatus.available:
      return Colors.green;
    case AdoptionStatus.inProcess:
      return Colors.orange;
    case AdoptionStatus.adopted:
      return Colors.purple;
  }
}

Color requestStatusColor(RequestStatus status) {
  switch (status) {
    case RequestStatus.pending:
      return Colors.orange;
    case RequestStatus.approved:
      return Colors.green;
    case RequestStatus.rejected:
      return Colors.red;
  }
}

/// Etiqueta pequeña de color (estado de adopción, estado de solicitud...).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
