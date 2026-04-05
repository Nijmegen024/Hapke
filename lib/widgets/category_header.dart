import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

class CategoryHeader extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onTap;
  final String Function(String id)? labelBuilder;

  CategoryHeader({
    required this.categories,
    required this.selected,
    required this.onTap,
    this.labelBuilder,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = cat == selected;
            final label = labelBuilder?.call(cat) ?? cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(label),
                onSelected: (_) => onTap(cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant CategoryHeader oldDelegate) {
    return !setEquals(categories.toSet(), oldDelegate.categories.toSet()) ||
        selected != oldDelegate.selected;
  }
}
