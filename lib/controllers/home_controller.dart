import 'package:get/get.dart';
import '../models/restaurant.dart';

class HomeController extends GetxController {
  final _query = ''.obs;
  String get query => _query.value;
  set query(String val) => _query.value = val;

  final _selectedCategory = RxnString();
  String? get selectedCategory => _selectedCategory.value;
  set selectedCategory(String? val) => _selectedCategory.value = val;

  final Map<String, String> chipIcons = {
    'Cafetaria':
        'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=120&q=60',
    'Sushi':
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=120&q=60',
    'Gezond':
        'https://images.unsplash.com/photo-1543353071-10c8ba85a904?auto=format&fit=crop&w=120&q=60',
  };

  void toggleCategory(String category) {
    if (_selectedCategory.value == category) {
      _selectedCategory.value = null;
    } else {
      _selectedCategory.value = category;
    }
  }

  List<Restaurant> getFilteredRestaurants(List<Restaurant> all) {
    final q = _query.value.toLowerCase();
    final cat = _selectedCategory.value;
    return all.where((r) {
      final matchesQuery =
          r.name.toLowerCase().contains(q) ||
          r.cuisine.toLowerCase().contains(q);
      final matchesCategory = cat == null || r.category == cat;
      return matchesQuery && matchesCategory;
    }).toList();
  }
}
