import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/routes/RoutesAdminPage.dart';
import 'package:train_app/utils/constants/sizes.dart';

class CreateRoutePage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  final TextEditingController nameController = TextEditingController();
  final RxList<String> selectedStations = <String>[].obs;

  CreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Route')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Route Name'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.6, // Limit the height
                child: buildStationSelector(selectedStations),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: _createRoute,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRoute() async {
    if (nameController.text.isEmpty || selectedStations.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a name and select at least one station',
      );
      return;
    }
    try {
      await adminController.createRoute(
        nameController.text.trim(),
        selectedStations.toList(),
      );
      Get.back();
      Get.snackbar('Success', 'Route created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create route: $e');
    }
  }
}
