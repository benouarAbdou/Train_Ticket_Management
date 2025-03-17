import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TicketUtils {
  static void shareTicket({
    required String departureCity,
    required String arrivalCity,
    required String departureTime,
    required String arrivalTime,
    required String departureDate,
    required String arrivalDate,
    required double price,
    int? numberOfPassengers,
    String? status,
    List<String>? passengerNames,
    String? ticketId,
  }) {
    final ticketDetails = '''
From: $departureCity at $departureTime, $departureDate
To: $arrivalCity at $arrivalTime, $arrivalDate
Passengers: ${numberOfPassengers ?? 1}
Price: \$${price.toStringAsFixed(0)}
Status: ${status ?? 'Unknown'}
Passenger Names: ${passengerNames?.join(', ') ?? 'Not provided'}
Ticket ID: ${ticketId ?? 'Not provided'}
''';
    Share.share(ticketDetails, subject: 'Train Ticket Details');
  }

  static bool isTicketExpired({
    required String departureDate,
    required String departureTime,
  }) {
    try {
      final currentDateTime = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      final departureDateTime = dateFormat.parse(
        '$departureDate $departureTime',
      );
      return departureDateTime.isBefore(currentDateTime);
    } catch (e) {
      return false;
    }
  }
}
