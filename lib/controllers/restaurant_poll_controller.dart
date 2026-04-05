import 'package:get/get.dart';
import '../screens/account/restaurant_poll_page.dart';

class RestaurantPollController extends GetxController {
  final Map<String, int> initialVotes;
  final String? initialChoice;

  RestaurantPollController({
    required this.initialVotes,
    this.initialChoice,
  });

  static const List<String> options = ['Mc Donalds', 'Mr. Shushi', 'KFC'];

  final _votes = <String, int>{}.obs;
  Map<String, int> get votes => _votes;

  final _selected = RxnString();
  String? get selected => _selected.value;
  set selected(String? val) => _selected.value = val;

  final _confirmed = RxnString();
  String? get confirmed => _confirmed.value;

  @override
  void onInit() {
    super.onInit();
    _votes.assignAll({
      for (final option in options) option: initialVotes[option] ?? 0,
    });
    _confirmed.value = initialChoice;
    _selected.value = initialChoice;
  }

  int get totalVotes =>
      _votes.values.fold<int>(0, (sum, value) => sum + value);

  void submitVote() {
    if (_selected.value == null) {
      Get.snackbar('Fout', 'Kies eerst een restaurant om op te stemmen',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_confirmed.value != null && _confirmed.value != _selected.value) {
      final current = _votes[_confirmed.value!] ?? 0;
      if (current > 0) {
        _votes[_confirmed.value!] = current - 1;
      }
    }
    
    if (_confirmed.value != _selected.value) {
      _votes[_selected.value!] = (_votes[_selected.value!] ?? 0) + 1;
    }
    _confirmed.value = _selected.value;

    Get.snackbar('Bedankt', 'Bedankt voor je stem!',
        snackPosition: SnackPosition.BOTTOM);
  }

  void clearVote() {
    if (_confirmed.value == null) return;

    final current = _votes[_confirmed.value!] ?? 0;
    if (current > 0) {
      _votes[_confirmed.value!] = current - 1;
    }
    _confirmed.value = null;
    _selected.value = null;

    Get.snackbar('Info', 'Je stem is verwijderd',
        snackPosition: SnackPosition.BOTTOM);
  }

  void close() {
    Get.back(result: RestaurantPollResult(
      selectedOption: _confirmed.value,
      votes: Map<String, int>.from(_votes),
    ));
  }
}
