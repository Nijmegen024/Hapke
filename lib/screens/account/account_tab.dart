import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/account_controller.dart';
import '../../models/user.dart';

class AccountTab extends StatelessWidget {
  final HapkeUser? user;
  final VoidCallback onLogin;
  final Future<void> Function()? onLogout;
  final Future<void> Function() onManageAddresses;

  const AccountTab({
    super.key,
    required this.user,
    required this.onLogin,
    required this.onLogout,
    required this.onManageAddresses,
  });

  static const Color primaryColor = Color(0xFF2AAAB3);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color accentColor = Color(0xFFFFC857);

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bekijk en pas aan',
              style: TextStyle(color: Color(0xFF6F7F99)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(color: Color(0xFF6F7F99)),
          ),
          trailing: const Icon(Icons.chevron_right, color: primaryColor),
          onTap:
              onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title kan je binnenkort aanpassen'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountController());

    if (user == null) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: ElevatedButton.icon(
          onPressed: onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.login),
          label: const Text('Inloggen / Aanmelden (e-mailcode)'),
        ),
      );
    }

    final displayName = user!.name.trim().isEmpty ? user!.email : user!.name;
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Obx(() => ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 22,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hé, ${displayName.split(' ').first}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user!.email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6F7F99),
                          ),
                        ),
                        if (user!.phone.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.phone,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6F7F99),
                            ),
                          ),
                        ],
                        if (user!.address.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.address,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6F7F99),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support opent binnenkort'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.headset_mic_outlined,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hulp nodig? Wij zijn er voor je',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap hier en we helpen je meteen verder.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Je account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.person_outline,
                    title: 'Persoonlijke gegevens',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gegevens wijzigen komt eraan'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.location_on_outlined,
                    title: 'Bezorgadressen',
                    onTap: () => onManageAddresses(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Instellingen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    context: context,
                    icon: Icons.my_location_outlined,
                    title: 'Locatieservices',
                    value: controller.locationServicesEnabled ? 'Aan' : 'Uit',
                    onTap: () => controller.openLocationSettings(),
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.language_outlined,
                    title: 'Taal',
                    value: controller.selectedLanguage,
                    onTap: () => controller.openLanguageSettings(),
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: 'Notificaties',
                    value: controller.notificationSummary,
                    onTap: () => controller.openNotificationSettings(),
                  ),
                  _buildSettingTile(
                    context: context,
                    icon: Icons.poll_outlined,
                    title: 'Stem mee',
                    value: controller.pollSummary,
                    onTap: () => controller.openPoll(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => controller.logout(onLogout),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Uitloggen',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
