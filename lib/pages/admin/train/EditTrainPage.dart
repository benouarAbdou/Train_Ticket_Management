import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';

class EditTrainPage extends StatelessWidget {
  final String trainId;
  final Map<String, dynamic> trainData;
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late final TextEditingController seatsController;
  late final TextEditingController priceController;
  late final RxMap<String, String> schedule;

  EditTrainPage({super.key, required this.trainId, required this.trainData}) {
    seatsController = TextEditingController(
      text: trainData['seatsTotal'].toString(),
    );
    priceController = TextEditingController(
      text: trainData['pricePerPassenger'].toString(),
    );
    // Convert Map<String, dynamic> to Map<String, String>
    schedule = RxMap<String, String>.from(
      (trainData['schedule'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Train')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Date: ${trainData['date']}'), // Date is not editable
              const SizedBox(height: 16),
              TextField(
                controller: seatsController,
                decoration: const InputDecoration(labelText: 'Total Seats'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Passenger',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildScheduleEditor(context),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(onPressed: _saveTrain, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleEditor(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          adminController.firestore
              .collection('routes')
              .doc(trainData['routeId'])
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final routeData = snapshot.data!.data() as Map<String, dynamic>;
        final stationIds = List<String>.from(routeData['stationIds']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule:'),
            ...stationIds.map((stationId) {
              return StreamBuilder<DocumentSnapshot>(
                stream:
                    adminController.firestore
                        .collection('stations')
                        .doc(stationId)
                        .snapshots(),
                builder: (context, stationSnapshot) {
                  if (!stationSnapshot.hasData) return const SizedBox.shrink();

                  final stationData =
                      stationSnapshot.data!.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(stationData['name'])),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: TextEditingController(
                              text: schedule[stationId],
                            ),
                            decoration: const InputDecoration(
                              hintText: 'HH:MM',
                            ),
                            onChanged: (value) => schedule[stationId] = value,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _saveTrain() async {
    if (seatsController.text.isEmpty ||
        priceController.text.isEmpty ||
        schedule.values.any((time) => time.isEmpty)) {
      Get.snackbar('Error', 'Please fill all fields including the schedule');
      return;
    }

    try {
      await adminController.editTrain(
        trainId,
        schedule: schedule,
        seatsTotal: int.parse(seatsController.text.trim()),
        pricePerPassenger: double.parse(priceController.text.trim()),
      );
      Get.back();
      Get.snackbar('Success', 'Train updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update train: $e');
    }
  }
}
