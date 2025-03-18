import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/firebase_options.dart';
import 'package:train_app/navigation_menu.dart';
import 'package:train_app/admin_navigation_menu.dart';
import 'package:train_app/utils/services/ConnectivityService.dart';
import 'package:train_app/utils/services/NotificationsService.dart';
import 'package:train_app/utils/theme/theme.dart';

// Entry point with async initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Hive for local storage and Firebase for backend
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register controllers with GetX for state management
  Get.put(HiveController());
  Get.put(FirebaseController());
  Get.put(FirebaseAdminController());
  Get.put(NotificationService());

  // Initialize connectivity service asynchronously
  await Get.putAsync(() async => ConnectivityService());

  runApp(const MyApp());
}

// Main app widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access admin controller for login state
    final FirebaseAdminController adminController = Get.find();

    return GetMaterialApp(
      title: 'Train app',
      themeMode: ThemeMode.system, // System-based theme switching
      theme: Train_appTheme.lightTheme,
      darkTheme: Train_appTheme.darkTheme,
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: Obx(
        // Toggle between admin and user navigation based on admin login
        () =>
            adminController.isAdminLoggedIn.value
                ? const AdminNavigationMenu()
                : const NavigationMenu(),
      ),
    );
  }
}
