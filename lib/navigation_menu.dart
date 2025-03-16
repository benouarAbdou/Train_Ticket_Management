import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/pages/client/HomePage.dart';
import 'package:train_app/pages/client/MyTickets.dart';
import 'package:train_app/pages/client/SettingsPage.dart';
import 'package:train_app/utils/constants/colors.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: TColors.black.withOpacity(0.1),
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected:
              (value) => controller.selectedIndex.value = value,
          destinations: const [
            NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
            NavigationDestination(icon: Icon(Iconsax.ticket), label: "Tickets"),
            NavigationDestination(
              icon: Icon(Iconsax.setting),
              label: "Settings",
            ),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const MyHomePage(),
    BookedTicketsScreen(),
    const SettingsScreen(),
  ];
}
