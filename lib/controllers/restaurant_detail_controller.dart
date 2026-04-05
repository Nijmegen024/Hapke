import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class RestaurantDetailController extends GetxController {
  final Restaurant restaurant;
  final RxMap<String, int> cart;
  final VoidCallback onCartChanged;

  RestaurantDetailController({
    required this.restaurant,
    required Map<String, int> initialCart,
    required this.onCartChanged,
  }) : cart = initialCart.obs;

  int get totalCount => cart.values.fold(0, (sum, count) => sum + count);

  int get totalCents {
    int total = 0;
    cart.forEach((itemId, count) {
      final item = restaurant.menu.firstWhere(
        (m) => m.id == itemId,
        orElse: () => MenuItem(id: '', name: '', description: '', priceCents: 0),
      );
      if (item.id.isNotEmpty) {
        total += item.priceCents * count;
      }
    });
    return total;
  }

  void addToCart(MenuItem item) {
    cart[item.id] = (cart[item.id] ?? 0) + 1;
    onCartChanged();
  }

  void removeFromCart(MenuItem item) {
    if ((cart[item.id] ?? 0) > 0) {
      cart[item.id] = cart[item.id]! - 1;
      if (cart[item.id] == 0) cart.remove(item.id);
      onCartChanged();
    }
  }
}
