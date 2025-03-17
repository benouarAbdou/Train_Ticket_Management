import 'package:flutter/material.dart';
import 'package:train_app/utils/constants/sizes.dart';

class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text('Error: $error', textAlign: TextAlign.center),
          const SizedBox(height: TSizes.spaceBtwItems),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
