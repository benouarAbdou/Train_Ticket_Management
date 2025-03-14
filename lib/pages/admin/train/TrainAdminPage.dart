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
                  if (snapshot.hasError)
                    return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final trains = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: trains.length,
                    itemBuilder: (context, index) {
                      final train = trains[index];
                      final trainData = train.data() as Map<String, dynamic>;
                      final trainId = train.id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Train on ${trainData['date']}'),
                        subtitle: Text(
                          ' Seats: ${trainData['seatsLeft']}/${trainData['seatsTotal']}',
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
