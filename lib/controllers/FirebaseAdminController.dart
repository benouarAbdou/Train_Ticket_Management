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
}
