import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/pages/TicketDetailsScreen.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/ConnectivityService.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class BookedTicketsScreen extends StatelessWidget {
  final FirebaseController firebaseController = Get.find();
  final HiveController hiveController = Get.find();
  final ConnectivityService connectivityService = Get.find();

  BookedTicketsScreen({super.key});

  Future<List<Map<String, dynamic>>> _getTickets(String userId) async {
    try {
      final isOnline = await connectivityService.checkConnectivity();
      List<Map<String, dynamic>> tickets;

      if (isOnline) {
        // Online: Get tickets from Firebase and update local storage
        tickets = await firebaseController.readBookedTickets(userId);
        // Update local storage with the latest data
        for (var ticket in tickets) {
          await hiveController.saveBookingLocally(ticket);
        }
      } else {
        // Offline: Get tickets from local storage
        tickets = await hiveController.getLocalBookings();
      }

      return tickets;
    } catch (e) {
      print('Error getting tickets: $e');
      // Fallback to local storage if there's an error
      return await hiveController.getLocalBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = hiveController.getUserIdSync();

    return Scaffold(
      backgroundColor: TColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: TSizes.appBarHeight / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Tickets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          connectivityService.isOnline.value
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connectivityService.isOnline.value
                              ? Icons.wifi
                              : Icons.wifi_off,
                          size: 16,
                          color:
                              connectivityService.isOnline.value
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          connectivityService.isOnline.value
                              ? 'Online'
                              : 'Offline',
                          style: TextStyle(
                            color:
                                connectivityService.isOnline.value
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Force refresh the tickets
                  await _getTickets(userId);
                },
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getTickets(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),
                            ElevatedButton(
                              onPressed: () {
                                // Retry loading tickets
                                _getTickets(userId);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),
                            const Text(
                              'No tickets found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final bookings = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(0),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return TrainTicket(
                          departureCity: booking['departureCity'] ?? 'Unknown',
                          arrivalCity: booking['arrivalCity'] ?? 'Unknown',
                          departureTime: booking['departureTime'] ?? 'Not set',
                          arrivalTime: booking['arrivalTime'] ?? 'Not set',
                          departureDate: booking['departureDate'] ?? 'Not set',
                          arrivalDate: booking['arrivalDate'] ?? 'Not set',
                          price: booking['price']?.toDouble() ?? 0.0,
                          numberOfPassengers:
                              booking['numberOfPassengers'] ?? 1,
                          status: booking['status'] ?? 'Unknown',
                          onTap: () {
                            Get.to(
                              () => TicketDetailsScreen(
                                departureCity:
                                    booking['departureCity'] ?? 'Unknown',
                                arrivalCity:
                                    booking['arrivalCity'] ?? 'Unknown',
                                departureTime:
                                    booking['departureTime'] ?? 'Not set',
                                arrivalTime:
                                    booking['arrivalTime'] ?? 'Not set',
                                departureDate:
                                    booking['departureDate'] ?? 'Not set',
                                arrivalDate:
                                    booking['arrivalDate'] ?? 'Not set',
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
            ),
          ],
        ),
      ),
    );
  }
}
