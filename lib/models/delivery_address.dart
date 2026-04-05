class DeliveryAddress {
  final String id;
  final String street;
  final String houseNumber;
  final String postalCode;
  final String city;
  final double? lat;
  final double? lng;
  final bool isPrimary;

  const DeliveryAddress({
    required this.id,
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.city,
    required this.lat,
    required this.lng,
    required this.isPrimary,
  });

  String get line1 => '$street $houseNumber'.trim();
  String get line2 => '$postalCode $city'.trim();
  bool get hasCoords => lat != null && lng != null;

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic value) {
      if (value is num) return value.toDouble();
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return DeliveryAddress(
      id: (json['id'] ?? '').toString(),
      street: (json['street'] ?? '').toString(),
      houseNumber: (json['houseNumber'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      lat: parseCoord(json['lat']),
      lng: parseCoord(json['lng']),
      isPrimary: json['isPrimary'] == true,
    );
  }
}

List<DeliveryAddress> parseDeliveryAddresses(dynamic payload) {
  if (payload is! List) return const <DeliveryAddress>[];
  return payload
      .whereType<Map<String, dynamic>>()
      .map(DeliveryAddress.fromJson)
      .where((address) => address.id.isNotEmpty)
      .toList();
}
