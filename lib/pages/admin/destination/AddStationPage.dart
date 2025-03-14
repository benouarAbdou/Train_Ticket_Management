import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';

class AddStationPage extends StatefulWidget {
  final RxList<String> selectedStations;

  const AddStationPage({super.key, required this.selectedStations});

  @override
  State<AddStationPage> createState() => _AddStationPageState();
}

class _AddStationPageState extends State<AddStationPage> {
  final FirebaseAdminController adminController =
      Get.find<FirebaseAdminController>();
  late Future<QuerySnapshot> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = adminController.firestore.collection('stations').get();
  }

  void _refreshStations() {
    setState(() {
      _stationsFuture = adminController.firestore.collection('stations').get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Station')),
      body: FutureBuilder<QuerySnapshot>(
        future: _stationsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No stations available'));
          }

          final stations = snapshot.data!.docs;
          final availableStations =
              stations
                  .where(
                    (station) =>
                        !widget.selectedStations.contains(station['name']),
                  )
                  .toList();

          return ListView.builder(
            itemCount: availableStations.length,
            itemBuilder: (context, index) {
              final station = availableStations[index];
              return ListTile(
                title: Text(station['name']),
                onTap: () {
                  widget.selectedStations.add(station['name']);
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
