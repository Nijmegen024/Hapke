import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cart_item.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../screens/auth/login_page.dart';
import '../screens/cart_page.dart';
import '../screens/order_tracking_page.dart';
import '../screens/payment_method_page.dart';
import '../screens/restaurant_detail_page.dart';

class RootController extends GetxController {
  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;
  set currentIndex(int val) => _currentIndex.value = val;

  bool restoredTracking = false;

  void changeIndex(int index) {
    _currentIndex.value = index;
  }

  void maybeResumeTracking({
    required String? pendingOrderId,
    required String? authToken,
    required Function(String) openTracking,
  }) {
    if (restoredTracking) return;
    if (pendingOrderId == null || pendingOrderId.isEmpty) return;
    if (authToken == null || authToken.isEmpty) return;
    
    restoredTracking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openTracking(pendingOrderId);
    });
  }

  Future<void> checkout({
    required BuildContext context,
    required List<CartItem> cartItems,
    required double? userLat,
    required double? userLng,
    required Future<bool> Function() onRequestLocation,
  }) async {
    if (cartItems.isEmpty) {
      Get.snackbar('Mandje', 'MANDDD!! is leeg');
      return;
    }
    if (userLat == null || userLng == null) {
      Get.snackbar('Locatie', 'Vul je locatie in om te bestellen');
      final ok = await onRequestLocation();
      if (!ok) return;
    }
    
    final cartSnapshot = cartItems.toList();
    final totalCents = cartSnapshot.fold(0, (sum, ci) => sum + ci.item.priceCents * ci.qty);

    Get.to(() => PaymentMethodPage(
      restaurant: cartSnapshot.first.restaurant,
      cart: {for (var ci in cartSnapshot) ci.item.id: ci.qty},
      totalCents: totalCents,
    ));
  }

  void openTracking(String orderId) {
    Get.to(() => OrderTrackingPage(orderId: orderId));
  }

  void openCartModal({
    required BuildContext context,
    required List<CartItem> cartItems,
    required List<Restaurant> restaurants,
    required VoidCallback onClear,
  }) {
    Get.bottomSheet(
      CartPage(
        cart: {for (var ci in cartItems) ci.item.id: ci.qty},
        restaurant: cartItems.isNotEmpty
            ? cartItems.first.restaurant
            : restaurants.first,
        onCartChanged: () {
          // In a full GetX refactor, CartPage would also use a CartController
          onClear(); 
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openRestaurant({
    required Restaurant restaurant,
    required List<CartItem> cartItems,
    required Function(BuildContext) openCartModal,
  }) {
    Get.to(() => RestaurantDetailPage(
      restaurant: restaurant,
      cart: {for (var ci in cartItems) ci.item.id: ci.qty},
      onCartChanged: () {},
      openCartModal: openCartModal,
    ));
  }

  Future<void> openLogin(Function(AuthSession) onLoggedIn) async {
    final result = await Get.to<AuthSession>(() => const LoginPage());
    if (result != null) {
      onLoggedIn(result);
    }
  }
}
