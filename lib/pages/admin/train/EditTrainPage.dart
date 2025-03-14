import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/TimeFunctions.dart'; // Assuming this is where showCustomTimePicker and formatTimeOfDay are

class EditTrainPage extends StatelessWidget {
  final String trainId;
  final Map<String, dynamic> trainData;
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late final TextEditingController seatsController;
  late final TextEditingController availableSeatsController;
  late final TextEditingController priceController;
  late final RxMap<String, String> schedule;
  late final Rx<DateTime> selectedDate;

  EditTrainPage({super.key, required this.trainId, required this.trainData}) {
    seatsController = TextEditingController(
      text: trainData['seatsTotal'].toString(),
    );
    availableSeatsController = TextEditingController(
      text:
          trainData['seatsAvailable']?.toString() ??
          trainData['seatsTotal'].toString(),
    );
    priceController = TextEditingController(
      text: trainData['pricePerPassenger'].toString(),
    );
    schedule = RxMap<String, String>.from(
      (trainData['schedule'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    selectedDate = Rx<DateTime>(DateTime.parse(trainData['date']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Train')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDatePicker(context),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextField(
                controller: seatsController,
                decoration: const InputDecoration(labelText: 'Total Seats'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextField(
                controller: availableSeatsController,
                decoration: const InputDecoration(labelText: 'Available Seats'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Passenger',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              _buildScheduleEditor(context),
              const SizedBox(height: TSizes.spaceBtwInputFields),
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

  Widget _buildDatePicker(BuildContext context) {
    return Obx(
      () => ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Date'),
        subtitle: Text(
          '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}', // Display YYYY-MM-DD
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate.value,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null && picked != selectedDate.value) {
            selectedDate.value = picked;
          }
        },
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
                          child: GestureDetector(
                            onTap: () async {
                              final TimeOfDay? picked =
                                  await showCustomTimePicker(context);
                              if (picked != null) {
                                schedule[stationId] = formatTimeOfDay(picked);
                              }
                            },
                            child: Obx(
                              () => TextField(
                                controller: TextEditingController(
                                  text: schedule[stationId],
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'HH:MM',
                                ),
                                enabled: false,
                              ),
                            ),
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
        availableSeatsController.text.isEmpty ||
        priceController.text.isEmpty ||
        schedule.values.any((time) => time.isEmpty)) {
      Get.snackbar('Error', 'Please fill all fields including the schedule');
      return;
    }

    final totalSeats = int.parse(seatsController.text.trim());
    final availableSeats = int.parse(availableSeatsController.text.trim());
    if (availableSeats > totalSeats) {
      Get.snackbar('Error', 'Available seats cannot exceed total seats');
      return;
    }

    try {
      await adminController.editTrain(
        trainId,
        schedule: schedule,
        seatsTotal: totalSeats,
        seatsAvailable: availableSeats,
        pricePerPassenger: double.parse(priceController.text.trim()),
        date:
            '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}', // Save as YYYY-MM-DD
      );
      Get.back();
      Get.snackbar('Success', 'Train updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update train: $e');
    }
  }
}
