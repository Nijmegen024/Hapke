import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/constants.dart';
import 'models/user.dart';
import 'models/restaurant.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'network/api_client.dart';
import 'network/api_helpers.dart';
import 'models/menu_item.dart';
import 'screens/root_tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const HapkeApp());
}

class HapkeApp extends StatelessWidget {
  const HapkeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hapke',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const _HapkeAppStateWrapper(),
    );
  }
}

class _HapkeAppStateWrapper extends StatefulWidget {
  const _HapkeAppStateWrapper();

  @override
  State<_HapkeAppStateWrapper> createState() => _HapkeAppState();
}

class _HapkeAppState extends State<_HapkeAppStateWrapper> {
  AuthSession? _session;
  final Map<String, int> _cart = {};
  List<Restaurant> _restaurants = [];
  bool _loadingRestaurants = false;
  double? _userLat = 51.8112349;
  double? _userLng = 5.8224106;
  bool _locationRequired = false;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadSession();
    await _loadLastOrder();
    await _fetchRestaurants();
  }

  Future<void> _loadSession() async {
    final token = await secureStorage.read(key: authTokenKey);
    final userJson = await secureStorage.read(key: authUserKey);
    if (token != null && userJson != null) {
      try {
        final user = HapkeUser.fromJson(jsonDecode(userJson));
        setState(() {
          _session = AuthSession(user: user, token: token);
        });
        apiClient.setToken(token);
      } catch (e) {
        debugPrint('Error loading session: $e');
      }
    }
  }

  Future<void> _loadLastOrder() async {
    final orderId = await secureStorage.read(key: lastOrderStorageKey);
    if (orderId != null && orderId.isNotEmpty) {
      setState(() => _pendingOrderId = orderId);
    }
  }

  Future<void> _fetchRestaurants() async {
    setState(() => _loadingRestaurants = true);
    try {
      final res = await apiClient.get(
        restaurantsUri(lat: _userLat!, lng: _userLng!),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final list = data
              .whereType<Map<String, dynamic>>()
              .map(Restaurant.fromJson)
              .toList();
          setState(() {
            _restaurants = list;
            _locationRequired = false;
          });
        }
      } else if (res.statusCode == 400) {
        setState(() => _locationRequired = true);
      }
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
    } finally {
      setState(() => _loadingRestaurants = false);
    }
  }

  Future<void> setSession(AuthSession? session) async {
    setState(() => _session = session);
    if (session != null) {
      await secureStorage.write(key: authTokenKey, value: session.token);
      await secureStorage.write(
        key: authUserKey,
        value: jsonEncode(session.user.toJson()),
      );
      apiClient.setToken(session.token);
    } else {
      await secureStorage.delete(key: authTokenKey);
      await secureStorage.delete(key: authUserKey);
      apiClient.setToken(null);
    }
  }

  void _onAdd(Restaurant r, MenuItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
  }

  void _onUpdateQty(CartItem ci, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _cart.remove(ci.item.id);
      } else {
        _cart[ci.item.id] = newQty;
      }
    });
  }

  void _onClearCart() {
    setState(() {
      _cart.clear();
    });
  }

  Future<void> _handleOrderPlaced(OrderSummary summary) async {
    await secureStorage.write(key: lastOrderStorageKey, value: summary.orderId);
    setState(() {
      _pendingOrderId = summary.orderId;
      _cart.clear();
    });
  }

  Future<void> _handleTrackingCompleted(String orderId) async {
    if (_pendingOrderId == orderId) {
      await secureStorage.delete(key: lastOrderStorageKey);
      setState(() => _pendingOrderId = null);
    }
  }

  Future<bool> _requestLocation() async {
    // Logic for requesting location
    return true;
  }

  Future<void> _manageAddresses() async {
    // Navigate to addresses page
  }

  List<CartItem> _getCartItems() {
    final list = <CartItem>[];
    _cart.forEach((itemId, qty) {
      for (final r in _restaurants) {
        try {
          final item = r.menu.firstWhere((m) => m.id == itemId);
          list.add(CartItem(restaurant: r, item: item, qty: qty));
          return;
        } catch (_) {}
      }
    });
    return list;
  }

  int _getCartTotalCents() {
    int total = 0;
    for (final ci in _getCartItems()) {
      total += ci.item.priceCents * ci.qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return RootTabs(
      restaurants: _restaurants,
      loadingRestaurants: _loadingRestaurants,
      cartItems: _getCartItems(),
      cartTotalCents: _getCartTotalCents(),
      onAdd: _onAdd,
      onUpdateQty: _onUpdateQty,
      onClear: _onClearCart,
      onLoggedIn: setSession,
      onLogout: () => setSession(null),
      currentUser: _session?.user,
      authToken: _session?.token,
      locationRequired: _locationRequired,
      userLat: _userLat,
      userLng: _userLng,
      onRequestLocation: _requestLocation,
      onManageAddresses: _manageAddresses,
      onOrderPlaced: _handleOrderPlaced,
      onTrackingCompleted: _handleTrackingCompleted,
      pendingOrderId: _pendingOrderId,
    );
  }
}
