import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:train_app/utils/constants/colors.dart';

class CustomToggleSwitch extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final double minWidth;
  final double minHeight;
  final double cornerRadius;
  final Color activeBgColor;
  final Color inactiveBgColor;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const CustomToggleSwitch({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.minWidth = 40.0,
    this.minHeight = 30.0,
    this.cornerRadius = 10.0,
    this.activeBgColor = TColors.buttonPrimary,
    this.inactiveBgColor = Colors.grey,
    this.activeIcon = Icons.check_circle,
    this.inactiveIcon = Icons.cancel,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleSwitch(
      minWidth: minWidth,
      minHeight: minHeight,
      cornerRadius: cornerRadius,
      activeBgColor: [activeBgColor], // Active background color
      inactiveBgColor: inactiveBgColor, // Inactive background color
      activeFgColor: Colors.white, // White thumb/icon in active state
      inactiveFgColor: Colors.white, // White thumb/icon in inactive state
      initialLabelIndex: isActive ? 0 : 1, // 0 = active, 1 = inactive
      totalSwitches: 2,
      icons: [activeIcon, inactiveIcon], // Customizable icons
      radiusStyle: true,
      onToggle: (index) => onToggle(),
    );
  }
}
