import 'package:flutter/material.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class TicketsList extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;
  final void Function(Map<String, dynamic>) onTicketTap;

  const TicketsList({
    super.key,
    required this.tickets,
    required this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final booking = tickets[index];
        return TrainTicket(
          departureCity: booking['departureCity'] ?? 'Unknown',
          arrivalCity: booking['arrivalCity'] ?? 'Unknown',
          departureTime: booking['departureTime'] ?? 'Not set',
          arrivalTime: booking['arrivalTime'] ?? 'Not set',
          departureDate: booking['departureDate'] ?? 'Not set',
          arrivalDate: booking['arrivalDate'] ?? 'Not set',
          price: booking['price']?.toDouble() ?? 0.0,
          numberOfPassengers: booking['numberOfPassengers'] ?? 1,
          status: booking['status'] ?? 'Unknown',
          onTap: () => onTicketTap(booking),
        );
      },
    );
  }
}
