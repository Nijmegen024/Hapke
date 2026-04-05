import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user.dart';
import '../../network/api_client.dart';
import '../../core/constants.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final _gender = RxnString();
  String? get gender => _gender.value;
  set gender(String? val) => _gender.value = val;

  final _loading = false.obs;
  bool get loading => _loading.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _isLogin = true.obs;
  bool get isLogin => _isLogin.value;

  final _resendBusy = false.obs;
  bool get resendBusy => _resendBusy.value;

  final _resendMessage = RxnString();
  String? get resendMessage => _resendMessage.value;

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.onClose();
  }

  void toggleAuthMode() {
    _isLogin.value = !_isLogin.value;
    _error.value = null;
    _resendMessage.value = null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    _loading.value = true;
    _error.value = null;
    _resendMessage.value = null;

    final session = _isLogin.value
        ? await _performLogin(email, password)
        : await _registerAndLogin(email, password);

    _loading.value = false;

    if (session != null) {
      if (session.token.isEmpty) {
        Get.snackbar('Auth', 'Geen toegangstoken ontvangen van de server');
        return;
      }
      Get.back(result: session);
    } else if (_error.value != null) {
      Get.snackbar('Auth', _error.value!);
    }
  }

  Future<AuthSession?> _performLogin(String email, String password) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email, 'password': password});
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/login'),
        headers: headers,
        body: body,
      );
      if (res.statusCode == 200) {
        return _parseAuthResponse(res.body);
      }
      final data = _parseJson(res.body);
      final message = data?['message']?.toString();
      _error.value = (message != null && message.trim().isNotEmpty)
          ? message
          : 'Inloggen mislukt (${res.statusCode})';
    } catch (e) {
      _error.value = 'Inloggen mislukt: $e';
    }
    return null;
  }

  Future<AuthSession?> _registerAndLogin(String email, String password) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email, 'password': password});
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/register'),
        headers: headers,
        body: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = _parseJson(res.body);
        final requiresVerification = data?['requiresVerification'] == true;
        if (requiresVerification) {
          _error.value = 'Account aangemaakt. Controleer je e-mail om je account te activeren.';
          return null;
        }
        return await _performLogin(email, password);
      }
      if (res.statusCode == 400 || res.statusCode == 409) {
        return await _performLogin(email, password);
      }
      final data = _parseJson(res.body);
      final message = data?['message']?.toString();
      _error.value = (message != null && message.trim().isNotEmpty)
          ? message
          : 'Registreren mislukt (${res.statusCode})';
    } catch (e) {
      _error.value = 'Registreren mislukt: $e';
    }
    return null;
  }

  Future<void> resendVerification() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || _resendBusy.value) return;
    
    _resendBusy.value = true;
    _resendMessage.value = null;
    
    try {
      final res = await apiClient.post(
        Uri.parse('$apiBase/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) {
        _resendMessage.value = 'Verificatiemail is opnieuw verstuurd.';
      } else {
        final data = _parseJson(res.body);
        _resendMessage.value = (data?['message'] ?? 'Opnieuw versturen mislukt').toString();
      }
    } catch (e) {
      _resendMessage.value = 'Opnieuw versturen mislukt: $e';
    } finally {
      _resendBusy.value = false;
    }
  }

  AuthSession _parseAuthResponse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final userData = data['user'] as Map<String, dynamic>? ?? const {};
    final tokenValue = data['access_token'] ?? data['accessToken'] ?? data['token'] ?? '';
    final token = tokenValue.toString();

    final userId = (userData['id'] ?? '').toString();
    final user = HapkeUser(
      id: userId,
      name: (userData['name'] ?? '').toString().trim().isNotEmpty
          ? userData['name'].toString()
          : nameCtrl.text.trim(),
      email: (userData['email'] ?? emailCtrl.text.trim()).toString(),
      phone: (userData['phone'] ?? phoneCtrl.text.trim()).toString(),
      address: (userData['address'] ?? addressCtrl.text.trim()).toString(),
      gender: _gender.value ?? (userData['gender'] ?? 'Zeg ik liever niet').toString(),
    );

    return AuthSession(user: user, token: token);
  }

  Map<String, dynamic>? _parseJson(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
