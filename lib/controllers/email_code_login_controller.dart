import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app_config.dart';
import '../../models/user.dart';
import '../../network/api_client.dart';
import '../../core/constants.dart';

class EmailCodeLoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _codeRequested = false.obs;
  bool get codeRequested => _codeRequested.value;

  final _requesting = false.obs;
  bool get requesting => _requesting.value;

  final _verifying = false.obs;
  bool get verifying => _verifying.value;

  final _googleBusy = false.obs;
  bool get googleBusy => _googleBusy.value;

  final _message = RxnString();
  String? get message => _message.value;

  final _error = RxnString();
  String? get error => _error.value;

  @override
  void onClose() {
    emailCtrl.dispose();
    codeCtrl.dispose();
    super.onClose();
  }

  Future<void> loginWithGoogle() async {
    _error.value = null;
    _message.value = null;
    _googleBusy.value = true;
    try {
      final googleSignIn = GoogleSignIn(
        clientId: AppConfig.googleWebClientId.isNotEmpty
            ? AppConfig.googleWebClientId
            : null,
      );
      final account = await googleSignIn.signInSilently() ??
          await googleSignIn.signIn();
      if (account == null) {
        _error.value = 'Google inloggen geannuleerd.';
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _error.value = 'Geen Google token ontvangen.';
        return;
      }
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = (data['accessToken'] ?? '').toString();
        final userJson = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        if (token.isEmpty || userJson.isEmpty) {
          _error.value = 'Ongeldige server-respons';
          return;
        }
        final session = AuthSession(
          token: token,
          user: HapkeUser(
            id: (userJson['id'] ?? '').toString(),
            name: (userJson['name'] ?? account.displayName ?? '').toString(),
            email: (userJson['email'] ?? account.email).toString(),
            phone: (userJson['phone'] ?? '').toString(),
            address: (userJson['address'] ?? '').toString(),
            gender: (userJson['gender'] ?? 'Zeg ik liever niet').toString(),
          ),
        );
        Get.back(result: session);
      } else {
        _error.value = 'Google login faalde (${res.statusCode}).';
      }
    } catch (e) {
      _error.value = 'Google login fout: $e';
    } finally {
      _googleBusy.value = false;
    }
  }

  Future<void> requestCode() async {
    final email = emailCtrl.text.trim();
    final emailOk = RegExp(r'^.+@.+\..+$').hasMatch(email);
    if (!emailOk) {
      _error.value = 'Vul een geldig e‑mailadres in';
      return;
    }
    _error.value = null;
    _message.value = null;
    _requesting.value = true;
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/email/request-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) {
        _codeRequested.value = true;
        _message.value = 'Code verstuurd. Check je mail (10 min geldig).';
      } else if (res.statusCode == 429) {
        _error.value = 'Even wachten, probeer zo opnieuw.';
      } else {
        _error.value = 'Kon geen code versturen (${res.statusCode}).';
      }
    } catch (e) {
      _error.value = 'Fout bij versturen code: $e';
    } finally {
      _requesting.value = false;
    }
  }

  Future<void> verifyCode() async {
    if (!_codeRequested.value) {
      _error.value = 'Vraag eerst een code aan.';
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    final email = emailCtrl.text.trim();
    final code = codeCtrl.text.trim();
    _error.value = null;
    _message.value = null;
    _verifying.value = true;
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/email/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = (data['accessToken'] ?? '').toString();
        final userJson = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        if (token.isEmpty || userJson.isEmpty) {
          _error.value = 'Ongeldige server-respons';
          return;
        }
        final session = AuthSession(
          token: token,
          user: HapkeUser(
            id: (userJson['id'] ?? '').toString(),
            name: (userJson['name'] ?? '').toString(),
            email: (userJson['email'] ?? email),
            phone: (userJson['phone'] ?? '').toString(),
            address: (userJson['address'] ?? '').toString(),
            gender: (userJson['gender'] ?? 'Zeg ik liever niet').toString(),
          ),
        );
        Get.back(result: session);
      } else if (res.statusCode == 401) {
        _error.value = 'Code klopt niet of is verlopen.';
      } else if (res.statusCode == 410) {
        _error.value = 'Code verlopen, vraag een nieuwe aan.';
      } else {
        _error.value = 'Inloggen mislukt (${res.statusCode}).';
      }
    } catch (e) {
      _error.value = 'Inloggen mislukt: $e';
    } finally {
      _verifying.value = false;
    }
  }
}
