import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/pages/client/BookingScreen.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _departController = TextEditingController();
  final _destinationController = TextEditingController();
  final _passengersController = TextEditingController();
  final _firebaseController = Get.find<FirebaseController>();
  DateTime? _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _searchTrains() async {
    final depart = _departController.text.trim();
    final destination = _destinationController.text.trim();
    final passengers = int.tryParse(_passengersController.text) ?? 0;
    final date = _selectedDate;

    if (_isValidInput(depart, destination, passengers, date)) {
      await _firebaseController.searchTrains(
        departureCity: depart,
        arrivalCity: destination,
        date: date!,
        passengers: passengers,
      );
    } else {
      _showErrorSnackBar(context);
    }
  }

  bool _isValidInput(
    String depart,
    String destination,
    int passengers,
    DateTime? date,
  ) {
    return depart.isNotEmpty &&
        destination.isNotEmpty &&
        passengers > 0 &&
        date != null;
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields correctly')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TSizes.appBarHeight / 2),
              const Text(
                'Where do you wanna go?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              _buildTypeAheadField(
                controller: _departController,
                label: 'Departure Station',
                suggestions: _firebaseController.stations,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              _buildTypeAheadField(
                controller: _destinationController,
                label: 'Destination Station',
                suggestions: _firebaseController.stations,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              _buildPassengersField(),
              const SizedBox(height: TSizes.spaceBtwInputFields / 2),
              _buildDateSelector(context),
              const SizedBox(height: TSizes.spaceBtwInputFields / 2),
              _buildSearchButton(),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              _buildSearchResults(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeAheadField({
    required TextEditingController controller,
    required String label,
    required List<String> suggestions,
  }) {
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback:
          (pattern) =>
              suggestions
                  .where(
                    (station) =>
                        station.toLowerCase().contains(pattern.toLowerCase()),
                  )
                  .toList(),
      itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
      onSelected: (suggestion) => controller.text = suggestion,
      builder:
          (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(labelText: label),
          ),
    );
  }

  Widget _buildPassengersField() {
    return TextField(
      keyboardType: TextInputType.number,
      controller: _passengersController,
      decoration: const InputDecoration(labelText: 'Number of passengers'),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _searchTrains,
        child: const Text('Search'),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Obx(
        () =>
            _firebaseController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _firebaseController.searchResults.isEmpty
                ? const Center(child: Text('No trains found'))
                : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _firebaseController.searchResults.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final train = _firebaseController.searchResults[index];
                    return TrainTicket(
                      departureCity: train['departureCity'],
                      arrivalCity: train['arrivalCity'],
                      departureTime: train['departureTime'],
                      arrivalTime: train['arrivalTime'],
                      departureDate: train['departureDate'],
                      arrivalDate: train['arrivalDate'],
                      seatsLeft: train['seatsLeft'],
                      price: train['price'],
                      distance: train['totalDistance'],
                      numberOfPassengers:
                          int.tryParse(_passengersController.text) ?? 1,
                      onTap:
                          () => Get.to(
                            () => BookingScreen(
                              departureCity: train['departureCity'],
                              arrivalCity: train['arrivalCity'],
                              departureTime: train['departureTime'],
                              arrivalTime: train['arrivalTime'],
                              departureDate: train['departureDate'],
                              arrivalDate: train['arrivalDate'],
                              price: train['price'],
                              seatsLeft: train['seatsLeft'],
                              numberOfPassengers:
                                  int.tryParse(_passengersController.text) ?? 1,
                              trainId: train['id'],
                            ),
                          ),
                    );
                  },
                ),
      ),
    );
  }

  @override
  void dispose() {
    _departController.dispose();
    _destinationController.dispose();
    _passengersController.dispose();
    super.dispose();
  }
}
