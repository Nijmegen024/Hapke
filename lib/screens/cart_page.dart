import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/restaurant.dart';
import '../../network/api_helpers.dart';
import 'payment_method_page.dart';
import '../../controllers/cart_controller.dart';

class CartPage extends StatelessWidget {
  final Map<String, int> cart;
  final Restaurant restaurant;
  final VoidCallback onCartChanged;

  const CartPage({
    super.key,
    required this.cart,
    required this.restaurant,
    required this.onCartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CartController(
        restaurant: restaurant,
        initialCart: cart,
        onCartChanged: onCartChanged,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Jouw mandje',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          if (controller.cartItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Je mandje is leeg')),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.cartItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = controller.cartItems[index];
                  final item = entry.key;
                  final count = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(formatPrice(item.priceCents * count)),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => controller.removeItem(item),
                          ),
                          Text('$count'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => controller.addItem(item),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Totaal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                formatPrice(controller.totalCents),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2AAAB3),
              ),
              onPressed: !controller.isMinOrderMet
                  ? null
                  : () {
                      Get.to(() => PaymentMethodPage(
                            restaurant: restaurant,
                            cart: controller.cart,
                            totalCents: controller.totalCents,
                          ));
                    },
              child: Text(
                !controller.isMinOrderMet
                    ? 'Minimaal ${formatPrice((restaurant.minOrder * 100).round())}'
                    : 'Afrekenen',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      )),
    );
  }
}
