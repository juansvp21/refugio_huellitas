import 'package:flutter/material.dart';
import 'package:refugio_huellitas/domain/models/pet.dart';
import 'package:refugio_huellitas/presentation/widgets/pet_visuals.dart';

class CustomPetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const CustomPetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPetTypeIcon(theme, colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.typeDisplayName} • ${pet.breed}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showDeleteButton && onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Eliminar mascota',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              _buildInfoRow(
                context: context,
                icon: Icons.cake_outlined,
                label: 'Edad',
                value: '${pet.age} ${pet.age == 1 ? 'año' : 'años'}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'Vacunación',
                value: pet.vaccinationStatusDisplayName,
                valueColor: _getVaccinationColor(colorScheme),
              ),
              if (pet.description != null && pet.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  pet.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusChip(
                    label: pet.adoptionStatus.displayName,
                    color: adoptionStatusColor(pet.adoptionStatus),
                  ),
                  const Spacer(),
                  Text(
                    'Registrado: ${_formatDate(pet.registrationDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetTypeIcon(ThemeData theme, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (pet.type) {
      case PetType.dog:
        iconData = Icons.pets;
        iconColor = Colors.brown;
        break;
      case PetType.cat:
        iconData = Icons.pets;
        iconColor = Colors.orange;
        break;
      case PetType.bird:
        iconData = Icons.air;
        iconColor = Colors.blue;
        break;
      case PetType.rabbit:
        iconData = Icons.pets;
        iconColor = Colors.pink;
        break;
      case PetType.other:
        iconData = Icons.pets;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getVaccinationColor(ColorScheme colorScheme) {
    switch (pet.vaccinationStatus) {
      case VaccinationStatus.vaccinated:
        return Colors.green;
      case VaccinationStatus.notVaccinated:
        return colorScheme.error;
      case VaccinationStatus.partiallyVaccinated:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class CustomPetCardCompact extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;

  const CustomPetCardCompact({
    super.key,
    required this.pet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildPetTypeAvatar(theme, colorScheme),
        title: Text(
          pet.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${pet.typeDisplayName} • ${pet.breed} • ${pet.age} ${pet.age == 1 ? 'año' : 'años'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildVaccinationChip(colorScheme),
      ),
    );
  }

  Widget _buildPetTypeAvatar(ThemeData theme, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (pet.type) {
      case PetType.dog:
        iconData = Icons.pets;
        iconColor = Colors.brown;
        bgColor = Colors.brown.withValues(alpha: 0.15);
        break;
      case PetType.cat:
        iconData = Icons.pets;
        iconColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.15);
        break;
      case PetType.bird:
        iconData = Icons.air;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.15);
        break;
      case PetType.rabbit:
        iconData = Icons.pets;
        iconColor = Colors.pink;
        bgColor = Colors.pink.withValues(alpha: 0.15);
        break;
      case PetType.other:
        iconData = Icons.pets;
        iconColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.15);
        break;
    }

    return CircleAvatar(
      backgroundColor: bgColor,
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildVaccinationChip(ColorScheme colorScheme) {
    Color chipColor;
    String label;

    switch (pet.vaccinationStatus) {
      case VaccinationStatus.vaccinated:
        chipColor = Colors.green;
        label = 'Vacunado';
        break;
      case VaccinationStatus.notVaccinated:
        chipColor = colorScheme.error;
        label = 'No vacunado';
        break;
      case VaccinationStatus.partiallyVaccinated:
        chipColor = Colors.orange;
        label = 'Parcial';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}