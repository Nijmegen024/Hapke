import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'order_tracking_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;

  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF2AAAB3),
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bestelling geplaatst!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Je bestelling ($orderId) is succesvol geplaatst bij het restaurant. We laten je weten wanneer het onderweg is!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2AAAB3),
                  ),
                  onPressed: () => Get.off(() => OrderTrackingPage(orderId: orderId)),
                  child: const Text(
                    'Volg je bestelling',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.until((route) => route.isFirst),
                child: const Text('Terug naar home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
