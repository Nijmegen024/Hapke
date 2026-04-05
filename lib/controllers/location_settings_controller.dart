import 'package:get/get.dart';
import '../screens/account/location_settings_page.dart';

class LocationSettingsController extends GetxController {
  final LocationSettingsResult initial;
  LocationSettingsController({required this.initial});

  final _servicesEnabled = false.obs;
  bool get servicesEnabled => _servicesEnabled.value;
  set servicesEnabled(bool val) {
    _servicesEnabled.value = val;
    if (!val) {
      _preciseEnabled.value = false;
      _historyEnabled.value = false;
    }
  }

  final _preciseEnabled = false.obs;
  bool get preciseEnabled => _preciseEnabled.value;
  set preciseEnabled(bool val) => _preciseEnabled.value = val;

  final _historyEnabled = false.obs;
  bool get historyEnabled => _historyEnabled.value;
  set historyEnabled(bool val) => _historyEnabled.value = val;

  @override
  void onInit() {
    super.onInit();
    _servicesEnabled.value = initial.servicesEnabled;
    _preciseEnabled.value = initial.preciseEnabled;
    _historyEnabled.value = initial.historyEnabled;
  }

  void close() {
    Get.back(result: LocationSettingsResult(
      servicesEnabled: _servicesEnabled.value,
      preciseEnabled: _preciseEnabled.value,
      historyEnabled: _historyEnabled.value,
    ));
  }
}
