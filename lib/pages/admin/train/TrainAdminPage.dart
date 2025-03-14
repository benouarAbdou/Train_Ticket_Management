import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/train/CreateTrainPage.dart';
import 'package:train_app/pages/admin/train/EditTrainPage.dart';
import 'package:train_app/utils/constants/sizes.dart';

class TrainAdminPage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();

  TrainAdminPage({super.key});

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
                  onPressed: () => Get.to(() => CreateTrainPage()),
                  child: const Text('Add'),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    adminController.firestore.collection('trains').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
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

                      // Safely get the first station and its departure time from the schedule
                      final schedule =
                          trainData['schedule'] as Map<String, dynamic>?;
                      final firstStation = schedule?.keys.first ?? 'Unknown';
                      final departureTime = schedule?[firstStation] ?? 'N/A';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Train on ${trainData['date'] ?? 'No date'}',
                        ),
                        subtitle: Text(
                          'Leaving from $firstStation at $departureTime - '
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
                              ),
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
