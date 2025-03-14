import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:toggle_switch/toggle_switch.dart';
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
          ToggleSwitch(
            minWidth: 40.0, // Compact width
            minHeight: 20.0,
            cornerRadius: 10.0,
            activeBgColor: [TColors.buttonPrimary], // Green when active
            activeFgColor: Colors.white,
            inactiveFgColor: Colors.white, // White text for contrast
            initialLabelIndex: isActive ? 0 : 1,
            totalSwitches: 2,
            icons: const [
              Icons.check_circle,
              Icons.cancel,
            ], // Icons for clarity
            radiusStyle: true,
            onToggle: (index) => onToggleActive(),
          ),
        ],
      ),
    );
  }
}
