import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';

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
