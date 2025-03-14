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

  // Create dummy data for testing with Algerian wilayas
  Future<void> createDummyData() async {
    try {
      // Define Algerian wilayas with approximate distances
      final Map<String, Map<String, int>> wilayasData = {
        'Algiers': {'Blida': 50, 'Tipaza': 70, 'Boumerdes': 40},
        'Blida': {'Algiers': 50, 'Medea': 70},
        'Tipaza': {'Algiers': 70, 'Ain Defla': 90},
        'Boumerdes': {'Algiers': 40, 'Tizi Ouzou': 60},
        'Medea': {'Blida': 70, 'Djelfa': 120},
        'Ain Defla': {'Tipaza': 90, 'Chlef': 110},
        'Tizi Ouzou': {'Boumerdes': 60, 'Bejaia': 100},
        'Djelfa': {'Medea': 120, 'Laghouat': 100},
        'Chlef': {'Ain Defla': 110, 'Mostaganem': 150},
        'Bejaia': {'Tizi Ouzou': 100, 'Jijel': 90},
      };

      // Add wilayas as stations
      for (var entry in wilayasData.entries) {
        await _firestore.collection('stations').doc(entry.key).set({
          'name': entry.key,
          'isActive': true,
          'distances': entry.value,
        });
      }

      // Define routes based on geographical proximity
      final List<Map<String, dynamic>> routes = [
        {
          'name': 'Central Line',
          'stationIds': ['Algiers', 'Blida', 'Medea', 'Djelfa'],
        },
        {
          'name': 'Coastal Line',
          'stationIds': ['Algiers', 'Tipaza', 'Ain Defla', 'Chlef'],
        },
        {
          'name': 'Kabylie Line',
          'stationIds': ['Algiers', 'Boumerdes', 'Tizi Ouzou', 'Bejaia'],
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

        // Create a small number of trains for each route
        final DateTime now = DateTime.now();
        for (int day = 0; day < 5; day++) {
          // Only 5 days for simplicity
          final DateTime trainDate = now.add(Duration(days: day));
          final String formattedDate =
              "${trainDate.year}-${trainDate.month.toString().padLeft(2, '0')}-${trainDate.day.toString().padLeft(2, '0')}";

          // 1 train per day
          final int trainsPerDay = 1;
          for (int t = 0; t < trainsPerDay; t++) {
            final Map<String, String> schedule = {};
            int departureHour = 6 + Random().nextInt(10); // Random start time
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
                    wilayasData[station]![nextStation]! ~/
                    2; // Rough travel time estimate
              }
            }

            await _firestore.collection('trains').add({
              'routeId': routeRef.id,
              'date': formattedDate,
              'schedule': schedule,
              'seatsTotal': 50, // Smaller number of seats
              'seatsLeft': 50,
              'pricePerPassenger': 30.0 + Random().nextDouble() * 50,
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
