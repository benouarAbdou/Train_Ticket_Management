import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/pages/TicketDetailsScreen.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class BookedTicketsScreen extends StatelessWidget {
  final FirebaseController firebaseController = Get.find();

  BookedTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = Get.find<HiveController>().getUserIdSync();

    return Scaffold(
      backgroundColor: TColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: TSizes.appBarHeight / 2),
            const Text(
              'My Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            Expanded(
              // Add this to constrain the FutureBuilder/ListView
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: firebaseController.readBookedTickets(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No booked tickets found'));
                  }

                  final bookings = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      print('Booking $index: $booking'); // Debug print
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
                        onTap: () {
                          Get.to(
                            () => TicketDetailsScreen(
                              departureCity:
                                  booking['departureCity'] ?? 'Unknown',
                              arrivalCity: booking['arrivalCity'] ?? 'Unknown',
                              departureTime:
                                  booking['departureTime'] ?? 'Not set',
                              arrivalTime: booking['arrivalTime'] ?? 'Not set',
                              departureDate:
                                  booking['departureDate'] ?? 'Not set',
                              arrivalDate: booking['arrivalDate'] ?? 'Not set',
                              price: booking['price']?.toDouble() ?? 0.0,
                              passengerNames:
                                  booking['passengerNames']?.cast<String>(),
                              numberOfPassengers:
                                  booking['numberOfPassengers'] ?? 1,
                              ticketId: booking["id"],
                              passengerId: booking['passengerId'],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
