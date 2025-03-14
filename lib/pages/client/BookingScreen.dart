import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/NotificationsService.dart';

class BookingScreen extends StatefulWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final double price;
  final int seatsLeft;
  final int numberOfPassengers;
  final String trainId;

  const BookingScreen({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.price,
    required this.seatsLeft,
    required this.numberOfPassengers,
    required this.trainId,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<TextEditingController> nameControllers = [TextEditingController()];
  TextEditingController passengersController = TextEditingController();

  final FirebaseController firebaseController = Get.find<FirebaseController>();
  final HiveController hiveController = Get.find<HiveController>();

  late int numberOfPassengers;

  @override
  void initState() {
    super.initState();
    numberOfPassengers = widget.numberOfPassengers;
    nameControllers = List.generate(
      numberOfPassengers,
      (index) => TextEditingController(),
    );
    passengersController.text = numberOfPassengers.toString();
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    passengersController.dispose();
    super.dispose();
  }

  void updatePassengerFields(int value) {
    setState(() {
      numberOfPassengers = value;
      if (nameControllers.length < value) {
        nameControllers.addAll(
          List.generate(
            value - nameControllers.length,
            (index) => TextEditingController(),
          ),
        );
      } else if (nameControllers.length > value) {
        nameControllers.removeRange(value, nameControllers.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Your Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.departureCity} → ${widget.arrivalCity}',
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
                      widget.departureTime,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge!.copyWith(color: TColors.primary),
                    ),
                    Text(
                      widget.departureDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.arrivalTime,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge!.copyWith(color: TColors.primary),
                    ),
                    Text(
                      widget.arrivalDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passengersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Passengers',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                int? parsedValue = int.tryParse(value);
                if (parsedValue != null &&
                    parsedValue > 0 &&
                    parsedValue <= widget.seatsLeft) {
                  updatePassengerFields(parsedValue);
                }
              },
            ),
            const SizedBox(height: 16.0),
            ...List.generate(
              numberOfPassengers,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: nameControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Passenger ${index + 1} Full Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Price per ticket: \$${widget.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Total: \$${(widget.price * numberOfPassengers).toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: TColors.primary),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  print("Button pressed");

                  String userId = await hiveController.getUserId();
                  List<String> passengerNames =
                      nameControllers
                          .map((controller) => controller.text.trim())
                          .toList();

                  if (passengerNames.any((name) => name.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all passenger names'),
                      ),
                    );
                    return;
                  }

                  try {
                    // List to store all booking results
                    List<bool> bookingResults = [];
                    List<Map<String, dynamic>> bookingDataList = [];

                    // Create individual bookings for each passenger
                    for (int i = 0; i < numberOfPassengers; i++) {
                      Map<String, dynamic> bookingData = {
                        'trainId': widget.trainId,
                        'departureCity': widget.departureCity,
                        'arrivalCity': widget.arrivalCity,
                        'departureTime': widget.departureTime,
                        'arrivalTime': widget.arrivalTime,
                        'departureDate': widget.departureDate,
                        'arrivalDate': widget.arrivalDate,
                        'passengers': 1, // Each booking is for one passenger
                        'userId': userId,
                        'passengerNames': [
                          passengerNames[i],
                        ], // Single passenger name
                        'price': widget.price,
                        'timestamp': DateTime.now().toIso8601String(),
                        'status': 'pending',
                      };

                      bool result = await firebaseController.bookTicket(
                        trainId: bookingData['trainId'],
                        departureCity: bookingData['departureCity'],
                        arrivalCity: bookingData['arrivalCity'],
                        passengers: 1, // One passenger per booking
                        userId: bookingData['userId'],
                        passengerNames: [passengerNames[i]],
                        departureTime: bookingData['departureTime'],
                        arrivalTime: bookingData['arrivalTime'],
                        departureDate: bookingData['departureDate'],
                        arrivalDate: bookingData['arrivalDate'],
                      );

                      bookingResults.add(result);
                      bookingData['status'] = result ? 'confirmed' : 'failed';
                      bookingDataList.add(bookingData);
                    }

                    // Save all bookings locally
                    for (var bookingData in bookingDataList) {
                      await hiveController.saveBookingLocally(bookingData);
                    }

                    if (bookingResults.every((result) => result)) {
                      final NotificationService notificationService =
                          Get.find<NotificationService>();

                      // Schedule notification for the trip
                      await notificationService.scheduleTicketNotification(
                        trainId: widget.trainId,
                        departureCity: widget.departureCity,
                        arrivalCity: widget.arrivalCity,
                        departureTime: widget.departureTime,
                        departureDate: widget.departureDate,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All bookings confirmed!'),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Some bookings failed. Please check your bookings',
                          ),
                        ),
                      );
                    }

                    print('Booking results: $bookingResults');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error booking tickets: $e')),
                    );
                    print('Booking error: $e');
                  }
                },

                child: const Text(
                  'Book Now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
