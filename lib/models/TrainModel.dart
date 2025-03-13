import 'package:cloud_firestore/cloud_firestore.dart';

// Train Model
class Train {
  final String id;
  final String routeId;
  final String date;
  final int seatsLeft;
  final double pricePerPassenger;
  final bool isActive;
  final Map<String, dynamic> schedule;

  Train({
    required this.id,
    required this.routeId,
    required this.date,
    required this.seatsLeft,
    required this.pricePerPassenger,
    required this.isActive,
    required this.schedule,
  });

  factory Train.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Train(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      date: data['date'] ?? '',
      seatsLeft: data['seatsLeft'] ?? 0,
      pricePerPassenger: (data['pricePerPassenger'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] ?? false,
      schedule: data['schedule'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'date': date,
      'seatsLeft': seatsLeft,
      'pricePerPassenger': pricePerPassenger,
      'isActive': isActive,
      'schedule': schedule,
    };
  }
}
