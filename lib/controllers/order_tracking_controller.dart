import 'dart:convert';
import 'package:get/get.dart';
import '../../models/order.dart';
import '../../network/api_client.dart';
import '../../core/constants.dart';

class OrderTrackingController extends GetxController {
  final String orderId;
  OrderTrackingController({required this.orderId});

  final _order = Rxn<OrderSummary>();
  OrderSummary? get order => _order.value;

  final _loading = true.obs;
  bool get loading => _loading.value;

  final _error = RxnString();
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    _loading.value = true;
    _error.value = null;
    try {
      final res = await apiClient.get(Uri.parse('$apiBase/orders/$orderId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _order.value = OrderSummary.fromJson(data);
      } else {
        _error.value = 'Oeps! We konden de status van je bestelling niet ophalen.';
      }
    } catch (e) {
      _error.value = 'Oeps! Er ging iets mis: $e';
    } finally {
      _loading.value = false;
    }
  }
}
