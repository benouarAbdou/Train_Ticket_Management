import 'package:flutter/material.dart';
import 'package:train_app/utils/constants/colors.dart';

class StationListTile extends StatelessWidget {
  final String stationName;
  final bool isActive;
  final Map<String, dynamic> distances;
  final VoidCallback onToggleActive;
  final VoidCallback onEditDistances;

  const StationListTile({
    super.key,
    required this.stationName,
    required this.isActive,
    required this.distances,
    required this.onToggleActive,
    required this.onEditDistances,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(stationName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: onEditDistances,
            tooltip: 'Edit Distances',
          ),
          Switch(
            value: isActive,
            onChanged: (_) => onToggleActive(),
            activeColor: TColors.primary,
          ),
        ],
      ),
    );
  }
}
