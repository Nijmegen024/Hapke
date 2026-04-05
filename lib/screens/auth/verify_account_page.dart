import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/verify_account_controller.dart';

class VerifyAccountPage extends StatelessWidget {
  final String email;

  const VerifyAccountPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyAccountController(email: email), tag: email);

    return Scaffold(
      appBar: AppBar(title: const Text('Account Verifiëren')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() => controller.loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.success ? Icons.check_circle : Icons.error_outline,
                      color: controller.success ? Colors.green : Colors.orange,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      controller.message ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => controller.checkVerification(),
                      child: const Text('Controleer opnieuw'),
                    ),
                    if (controller.success) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Terug naar inloggen'),
                      ),
                    ],
                  ],
                )),
        ),
      ),
    );
  }
}
