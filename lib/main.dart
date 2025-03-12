import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/firebase_options.dart';
import 'package:train_app/navigation_menu.dart';
import 'package:train_app/utils/theme/theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized before any other code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Put the FirebaseController instance
  Get.put(FirebaseController());

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
