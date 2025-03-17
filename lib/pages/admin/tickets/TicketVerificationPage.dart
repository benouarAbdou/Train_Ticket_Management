import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:train_app/controllers/FirebaseAdminController.dart';
import 'package:train_app/pages/client/TicketDetailsScreen.dart';
import 'package:train_app/utils/constants/colors.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/TicketUtils.dart';
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

  Future<void> _scanBarcode() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Scan Ticket Barcode',
        centerTitle: true,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back),
      ),
      isShowFlashIcon: true,
      delayMillis: 2000,
      cameraFace: CameraFace.back, // Using rear camera for better quality
    );

    if (res!.isNotEmpty && res != '-1') {
      // -1 is returned when scanner is closed without scanning
      _ticketIdController.text = res;
      await _verifyTicket();
    }
  }

  Future<void> _verifyTicket() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final result = await TicketUtils.verifyTicket(
      context: context,
      ticketId: _ticketIdController.text,
      adminController: _adminController,
    );
    setState(() {
      _ticketDetails = result;
      _isLoading = false;
    });
  }

  Future<void> _markTicketAsUsed() async {
    setState(() => _isVerifying = true);
    await TicketUtils.markTicketAsUsed(
      context: context,
      ticketId: _ticketIdController.text,
      adminController: _adminController,
    );
    await _verifyTicket();
    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          onPressed: _isLoading ? null : _verifyTicket,
                        ),
                      ),
                      onSubmitted: (_) => _verifyTicket(),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  ElevatedButton(
                    onPressed: _scanBarcode,
                    child: const Icon(
                      Iconsax.scan,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
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
                  seatsLeft: null,
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
      ),
    );
  }
}
