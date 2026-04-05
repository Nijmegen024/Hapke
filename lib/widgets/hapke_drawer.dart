import 'package:flutter/material.dart';

import '../models/user.dart';

class HapkeDrawer extends StatelessWidget {
  final HapkeUser? user;
  final int cartCount;
  final VoidCallback onOpenCart;
  final VoidCallback onLoginTap;
  final Future<void> Function() onLogoutTap;

  const HapkeDrawer({
    super.key,
    required this.user,
    required this.cartCount,
    required this.onOpenCart,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Niet ingelogd'),
              accountEmail: Text(user?.email ?? 'Log in om te bestellen'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.name.isNotEmpty ?? false)
                      ? user!.name[0].toUpperCase()
                      : 'H',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text('MANDDD!! (${cartCount})'),
              onTap: () {
                Navigator.pop(context);
                onOpenCart();
              },
            ),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Inloggen / Aanmelden'),
                onTap: () {
                  Navigator.pop(context);
                  onLoginTap();
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profiel'),
                subtitle: Text(
                  '${user!.name} • ${user!.phone}\n${user!.address}',
                ),
                isThreeLine: true,
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Uitloggen'),
                onTap: () async {
                  Navigator.pop(context);
                  await onLogoutTap();
                },
              ),
            ],
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Hapke • live build',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
