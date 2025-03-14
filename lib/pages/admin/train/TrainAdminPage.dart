import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/train/CreateTrainPage.dart';
import 'package:train_app/pages/admin/train/EditTrainPage.dart';
import 'package:train_app/utils/constants/sizes.dart';

class TrainAdminPage extends StatefulWidget {
  const TrainAdminPage({super.key});

  @override
  State<TrainAdminPage> createState() => _TrainAdminPageState();
}

class _TrainAdminPageState extends State<TrainAdminPage> {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late Future<QuerySnapshot> _trainsFuture;

  @override
  void initState() {
    super.initState();
    _trainsFuture = adminController.firestore.collection('trains').get();
  }

  void _refreshTrains() {
    setState(() {
      _trainsFuture = adminController.firestore.collection('trains').get();
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
                    "Train Management",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => CreateTrainPage(),
                    )?.then((_) => _refreshTrains());
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _trainsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No trains found'));
                  }

                  final trains = snapshot.data!.docs;

                  // Sort trains by date
                  trains.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate =
                        aData['date'] ?? '1970-01-01'; // Fallback date
                    final bDate =
                        bData['date'] ?? '1970-01-01'; // Fallback date
                    return aDate.compareTo(bDate); // Ascending order
                  });

                  return ListView.builder(
                    itemCount: trains.length,
                    itemBuilder: (context, index) {
                      final train = trains[index];
                      final trainData = train.data() as Map<String, dynamic>;
                      final trainId = train.id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Train on ${trainData['date'] ?? 'No date'}',
                        ),
                        subtitle: Text(
                          '$trainId - '
                          '${trainData['seatsLeft'] ?? 0}/${trainData['seatsTotal'] ?? 0}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Iconsax.edit_copy),
                          onPressed:
                              () => Get.to(
                                () => EditTrainPage(
                                  trainId: trainId,
                                  trainData: trainData,
                                ),
                              )?.then((_) => _refreshTrains()),
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
