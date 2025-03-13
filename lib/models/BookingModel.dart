import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String trainId;
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final String passengerName; // Changed from List<String> to String
  final String bookingDate;
  final String status;
  final double price;
  final String? cancelledAt;

  Booking({
    required this.id,
    required this.userId,
    required this.trainId,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.passengerName, // Updated
    required this.bookingDate,
    required this.status,
    required this.price,
    this.cancelledAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      trainId: data['trainId'] ?? '',
      departureCity: data['departureCity'] ?? '',
      arrivalCity: data['arrivalCity'] ?? '',
      departureTime: data['departureTime'] ?? '',
      arrivalTime: data['arrivalTime'] ?? '',
      departureDate: data['departureDate'] ?? '',
      arrivalDate: data['arrivalDate'] ?? '',
      passengerName: data['passengerName'] ?? '', // Updated
      bookingDate: data['bookingDate'] ?? '',
      status: data['status'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      cancelledAt: data['cancelledAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'trainId': trainId,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'departureDate': departureDate,
      'arrivalDate': arrivalDate,
      'passengerName': passengerName, // Updated
      'bookingDate': bookingDate,
      'status': status,
      'price': price,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
    };
  }
}
