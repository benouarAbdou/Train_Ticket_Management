import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:intl/intl.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/TimeFunctions.dart';

class CreateTrainPage extends StatelessWidget {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final RxString selectedRouteId = ''.obs;
  final RxMap<String, String> schedule = <String, String>{}.obs;

  CreateTrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Train')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildRouteDropdown(),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    dateController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(pickedDate);
                  }
                },
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextField(
                controller: seatsController,
                decoration: const InputDecoration(labelText: 'Total Seats'),
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
              Obx(() => _buildScheduleEditor(context)),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: _createTrain,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          adminController.firestore
              .collection('routes')
              .where('isActive', isEqualTo: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final routes = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Select Route'),
          items:
              routes.map((route) {
                final routeData = route.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: route.id,
                  child: Text(routeData['name']),
                );
              }).toList(),
          onChanged: (value) {
            selectedRouteId.value = value ?? '';
            schedule.clear();
            if (value != null) {
              _loadStationsForRoute(value);
            }
          },
        );
      },
    );
  }

  Future<void> _loadStationsForRoute(String routeId) async {
    final routeDoc =
        await adminController.firestore.collection('routes').doc(routeId).get();
    final routeData = routeDoc.data() as Map<String, dynamic>;
    final stationIds = List<String>.from(routeData['stationIds']);

    for (String stationId in stationIds) {
      schedule[stationId] = ''; // Initialize with empty time
    }
  }

  Widget _buildScheduleEditor(BuildContext context) {
    if (selectedRouteId.value.isEmpty) {
      return const Text('Please select a route to set the schedule');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          adminController.firestore
              .collection('routes')
              .doc(selectedRouteId.value)
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
                                enabled: false, // Disable direct text input
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

  Future<void> _createTrain() async {
    if (selectedRouteId.value.isEmpty ||
        dateController.text.isEmpty ||
        seatsController.text.isEmpty ||
        priceController.text.isEmpty ||
        schedule.values.any((time) => time.isEmpty)) {
      Get.snackbar('Error', 'Please fill all fields including the schedule');
      return;
    }

    try {
      await adminController.createTrain(
        routeId: selectedRouteId.value,
        date: dateController.text.trim(),
        schedule: schedule,
        seatsTotal: int.parse(seatsController.text.trim()),
        pricePerPassenger: double.parse(priceController.text.trim()),
      );
      Get.back();
      Get.snackbar('Success', 'Train created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create train: $e');
    }
  }
}
