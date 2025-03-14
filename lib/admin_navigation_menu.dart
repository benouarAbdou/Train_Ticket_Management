import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/RoutesAdminPage.dart';
import 'package:train_app/pages/admin/TicketVerificationPage.dart';
import 'package:train_app/pages/admin/destination/DestinationManagementPage.dart';
import 'package:train_app/pages/admin/train/TrainAdminPage.dart';
import 'package:train_app/utils/constants/colors.dart';

class AdminNavigationMenu extends StatelessWidget {
  const AdminNavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminNavigationController());
    final adminController = Get.find<FirebaseAdminController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () async {
              await adminController.signOut();
              // The Obx in MyApp will automatically switch to regular NavigationMenu
            },
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          backgroundColor: TColors.white,
          indicatorColor: TColors.black.withOpacity(0.1),
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected:
              (value) => controller.selectedIndex.value = value,
          destinations: const [
            NavigationDestination(icon: Icon(Iconsax.ticket), label: "Tickets"),
            NavigationDestination(
              icon: Icon(Iconsax.building),
              label: "Stations",
            ),
            NavigationDestination(icon: Icon(Icons.route), label: "Routes"),
            NavigationDestination(icon: Icon(Icons.train), label: "Trains"),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class AdminNavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    TicketVerificationPage(),
    DestinationManagementPage(),
    RoutesAdminPage(),
    TrainAdminPage(),
  ];
}
