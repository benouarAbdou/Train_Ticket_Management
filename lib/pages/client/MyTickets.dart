import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:train_app/controllers/FirebaseController.dart';
import 'package:train_app/controllers/HiveController.dart';
import 'package:train_app/pages/client/TicketDetailsScreen.dart';
import 'package:train_app/utils/constants/sizes.dart';
import 'package:train_app/utils/services/ConnectivityService.dart';
import 'package:train_app/widgets/client/ConnectivityStatusWidget.dart';
import 'package:train_app/widgets/client/EmptyViewWidget.dart';
import 'package:train_app/widgets/client/ErrorViewWidget.dart';
import 'package:train_app/widgets/client/TicketListWidget.dart';

// Screen to display user's booked tickets
class BookedTicketsScreen extends StatelessWidget {
  final _firebaseController = Get.find<FirebaseController>();
  final _hiveController = Get.find<HiveController>();
  final _connectivityService = Get.find<ConnectivityService>();

  BookedTicketsScreen({super.key});

  // Fetch tickets from Firebase or local storage based on connectivity
  Future<List<Map<String, dynamic>>> _fetchTickets(String userId) async {
    try {
      final isOnline = await _connectivityService.checkConnectivity();
      List<Map<String, dynamic>> tickets;

      if (isOnline) {
        tickets = await _firebaseController.readBookedTickets(userId);
        for (var ticket in tickets) {
          await _hiveController.saveBookingLocally(
            ticket,
          ); // Sync to local storage
        }
      } else {
        tickets = await _hiveController.getLocalBookings(); // Use cached data
      }
      return tickets;
    } catch (e) {
      return await _hiveController
          .getLocalBookings(); // Fallback to local on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _hiveController.getUserIdSync(); // Get user ID synchronously

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TSizes.appBarHeight / 2),
            _buildHeader(),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            _buildTicketsList(userId),
          ],
        ),
      ),
    );
  }

  // Build header with title and connectivity status
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Tickets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Obx(
          () =>
              ConnectivityStatus(isOnline: _connectivityService.isOnline.value),
        ),
      ],
    );
  }

  // Build tickets list with refresh capability
  Widget _buildTicketsList(String userId) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _fetchTickets(userId),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTickets(userId),
          builder:
              (context, snapshot) => _buildContent(context, snapshot, userId),
        ),
      ),
    );
  }

  // Handle different states of ticket data loading
  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    String userId,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return ErrorView(
        error: snapshot.error,
        onRetry: () => _fetchTickets(userId),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const EmptyView();
    }

    return TicketsList(
      tickets: snapshot.data!,
      onTicketTap: _navigateToDetails,
    );
  }

  // Navigate to ticket details screen
  void _navigateToDetails(Map<String, dynamic> booking) {
    Get.to(
      () => TicketDetailsScreen(
        departureCity: booking['departureCity'] ?? 'Unknown',
        arrivalCity: booking['arrivalCity'] ?? 'Unknown',
        departureTime: booking['departureTime'] ?? 'Not set',
        arrivalTime: booking['arrivalTime'] ?? 'Not set',
        departureDate: booking['departureDate'] ?? 'Not set',
        arrivalDate: booking['arrivalDate'] ?? 'Not set',
        price: booking['price']?.toDouble() ?? 0.0,
        passengerNames: booking['passengerNames']?.cast<String>(),
        numberOfPassengers: booking['numberOfPassengers'] ?? 1,
        ticketId: booking['id'],
        passengerId: booking['passengerId'],
        status: booking['status'],
      ),
    );
  }
}
