import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/firebase_options.dart';
import 'package:train_app/navigation_menu.dart';
import 'package:train_app/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Don't open boxes here, let HiveController handle it
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(FirebaseController());
  Get.put(HiveController()); // Controller will handle box initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: Train_appTheme.lightTheme,
      darkTheme: Train_appTheme.darkTheme,
      home: const NavigationMenu(),
    );
  }
}
