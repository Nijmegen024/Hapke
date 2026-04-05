import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class CartController extends GetxController {
  final Restaurant restaurant;
  final RxMap<String, int> cart;
  final VoidCallback onCartChanged;

  CartController({
    required this.restaurant,
    required Map<String, int> initialCart,
    required this.onCartChanged,
  }) : cart = initialCart.obs;

  int get totalCents {
    int total = 0;
    cart.forEach((itemId, count) {
      final item = restaurant.menu.firstWhere(
        (m) => m.id == itemId,
        orElse: () => MenuItem(id: '', name: '', description: '', priceCents: 0),
      );
      total += item.priceCents * count;
    });
    return total;
  }

  List<MapEntry<MenuItem, int>> get cartItems {
    return cart.entries.map((e) {
      final item = restaurant.menu.firstWhere((m) => m.id == e.key);
      return MapEntry(item, e.value);
    }).toList();
  }

  void addItem(MenuItem item) {
    cart[item.id] = (cart[item.id] ?? 0) + 1;
    onCartChanged();
  }

  void removeItem(MenuItem item) {
    if ((cart[item.id] ?? 0) > 0) {
      cart[item.id] = cart[item.id]! - 1;
      if (cart[item.id] == 0) cart.remove(item.id);
      onCartChanged();
    }
  }

  bool get isMinOrderMet => totalCents >= (restaurant.minOrder * 100).round();
}
