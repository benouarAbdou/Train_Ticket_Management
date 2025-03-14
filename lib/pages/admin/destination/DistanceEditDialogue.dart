import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    // Fetch all routes from Firestore
    final routesSnapshot = await _firestore.collection('routes').get();
    Set<String> connectedStations = {};

    // Iterate through each route to find connected stations
    for (var routeDoc in routesSnapshot.docs) {
      final routeData = routeDoc.data();
      final stationIds = List<String>.from(routeData['stationIds']);

      // Find the index of the current station in the route
      int currentIndex = stationIds.indexOf(widget.stationName);
      if (currentIndex != -1) {
        // Add the next station (if it exists)
        if (currentIndex < stationIds.length - 1) {
          connectedStations.add(stationIds[currentIndex + 1]);
        }
      }
    }

    // Initialize controllers for connected stations only
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
                _controllers.isEmpty
                    ? [const Text('No connected stations found')]
                    : _controllers.entries.map((entry) {
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
