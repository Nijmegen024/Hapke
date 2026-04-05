import 'package:flutter/material.dart';

class HapkeBadge extends StatelessWidget {
  final int? count;
  const HapkeBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = count ?? 0;
    if (c <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        c.toString(),
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }
}
