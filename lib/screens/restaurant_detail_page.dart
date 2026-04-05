import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/restaurant.dart';
import '../../widgets/sticky_cart_bar.dart';
import '../../widgets/menu_item_card.dart';
import '../../controllers/restaurant_detail_controller.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;
  final Map<String, int> cart;
  final VoidCallback onCartChanged;
  final void Function(BuildContext) openCartModal;

  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
    required this.cart,
    required this.onCartChanged,
    required this.openCartModal,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      RestaurantDetailController(
        restaurant: restaurant,
        initialCart: cart,
        onCartChanged: onCartChanged,
      ),
      tag: restaurant.id,
    );

    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              restaurant.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.cuisine,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${restaurant.rating} • ${restaurant.eta}'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: restaurant.menu.length,
              itemBuilder: (context, index) {
                final item = restaurant.menu[index];
                return Obx(() {
                  return MenuItemCard(
                    item: item,
                    count: controller.cart[item.id] ?? 0,
                    onAdd: () => controller.addToCart(item),
                    onRemove: () => controller.removeFromCart(item),
                  );
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.totalCount > 0
            ? StickyCartBar(
                totalCents: controller.totalCents,
                itemCount: controller.totalCount,
                onTap: () => openCartModal(context),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
