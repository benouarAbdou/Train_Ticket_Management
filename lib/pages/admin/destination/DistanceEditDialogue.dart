import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistanceEditDialog extends StatefulWidget {
  final String stationName;
  final Map<String, int> currentDistances;
  final Function(String, Map<String, int>)
  onSave; // Modified callback signature

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
  late TextEditingController
  _nameController; // Added controller for station name
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String newName = "";

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _nameController = TextEditingController(
      text: widget.stationName,
    ); // Initialize name controller
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    final routesSnapshot = await _firestore.collection('routes').get();
    Set<String> connectedStations = {};

    for (var routeDoc in routesSnapshot.docs) {
      final routeData = routeDoc.data();
      final stationIds = List<String>.from(routeData['stationIds']);

      int currentIndex = stationIds.indexOf(widget.stationName);
      if (currentIndex != -1) {
        if (currentIndex < stationIds.length - 1) {
          connectedStations.add(stationIds[currentIndex + 1]);
        }
      }
    }

    for (String stationId in connectedStations) {
      _controllers[stationId] = TextEditingController(
        text: widget.currentDistances[stationId]?.toString() ?? '',
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _nameController.dispose(); // Dispose name controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Station Details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Added station name field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Station Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a station name';
                    }
                    return null;
                  },
                ),
              ),
              // Distance fields
              ..._controllers.isEmpty
                  ? [const Text('No connected stations found')]
                  : _controllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: 'To ${entry.key} (km)',
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
            ],
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
              widget.onSave(
                _nameController.text,
                distances,
              ); // Pass name and distances
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
