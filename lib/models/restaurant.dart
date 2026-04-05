import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine; // free text shown to user
  final String category; // one of: Cafetaria, Sushi, Gezond
  final double rating;
  final String eta; // e.g., "25–35 min"
  final List<MenuItem> menu;
  final String imageUrl;
  final double minOrder; // e.g., 15.00
  final double? deliveryFee; // null => gratis bezorging

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.category,
    required this.rating,
    required this.eta,
    required this.menu,
    required this.imageUrl,
    required this.minOrder,
    this.deliveryFee,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    var menuList = (json['menu'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    return Restaurant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      cuisine: (json['cuisine'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      eta: (json['eta'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      minOrder: (json['minOrder'] ?? 0.0).toDouble(),
      deliveryFee: json['deliveryFee'] != null ? (json['deliveryFee'] as num).toDouble() : null,
      menu: menuList.map(MenuItem.fromJson).toList(),
    );
  }
}
