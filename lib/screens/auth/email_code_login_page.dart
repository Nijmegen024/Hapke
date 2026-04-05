import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/email_code_login_controller.dart';

class EmailCodeLoginPage extends StatelessWidget {
  const EmailCodeLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmailCodeLoginController());
    const bg = Color(0xFF1F1F1F);
    const card = Color(0xFF141414);
    const teal = Color(0xFF2AAAB3);
    const orange = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Inloggen of account aanmaken',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _AuthButton(
                  background: Colors.black,
                  foreground: Colors.white,
                  label: 'Doorgaan met Apple',
                  icon: const Icon(Icons.apple, color: Colors.white),
                  onTap: () {
                    Get.snackbar('Auth', 'Apple login nog te configureren.');
                  },
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  background: Colors.white,
                  foreground: Colors.black87,
                  label: 'Doorgaan met Google',
                  icon: controller.googleBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, color: Colors.black),
                  onTap: controller.googleBusy ? null : () => controller.loginWithGoogle(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'of',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Doorgaan met e-mailadres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: controller.emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'E-mailadres',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      final emailOk = RegExp(r'^.+@.+\..+$').hasMatch(value);
                      return emailOk ? null : 'Vul een geldig e‑mailadres in';
                    },
                  ),
                ),
                const SizedBox(height: 14),
                if (controller.codeRequested)
                  Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: controller.codeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Verificatiecode (6 cijfers)',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (v) =>
                          (v?.trim().length ?? 0) >= 4 ? null : 'Vul de code in',
                    ),
                  ),
                if (controller.codeRequested) const SizedBox(height: 8),
                if (controller.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      controller.message!,
                      style: const TextStyle(color: Colors.tealAccent),
                    ),
                  ),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      controller.error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 6),
                _AuthButton(
                  background: orange,
                  foreground: Colors.white,
                  label: controller.codeRequested
                      ? 'Verificatiecode opnieuw sturen'
                      : 'Verificatiecode aanvragen',
                  icon: const Icon(Icons.mail_outline, color: Colors.white),
                  onTap: controller.requesting ? null : () => controller.requestCode(),
                  busy: controller.requesting,
                ),
                if (controller.codeRequested) ...[
                  const SizedBox(height: 10),
                  _AuthButton(
                    background: teal,
                    foreground: Colors.white,
                    label: 'Code invoeren',
                    icon: const Icon(Icons.lock_open, color: Colors.white),
                    onTap: controller.verifying ? null : () => controller.verifyCode(),
                    busy: controller.verifying,
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Door verder te gaan, ga je akkoord met onze Algemene voorwaarden en Privacyverklaring.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            )),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final Color background;
  final Color foreground;
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool busy;
  const _AuthButton({
    required this.background,
    required this.foreground,
    required this.label,
    required this.icon,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: disabled ? 0.7 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
