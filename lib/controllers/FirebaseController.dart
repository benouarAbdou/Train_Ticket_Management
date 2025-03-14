import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final Rx<User?> user = Rx<User?>(null);
  final RxList<Map<String, dynamic>> trainRoutes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<String> stations = <String>[].obs; // Added stations cache

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? currentUser) {
      user.value = currentUser;
    });
    _loadStations(); // Load stations when controller initializes
  }

  String generateRandomUuid() {
    final Uuid uuid = Uuid();
    return uuid.v4();
  }

  // New method to load stations
  Future<void> _loadStations() async {
    if (stations.isEmpty) {
      try {
        QuerySnapshot snapshot = await _firestore.collection('stations').get();
        stations.value = snapshot.docs.map((doc) => doc.id).toList();
      } catch (e) {
      }
    }
  }

  // Public method to get stations (can be called if needed)
  Future<List<String>> getStations() async {
    if (stations.isEmpty) {
      await _loadStations();
    }
    return stations.toList();
  }

  // Authentication methods
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true;
  }

  // Train search methods (Updated for new structure)
  Future<void> searchTrains({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
    required int passengers,
  }) async {
    isLoading.value = true;
    searchResults.clear();

    try {
      final String formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final QuerySnapshot routeSnapshot =
          await _firestore
              .collection('routes')
              .where('stationIds', arrayContains: departureCity)
              .where('isActive', isEqualTo: true)
              .get();

      for (var routeDoc in routeSnapshot.docs) {
        final routeData = routeDoc.data() as Map<String, dynamic>;
        final List<dynamic> stationIds = routeData['stationIds'];

        final int departureIndex = stationIds.indexOf(departureCity);
        final int arrivalIndex = stationIds.indexOf(arrivalCity);

        if (departureIndex != -1 &&
            arrivalIndex != -1 &&
            departureIndex < arrivalIndex) {
          final QuerySnapshot trainSnapshot =
              await _firestore
                  .collection('trains')
                  .where('routeId', isEqualTo: routeDoc.id)
                  .where('date', isEqualTo: formattedDate)
                  .where('seatsLeft', isGreaterThanOrEqualTo: passengers)
                  .where('isActive', isEqualTo: true)
                  .get();

          for (var trainDoc in trainSnapshot.docs) {
            final trainData = trainDoc.data() as Map<String, dynamic>;
            final schedule = trainData['schedule'] as Map<String, dynamic>;

            if (schedule.containsKey(departureCity) &&
                schedule.containsKey(arrivalCity)) {
              searchResults.add({
                'id': trainDoc.id,
                'departureCity': departureCity,
                'arrivalCity': arrivalCity,
                'departureTime': schedule[departureCity],
                'arrivalTime': schedule[arrivalCity],
                'departureDate': formattedDate,
                'arrivalDate': formattedDate,
                'seatsLeft': trainData['seatsLeft'],
                'price': trainData['pricePerPassenger'],
              });
            }
          }
        }
      }

      searchResults.sort(
        (a, b) => a['departureTime'].compareTo(b['departureTime']),
      );
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  // Booking methods remain unchanged
  Future<bool> bookTicket({
    required String trainId,
    required String departureCity,
    required String arrivalCity,
    required int passengers,
    required String userId,
    required String departureTime,
    required String arrivalTime,
    required String departureDate,
    required String arrivalDate,
    required List<String> passengerNames,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentReference trainRef = _firestore
            .collection('trains')
            .doc(trainId);
        DocumentSnapshot trainSnapshot = await transaction.get(trainRef);

        if (!trainSnapshot.exists ||
            !(trainSnapshot.data() as Map<String, dynamic>)['isActive']) {
          return false;
        }

        final trainData = trainSnapshot.data() as Map<String, dynamic>;
        final int seatsLeft = trainData['seatsLeft'];

        if (seatsLeft < 1) {
          return false;
        }

        if (passengerNames.length != 1) {
          return false;
        }

        transaction.update(trainRef, {'seatsLeft': seatsLeft - 1});

        String passengerId = generateRandomUuid();

        DocumentReference bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          'userId': userId,
          'trainId': trainId,
          'departureCity': departureCity,
          'arrivalCity': arrivalCity,
          'departureTime': departureTime,
          'arrivalTime': arrivalTime,
          'departureDate': departureDate,
          'arrivalDate': arrivalDate,
          'passengerId': passengerId,
          'passengerNames': passengerNames,
          'bookingDate': DateTime.now().toIso8601String(),
          'status': 'confirmed',
          'price': trainData['pricePerPassenger'],
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> readBookedTickets(String userId) async {
    try {
      QuerySnapshot bookingSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .get();

      List<Map<String, dynamic>> bookings = [];

      for (var doc in bookingSnapshot.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;

        bookings.add({
          'departureCity': bookingData['departureCity'],
          'arrivalCity': bookingData['arrivalCity'],
          'departureTime': bookingData['departureTime'],
          'arrivalTime': bookingData['arrivalTime'],
          'departureDate': bookingData['departureDate'],
          'arrivalDate': bookingData['arrivalDate'],
          'price': bookingData['price'],
          'passengerId': bookingData['passengerId'],
          'status': bookingData['status'],
          'passengerNames': bookingData['passengerNames'],
          'id': doc.id,
        });
      }

      return bookings;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot bookingsSnapshot =
          await _firestore
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .orderBy('bookingDate', descending: true)
              .get();

      return bookingsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
