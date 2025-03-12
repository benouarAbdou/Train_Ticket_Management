import 'package:flutter/material.dart';
import 'dart:math';

import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';

class TicketDetailsScreen extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final int price;

  const TicketDetailsScreen({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.price,
  });

  // Generate a random passenger ID (e.g., 6-digit number)
  String _generatePassengerId() {
    final random = Random();
    return 'P${random.nextInt(900000) + 100000}'; // Generates P100000 to P999999
  }

  // Generate ticket number with "TRA" prefix
  String _generateTicketNumber() {
    final random = Random();
    return 'TRA${random.nextInt(900000) + 100000}'; // Generates TRA100000 to TRA999999
  }

  @override
  Widget build(BuildContext context) {
    final passengerId = _generatePassengerId();
    final ticketNumber = _generateTicketNumber();

    return Scaffold(
      backgroundColor: TColors.bg,
      appBar: AppBar(title: const Text('Boarding Pass')),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '$departureCity → $arrivalCity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departureTime,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: TColors.primary,
                        ),
                      ),
                      Text(
                        departureDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        arrivalTime,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: TColors.primary,
                        ),
                      ),
                      Text(
                        arrivalDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Passenger Details
              Text('Passenger', style: Theme.of(context).textTheme.bodyMedium),
              Text('1 Adult', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8.0),
              Text(
                'Passenger ID',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(passengerId, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8.0),

              Text(
                'Ticket Number',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(ticketNumber, style: Theme.of(context).textTheme.bodyLarge),

              // Barcode Placeholder
              const SizedBox(height: 16.0),
              // Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Download Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
