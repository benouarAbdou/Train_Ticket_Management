import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationManagementPage extends StatefulWidget {
  const DestinationManagementPage({super.key});

  @override
  State<DestinationManagementPage> createState() =>
      _DestinationManagementPageState();
}

class _DestinationManagementPageState extends State<DestinationManagementPage> {
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();
  final _formKey = GlobalKey<FormState>();
  final _stationNameController = TextEditingController();

  @override
  void dispose() {
    _stationNameController.dispose();
    super.dispose();
  }

  Future<void> _addNewStation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _adminController.addStation(
        _stationNameController.text.trim(),
        {}, // Empty distances map initially
      );
      _stationNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding station: ${e.toString()}')),
      );
    }
  }

  void _showDistanceDialog(
    String stationName,
    Map<String, dynamic> currentDistances,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => DistanceEditDialog(
            stationName: stationName,
            currentDistances: Map<String, int>.from(currentDistances),
            onSave: (distances) async {
              try {
                await _adminController.editStation(
                  stationName,
                  distances: distances,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Distances updated successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating distances: ${e.toString()}'),
                  ),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Destinations')),
      body: Column(
        children: [
          // Add New Station Form
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stationNameController,
                      decoration: const InputDecoration(
                        labelText: 'New Station Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a station name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  ElevatedButton(
                    onPressed: _addNewStation,
                    child: const Text('Add Station'),
                  ),
                ],
              ),
            ),
          ),

          // Stations List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final station = snapshot.data!.docs[index];
                    final data = station.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] as bool;

                    return StationListTile(
                      stationName: station.id,
                      isActive: isActive,
                      distances: data['distances'] as Map<String, dynamic>,
                      onToggleActive: () async {
                        await _adminController.toggleStationActive(
                          station.id,
                          !isActive,
                        );
                      },
                      onEditDistances: () {
                        _showDistanceDialog(
                          station.id,
                          data['distances'] as Map<String, dynamic>,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StationListTile extends StatelessWidget {
  final String stationName;
  final bool isActive;
  final Map<String, dynamic> distances;
  final VoidCallback onToggleActive;
  final VoidCallback onEditDistances;

  const StationListTile({
    super.key,
    required this.stationName,
    required this.isActive,
    required this.distances,
    required this.onToggleActive,
    required this.onEditDistances,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(stationName),
      subtitle: Text('Connected to ${distances.length} stations'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            onPressed: onEditDistances,
            tooltip: 'Edit Distances',
          ),
          Switch(
            value: isActive,
            onChanged: (_) => onToggleActive(),
            activeColor: TColors.primary,
          ),
        ],
      ),
    );
  }
}

class DistanceEditDialog extends StatefulWidget {
  final String stationName;
  final Map<String, int> currentDistances;
  final Function(Map<String, int>) onSave;

  const DistanceEditDialog({
    super.key,
    required this.stationName,
    required this.currentDistances,
    required this.onSave,
  });

  @override
  State<DistanceEditDialog> createState() => _DistanceEditDialogState();
}

class _DistanceEditDialogState extends State<DistanceEditDialog> {
  late Map<String, TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    FirebaseFirestore.instance.collection('stations').get().then((stations) {
      for (var station in stations.docs) {
        if (station.id != widget.stationName) {
          _controllers[station.id] = TextEditingController(
            text: widget.currentDistances[station.id]?.toString() ?? '',
          );
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Distances from ${widget.stationName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Distance to ${entry.key} (km)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final number = int.tryParse(value);
                          if (number == null || number <= 0) {
                            return 'Please enter a valid distance';
                          }
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final distances = <String, int>{};
              _controllers.forEach((station, controller) {
                if (controller.text.isNotEmpty) {
                  distances[station] = int.parse(controller.text);
                }
              });
              widget.onSave(distances);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
