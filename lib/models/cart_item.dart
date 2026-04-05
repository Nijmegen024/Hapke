import 'menu_item.dart';
import 'restaurant.dart';

class CartItem {
  final Restaurant restaurant;
  final MenuItem item;
  int qty;
  CartItem({required this.restaurant, required this.item, this.qty = 1});
}
