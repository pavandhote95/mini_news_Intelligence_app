import 'package:flutter/material.dart';

import '../../domain/entities/news_category.dart';

/// UI-only data for categories, kept out of the domain enum.
extension NewsCategoryUi on NewsCategory {
  IconData get icon => switch (this) {
        NewsCategory.business => Icons.trending_up_rounded,
        NewsCategory.technology => Icons.memory_rounded,
        NewsCategory.general => Icons.public_rounded,
        NewsCategory.science => Icons.science_outlined,
        NewsCategory.health => Icons.favorite_border_rounded,
        NewsCategory.entertainment => Icons.movie_outlined,
        NewsCategory.sports => Icons.sports_soccer_rounded,
      };
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.selected, required this.onSelected});

  final NewsCategory selected;
  final ValueChanged<NewsCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: NewsCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = NewsCategory.values[index];
          final isSelected = category == selected;
          return ChoiceChip(
            avatar: Icon(category.icon, size: 18),
            label: Text(category.label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}
