import 'dart:convert';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';
import '../../network/api_client.dart';
import '../../core/constants.dart';
import '../screens/order_confirmation_page.dart';

class PaymentMethodController extends GetxController {
  final Restaurant restaurant;
  final Map<String, int> cart;
  final int totalCents;

  PaymentMethodController({
    required this.restaurant,
    required this.cart,
    required this.totalCents,
  });

  final _busy = false.obs;
  bool get busy => _busy.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _selectedMethod = 'IDEAL'.obs;
  String get selectedMethod => _selectedMethod.value;
  set selectedMethod(String val) => _selectedMethod.value = val;

  Future<void> startPayment() async {
    _busy.value = true;
    _error.value = null;

    try {
      final items = cart.entries.map((e) {
        return {
          'id': e.key,
          'quantity': e.value,
        };
      }).toList();

      final response = await apiClient.post(
        Uri.parse('$apiBase/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurantId': restaurant.id,
          'items': items,
          'paymentMethod': _selectedMethod.value,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data['orderId'];
        final paymentUrl = data['paymentUrl'];

        if (paymentUrl != null && await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
          _pollOrderStatus(orderId);
        } else {
          // If no payment URL, assume it's a test or cash payment
          Get.off(() => OrderConfirmationPage(orderId: orderId));
        }
      } else {
        _error.value = 'Oeps! Er ging iets mis bij het aanmaken van je bestelling.';
        _busy.value = false;
      }
    } catch (e) {
      _error.value = 'Oeps! Er ging iets mis: $e';
      _busy.value = false;
    }
  }

  Future<void> _pollOrderStatus(String orderId) async {
    int attempts = 0;
    while (attempts < 30) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final response = await apiClient.get(Uri.parse('$apiBase/orders/$orderId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'PAID' || data['status'] == 'CONFIRMED') {
            Get.off(() => OrderConfirmationPage(orderId: orderId));
            return;
          }
        }
      } catch (_) {}
      attempts++;
    }
    _error.value = 'We hebben je betaling nog niet kunnen bevestigen. Controleer je bank-app.';
    _busy.value = false;
  }
}
