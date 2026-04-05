import 'package:get/get.dart';
import '../screens/account/location_settings_page.dart';
import '../screens/account/language_settings_page.dart';
import '../screens/account/notification_settings_page.dart';
import '../screens/account/restaurant_poll_page.dart';

class AccountController extends GetxController {
  final _locationServicesEnabled = true.obs;
  bool get locationServicesEnabled => _locationServicesEnabled.value;

  final _preciseLocationEnabled = true.obs;
  bool get preciseLocationEnabled => _preciseLocationEnabled.value;

  final _saveLocationHistory = true.obs;
  bool get saveLocationHistory => _saveLocationHistory.value;

  final _selectedLanguage = 'Nederlands (NL)'.obs;
  String get selectedLanguage => _selectedLanguage.value;

  final _pushNotifications = true.obs;
  bool get pushNotifications => _pushNotifications.value;

  final _emailNotifications = true.obs;
  bool get emailNotifications => _emailNotifications.value;

  final _smsNotifications = false.obs;
  bool get smsNotifications => _smsNotifications.value;

  final _pollVotes = <String, int>{'Mc Donalds': 0, 'Mr. Shushi': 0, 'KFC': 0}.obs;
  Map<String, int> get pollVotes => _pollVotes;

  final _pollSelection = RxnString();
  String? get pollSelection => _pollSelection.value;

  String get notificationSummary {
    final selections = <String>[];
    if (_pushNotifications.value) selections.add('Push');
    if (_emailNotifications.value) selections.add('E-mail');
    if (_smsNotifications.value) selections.add('SMS');
    return selections.isEmpty ? 'Uitgeschakeld' : selections.join(', ');
  }

  String get pollSummary => _pollSelection.value == null
      ? 'Stem op het volgende restaurant'
      : 'Je stem: ${_pollSelection.value}';

  Future<void> openLocationSettings() async {
    final result = await Get.to<LocationSettingsResult>(() => LocationSettingsPage(
      initial: LocationSettingsResult(
        servicesEnabled: _locationServicesEnabled.value,
        preciseEnabled: _preciseLocationEnabled.value,
        historyEnabled: _saveLocationHistory.value,
      ),
    ));

    if (result != null) {
      _locationServicesEnabled.value = result.servicesEnabled;
      _preciseLocationEnabled.value = result.preciseEnabled;
      _saveLocationHistory.value = result.historyEnabled;
    }
  }

  Future<void> openLanguageSettings() async {
    final result = await Get.to<String>(() => LanguageSettingsPage(
      initialLanguage: _selectedLanguage.value,
    ));

    if (result != null && result.isNotEmpty) {
      _selectedLanguage.value = result;
    }
  }

  Future<void> openNotificationSettings() async {
    final result = await Get.to<NotificationSettingsResult>(() => NotificationSettingsPage(
      initial: NotificationSettingsResult(
        push: _pushNotifications.value,
        email: _emailNotifications.value,
        sms: _smsNotifications.value,
      ),
    ));

    if (result != null) {
      _pushNotifications.value = result.push;
      _emailNotifications.value = result.email;
      _smsNotifications.value = result.sms;
    }
  }

  Future<void> openPoll() async {
    final result = await Get.to<RestaurantPollResult>(() => RestaurantPollPage(
      initialChoice: _pollSelection.value,
      initialVotes: _pollVotes,
    ));

    if (result != null) {
      _pollSelection.value = result.selectedOption;
      _pollVotes.assignAll(result.votes);
    }
  }

  Future<void> logout(Future<void> Function()? onLogout) async {
    if (onLogout != null) {
      await onLogout();
      Get.snackbar('Account', 'Je bent uitgelogd');
    }
  }
}
