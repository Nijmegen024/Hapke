import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/location_settings_controller.dart';

class LocationSettingsResult {
  final bool servicesEnabled;
  final bool preciseEnabled;
  final bool historyEnabled;

  const LocationSettingsResult({
    required this.servicesEnabled,
    required this.preciseEnabled,
    required this.historyEnabled,
  });
}

class LocationSettingsPage extends StatelessWidget {
  final LocationSettingsResult initial;
  const LocationSettingsPage({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocationSettingsController(initial: initial));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Locatieservices'),
          actions: [TextButton(onPressed: () => controller.close(), child: const Text('Gereed'))],
        ),
        body: Obx(() => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Bepaal hoe Hapke je locatie gebruikt om sneller te bezorgen.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Locatie delen met Hapke'),
              subtitle: const Text(
                'Nodig voor bezorging en lokale acties in je buurt.',
              ),
              value: controller.servicesEnabled,
              onChanged: (value) => controller.servicesEnabled = value,
            ),
            SwitchListTile(
              title: const Text('Precisie-locatie'),
              subtitle: const Text(
                'Gebruik GPS voor nauwkeurige bezorgupdates.',
              ),
              value: controller.preciseEnabled,
              onChanged: controller.servicesEnabled
                  ? (value) => controller.preciseEnabled = value
                  : null,
            ),
            SwitchListTile(
              title: const Text('Locatiegeschiedenis opslaan'),
              subtitle: const Text(
                'Handig om sneller op je favoriete adressen te bestellen.',
              ),
              value: controller.historyEnabled,
              onChanged: controller.servicesEnabled
                  ? (value) => controller.historyEnabled = value
                  : null,
            ),
          ],
        )),
      ),
    );
  }
}
