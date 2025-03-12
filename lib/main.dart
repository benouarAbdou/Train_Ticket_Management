import 'package:flutter/material.dart';
import 'package:train_app/navigation_menu.dart';
import 'package:train_app/utils/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: Train_appTheme.lightTheme,
      darkTheme: Train_appTheme.darkTheme,
      home: const NavigationMenu(),
    );
  }
}
