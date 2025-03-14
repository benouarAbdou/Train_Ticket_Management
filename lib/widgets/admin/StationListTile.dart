import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/widgets/CustomToggle.dart';

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
      contentPadding: EdgeInsets.zero,
      title: Text(stationName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Iconsax.edit_copy),
            onPressed: onEditDistances,
            tooltip: 'Edit Distances',
          ),
          const SizedBox(width: 8), // Small gap for spacing
          CustomToggleSwitch(isActive: isActive, onToggle: onToggleActive),
        ],
      ),
    );
  }
}
