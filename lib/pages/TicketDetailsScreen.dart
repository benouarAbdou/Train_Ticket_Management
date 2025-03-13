import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:share_plus/share_plus.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/PdfServices.dart';
import '../controllers/HiveController.dart';

class TicketDetailsScreen extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final double price;
  final int? numberOfPassengers;
  final String? status;
  final List<String>? passengerNames;
  final String? ticketId;

  const TicketDetailsScreen({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.price,
    this.numberOfPassengers,
    this.status,
    this.passengerNames,
    this.ticketId,
  });

  // Share ticket details
  void _shareTicket() {
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

  // Generate and view PDF

  @override
  Widget build(BuildContext context) {
    String userId = Get.find<HiveController>().getUserIdSync();

    return Scaffold(
      backgroundColor: TColors.bg,
      appBar: AppBar(title: const Text('Boarding Pass')),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: TSizes.defaultSpace * 2,
              horizontal: TSizes.defaultSpace,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$departureCity → $arrivalCity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureTime.isNotEmpty ? departureTime : 'Not set',
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(color: TColors.primary),
                        ),
                        Text(
                          departureDate.isNotEmpty ? departureDate : 'Not set',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrivalTime.isNotEmpty ? arrivalTime : 'Not set',
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(color: TColors.primary),
                        ),
                        Text(
                          arrivalDate.isNotEmpty ? arrivalDate : 'Not set',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.md),
                Text(
                  'Ticket Number',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  ticketId ?? "",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: TSizes.sm),
                Text(
                  'Passenger ID',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(userId, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: TSizes.sm),
                Text(
                  'Passengers',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${numberOfPassengers ?? 1} Adult${(numberOfPassengers ?? 1) > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: TSizes.sm),
                if (passengerNames != null && passengerNames!.isNotEmpty) ...[
                  Text(
                    'Passenger Names',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    passengerNames!.join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: TSizes.sm),
                ],
                Text('Price', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: TColors.primary),
                ),
                const SizedBox(height: TSizes.sm),
                if (status != null) ...[
                  Text('Status', style: Theme.of(context).textTheme.bodyMedium),
                  Text(status!, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: TSizes.sm),
                ],
                SizedBox(height: TSizes.spaceBtwItems),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _shareTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Share Ticket'),
                      ),
                    ),
                    const SizedBox(width: TSizes.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            () => generateAndOpenTicketPdf(
                              context: context,
                              departureCity: departureCity,
                              arrivalCity: arrivalCity,
                              departureTime: departureTime,
                              arrivalTime: arrivalTime,
                              departureDate: departureDate,
                              arrivalDate: arrivalDate,
                              price: price,
                              numberOfPassengers: numberOfPassengers,
                              status: status,
                              passengerNames: passengerNames,
                              ticketId: ticketId,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Download PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
