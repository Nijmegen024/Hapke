import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/root_controller.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import 'friends/friends_tab.dart';
import 'videos/videos_tab.dart';
import 'home_page.dart';
import 'account/account_tab.dart';

class RootTabs extends StatelessWidget {
  final List<Restaurant> restaurants;
  final bool loadingRestaurants;
  final List<CartItem> cartItems;
  final int cartTotalCents;
  final void Function(Restaurant, MenuItem) onAdd;
  final void Function(CartItem, int) onUpdateQty;
  final VoidCallback onClear;
  final void Function(AuthSession) onLoggedIn;
  final Future<void> Function() onLogout;
  final HapkeUser? currentUser;
  final String? authToken;
  final bool locationRequired;
  final double? userLat;
  final double? userLng;
  final Future<bool> Function() onRequestLocation;
  final Future<void> Function() onManageAddresses;
  final Future<void> Function(OrderSummary summary) onOrderPlaced;
  final Future<void> Function(String orderId) onTrackingCompleted;
  final String? pendingOrderId;

  const RootTabs({
    super.key,
    required this.restaurants,
    required this.loadingRestaurants,
    required this.cartItems,
    required this.cartTotalCents,
    required this.onAdd,
    required this.onUpdateQty,
    required this.onClear,
    required this.onLoggedIn,
    required this.onLogout,
    required this.currentUser,
    required this.authToken,
    required this.locationRequired,
    required this.userLat,
    required this.userLng,
    required this.onRequestLocation,
    required this.onManageAddresses,
    required this.onOrderPlaced,
    required this.onTrackingCompleted,
    required this.pendingOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RootController());

    // Update tracking if needed
    controller.maybeResumeTracking(
      pendingOrderId: pendingOrderId,
      authToken: authToken,
      openTracking: (id) => controller.openTracking(id),
    );

    return Obx(() {
      final pages = <Widget>[
        HomePage(
          restaurants: restaurants,
          loadingRestaurants: loadingRestaurants,
          cartCount: cartItems.fold<int>(0, (sum, item) => sum + item.qty),
          currentUser: currentUser,
          openCartModal: (ctx) async => controller.openCartModal(
            context: ctx,
            cartItems: cartItems,
            restaurants: restaurants,
            onClear: onClear,
          ),
          addToCart: onAdd,
          onUpdateQty: onUpdateQty,
          onClearCart: onClear,
          cartItems: cartItems,
          onLoggedIn: onLoggedIn,
          onLogout: onLogout,
          locationRequired: locationRequired,
          onRequestLocation: onRequestLocation,
        ),
        VideosTab(
          restaurants: restaurants,
          isActive: controller.currentIndex == 1,
          userLat: userLat,
          userLng: userLng,
          onOpenRestaurant: (r) => controller.openRestaurant(
            restaurant: r,
            cartItems: cartItems,
            openCartModal: (ctx) => controller.openCartModal(
              context: ctx,
              cartItems: cartItems,
              restaurants: restaurants,
              onClear: onClear,
            ),
          ),
          onAddMenuItem: (r, item) => onAdd(r, item),
        ),
        const Center(child: Text('Shopping Cart View')),
        FriendsTab(
          currentUser: currentUser,
          onLogin: () => controller.openLogin(onLoggedIn),
        ),
        AccountTab(
          user: currentUser,
          onLogin: () => controller.openLogin(onLoggedIn),
          onLogout: onLogout,
          onManageAddresses: onManageAddresses,
        ),
      ];

      return Scaffold(
        body: IndexedStack(index: controller.currentIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF2AAAB3),
          selectedItemColor: const Color(0xFFFFC857),
          unselectedItemColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: controller.currentIndex,
          onTap: (i) => controller.changeIndex(i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              label: 'Ontdek',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ondemand_video_outlined),
              label: "Video's",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'MANDDD!!',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              label: 'Vrienden',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      );
    });
  }
}
