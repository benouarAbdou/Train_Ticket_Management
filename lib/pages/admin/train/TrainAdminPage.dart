import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/train/CreateTrainPage.dart';
import 'package:train_app/pages/admin/train/EditTrainPage.dart';

class TrainAdminPage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();

  TrainAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Trains'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => CreateTrainPage()),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: adminController.firestore.collection('trains').snapshots(),
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
                title: Text('Train on ${trainData['date']}'),
                subtitle: Text(
                  'Route ID: ${trainData['routeId']} - Seats: ${trainData['seatsLeft']}/${trainData['seatsTotal']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
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
    );
  }
}
