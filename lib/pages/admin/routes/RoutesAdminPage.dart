import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/destination/AddStationPage.dart';
import 'package:train_app/pages/admin/routes/CreateRoutePage.dart';
import 'package:train_app/pages/admin/routes/EditRoutePage.dart';
import 'package:train_app/utils/constants/sizes.dart';

class RoutesAdminPage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();

  RoutesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),

        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "Routes Management",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                ElevatedButton(
                  onPressed: () => Get.to(() => CreateRoutePage()),
                  child: const Text('Add'),
                ),
              ],
            ),
            Expanded(
              // Wrap the ListView in an Expanded widget
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    adminController.firestore.collection('routes').snapshots(),
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
                        contentPadding: EdgeInsets.zero,
                        title: Text(routeData['name']),
                        subtitle: Text(
                          'Stations: ${routeData['stationIds'].length}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Iconsax.edit_copy),
                              onPressed:
                                  () => Get.to(
                                    () => EditRoutePage(
                                      routeId: routeId,
                                      routeData: routeData,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildStationSelector(RxList<String> selectedStations) {
  final adminController = Get.find<FirebaseAdminController>();

  return StreamBuilder<QuerySnapshot>(
    stream: adminController.firestore.collection('stations').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator();

      final stations = snapshot.data!.docs;

      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
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
                                contentPadding: EdgeInsets.zero,

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
          const SizedBox(height: TSizes.spaceBtwItems),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  () => Get.to(
                    () => AddStationPage(selectedStations: selectedStations),
                  ),
              child: const Text('Add Station'),
            ),
          ),
        ],
      );
    },
  );
}
