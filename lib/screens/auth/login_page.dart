import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isLogin ? 'Inloggen' : 'Account aanmaken')),
      ),
      body: Form(
        key: controller.formKey,
        child: Obx(() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!controller.isLogin) ...[
              TextFormField(
                controller: controller.nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Naam',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => controller.isLogin || (v != null && v.trim().isNotEmpty)
                    ? null
                    : 'Vul je naam in',
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: controller.emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E‑mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                final emailOk = RegExp(r'^.+@.+\..+$').hasMatch(value);
                return emailOk ? null : 'Vul een geldig e‑mailadres in';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Wachtwoord (minimaal 6 tekens)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) => (v == null || v.trim().length < 6)
                  ? 'Vul een wachtwoord in'
                  : null,
            ),
            const SizedBox(height: 12),
            if (!controller.isLogin) ...[
              TextFormField(
                controller: controller.phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mobiel nummer',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    controller.isLogin || (v != null && v.trim().length >= 6)
                    ? null
                    : 'Vul een geldig nummer in',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => controller.isLogin || (v != null && v.trim().isNotEmpty)
                    ? null
                    : 'Vul je adres in',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: controller.gender,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Geslacht',
                ),
                items: const [
                  DropdownMenuItem(value: 'Man', child: Text('Man')),
                  DropdownMenuItem(value: 'Vrouw', child: Text('Vrouw')),
                  DropdownMenuItem(value: 'Anders', child: Text('Anders')),
                  DropdownMenuItem(
                    value: 'Zeg ik liever niet',
                    child: Text('Zeg ik liever niet'),
                  ),
                ],
                onChanged: (value) => controller.gender = value,
                validator: (v) => controller.isLogin || (v != null && v.isNotEmpty)
                    ? null
                    : 'Maak een keuze',
              ),
              const SizedBox(height: 16),
            ],
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(controller.error!, style: const TextStyle(color: Colors.red)),
              ),
            if (controller.error?.toLowerCase().contains('activeer') == true ||
                controller.error?.toLowerCase().contains('verifieer') == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: controller.resendBusy ? null : controller.resendVerification,
                      child: controller.resendBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Stuur verificatiemail opnieuw'),
                    ),
                    if (controller.resendMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          controller.resendMessage!,
                          style: const TextStyle(color: Colors.teal),
                        ),
                      ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: controller.loading ? null : controller.submit,
              child: controller.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(controller.isLogin ? 'Inloggen' : 'Account aanmaken'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.loading
                  ? null
                  : () => controller.toggleAuthMode(),
              child: Text(
                controller.isLogin
                    ? 'Nog geen account? Registreren'
                    : 'Ik heb al een account - Inloggen',
              ),
            ),
          ],
        )),
      ),
    );
  }
}
