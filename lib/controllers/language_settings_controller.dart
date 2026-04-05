import 'package:get/get.dart';

class LanguageSettingsController extends GetxController {
  final String initialLanguage;
  LanguageSettingsController({required this.initialLanguage});

  final _selectedLanguage = ''.obs;
  String get selectedLanguage => _selectedLanguage.value;
  set selectedLanguage(String val) => _selectedLanguage.value = val;

  final _languages = <String>[].obs;
  List<String> get languages => _languages;

  @override
  void onInit() {
    super.onInit();
    _languages.assignAll([
      'Nederlands (NL)',
      'Nederlands (BE)',
      'Engels (EN)',
      'Duits (DE)',
    ]);
    _selectedLanguage.value = initialLanguage;
    if (!_languages.contains(initialLanguage)) {
      _languages.insert(0, initialLanguage);
    }
  }

  void close() {
    Get.back(result: _selectedLanguage.value);
  }
}
