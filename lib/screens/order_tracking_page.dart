import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_tracking_controller.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderTrackingController(orderId: orderId), tag: orderId);

    return Obx(() {
      if (controller.loading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.error != null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Bestelling volgen')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(controller.error!, textAlign: TextAlign.center),
            ),
          ),
        );
      }

      final order = controller.order;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Bestelling volgen'),
          actions: [
            IconButton(
              onPressed: () => controller.fetchStatus(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: order == null
            ? const Center(child: Text('Geen informatie gevonden.'))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Bestelling #$orderId',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.restaurantName ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  _buildStatusStep(
                    'Ontvangen',
                    'We hebben je bestelling ontvangen.',
                    order.status != 'CANCELLED',
                    isFirst: true,
                  ),
                  _buildStatusStep(
                    'Bereiden',
                    'Het restaurant bereidt je eten.',
                    ['PREPARING', 'READY', 'DELIVERING', 'COMPLETED'].contains(order.status),
                  ),
                  _buildStatusStep(
                    'Klaar voor bezorging',
                    'Je eten is klaar!',
                    ['READY', 'DELIVERING', 'COMPLETED'].contains(order.status),
                  ),
                  _buildStatusStep(
                    'Onderweg',
                    'De bezorger is onderweg.',
                    ['DELIVERING', 'COMPLETED'].contains(order.status),
                  ),
                  _buildStatusStep(
                    'Bezorgd',
                    'Eet smakelijk!',
                    order.status == 'COMPLETED',
                    isLast: true,
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildStatusStep(String title, String description, bool completed,
      {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF2AAAB3) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: completed ? const Color(0xFF2AAAB3) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: completed ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
