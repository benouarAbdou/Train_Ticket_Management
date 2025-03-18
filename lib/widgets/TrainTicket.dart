import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for better date parsing
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';

class TrainTicket extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime; // Expected format: "HH:MM" (e.g., "14:30")
  final String arrivalTime;
  final String
  departureDate; // Expected format: "MMM DD, YYYY" (e.g., "Mar 14, 2025")
  final String arrivalDate;
  final int? seatsLeft;
  final double price;
  final int numberOfPassengers;
  final num? distance;
  final String? status;
  final GestureTapCallback onTap;

  const TrainTicket({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    this.seatsLeft,
    required this.price,
    required this.numberOfPassengers,
    this.status,
    this.distance, // Added to constructor parameters
    required this.onTap,
  });

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: TSizes.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,

          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Column(
                children: [
                  SizedBox(height: TSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        departureCity,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: TColors.primary,
                        ),
                      ),
                      Text(
                        arrivalCity,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: TColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            departureTime,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            departureDate,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.train),
                            Text(
                              distance == null || distance == 0
                                  ? ""
                                  : "$distance km",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            arrivalTime,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            arrivalDate,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status or Seats Left Indicator at Top-Right
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
                  isExpired
                      ? 'Expired'
                      : (seatsLeft != null
                          ? '$seatsLeft Seats Left'
                          : (status ?? 'Unknown')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: TSizes.fontSizeSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.lg,
                  vertical: TSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(TSizes.borderRadiusMd),
                    topLeft: Radius.circular(TSizes.borderRadiusLg),
                  ),
                ),
                child: Text(
                  '\$${price.toStringAsFixed(0)}',
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
    );
  }
}
