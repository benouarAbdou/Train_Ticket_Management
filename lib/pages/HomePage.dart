import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _departController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  final List<String> stations = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: TSizes.appBarHeight / 2),
            const Text(
              'Where do you wanna go?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TypeAheadField(
              controller: _departController, // Add controller
              suggestionsCallback: (pattern) {
                return stations
                    .where(
                      (station) =>
                          station.toLowerCase().contains(pattern.toLowerCase()),
                    )
                    .toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSelected: (suggestion) {
                _departController.text = suggestion;
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Departure Station',
                  ),
                );
              },
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TypeAheadField(
              controller: _destinationController, // Add controller
              suggestionsCallback: (pattern) {
                return stations
                    .where(
                      (station) =>
                          station.toLowerCase().contains(pattern.toLowerCase()),
                    )
                    .toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSelected: (suggestion) {
                _destinationController.text = suggestion;
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Destination Station',
                  ),
                );
              },
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextField(
              keyboardType: TextInputType.number,
              controller: _passengersController,
              decoration: const InputDecoration(
                labelText: 'Number of passengers',
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields / 2),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields / 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final depart = _departController.text;
                  final destination = _destinationController.text;
                  final date = _selectedDate;

                  if (depart.isNotEmpty &&
                      destination.isNotEmpty &&
                      date != null) {
                    print('Searching for $depart to $destination on $date');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                  }
                },
                child: const Text('Search'),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields / 2),
            TrainTicket(
              departureCity: 'Oran',
              arrivalCity: 'Alger',
              departureTime: '8:45 AM',
              arrivalTime: '12:30 PM',
              departureDate: '25-12-2025',
              arrivalDate: '25-12-2025',
              seatsLeft: 5,
            ),
          ],
        ),
      ),
    );
  }
}
