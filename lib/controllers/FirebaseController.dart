import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final Rx<User?> user = Rx<User?>(null);
  final RxList<Map<String, dynamic>> trainRoutes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? currentUser) {
      user.value = currentUser;
    });
  }

  // Authentication methods
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Assuming custom claims are used for admin status
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

      // Query active routes with departureCity in stationIds
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
      print('Error searching trains: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Booking methods (Updated for new structure)
  Future<bool> bookTicket({
    required String trainId,
    required String departureCity,
    required String arrivalCity,
    required int passengers,
    required String userId,
    required List<String> passengerNames,
  }) async {
    try {
      print("Starting booking process"); // Debugging print
      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentReference trainRef = _firestore
            .collection('trains')
            .doc(trainId);
        DocumentSnapshot trainSnapshot = await transaction.get(trainRef);

        if (!trainSnapshot.exists ||
            !(trainSnapshot.data() as Map<String, dynamic>)['isActive']) {
          print("Train does not exist or is not active"); // Debugging print
          return false;
        }

        final trainData = trainSnapshot.data() as Map<String, dynamic>;
        final int seatsLeft = trainData['seatsLeft'];

        if (seatsLeft < passengers) {
          print("Not enough seats left"); // Debugging print
          return false;
        }

        if (passengerNames.length != passengers) {
          print(
            "Passenger names do not match the number of passengers",
          ); // Debugging print
          return false;
        }

        transaction.update(trainRef, {'seatsLeft': seatsLeft - passengers});

        DocumentReference bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          'userId': userId,
          'trainId': trainId,
          'departureCity': departureCity,
          'arrivalCity': arrivalCity,
          'passengers': passengers,
          'passengerNames': passengerNames,
          'bookingDate': DateTime.now().toIso8601String(),
          'status': 'confirmed',
          'price': trainData['pricePerPassenger'] * passengers,
        });

        print('Booking successful'); // Debugging print
        return true;
      });
    } catch (e) {
      print('Error booking ticket: $e'); // Debugging print
      return false;
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
      print('Error getting user bookings: $e');
      return [];
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentReference bookingRef = _firestore
            .collection('bookings')
            .doc(bookingId);
        DocumentSnapshot bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) return false;

        final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
        if (bookingData['status'] == 'cancelled') return false;

        DocumentReference trainRef = _firestore
            .collection('trains')
            .doc(bookingData['trainId']);
        DocumentSnapshot trainSnapshot = await transaction.get(trainRef);

        if (!trainSnapshot.exists) return false;

        final trainData = trainSnapshot.data() as Map<String, dynamic>;
        transaction.update(trainRef, {
          'seatsLeft': trainData['seatsLeft'] + bookingData['passengers'],
        });

        transaction.update(bookingRef, {
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toIso8601String(),
        });

        return true;
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Admin: Destination Management
  Future<void> addStation(String name, Map<String, int> distances) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    await _firestore.collection('stations').doc(name).set({
      'name': name,
      'isActive': true,
      'distances': distances,
    });
  }

  Future<void> editStation(
    String name, {
    Map<String, int>? distances,
    bool? isActive,
  }) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    final updates = <String, dynamic>{};
    if (distances != null) updates['distances'] = distances;
    if (isActive != null) updates['isActive'] = isActive;
    await _firestore.collection('stations').doc(name).update(updates);
  }

  Future<void> toggleStationActive(String name, bool isActive) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    await _firestore.collection('stations').doc(name).update({
      'isActive': isActive,
    });
  }

  // Admin: Train Management
  Future<void> createRoute(String name, List<String> stationIds) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    await _firestore.collection('routes').add({
      'name': name,
      'stationIds': stationIds,
      'isActive': true,
    });
  }

  Future<void> editRoute(
    String routeId, {
    List<String>? stationIds,
    bool? isActive,
  }) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    final updates = <String, dynamic>{};
    if (stationIds != null) updates['stationIds'] = stationIds;
    if (isActive != null) updates['isActive'] = isActive;
    await _firestore.collection('routes').doc(routeId).update(updates);
  }

  Future<void> createTrain({
    required String routeId,
    required String date,
    required Map<String, String> schedule,
    required int seatsTotal,
    required double pricePerPassenger,
  }) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    await _firestore.collection('trains').add({
      'routeId': routeId,
      'date': date,
      'schedule': schedule,
      'seatsTotal': seatsTotal,
      'seatsLeft': seatsTotal,
      'pricePerPassenger': pricePerPassenger,
      'isActive': true,
    });
  }

  Future<void> editTrain(
    String trainId, {
    Map<String, String>? schedule,
    int? seatsTotal,
    double? pricePerPassenger,
    bool? isActive,
  }) async {
    if (!(await isAdmin())) throw Exception('Not authorized');
    final updates = <String, dynamic>{};
    if (schedule != null) updates['schedule'] = schedule;
    if (seatsTotal != null) updates['seatsTotal'] = seatsTotal;
    if (pricePerPassenger != null)
      updates['pricePerPassenger'] = pricePerPassenger;
    if (isActive != null) updates['isActive'] = isActive;
    await _firestore.collection('trains').doc(trainId).update(updates);
  }
}
