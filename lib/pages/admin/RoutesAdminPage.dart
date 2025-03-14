import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';

class RoutesAdminPage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();

  RoutesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => CreateRoutePage()),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: adminController.firestore.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final routes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final routeData = route.data() as Map<String, dynamic>;
              final routeId = route.id;

              return ListTile(
                title: Text(routeData['name']),
                subtitle: Text('Stations: ${routeData['stationIds'].length}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => Get.to(
                            () => EditRoutePage(
                              routeId: routeId,
                              routeData: routeData,
                            ),
                          ),
                    ),
                    Switch(
                      value: routeData['isActive'],
                      onChanged: (value) async {
                        await adminController.editRoute(
                          routeId,
                          isActive: value,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Route Name'),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildStationSelector(selectedStations)),
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
            Expanded(child: _buildStationSelector(selectedStations)),
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

class AddStationPage extends StatelessWidget {
  final RxList<String> selectedStations;
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();

  AddStationPage({super.key, required this.selectedStations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Station')),
      body: StreamBuilder<QuerySnapshot>(
        stream: adminController.firestore.collection('stations').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final stations = snapshot.data!.docs;
          final availableStations =
              stations
                  .where(
                    (station) => !selectedStations.contains(station['name']),
                  )
                  .toList();

          return ListView.builder(
            itemCount: availableStations.length,
            itemBuilder: (context, index) {
              final station = availableStations[index];
              return ListTile(
                title: Text(station['name']),
                onTap: () {
                  selectedStations.add(station['name']);
                  Get.back();
                },
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildStationSelector(RxList<String> selectedStations) {
  final adminController = Get.find<FirebaseAdminController>();

  return StreamBuilder<QuerySnapshot>(
    stream: adminController.firestore.collection('stations').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator();

      final stations = snapshot.data!.docs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stations:'),
          Obx(
            () =>
                selectedStations.isEmpty
                    ? const Text('No stations selected')
                    : Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final station = selectedStations.removeAt(oldIndex);
                          selectedStations.insert(newIndex, station);
                        },
                        children:
                            selectedStations.map((stationId) {
                              final station = stations.firstWhere(
                                (doc) => doc['name'] == stationId,
                              );
                              return ListTile(
                                key: ValueKey(stationId),
                                title: Text(station['name']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      () => selectedStations.remove(stationId),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                () => Get.to(
                  () => AddStationPage(selectedStations: selectedStations),
                ),
            child: const Text('Add Station'),
          ),
        ],
      );
    },
  );
}
