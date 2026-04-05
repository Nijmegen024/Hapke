import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/delivery_addresses_controller.dart';
import '../../models/delivery_address.dart';

class DeliveryAddressesPage extends StatelessWidget {
  final Future<void> Function(DeliveryAddress address) onLocationSelected;
  const DeliveryAddressesPage({super.key, required this.onLocationSelected});

  static const Color primaryColor = Color(0xFF2AAAB3);
  static const Color mutedColor = Color(0xFF6F7F99);

  @override
  Widget build(BuildContext context) {
    // We use Get.put here because this is the primary entry for this logic.
    // If it were already provided by a parent, we'd use Get.find.
    final controller = Get.put(DeliveryAddressesController(onLocationSelected: onLocationSelected));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bezorgadressen'),
        actions: [
          Obx(() => IconButton(
            onPressed: controller.saving ? null : () => _createOrEditAddress(context, controller),
            icon: const Icon(Icons.add),
            tooltip: 'Adres toevoegen',
          )),
        ],
      ),
      body: Container(
        color: const Color(0xFFF4F7FB),
        child: Obx(() {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 48, color: Colors.black38),
                    const SizedBox(height: 12),
                    const Text(
                      'Voeg een bezorgadres toe om restaurants in jouw buurt te zien.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.saving ? null : () => _createOrEditAddress(context, controller),
                      child: const Text('Adres toevoegen'),
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: 12),
                      Text(controller.error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(controller.error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ...controller.addresses.map((address) => _buildAddressCard(context, controller, address)),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _createOrEditAddress(BuildContext context, DeliveryAddressesController controller, {DeliveryAddress? existing}) async {
    final result = await _openAddressDialog(context, existing: existing);
    if (result == null) return;
    
    final success = await controller.createOrEditAddress(
      existing: existing,
      street: result.street,
      houseNumber: result.houseNumber,
      postalCode: result.postalCode,
      city: result.city,
    );
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Adres toegevoegd' : 'Adres bijgewerkt'),
        ),
      );
    }
  }

  Future<void> _deleteAddress(BuildContext context, DeliveryAddressesController controller, DeliveryAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Adres verwijderen'),
        content: Text('Weet je zeker dat je ${address.line1} wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteAddress(address);
    }
  }

  Widget _buildAddressCard(BuildContext context, DeliveryAddressesController controller, DeliveryAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_outlined, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.line1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(address.line2, style: const TextStyle(color: mutedColor)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (address.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Primair',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (!address.isPrimary) ...[
                      TextButton(
                        onPressed: controller.saving ? null : () => controller.setPrimary(address),
                        child: const Text('Primair maken'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed:
                    controller.saving ? null : () => _createOrEditAddress(context, controller, existing: address),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Aanpassen',
              ),
              IconButton(
                onPressed: controller.saving ? null : () => _deleteAddress(context, controller, address),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Verwijderen',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<_AddressDraft?> _openAddressDialog(BuildContext context, {DeliveryAddress? existing}) async {
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final houseCtrl = TextEditingController(text: existing?.houseNumber ?? '');
    final postalCtrl = TextEditingController(text: existing?.postalCode ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    String? error;

    return showDialog<_AddressDraft>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void submit() {
              final street = streetCtrl.text.trim();
              final houseNumber = houseCtrl.text.trim();
              final postalCode = postalCtrl.text.trim();
              final city = cityCtrl.text.trim();
              final postalOk = RegExp(r'^[1-9][0-9]{3}\s?[A-Za-z]{2}$').hasMatch(postalCode);
              if (street.isEmpty || houseNumber.isEmpty || city.isEmpty || !postalOk) {
                setDialogState(() {
                  error = 'Vul een geldig adres in (postcode 1234 AB).';
                });
                return;
              }
              Navigator.of(dialogCtx).pop(
                _AddressDraft(
                  street: street,
                  houseNumber: houseNumber,
                  postalCode: postalCode,
                  city: city,
                ),
              );
            }

            return AlertDialog(
              title: Text(existing == null ? 'Adres toevoegen' : 'Adres aanpassen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(labelText: 'Straat'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: houseCtrl,
                      decoration: const InputDecoration(labelText: 'Huisnummer'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: postalCtrl,
                      decoration: const InputDecoration(labelText: 'Postcode'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'Plaats'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Annuleren'),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('Opslaan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AddressDraft {
  final String street;
  final String houseNumber;
  final String postalCode;
  final String city;

  const _AddressDraft({
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.city,
  });
}
