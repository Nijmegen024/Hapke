import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

Uri restaurantsUri({double? lat, double? lng}) {
  final base = Uri.parse('$apiBase/restaurants');
  if (lat == null || lng == null) return base;
  return base.replace(
    queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
  );
}

String extractErrorMessage(http.Response res) {
  try {
    if (res.body.isEmpty) {
      return 'Status ${res.statusCode}';
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final errors = decoded['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String && first.trim().isNotEmpty) {
          return first.trim();
        }
        if (first is Map && first['message'] is String) {
          return (first['message'] as String).trim();
        }
      }
    }
  } catch (_) {
    // fallback below
  }
  return 'Status ${res.statusCode}';
}

String formatPrice(int cents) {
  final euros = cents / 100.0;
  return '€ ${euros.toStringAsFixed(2)}';
}

String formatEuros(double euros) => '€ ' + euros.toStringAsFixed(2);
