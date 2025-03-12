import 'package:flutter/material.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';

class TrainTicket extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final int seatsLeft;

  const TrainTicket({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.seatsLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge!.copyWith(color: TColors.primary),
                    ),
                    Text(
                      arrivalCity,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge!.copyWith(color: TColors.primary),
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
                    const Center(child: Icon(Icons.train)),
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
          // Seats Left Indicator at Top-Right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.lg,
                vertical: TSizes.xs,
              ),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(TSizes.borderRadiusMd),
                  topRight: Radius.circular(TSizes.borderRadiusLg),
                ),
              ),
              child: Text(
                '$seatsLeft Seats Left',
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
    );
  }
}
