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
  final num? totalDistance;
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
    this.totalDistance,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late List<TextEditingController> _nameControllers;
  late TextEditingController _passengersController;
  late int _numberOfPassengers;
  bool _isBooking = false;

  final _firebaseController = Get.find<FirebaseController>();
  final _hiveController = Get.find<HiveController>();
  final _notificationService = Get.find<NotificationService>();

  @override
  void initState() {
    super.initState();
    _numberOfPassengers = widget.numberOfPassengers;
    _nameControllers = List.generate(
      _numberOfPassengers,
      (_) => TextEditingController(),
    );
    _passengersController = TextEditingController(
      text: _numberOfPassengers.toString(),
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _passengersController.dispose();
    super.dispose();
  }

  void _updatePassengerFields(int value) {
    setState(() {
      _numberOfPassengers = value;
      final currentLength = _nameControllers.length;
      if (currentLength < value) {
        _nameControllers.addAll(
          List.generate(value - currentLength, (_) => TextEditingController()),
        );
      } else if (currentLength > value) {
        _nameControllers.removeRange(value, currentLength);
      }
    });
  }

  Future<void> _bookTickets() async {
    setState(() => _isBooking = true);
    final userId = await _hiveController.getUserId();
    final passengerNames = _nameControllers.map((c) => c.text.trim()).toList();

    if (!_isValidInput(passengerNames)) {
      setState(() => _isBooking = false);
      _showSnackBar(context, 'Please fill in all passenger names');
      return;
    }

    try {
      final bookingResults = await _processBookings(userId, passengerNames);
      await _handleBookingResults(bookingResults);
    } catch (e) {
      _showSnackBar(context, 'Error booking tickets: $e');
    } finally {
      setState(() => _isBooking = true);
    }
  }

  bool _isValidInput(List<String> passengerNames) {
    return passengerNames.every((name) => name.isNotEmpty);
  }

  Future<List<Map<String, dynamic>>> _processBookings(
    String userId,
    List<String> passengerNames,
  ) async {
    final bookingDataList = <Map<String, dynamic>>[];
    for (var i = 0; i < _numberOfPassengers; i++) {
      final bookingData = _createBookingData(userId, passengerNames[i]);
      final result = await _firebaseController.bookTicket(
        trainId: bookingData['trainId'],
        departureCity: bookingData['departureCity'],
        arrivalCity: bookingData['arrivalCity'],
        passengers: 1,
        userId: bookingData['userId'],
        passengerNames: [passengerNames[i]],
        departureTime: bookingData['departureTime'],
        arrivalTime: bookingData['arrivalTime'],
        departureDate: bookingData['departureDate'],
        arrivalDate: bookingData['arrivalDate'],
        totalDistance: bookingData['totalDistance'],
      );
      bookingData['status'] = result ? 'confirmed' : 'failed';
      bookingDataList.add(bookingData);
      await _hiveController.saveBookingLocally(bookingData);
    }
    return bookingDataList;
  }

  Map<String, dynamic> _createBookingData(String userId, String passengerName) {
    return {
      'trainId': widget.trainId,
      'departureCity': widget.departureCity,
      'arrivalCity': widget.arrivalCity,
      'departureTime': widget.departureTime,
      'arrivalTime': widget.arrivalTime,
      'departureDate': widget.departureDate,
      'arrivalDate': widget.arrivalDate,
      'passengers': 1,
      'userId': userId,
      'passengerNames': [passengerName],
      'price': widget.price,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
      if (widget.totalDistance != null) 'totalDistance': widget.totalDistance,
    };
  }

  Future<void> _handleBookingResults(
    List<Map<String, dynamic>> bookingDataList,
  ) async {
    final allConfirmed = bookingDataList.every(
      (data) => data['status'] == 'confirmed',
    );
    if (allConfirmed) {
      await _notificationService.scheduleTicketNotification(
        trainId: widget.trainId,
        departureCity: widget.departureCity,
        arrivalCity: widget.arrivalCity,
        departureTime: widget.departureTime,
        departureDate: widget.departureDate,
      );
      _showSnackBar(context, 'All bookings confirmed!');
      Navigator.pop(context);
    } else {
      _showSnackBar(
        context,
        'Some bookings failed. Please check your bookings',
      );
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            _buildTripInfo(context),
            const SizedBox(height: TSizes.spaceBtwItems),
            _buildPassengersField(),
            const SizedBox(height: TSizes.spaceBtwItems),
            _buildNameFields(),
            const SizedBox(height: TSizes.spaceBtwItems),
            _buildPriceInfo(context),
            const SizedBox(height: TSizes.spaceBtwSections),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.departureCity} → ${widget.arrivalCity}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: TSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TimeColumn(time: widget.departureTime, date: widget.departureDate),
            _TimeColumn(
              time: widget.arrivalTime,
              date: widget.arrivalDate,
              isEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengersField() {
    return TextField(
      controller: _passengersController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Number of Passengers',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsedValue = int.tryParse(value);
        if (parsedValue != null &&
            parsedValue > 0 &&
            parsedValue <= widget.seatsLeft) {
          _updatePassengerFields(parsedValue);
        }
      },
    );
  }

  Widget _buildNameFields() {
    return Column(
      children: List.generate(
        _numberOfPassengers,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: TSizes.sm),
          child: TextField(
            controller: _nameControllers[index],
            decoration: InputDecoration(
              labelText: 'Passenger ${index + 1} Full Name',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price per ticket: \$${widget.price.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          'Total: \$${(widget.price * _numberOfPassengers).toStringAsFixed(0)}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: TColors.primary),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isBooking ? null : _bookTickets, // Disable button while booking
        child:
            _isBooking
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text('Book Now', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String time;
  final String date;
  final bool isEnd;

  const _TimeColumn({
    required this.time,
    required this.date,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: TColors.primary),
        ),
        Text(date, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
