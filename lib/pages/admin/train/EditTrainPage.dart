import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/TimeFunctions.dart';

class EditTrainPage extends StatefulWidget {
  final String trainId;
  final Map<String, dynamic> trainData;

  const EditTrainPage({
    super.key,
    required this.trainId,
    required this.trainData,
  });

  @override
  State<EditTrainPage> createState() => _EditTrainPageState();
}

class _EditTrainPageState extends State<EditTrainPage> {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late final TextEditingController seatsController;
  late final TextEditingController availableSeatsController;
  late final TextEditingController priceController;
  late final RxMap<String, String> schedule;
  late final Rx<DateTime> selectedDate;
  late Future<DocumentSnapshot> _routeFuture;

  @override
  void initState() {
    super.initState();
    seatsController = TextEditingController(
      text: widget.trainData['seatsTotal'].toString(),
    );
    availableSeatsController = TextEditingController(
      text:
          widget.trainData['seatsAvailable']?.toString() ??
          widget.trainData['seatsTotal'].toString(),
    );
    priceController = TextEditingController(
      text: widget.trainData['pricePerPassenger'].toString(),
    );
    schedule = RxMap<String, String>.from(
      (widget.trainData['schedule'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    selectedDate = Rx<DateTime>(DateTime.parse(widget.trainData['date']));
    _routeFuture =
        adminController.firestore
            .collection('routes')
            .doc(widget.trainData['routeId'])
            .get();
  }

  void _refreshRoute() {
    setState(() {
      _routeFuture =
          adminController.firestore
              .collection('routes')
              .doc(widget.trainData['routeId'])
              .get();
    });
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
          '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}',
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
    return FutureBuilder<DocumentSnapshot>(
      future: _routeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading route data');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Route not found');
        }

        final routeData = snapshot.data!.data() as Map<String, dynamic>;
        final stationIds = List<String>.from(routeData['stationIds']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule:'),
            ...stationIds.map((stationId) {
              return FutureBuilder<DocumentSnapshot>(
                future:
                    adminController.firestore
                        .collection('stations')
                        .doc(stationId)
                        .get(),
                builder: (context, stationSnapshot) {
                  if (stationSnapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  if (stationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!stationSnapshot.hasData ||
                      !stationSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

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
        widget.trainId,
        schedule: schedule,
        seatsTotal: totalSeats,
        seatsAvailable: availableSeats,
        pricePerPassenger: double.parse(priceController.text.trim()),
        date:
            '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}',
      );
      Get.back();
      Get.snackbar('Success', 'Train updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update train: $e');
    }
  }
}
