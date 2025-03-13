import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class HiveController extends GetxController {
  late Box _userBox;
  late Box _bookingBox;
  final Uuid uuid = Uuid();
  bool _isInitialized = false;

  HiveController() {
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    try {
      debugPrint('HiveController: Initializing boxes...');
      _userBox = await Hive.openBox('userBox');
      _bookingBox = await Hive.openBox('bookingBox');
      _isInitialized = true;
      debugPrint('HiveController: Boxes initialized successfully');
    } catch (e) {
      debugPrint('HiveController: Error initializing boxes: $e');
      rethrow;
    }
  }

  // Ensure initialization is complete before proceeding
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      debugPrint('HiveController: Waiting for initialization...');
      await _initBoxes();
    }
  }

  // Generate and save a unique user ID
  Future<String> getUserId() async {
    await _ensureInitialized();
    debugPrint('HiveController: Getting user ID');
    String userId = _userBox.get('userId', defaultValue: '');
    if (userId.isEmpty) {
      userId = uuid.v4();
      await _userBox.put('userId', userId);
      debugPrint('HiveController: Generated new user ID: $userId');
    } else {
      debugPrint('HiveController: Retrieved existing user ID: $userId');
    }
    return userId;
  }

  // Save a booking ticket locally
  Future<void> saveBookingLocally(Map<String, dynamic> booking) async {
    await _ensureInitialized();
    String bookingId = uuid.v4();
    booking['localId'] = bookingId;
    debugPrint('HiveController: Saving booking with ID: $bookingId');
    await _bookingBox.put(bookingId, booking);
    debugPrint('HiveController: Booking saved successfully');
  }

  // Get all locally saved bookings
  Future<List<Map<String, dynamic>>> getLocalBookings() async {
    await _ensureInitialized();
    debugPrint('HiveController: Retrieving all bookings');
    List<Map<String, dynamic>> bookings = [];
    for (var key in _bookingBox.keys) {
      var booking = _bookingBox.get(key);
      bookings.add(booking);
      debugPrint('HiveController: Found booking with key: $key');
    }
    debugPrint('HiveController: Total bookings retrieved: ${bookings.length}');
    return bookings;
  }

  // Get a specific booking by local ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    await _ensureInitialized();
    debugPrint('HiveController: Retrieving booking with ID: $bookingId');
    final booking = _bookingBox.get(bookingId);
    if (booking != null) {
      debugPrint('HiveController: Booking found');
    } else {
      debugPrint('HiveController: No booking found with ID: $bookingId');
    }
    return booking;
  }

  // In HiveController.dart
  String getUserIdSync() {
    if (!_isInitialized) {
      throw Exception('HiveController not initialized yet');
    }
    String userId = _userBox.get('userId', defaultValue: '');
    if (userId.isEmpty) {
      userId = uuid.v4();
      _userBox.put('userId', userId);
    }
    return userId;
  }

  // Delete a booking by local ID
  Future<void> deleteBookingById(String bookingId) async {
    await _ensureInitialized();
    debugPrint('HiveController: Deleting booking with ID: $bookingId');
    await _bookingBox.delete(bookingId);
    debugPrint('HiveController: Booking deleted successfully');
  }

  @override
  void onClose() {
    debugPrint('HiveController: Closing controller and boxes');
    _userBox.close();
    _bookingBox.close();
    super.onClose();
  }
}
