import 'dart:convert';
import 'package:get/get.dart';
import '../../network/api_client.dart';
import '../../core/constants.dart';

class VerifyAccountController extends GetxController {
  final String email;
  VerifyAccountController({required this.email});

  final _loading = true.obs;
  bool get loading => _loading.value;

  final _message = RxnString();
  String? get message => _message.value;

  final _success = false.obs;
  bool get success => _success.value;

  @override
  void onInit() {
    super.onInit();
    checkVerification();
  }

  Future<void> checkVerification() async {
    _loading.value = true;
    _message.value = null;
    try {
      final res = await apiClient.get(
        Uri.parse('$apiBase/auth/status?email=$email'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _success.value = data['isVerified'] == true;
        _message.value = _success.value
            ? 'Je account is geverifieerd! Je kunt nu inloggen.'
            : 'Je account is nog niet geverifieerd. Controleer je e-mail.';
      } else {
        _message.value = 'Er ging iets mis bij het controleren van je status.';
      }
    } catch (e) {
      _message.value = 'Fout: $e';
    } finally {
      _loading.value = false;
    }
  }
}
