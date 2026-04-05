import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/language_settings_controller.dart';

class LanguageSettingsPage extends StatelessWidget {
  final String initialLanguage;
  const LanguageSettingsPage({super.key, required this.initialLanguage});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LanguageSettingsController(initialLanguage: initialLanguage));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Taal'),
          actions: [TextButton(onPressed: () => controller.close(), child: const Text('Gereed'))],
        ),
        body: Obx(() => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Kies de taal voor de app en onze communicatie.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...controller.languages.map(
              (language) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: controller.selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedLanguage = value;
                    }
                  },
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
