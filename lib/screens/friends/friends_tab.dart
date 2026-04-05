import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/friends_controller.dart';
import '../../models/user.dart';
import '../../models/friend.dart';
import 'chat_page.dart';
import '../auth/login_page.dart';

class FriendsTab extends StatefulWidget {
  final HapkeUser? currentUser;
  final Future<void> Function()? onLogin;
  const FriendsTab({super.key, required this.currentUser, this.onLogin});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  late FriendsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FriendsController(currentUser: widget.currentUser));
  }

  @override
  void didUpdateWidget(covariant FriendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser?.id != widget.currentUser?.id) {
      // Re-initialize controller with new user context
      Get.delete<FriendsController>();
      controller = Get.put(FriendsController(currentUser: widget.currentUser));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    if (widget.currentUser == null) {
      await _promptLogin();
      return;
    }
    await controller.handleSearch(_searchCtrl.text);
  }

  Future<void> _openChat(FriendUserInfo friend) async {
    final currentUser = widget.currentUser;
    if (currentUser == null) {
      await _promptLogin();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(friend: friend, currentUser: currentUser),
      ),
    );
    await controller.loadAll();
  }

  Future<void> _promptLogin() async {
    if (widget.onLogin != null) {
      await widget.onLogin!.call();
      return;
    }
    final result = await Navigator.of(
      context,
    ).push<AuthSession>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (result != null) {
      // Parent handles state update
    }
  }

  Widget _buildSearchAction(FriendSearchResult result) {
    switch (result.relationship.toUpperCase()) {
      case 'NONE':
        return Obx(
          () => ElevatedButton(
            onPressed: controller.searching
                ? null
                : () async {
                    final success = await controller.sendFriendRequest(
                      result.user.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vriendschapsverzoek verstuurd'),
                        ),
                      );
                      await controller.handleSearch(_searchCtrl.text);
                    }
                  },
            child: const Text('Toevoegen'),
          ),
        );
      case 'FRIEND':
        return OutlinedButton(
          onPressed: () => _openChat(result.user),
          child: const Text('Open chat'),
        );
      case 'PENDING_OUTGOING':
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Verzoek verstuurd'),
        );
      case 'PENDING_INCOMING':
        if (result.friendshipId == null) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () =>
                  controller.respondToRequest(result.friendshipId!, 'accept'),
              child: const Text('Accepteer'),
            ),
            TextButton(
              onPressed: () =>
                  controller.respondToRequest(result.friendshipId!, 'decline'),
              child: const Text('Weiger'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vrienden')),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: _promptLogin,
            icon: const Icon(Icons.login),
            label: const Text('Log in om vrienden te beheren'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vrienden')),
      body: RefreshIndicator(
        onRefresh: controller.loadAll,
        child: Obx(() {
          final showSpinner =
              controller.loading &&
              controller.friends.isEmpty &&
              controller.incoming.isEmpty &&
              controller.outgoing.isEmpty;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Zoek op naam of e-mail',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _handleSearch,
                  ),
                ),
                onSubmitted: (_) => _handleSearch(),
              ),
              if (controller.searching) const LinearProgressIndicator(),
              if (!controller.searching &&
                  controller.searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Zoekresultaten',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...controller.searchResults.map(
                  (result) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          result.user.displayName.isNotEmpty
                              ? result.user.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(result.user.displayName),
                      subtitle: Text(result.user.email),
                      trailing: _buildSearchAction(result),
                    ),
                  ),
                ),
              ],
              if (showSpinner)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (controller.incoming.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Binnenkomende verzoeken',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...controller.incoming.map((req) {
                  final other = req.requester;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          other.displayName.isNotEmpty
                              ? other.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(other.displayName),
                      subtitle: Text(other.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => controller.respondToRequest(
                              req.friendshipId,
                              'accept',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => controller.respondToRequest(
                              req.friendshipId,
                              'decline',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (controller.friends.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Je vrienden (${controller.friends.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                ...controller.friends.map(
                  (f) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          f.user.displayName.isNotEmpty
                              ? f.user.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(f.user.displayName),
                      subtitle: Text(f.user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_outlined),
                        onPressed: () => _openChat(f.user),
                      ),
                    ),
                  ),
                ),
              ],
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
