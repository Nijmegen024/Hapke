import 'dart:convert';
import 'package:get/get.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../models/friend.dart';
import '../../models/chat.dart';
import '../../network/api_client.dart';
import '../../network/api_helpers.dart';

class ChatController extends GetxController {
  final FriendUserInfo friend;
  final HapkeUser currentUser;

  final _thread = Rxn<ChatThread>();
  ChatThread? get thread => _thread.value;

  final _loading = true.obs;
  bool get loading => _loading.value;

  final _sending = false.obs;
  bool get sending => _sending.value;

  final _error = RxnString();
  String? get error => _error.value;

  ChatController({required this.friend, required this.currentUser});

  @override
  void onInit() {
    super.onInit();
    loadThread();
  }

  Future<void> loadThread() async {
    _loading.value = true;
    _error.value = null;
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/chats/direct/${friend.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(extractErrorMessage(res));
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        _thread.value = ChatThread.fromJson(decoded, currentUser.id);
      } else {
        throw Exception('Ongeldig antwoord van server');
      }
    } catch (e) {
      _error.value = 'Kon chat niet laden: $e';
    } finally {
      _loading.value = false;
    }
  }

  Future<bool> sendMessage(String text) async {
    final currentThread = _thread.value;
    if (currentThread == null || text.trim().isEmpty) return false;
    
    _sending.value = true;
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/chats/${currentThread.id}/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'content': text.trim()}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(extractErrorMessage(res));
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final message = ChatMessageView.fromJson(decoded, currentUser.id);
        _thread.value = ChatThread(
          id: currentThread.id,
          participants: currentThread.participants,
          messages: [...currentThread.messages, message],
        );
        return true;
      }
      return false;
    } catch (e) {
      _error.value = 'Bericht versturen mislukt: $e';
      return false;
    } finally {
      _sending.value = false;
    }
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
