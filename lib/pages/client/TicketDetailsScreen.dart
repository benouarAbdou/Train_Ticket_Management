import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date parsing
import 'package:share_plus/share_plus.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/PdfServices.dart';

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
  final String passengerId;

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
    required this.passengerId,
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

  // Helper method to check if ticket is expired
  bool _isTicketExpired() {
    try {
      // Get the current date and time
      final currentDateTime = DateTime.now();

      // Parse the arrival date and time
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      final departureDateTime = dateFormat.parse(
        '$departureDate $departureTime',
      );

      // Compare arrival time with the current time
      return departureDateTime.isBefore(currentDateTime);
    } catch (e) {
      return false; // Assume not expired if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _isTicketExpired();
    final displayStatus = isExpired ? 'Expired' : (status ?? 'Unknown');

    return Scaffold(
      backgroundColor: TColors.bg,
      appBar: AppBar(title: const Text('Boarding Pass')),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: TSizes.defaultSpace,
              horizontal: TSizes.defaultSpace,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: TSizes.lg,
                  ), // Space for status container
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: TSizes.spaceBtwItems),
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
                                departureTime.isNotEmpty
                                    ? departureTime
                                    : 'Not set',
                                style: Theme.of(context).textTheme.titleLarge!
                                    .copyWith(color: TColors.primary),
                              ),
                              Text(
                                departureDate.isNotEmpty
                                    ? departureDate
                                    : 'Not set',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                arrivalTime.isNotEmpty
                                    ? arrivalTime
                                    : 'Not set',
                                style: Theme.of(context).textTheme.titleLarge!
                                    .copyWith(color: TColors.primary),
                              ),
                              Text(
                                arrivalDate.isNotEmpty
                                    ? arrivalDate
                                    : 'Not set',
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
                      Text(
                        passengerId,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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
                      if (passengerNames != null &&
                          passengerNames!.isNotEmpty) ...[
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
                      Text(
                        'Price',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(color: TColors.primary),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _shareTicket,
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
                              child: const Text('Download PDF'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status container at top-right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.lg,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red : TColors.black,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(TSizes.borderRadiusMd),
                        topRight: Radius.circular(TSizes.borderRadiusLg),
                      ),
                    ),
                    child: Text(
                      displayStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: TSizes.fontSizeSm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
