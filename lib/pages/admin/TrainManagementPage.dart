import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrainManagementPage extends StatelessWidget {
  const TrainManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Train Management'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Routes'), Tab(text: 'Trains')],
          ),
        ),
        body: const TabBarView(
          children: [RouteManagementTab(), TrainScheduleTab()],
        ),
      ),
    );
  }
}

class RouteManagementTab extends StatefulWidget {
  const RouteManagementTab({super.key});

  @override
  State<RouteManagementTab> createState() => _RouteManagementTabState();
}

class _RouteManagementTabState extends State<RouteManagementTab> {
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();
  final _routeNameController = TextEditingController();
  List<String> _selectedStations = [];

  @override
  void dispose() {
    _routeNameController.dispose();
    super.dispose();
  }

  void _showCreateRouteDialog() {
    _routeNameController.clear();
    _selectedStations = [];
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Create New Route'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _routeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Route Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwInputFields),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('stations')
                                  .where('isActive', isEqualTo: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            return Column(
                              children:
                                  snapshot.data!.docs.map((station) {
                                    final stationId = station.id;
                                    return CheckboxListTile(
                                      title: Text(stationId),
                                      value: _selectedStations.contains(
                                        stationId,
                                      ),
                                      onChanged: (selected) {
                                        setState(() {
                                          if (selected!) {
                                            _selectedStations.add(stationId);
                                          } else {
                                            _selectedStations.remove(stationId);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_routeNameController.text.isNotEmpty &&
                            _selectedStations.length >= 2) {
                          await _adminController.createRoute(
                            _routeNameController.text,
                            _selectedStations,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRouteDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final route = snapshot.data!.docs[index];
              final data = route.data() as Map<String, dynamic>;
              final stationIds = List<String>.from(data['stationIds']);

              return Card(
                margin: const EdgeInsets.all(TSizes.sm),
                child: ExpansionTile(
                  title: Text(data['name']),
                  subtitle: Text('${stationIds.length} stations'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(TSizes.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stations:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...stationIds.map((station) => Text('• $station')),
                          OverflowBar(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await _adminController.editRoute(
                                    route.id,
                                    isActive: !(data['isActive'] ?? true),
                                  );
                                },
                                child: Text(
                                  data['isActive'] ?? true
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TrainScheduleTab extends StatelessWidget {
  const TrainScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTrainDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trains').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final train = snapshot.data!.docs[index];
              final data = train.data() as Map<String, dynamic>;

              return TrainCard(trainId: train.id, trainData: data);
            },
          );
        },
      ),
    );
  }

  void _showCreateTrainDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTrainDialog(),
    );
  }
}

class TrainCard extends StatelessWidget {
  final String trainId;
  final Map<String, dynamic> trainData;
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();

  TrainCard({super.key, required this.trainId, required this.trainData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(TSizes.sm),
      child: ExpansionTile(
        title: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('routes')
                  .doc(trainData['routeId'])
                  .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Loading...');
            final routeData = snapshot.data!.data() as Map<String, dynamic>;
            return Text('${routeData['name']} - ${trainData['date']}');
          },
        ),
        subtitle: Text(
          'Seats: ${trainData['seatsLeft']}/${trainData['seatsTotal']}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(TSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: \$${trainData['pricePerPassenger']}'),
                const Divider(),
                const Text(
                  'Schedule:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...Map<String, String>.from(
                  trainData['schedule'],
                ).entries.map((e) => Text('${e.key}: ${e.value}')),
                OverflowBar(
                  children: [
                    TextButton(
                      onPressed: () => _showEditTrainDialog(context),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _adminController.editTrain(
                          trainId,
                          isActive: !(trainData['isActive'] ?? true),
                        );
                      },
                      child: Text(
                        trainData['isActive'] ?? true
                            ? 'Deactivate'
                            : 'Activate',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTrainDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => EditTrainDialog(trainId: trainId, trainData: trainData),
    );
  }
}

class CreateTrainDialog extends StatefulWidget {
  const CreateTrainDialog({super.key});

  @override
  State<CreateTrainDialog> createState() => _CreateTrainDialogState();
}

class _CreateTrainDialogState extends State<CreateTrainDialog> {
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();
  String? _selectedRouteId;
  final _dateController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  final Map<String, TextEditingController> _scheduleControllers = {};

  @override
  void dispose() {
    _dateController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    for (var controller in _scheduleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Train'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('routes')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<String>(
                  value: _selectedRouteId,
                  decoration: const InputDecoration(
                    labelText: 'Route',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      snapshot.data!.docs.map((route) {
                        final data = route.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: route.id,
                          child: Text(data['name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRouteId = value;
                      _updateScheduleControllers(value!);
                    });
                  },
                );
              },
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(
                labelText: 'Total Seats',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Passenger',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            if (_scheduleControllers.isNotEmpty) ...[
              const SizedBox(height: TSizes.spaceBtwSections),
              const Text(
                'Schedule:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._scheduleControllers.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        entry.value.text = time.format(context);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createTrain, child: const Text('Create')),
      ],
    );
  }

  Future<void> _updateScheduleControllers(String routeId) async {
    final route =
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .get();
    final stationIds = List<String>.from(route['stationIds']);

    setState(() {
      _scheduleControllers.clear();
      for (var station in stationIds) {
        _scheduleControllers[station] = TextEditingController();
      }
    });
  }

  Future<void> _createTrain() async {
    if (_selectedRouteId == null ||
        _dateController.text.isEmpty ||
        _seatsController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _scheduleControllers.values.any(
          (controller) => controller.text.isEmpty,
        )) {
      return;
    }

    final schedule = <String, String>{};
    _scheduleControllers.forEach((station, controller) {
      schedule[station] = controller.text;
    });

    await _adminController.createTrain(
      routeId: _selectedRouteId!,
      date: _dateController.text,
      schedule: schedule,
      seatsTotal: int.parse(_seatsController.text),
      pricePerPassenger: double.parse(_priceController.text),
    );

    Navigator.pop(context);
  }
}

class EditTrainDialog extends StatefulWidget {
  final String trainId;
  final Map<String, dynamic> trainData;

  const EditTrainDialog({
    super.key,
    required this.trainId,
    required this.trainData,
  });

  @override
  State<EditTrainDialog> createState() => _EditTrainDialogState();
}

class _EditTrainDialogState extends State<EditTrainDialog> {
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  final Map<String, TextEditingController> _scheduleControllers = {};

  @override
  void initState() {
    super.initState();
    _seatsController.text = widget.trainData['seatsTotal'].toString();
    _priceController.text = widget.trainData['pricePerPassenger'].toString();

    final schedule = Map<String, String>.from(widget.trainData['schedule']);
    schedule.forEach((station, time) {
      _scheduleControllers[station] = TextEditingController(text: time);
    });
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _priceController.dispose();
    for (var controller in _scheduleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Train'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(
                labelText: 'Total Seats',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Passenger',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            const Text(
              'Schedule:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._scheduleControllers.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      entry.value.text = time.format(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _updateTrain, child: const Text('Save')),
      ],
    );
  }

  Future<void> _updateTrain() async {
    final schedule = <String, String>{};
    _scheduleControllers.forEach((station, controller) {
      schedule[station] = controller.text;
    });

    await _adminController.editTrain(
      widget.trainId,
      schedule: schedule,
      seatsTotal: int.parse(_seatsController.text),
      pricePerPassenger: double.parse(_priceController.text),
    );

    Navigator.pop(context);
  }
}
