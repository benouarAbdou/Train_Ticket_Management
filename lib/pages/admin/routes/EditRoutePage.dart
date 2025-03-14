import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/routes/RoutesAdminPage.dart';

class EditRoutePage extends StatelessWidget {
  final String routeId;
  final Map<String, dynamic> routeData;
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late final TextEditingController nameController;
  late final RxList<String> selectedStations;

  EditRoutePage({super.key, required this.routeId, required this.routeData}) {
    nameController = TextEditingController(text: routeData['name']);
    selectedStations = List<String>.from(routeData['stationIds']).obs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Route')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Route Name'),
            ),
            const SizedBox(height: 16),
            Expanded(child: buildStationSelector(selectedStations)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                TextButton(onPressed: _saveRoute, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoute() async {
    if (selectedStations.isEmpty) {
      Get.snackbar('Error', 'Please select at least one station');
      return;
    }
    try {
      await adminController.editRoute(
        routeId,
        stationIds: selectedStations.toList(),
      );
      Get.back();
      Get.snackbar('Success', 'Route updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update route: $e');
    }
  }
}
