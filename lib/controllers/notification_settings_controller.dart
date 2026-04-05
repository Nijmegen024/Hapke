import 'package:get/get.dart';
import '../screens/account/notification_settings_page.dart';

class NotificationSettingsController extends GetxController {
  final NotificationSettingsResult initial;
  NotificationSettingsController({required this.initial});

  final _push = false.obs;
  bool get push => _push.value;
  set push(bool val) => _push.value = val;

  final _email = false.obs;
  bool get email => _email.value;
  set email(bool val) => _email.value = val;

  final _sms = false.obs;
  bool get sms => _sms.value;
  set sms(bool val) => _sms.value = val;

  @override
  void onInit() {
    super.onInit();
    _push.value = initial.push;
    _email.value = initial.email;
    _sms.value = initial.sms;
  }

  void close() {
    Get.back(result: NotificationSettingsResult(
      push: _push.value,
      email: _email.value,
      sms: _sms.value,
    ));
  }
}
