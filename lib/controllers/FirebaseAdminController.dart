import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:train_app/controllers/HiveController.dart';

class FirebaseAdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool isAdminLoggedIn = false.obs;
  final HiveController hiveController = Get.find<HiveController>();

  @override
  void onInit() {
    super.onInit();
    _loadInitialLoginStatus();
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Assuming custom claims are used for admin status
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true;
  }

  Future<void> _loadInitialLoginStatus() async {
    isAdminLoggedIn.value = await hiveController.getAdminLoginStatus();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      await hiveController.saveAdminLoginStatus(true);
      isAdminLoggedIn.value = true;
      return userCredential;
    } catch (e) {
      throw 'Failed to sign in: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await hiveController.saveAdminLoginStatus(false);
    isAdminLoggedIn.value = false;
  }

  // Modified verifyTicket with arguments
  Future<Map<String, dynamic>?> verifyTicket({
    required String ticketId,
    required Function(String) onError,
    required Function(bool) onLoading,
  }) async {
    if (ticketId.isEmpty) {
      onError('Please enter a ticket ID');
      return null;
    }

    onLoading(true);

    try {
      final DocumentSnapshot ticket =
          await _firestore.collection('bookings').doc(ticketId.trim()).get();

      if (!ticket.exists) {
        throw Exception('Ticket not found');
      }

      return ticket.data() as Map<String, dynamic>;
    } catch (e) {
      onError(e.toString());
      return null;
    } finally {
      onLoading(false);
    }
  }

  // New markTicketAsUsed function
  Future<void> markTicketAsUsed({
    required String ticketId,
    required Function(String) onError,
    required Function(bool) onLoading,
    required Function(String) onSuccess,
  }) async {
    onLoading(true);

    try {
      final ticketRef = _firestore.collection('bookings').doc(ticketId.trim());
      final ticketSnapshot = await ticketRef.get();

      if (!ticketSnapshot.exists) {
        throw Exception('Ticket not found');
      }

      final ticketData = ticketSnapshot.data() as Map<String, dynamic>;
      if (ticketData['status'] == 'used') {
        throw Exception('Ticket already marked as used');
      }

      await ticketRef.update({
        'status': 'used',
        'usedAt': DateTime.now().toIso8601String(),
        'verifiedBy': _firestore
            .collection('admins')
            .doc(_auth.currentUser?.uid),
      });

      onSuccess('Ticket marked as used');
    } catch (e) {
      onError('Error marking ticket as used: ${e.toString()}');
    } finally {
      onLoading(false);
    }
  }
}
