import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseDummyController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables

  // Clear Firestore data
  Future<void> clearFirestoreData() async {
    try {
      final collections = ['stations', 'routes', 'trains', 'bookings'];
      for (String collection in collections) {
        final QuerySnapshot snapshot =
            await _firestore.collection(collection).get();
        final batch = _firestore.batch();
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      print('All Firestore data cleared successfully');
    } catch (e) {
      print('Error clearing Firestore data: $e');
    }
  }

  // Create dummy data for testing (Updated for new structure)
  Future<void> createDummyData() async {
    try {
      // Predefined stations with realistic distances (subset for simplicity)
      final Map<String, Map<String, int>> stationsData = {
        'New York': {'Philadelphia': 94, 'Washington': 225, 'Boston': 215},
        'Philadelphia': {'New York': 94, 'Washington': 135},
        'Washington': {'New York': 225, 'Philadelphia': 135},
        'Boston': {'New York': 215},
        'Chicago': {'Indianapolis': 183, 'Columbus': 317},
        'Indianapolis': {'Chicago': 183},
        'Columbus': {'Chicago': 317},
      };

      // Add stations
      for (var entry in stationsData.entries) {
        await _firestore.collection('stations').doc(entry.key).set({
          'name': entry.key,
          'isActive': true,
          'distances': entry.value,
        });
      }

      // Predefined routes (realistic examples)
      final List<Map<String, dynamic>> routes = [
        {
          'name': 'Northeast Corridor',
          'stationIds': ['Boston', 'New York', 'Philadelphia', 'Washington'],
        },
        {
          'name': 'Midwest Loop',
          'stationIds': ['Chicago', 'Indianapolis', 'Columbus'],
        },
      ];

      for (var route in routes) {
        final DocumentReference routeRef = await _firestore
            .collection('routes')
            .add({
              'name': route['name'],
              'stationIds': route['stationIds'],
              'isActive': true,
            });

        // Create trains for 15 days
        final DateTime now = DateTime.now();
        for (int day = 0; day < 15; day++) {
          final DateTime trainDate = now.add(Duration(days: day));
          final String formattedDate =
              "${trainDate.year}-${trainDate.month.toString().padLeft(2, '0')}-${trainDate.day.toString().padLeft(2, '0')}";

          // 1-2 trains per day
          final int trainsPerDay = 1 + Random().nextInt(2);
          for (int t = 0; t < trainsPerDay; t++) {
            final Map<String, String> schedule = {};
            int departureHour = 6 + Random().nextInt(14);
            int totalMinutes = 0;

            for (int s = 0; s < (route['stationIds'] as List).length; s++) {
              final String station = (route['stationIds'] as List)[s];
              final int hour = departureHour + (totalMinutes ~/ 60);
              final int minute = totalMinutes % 60;
              schedule[station] =
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              if (s < (route['stationIds'] as List).length - 1) {
                final nextStation = (route['stationIds'] as List)[s + 1];
                totalMinutes +=
                    stationsData[station]![nextStation]! ~/
                    2; // Rough travel time estimate
              }
            }

            await _firestore.collection('trains').add({
              'routeId': routeRef.id,
              'date': formattedDate,
              'schedule': schedule,
              'seatsTotal': 100,
              'seatsLeft': 100,
              'pricePerPassenger': 50.0 + Random().nextDouble() * 100,
              'isActive': true,
            });
          }
        }
      }

      print('Dummy data created successfully');
    } catch (e) {
      print('Error creating dummy data: $e');
    }
  }
}
