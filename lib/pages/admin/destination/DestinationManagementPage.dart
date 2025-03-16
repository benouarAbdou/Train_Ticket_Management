import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/admin/destination/DistanceEditDialogue.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_app/widgets/admin/StationListTile.dart';

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
  late Future<QuerySnapshot> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = FirebaseFirestore.instance.collection('stations').get();
  }

  @override
  void dispose() {
    _stationNameController.dispose();
    super.dispose();
  }

  void _refreshStations() {
    setState(() {
      _stationsFuture = FirebaseFirestore.instance.collection('stations').get();
    });
  }

  Future<void> _addNewStation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _adminController.addStation(
        _stationNameController.text.trim(),
        {}, // Empty distances map initially
      );
      _stationNameController.clear();
      _refreshStations(); // Refresh the list after adding
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
            onSave: (String updatedName, Map<String, int> distances) async {
              try {
                await _adminController.editStation(
                  stationName,
                  newName: updatedName,
                  distances: distances,
                );
                _refreshStations(); // Refresh the list after editing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Station updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating station: ${e.toString()}'),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Stations Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              // Add New Station Form
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                      ),
                      onPressed: _addNewStation,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems), // Add some spacing
              // Stations List
              FutureBuilder<QuerySnapshot>(
                future: _stationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No stations found'));
                  }

                  return SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                        0.6, // Adjust height as needed
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
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
                            _refreshStations(); // Refresh after toggling
                          },
                          onEditDistances: () {
                            _showDistanceDialog(
                              station.id,
                              data['distances'] as Map<String, dynamic>,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
