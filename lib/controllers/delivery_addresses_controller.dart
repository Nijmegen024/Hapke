import 'dart:convert';
import 'package:get/get.dart';
import '../core/constants.dart';
import '../models/delivery_address.dart';
import '../network/api_client.dart';
import '../network/api_helpers.dart';

class DeliveryAddressesController extends GetxController {
  final _loading = true.obs;
  bool get loading => _loading.value;

  final _saving = false.obs;
  bool get saving => _saving.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _addresses = <DeliveryAddress>[].obs;
  List<DeliveryAddress> get addresses => _addresses;

  final Future<void> Function(DeliveryAddress address) onLocationSelected;

  DeliveryAddressesController({required this.onLocationSelected});

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    _loading.value = true;
    _error.value = null;
    try {
      final res = await apiClient.get(
        Uri.parse('$apiBase/users/addresses'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        throw Exception(extractErrorMessage(res));
      }
      final decoded = jsonDecode(res.body);
      final addressesList = parseDeliveryAddresses(decoded);
      _addresses.value = addressesList;
      await notifyPrimaryLocation(addressesList);
    } catch (e) {
      _error.value = 'Adressen ophalen mislukt: $e';
    } finally {
      _loading.value = false;
    }
  }

  Future<void> notifyPrimaryLocation(List<DeliveryAddress> addressesList) async {
    if (addressesList.isEmpty) return;
    final primary = addressesList.firstWhere(
      (address) => address.isPrimary,
      orElse: () => addressesList.first,
    );
    if (!primary.hasCoords) return;
    await onLocationSelected(primary);
  }

  Future<bool> createOrEditAddress({
    DeliveryAddress? existing,
    required String street,
    required String houseNumber,
    required String postalCode,
    required String city,
  }) async {
    if (saving) return false;
    _saving.value = true;
    try {
      final uri = existing == null
          ? Uri.parse('$apiBase/users/addresses')
          : Uri.parse('$apiBase/users/addresses/${existing.id}');
      final body = jsonEncode({
        'street': street,
        'houseNumber': houseNumber,
        'postalCode': postalCode,
        'city': city,
      });
      final res = existing == null
          ? await apiClient.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body,
            )
          : await apiClient.patch(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body,
            );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(extractErrorMessage(res));
      }
      await loadAddresses();
      return true;
    } catch (e) {
      _error.value = 'Opslaan mislukt: $e';
      return false;
    } finally {
      _saving.value = false;
    }
  }

  Future<void> setPrimary(DeliveryAddress address) async {
    if (saving) return;
    _saving.value = true;
    try {
      final res = await apiClient.patch(
        Uri.parse('$apiBase/users/addresses/${address.id}/primary'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        throw Exception(extractErrorMessage(res));
      }
      await loadAddresses();
    } catch (e) {
      _error.value = 'Primair instellen mislukt: $e';
    } finally {
      _saving.value = false;
    }
  }

  Future<bool> deleteAddress(DeliveryAddress address) async {
    if (saving) return false;
    _saving.value = true;
    try {
      final res = await apiClient.delete(
        Uri.parse('$apiBase/users/addresses/${address.id}'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 204) {
        throw Exception(extractErrorMessage(res));
      }
      await loadAddresses();
      return true;
    } catch (e) {
      _error.value = 'Verwijderen mislukt: $e';
      return false;
    } finally {
      _saving.value = false;
    }
  }
}
