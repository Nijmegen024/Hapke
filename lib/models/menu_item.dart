class MenuItem {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] ?? json['itemId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceCents: readPriceCents(json),
      imageUrl: (json['imageUrl'] ?? '').toString().isEmpty ? null : json['imageUrl'].toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
    );
  }
}

List<MenuItem> parseMenuItemsFromApi(dynamic rawMenu) {
  if (rawMenu is! List) {
    return const <MenuItem>[];
  }
  final parsed = <MenuItem>[];
  for (final entry in rawMenu) {
    if (entry is! Map<String, dynamic>) continue;
    final id = (entry['id'] ?? entry['itemId'] ?? '').toString().trim();
    final name = (entry['name'] ?? '').toString().trim();
    if (id.isEmpty || name.isEmpty) continue;
    final description = (entry['description'] ?? '').toString().trim();
    final priceCents = readPriceCents(entry);
    final rawImage = (entry['imageUrl'] ?? '').toString().trim();
    final imageUrl = rawImage.isEmpty ? null : rawImage;
    final rawCategoryId = (entry['categoryId'] ?? '').toString().trim();
    final rawCategoryName = (entry['categoryName'] ?? entry['category'] ?? '')
        .toString()
        .trim();
    parsed.add(
      MenuItem(
        id: id,
        name: name,
        description: description,
        priceCents: priceCents,
        imageUrl: imageUrl,
        categoryId: rawCategoryId.isNotEmpty
            ? rawCategoryId
            : (rawCategoryName.isNotEmpty ? rawCategoryName : null),
        categoryName: rawCategoryName.isNotEmpty ? rawCategoryName : null,
      ),
    );
  }
  return parsed;
}

int readPriceCents(Map<String, dynamic> json) {
  final rawCents = json['priceCents'];
  if (rawCents is num) {
    final cents = rawCents.round();
    return cents >= 0 ? cents : 0;
  }
  final rawPrice = json['price'];
  double? euros;
  if (rawPrice is num) {
    euros = rawPrice.toDouble();
  } else if (rawPrice != null) {
    euros = double.tryParse(rawPrice.toString());
  }
  if (euros == null) {
    return 0;
  }
  final cents = (euros * 100).round();
  return cents >= 0 ? cents : 0;
}
