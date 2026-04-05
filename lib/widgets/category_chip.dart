import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final String? iconUrl; // kleine afbeelding (niet de restaurantfoto)

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.iconUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        avatar: iconUrl == null
            ? const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white24,
                child: Icon(Icons.fastfood, size: 14, color: Colors.white),
              )
            : CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.network(
                    iconUrl!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.fastfood,
                      size: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        backgroundColor: const Color(0xFF2AAAB3), // teal
        selectedColor: const Color(0xFF2AAAB3),
        side: BorderSide(color: selected ? Colors.white : Colors.white24),
        onSelected: (_) => onSelected(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
