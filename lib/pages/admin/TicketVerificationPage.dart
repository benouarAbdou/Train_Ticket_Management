import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/client/TicketDetailsScreen.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/widgets/TrainTicket.dart';

class TicketVerificationPage extends StatefulWidget {
  const TicketVerificationPage({super.key});

  @override
  State<TicketVerificationPage> createState() => _TicketVerificationPageState();
}

class _TicketVerificationPageState extends State<TicketVerificationPage> {
  final _ticketIdController = TextEditingController();
  final FirebaseAdminController _adminController =
      Get.find<FirebaseAdminController>();
  Map<String, dynamic>? _ticketDetails;
  bool _isLoading = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _ticketIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyTicket() async {
    FocusScope.of(context).unfocus();

    final result = await _adminController.verifyTicket(
      ticketId: _ticketIdController.text,
      onError:
          (error) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error))),
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    if (result != null) {
      setState(() => _ticketDetails = result);
    }
  }

  Future<void> _markTicketAsUsed() async {
    await _adminController.markTicketAsUsed(
      ticketId: _ticketIdController.text,
      onError:
          (error) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error))),
      onSuccess:
          (message) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message))),
      onLoading: (loading) => setState(() => _isVerifying = loading),
    );
    await _verifyTicket(); // Refresh ticket details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ticket verification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            // Ticket ID Input
            TextField(
              controller: _ticketIdController,
              decoration: InputDecoration(
                labelText: 'Enter Ticket ID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.search),
                  onPressed: _isLoading ? null : _verifyTicket,
                ),
              ),
              onSubmitted: (_) => _verifyTicket(),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Ticket Details using TrainTicket widget
            if (_ticketDetails != null) ...[
              TrainTicket(
                departureCity: _ticketDetails!['departureCity'],
                arrivalCity: _ticketDetails!['arrivalCity'],
                departureTime: _ticketDetails!['departureTime'],
                arrivalTime: _ticketDetails!['arrivalTime'],
                departureDate: _ticketDetails!['departureDate'],
                arrivalDate: _ticketDetails!['arrivalDate'],
                seatsLeft: null, // Not available in verification context
                price:
                    (_ticketDetails!['price'] is int)
                        ? (_ticketDetails!['price'] as int).toDouble()
                        : _ticketDetails!['price'] as double,
                numberOfPassengers: _ticketDetails!['passengerNames'].length,
                status: _ticketDetails!['status'],
                onTap: () {
                  FocusScope.of(context).unfocus();

                  Get.to(
                    () => TicketDetailsScreen(
                      departureCity: _ticketDetails!['departureCity'],
                      arrivalCity: _ticketDetails!['arrivalCity'],
                      departureTime: _ticketDetails!['departureTime'],
                      arrivalTime: _ticketDetails!['arrivalTime'],
                      departureDate: _ticketDetails!['departureDate'],
                      arrivalDate: _ticketDetails!['arrivalDate'],
                      price:
                          (_ticketDetails!['price'] is int)
                              ? (_ticketDetails!['price'] as int).toDouble()
                              : _ticketDetails!['price'] as double,
                      numberOfPassengers:
                          _ticketDetails!['passengerNames'].length,
                      status: _ticketDetails!['status'],
                      passengerNames: List<String>.from(
                        _ticketDetails!['passengerNames'],
                      ),
                      ticketId: _ticketIdController.text,
                      passengerId:
                          _ticketDetails!['passengerId'] ?? 'Not provided',
                    ),
                  );
                },
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              if (_ticketDetails!['status'] == 'confirmed')
                ElevatedButton(
                  onPressed: _markTicketAsUsed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: TSizes.buttonHeight,
                    ),
                  ),
                  child:
                      _isVerifying
                          ? const Text("Marking...")
                          : const Text(
                            'Mark as Used',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
