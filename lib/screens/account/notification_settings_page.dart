import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_settings_controller.dart';

class NotificationSettingsResult {
  final bool push;
  final bool email;
  final bool sms;

  const NotificationSettingsResult({
    required this.push,
    required this.email,
    required this.sms,
  });
}

class NotificationSettingsPage extends StatelessWidget {
  final NotificationSettingsResult initial;
  const NotificationSettingsPage({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationSettingsController(initial: initial));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificaties'),
          actions: [TextButton(onPressed: () => controller.close(), child: const Text('Gereed'))],
        ),
        body: Obx(() => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Stel in hoe wij je op de hoogte houden van bestellingen en acties.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pushberichten'),
              subtitle: const Text('Live updates over bezorging en promoties.'),
              value: controller.push,
              onChanged: (value) => controller.push = value,
            ),
            SwitchListTile(
              title: const Text('E-mail'),
              subtitle: const Text(
                'Ontvang samenvattingen en exclusieve deals.',
              ),
              value: controller.email,
              onChanged: (value) => controller.email = value,
            ),
            SwitchListTile(
              title: const Text('SMS'),
              subtitle: const Text(
                'Korte statusupdates over je bezorging en acties.',
              ),
              value: controller.sms,
              onChanged: (value) => controller.sms = value,
            ),
          ],
        )),
      ),
    );
  }
}
