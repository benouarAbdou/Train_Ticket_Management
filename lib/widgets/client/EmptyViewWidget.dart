import 'package:flutter/material.dart';
import 'package:train_app/utils/constants/sizes.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No tickets found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
