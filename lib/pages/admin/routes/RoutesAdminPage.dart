import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/destination/AddStationPage.dart';
import 'package:train_app/pages/admin/routes/CreateRoutePage.dart';
import 'package:train_app/pages/admin/routes/EditRoutePage.dart';
import 'package:train_app/utils/constants/sizes.dart';

class RoutesAdminPage extends StatefulWidget {
  const RoutesAdminPage({super.key});

  @override
  State<RoutesAdminPage> createState() => _RoutesAdminPageState();
}

class _RoutesAdminPageState extends State<RoutesAdminPage> {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late Future<QuerySnapshot> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = adminController.firestore.collection('routes').get();
  }

  void _refreshRoutes() {
    setState(() {
      _routesFuture = adminController.firestore.collection('routes').get();
    });
  }

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
                  onPressed: () {
                    Get.to(
                      () => CreateRoutePage(),
                    )?.then((_) => _refreshRoutes());
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _routesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading ...");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No routes found'));
                  }

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
                                  )?.then((_) => _refreshRoutes()),
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

  Future<QuerySnapshot> stationsFuture =
      adminController.firestore.collection('stations').get();

  return FutureBuilder<QuerySnapshot>(
    future: stationsFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text("Loading ...");
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Text('No stations available');
      }

      final stations = snapshot.data!.docs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stations:'),
          Obx(
            () =>
                selectedStations.isEmpty
                    ? const Text('No stations selected')
                    : SizedBox(
                      height:
                          MediaQuery.of(context).size.height *
                          0.4, // Limit the height
                      child: ReorderableListView(
                        physics: BouncingScrollPhysics(),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                key: ValueKey(stationId),
                                title: Text(station['name']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      () => selectedStations.remove(stationId),
                                ),
                                leading: ReorderableDragStartListener(
                                  index: selectedStations.indexOf(stationId),
                                  child: const Icon(Icons.drag_indicator),
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
