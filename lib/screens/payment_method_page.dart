import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/restaurant.dart';
import '../../network/api_helpers.dart';
import '../../controllers/payment_method_controller.dart';

class PaymentMethodPage extends StatelessWidget {
  final Restaurant restaurant;
  final Map<String, int> cart;
  final int totalCents;

  const PaymentMethodPage({
    super.key,
    required this.restaurant,
    required this.cart,
    required this.totalCents,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController(
      restaurant: restaurant,
      cart: cart,
      totalCents: totalCents,
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Betaalmethode')),
      body: Obx(() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Kies hoe je wilt betalen',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildMethodTile(controller, 'IDEAL', 'iDEAL', Icons.account_balance),
          _buildMethodTile(controller, 'CREDIT_CARD', 'Creditcard', Icons.credit_card),
          _buildMethodTile(controller, 'CASH', 'Contant', Icons.money),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF2AAAB3),
            ),
            onPressed: controller.busy ? null : () => controller.startPayment(),
            child: controller.busy
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Betaal ${formatPrice(totalCents)}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      )),
    );
  }

  Widget _buildMethodTile(PaymentMethodController controller, String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: controller.selectedMethod,
      onChanged: (v) => controller.selectedMethod = v!,
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
