// ─────────────────────────────────────────
// lib/models/food_model.dart
// Nigerian food database model
// ─────────────────────────────────────────

import 'package:hive/hive.dart';

part 'food_model.g.dart';

/// Glycemic impact of a food item
enum GlycemicImpact { low, medium, high }

/// Nutritional category of a food
enum FoodType { carb, protein, fat, fiber, vegetable }

/// Which meals a food is suitable for
enum MealCategory { breakfast, lunch, dinner, snack, any }

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String localName; // e.g. "Ewa" for beans

  @HiveField(3)
  final String emoji;

  @HiveField(4)
  final String typeStr; // stored as string for Hive

  @HiveField(5)
  final String glycemicImpactStr;

  @HiveField(6)
  final double fiberLevel; // 0.0 – 10.0

  @HiveField(7)
  final double proteinLevel; // 0.0 – 10.0

  @HiveField(8)
  final double carbLevel; // 0.0 – 10.0

  @HiveField(9)
  final int calories; // per standard serving

  @HiveField(10)
  final int priceNaira; // ₦ realistic street price

  @HiveField(11)
  final List<String> mealCategories;

  @HiveField(12)
  final String description;

  @HiveField(13)
  final String servingSize; // e.g. "1 cup", "2 pieces"

  @HiveField(14)
  final List<String> goodPairingIds; // IDs of foods that pair well

  @HiveField(15)
  final List<String> healthBenefits;

  @HiveField(16)
  final bool isOffline; // always true – pre-loaded

  const FoodItem({
    required this.id,
    required this.name,
    required this.localName,
    required this.emoji,
    required this.typeStr,
    required this.glycemicImpactStr,
    required this.fiberLevel,
    required this.proteinLevel,
    required this.carbLevel,
    required this.calories,
    required this.priceNaira,
    required this.mealCategories,
    required this.description,
    required this.servingSize,
    required this.goodPairingIds,
    required this.healthBenefits,
    this.isOffline = true,
  });

  FoodType get foodType {
    switch (typeStr) {
      case 'protein': return FoodType.protein;
      case 'fat': return FoodType.fat;
      case 'fiber': return FoodType.fiber;
      case 'vegetable': return FoodType.vegetable;
      default: return FoodType.carb;
    }
  }

  GlycemicImpact get glycemicImpact {
    switch (glycemicImpactStr) {
      case 'low': return GlycemicImpact.low;
      case 'high': return GlycemicImpact.high;
      default: return GlycemicImpact.medium;
    }
  }

  /// Health score contribution of this food (0–100)
  int get healthScore {
    int score = 50;
    score += (fiberLevel * 3).round();
    score += (proteinLevel * 2).round();
    if (glycemicImpact == GlycemicImpact.low) score += 20;
    if (glycemicImpact == GlycemicImpact.high) score -= 20;
    if (fiberLevel > 6) score += 10;
    return score.clamp(0, 100);
  }

  bool suitableFor(String meal) =>
      mealCategories.contains(meal) || mealCategories.contains('any');
}
