import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Add this to pubspec.yaml: crypto: ^3.0.3

class HiveController extends GetxController {
  late Box _userBox;
  late Box _bookingBox;
  final Uuid uuid = Uuid();
  bool _isInitialized = false;

  // Local secret key (generated once and stored)
  static const String _secretKeyField = 'adminSecretKey';
  static const String _adminHashField = 'adminHash';

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
      // Ensure secret key exists
      await _ensureSecretKey();
    } catch (e) {
      debugPrint('HiveController: Error initializing boxes: $e');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      debugPrint('HiveController: Waiting for initialization...');
      await _initBoxes();
    }
  }

  // Generate or retrieve a secret key for admin status verification
  Future<String> _getSecretKey() async {
    String secretKey = _userBox.get(_secretKeyField, defaultValue: '');
    if (secretKey.isEmpty) {
      secretKey = uuid.v4(); // Generate a unique secret key
      await _userBox.put(_secretKeyField, secretKey);
    }
    return secretKey;
  }

  Future<void> _ensureSecretKey() async {
    await _getSecretKey();
  }

  // Generate a secure hash for admin status
  String _generateAdminHash(bool isLoggedIn, String secretKey) {
    final data = '$isLoggedIn|$secretKey';
    return sha256.convert(utf8.encode(data)).toString();
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

  // Save admin login status with secure hash
  Future<void> saveAdminLoginStatus(bool isLoggedIn) async {
    await _ensureInitialized();
    debugPrint('HiveController: Saving admin login status: $isLoggedIn');

    final secretKey = await _getSecretKey();
    final adminHash = _generateAdminHash(isLoggedIn, secretKey);

    // Store both the status and its hash
    await _userBox.put('isAdminLoggedIn', isLoggedIn);
    await _userBox.put(_adminHashField, adminHash);
  }

  // Get admin login status with verification
  Future<bool> getAdminLoginStatus() async {
    await _ensureInitialized();
    final isLoggedIn = _userBox.get('isAdminLoggedIn', defaultValue: false);
    final storedHash = _userBox.get(_adminHashField, defaultValue: '');
    final secretKey = await _getSecretKey();
    final expectedHash = _generateAdminHash(isLoggedIn, secretKey);

    // Verify the hash matches
    if (storedHash != expectedHash) {
      debugPrint('HiveController: Admin status tampered! Resetting to false');
      await saveAdminLoginStatus(false); // Reset if tampered
      return false;
    }

    debugPrint('HiveController: Retrieved admin login status: $isLoggedIn');
    return isLoggedIn;
  }

  // Save a booking ticket locally
  Future<void> saveBookingLocally(Map<String, dynamic> booking) async {
    await _ensureInitialized();
    final String bookingId = booking['id'] ?? '';
    if (bookingId.isEmpty) {
      debugPrint(
        'HiveController: Warning - Attempting to save booking without ID',
      );
      return;
    }
    debugPrint('HiveController: Saving booking with ID: $bookingId');
    try {
      await _bookingBox.put(bookingId, booking);
      debugPrint('HiveController: Booking saved successfully');
    } catch (e) {
      debugPrint('HiveController: Error saving booking - $e');
      rethrow;
    }
  }

  // Get all locally saved bookings
  Future<List<Map<String, dynamic>>> getLocalBookings() async {
    await _ensureInitialized();
    try {
      return _bookingBox.values
          .map((booking) => Map<String, dynamic>.from(booking))
          .toList();
    } catch (e) {
      debugPrint('HiveController: Error getting local bookings - $e');
      return [];
    }
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
