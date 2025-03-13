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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp()); // Start app immediately
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> initializeApp() async {
    await Hive.initFlutter();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register controllers with GetX
    Get.put(HiveController());
    Get.put(FirebaseController());
    Get.put(FirebaseAdminController()); // Ensure this is registered here
    Get.put(NotificationService()); // Add this line
    await Get.putAsync(() async => ConnectivityService());
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: Train_appTheme.lightTheme,
      darkTheme: Train_appTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: initializeApp(),
        builder: (context, snapshot) {
          // Show a loading screen while initializing
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If there's an error during initialization
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error initializing app')),
            );
          }

          // Once initialization is complete, controllers are available
          final FirebaseAdminController adminController = Get.find();
          return Obx(
            () =>
                adminController.isAdminLoggedIn.value
                    ? const AdminNavigationMenu()
                    : const NavigationMenu(),
          );
        },
      ),
    );
  }
}
