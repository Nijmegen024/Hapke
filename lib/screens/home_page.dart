import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../network/api_helpers.dart';
import '../widgets/sticky_cart_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_pill.dart';
import 'restaurant_detail_page.dart';

class HomePage extends StatelessWidget {
  final List<Restaurant> restaurants;
  final bool loadingRestaurants;
  final int cartCount;
  final HapkeUser? currentUser;
  final Future<void> Function(BuildContext) openCartModal;
  final void Function(Restaurant, MenuItem) addToCart;
  final void Function(CartItem, int) onUpdateQty;
  final VoidCallback onClearCart;
  final List<CartItem> cartItems;
  final void Function(AuthSession) onLoggedIn;
  final Future<void> Function() onLogout;
  final bool locationRequired;
  final Future<bool> Function() onRequestLocation;

  const HomePage({
    super.key,
    required this.restaurants,
    required this.loadingRestaurants,
    required this.cartCount,
    required this.currentUser,
    required this.openCartModal,
    required this.addToCart,
    required this.onUpdateQty,
    required this.onClearCart,
    required this.cartItems,
    required this.onLoggedIn,
    required this.onLogout,
    required this.locationRequired,
    required this.onRequestLocation,
  });

  Future<void> _openCart(BuildContext context) async {
    await openCartModal(context);
    // Note: With GetX, we'd ideally have a CartController to avoid manual refreshing
  }

  void _openRestaurant(BuildContext context, Restaurant r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(
          restaurant: r,
          cart: { for (var ci in cartItems) if (ci.restaurant.id == r.id) ci.item.id : ci.qty },
          onCartChanged: () {
            // Ideally call a cart refresh logic here
          },
          openCartModal: openCartModal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AAAB3),
        clipBehavior: Clip.none,
        title: Transform.scale(
          scale: 1.15,
          child: SizedBox(
            height: kToolbarHeight * 0.88,
            child: Image.asset(
              'assets/icons/hapke_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text(
                  'Hapke',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      bottomSheet: cartItems.isEmpty
          ? null
          : StickyCartBar(
              totalCents: cartItems.fold<int>(0, (s, ci) => s + ci.item.priceCents * ci.qty),
              itemCount: cartItems.fold<int>(0, (n, ci) => n + ci.qty),
              onTap: () => _openCart(context),
            ),
      body: Obx(() {
        final filtered = controller.getFilteredRestaurants(restaurants);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xFF2AAAB3),
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              title: SearchPill(onChanged: (v) => controller.query = v),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final cat in controller.chipIcons.keys)
                      CategoryChip(
                        label: cat,
                        iconUrl: controller.chipIcons[cat],
                        selected: controller.selectedCategory == cat,
                        onSelected: () => controller.toggleCategory(cat),
                      ),
                  ],
                ),
              ),
            ),
            if (locationRequired) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 48,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 48,
                        color: Colors.black38,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Vul je bezorgadres in om restaurants in jouw buurt te zien.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: onRequestLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Bezorgadres instellen'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ] else if (loadingRestaurants) 
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (filtered.isEmpty) 
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 40,
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 48,
                        color: Colors.black38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nog geen restaurants gevonden',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nieuwe restaurants melden zich aan via het portal en verschijnen hier automatisch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            else 
              SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final r = filtered[i];
                  return InkWell(
                    onTap: () => _openRestaurant(context, r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Hero(
                                      tag: 'rest_${r.id}',
                                      child: Image.network(
                                        r.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(
                                              color: Colors.black12,
                                              child: Center(
                                                child: Icon(
                                                  Icons.storefront,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 8,
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  r.rating.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Icon(
                                                  Icons.timer,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  r.eta,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .shopping_basket_outlined,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Min. ' +
                                                          formatEuros(
                                                            r.minOrder,
                                                          ),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.pedal_bike,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      r.deliveryFee == null
                                                          ? 'Gratis bezorging'
                                                          : formatEuros(
                                                                  r.deliveryFee!,
                                                                ) +
                                                                  ' bezorging',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.cuisine,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
    );
  }
}
