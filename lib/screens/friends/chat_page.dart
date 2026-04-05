import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chat_controller.dart';
import '../../models/user.dart';
import '../../models/friend.dart';

class ChatPage extends StatefulWidget {
  final FriendUserInfo friend;
  final HapkeUser currentUser;
  const ChatPage({super.key, required this.friend, required this.currentUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late ChatController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatController(friend: widget.friend, currentUser: widget.currentUser));
    
    // Initial scroll to bottom after loading
    ever(controller.loading.obs, (loading) {
      if (!loading) _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friend.id != widget.friend.id) {
       Get.delete<ChatController>();
       controller = Get.put(ChatController(friend: widget.friend, currentUser: widget.currentUser));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSendMessage() async {
    final success = await controller.sendMessage(_ctrl.text);
    if (success) {
      _ctrl.clear();
      _scrollToBottom();
    } else if (controller.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friend.displayName)),
      body: Obx(() {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null && controller.thread == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error!, textAlign: TextAlign.center),
                ElevatedButton.icon(
                  onPressed: controller.loadThread,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Opnieuw proberen'),
                ),
              ],
            ),
          );
        }
        final thread = controller.thread;
        if (thread == null) {
          return const Center(child: Text('Geen chat gevonden'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: thread.messages.length,
                itemBuilder: (_, i) {
                  final message = thread.messages[i];
                  final alignment = message.isMine ? Alignment.centerRight : Alignment.centerLeft;
                  final bubbleColor = message.isMine ? const Color(0xFF2AAAB3) : Colors.grey.shade200;
                  final textColor = message.isMine ? Colors.white : Colors.black87;
                  return Align(
                    alignment: alignment,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!message.isMine)
                            Text(
                              message.sender.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          Text(message.content, style: TextStyle(color: textColor, fontSize: 15)),
                          Text(
                            controller.formatTimestamp(message.createdAt),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Schrijf een bericht...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controller.sending ? null : _handleSendMessage,
                      child: controller.sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
