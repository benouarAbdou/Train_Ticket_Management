import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
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
  final FirebaseController firebaseController = Get.find<FirebaseController>();

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
    'Austin',
    'Jacksonville',
    'Fort Worth',
    'Columbus',
    'Indianapolis',
    'Charlotte',
    'Seattle',
    'Denver',
    'Washington',
    'Boston',
    'Oran',
    'Alger',
    'Constantine',
    'Annaba',
    'Tlemcen',
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

  void _searchTrains() async {
    final depart = _departController.text;
    final destination = _destinationController.text;
    final passengers = int.tryParse(_passengersController.text) ?? 0;
    final date = _selectedDate;

    if (depart.isNotEmpty &&
        destination.isNotEmpty &&
        passengers > 0 &&
        date != null) {
      await firebaseController.searchTrains(
        departureCity: depart,
        arrivalCity: destination,
        date: date,
        passengers: passengers,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
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
              controller: _departController,
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
              controller: _destinationController,
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
                onPressed: _searchTrains,
                child: const Text('Search'),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            // Display search results
            Expanded(
              child: Obx(
                () =>
                    firebaseController.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : firebaseController.searchResults.isEmpty
                        ? const Center(child: Text('No trains found'))
                        : ListView.builder(
                          itemCount: firebaseController.searchResults.length,
                          itemBuilder: (context, index) {
                            final train =
                                firebaseController.searchResults[index];
                            return TrainTicket(
                              departureCity: train['departureCity'],
                              arrivalCity: train['arrivalCity'],
                              departureTime: train['departureTime'],
                              arrivalTime: train['arrivalTime'],
                              departureDate: train['departureDate'],
                              arrivalDate: train['arrivalDate'],
                              seatsLeft: train['seatsLeft'],
                            );
                          },
                        ),
              ),
            ),
            // Debug buttons
            /*SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await firebaseController.createDummyData();
                },
                child: const Text('Add dummy data'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await firebaseController.clearFirestoreData();
                },
                child: const Text('Clear dummy data'),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
