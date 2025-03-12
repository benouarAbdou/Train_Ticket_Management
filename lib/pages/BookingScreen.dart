import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';

class BookingScreen extends StatefulWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final double price; // Change this to double
  final int seatsLeft;
  final int numberOfPassengers;

  const BookingScreen({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.price, // Change this to double
    required this.seatsLeft,
    required this.numberOfPassengers,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<TextEditingController> nameControllers = [TextEditingController()];
  TextEditingController passengersController = TextEditingController();

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
            // Header
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

            // Number of passengers
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

            // Passenger name fields
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

            // Price information
            Text(
              'Price per ticket: \$${widget.price}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Total: \$${(widget.price * numberOfPassengers).toStringAsFixed(2)}', // Use double and format the total price
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: TColors.primary),
            ),
            const SizedBox(height: 24.0),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  print("Button pressed"); // Debugging print

                  // Get passenger names from controllers
                  List<String> passengerNames =
                      nameControllers
                          .map((controller) => controller.text.trim())
                          .toList();

                  // Validate all names are provided
                  if (passengerNames.any((name) => name.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all passenger names'),
                      ),
                    );
                    return;
                  }

                  // Get FirebaseController instance
                  final FirebaseController firebaseController =
                      Get.find<FirebaseController>();

                  // Attempt to book the ticket
                  bool result = await firebaseController.bookTicket(
                    trainId: 'KmbvZVlX3rS2XhspIyzA',
                    departureCity: widget.departureCity,
                    arrivalCity: widget.arrivalCity,
                    passengers: numberOfPassengers,
                    userId: "dq",
                    passengerNames: passengerNames,
                  );

                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking confirmed!')),
                    );
                    // Optionally navigate back or to a confirmation screen
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to book ticket')),
                    );
                  }

                  print('Booking result: $result'); // Debugging print
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: TSizes.lg),
                  backgroundColor: TColors.primary,
                ),
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
