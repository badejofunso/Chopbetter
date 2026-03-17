// ─────────────────────────────────────────
// lib/models/user_profile.dart
// ─────────────────────────────────────────

import 'package:hive/hive.dart';

part 'user_profile.g.dart';

enum HealthGoal { loseWeight, maintain, gainWeight }
enum HealthCondition { none, diabetes, hypertension, both }
enum Gender { male, female }

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) int age;
  @HiveField(2) String genderStr;
  @HiveField(3) double weightKg;
  @HiveField(4) String healthGoalStr;
  @HiveField(5) String healthConditionStr;
  @HiveField(6) int dailyBudgetNaira;
  @HiveField(7) bool onboardingComplete;
  @HiveField(8) DateTime createdAt;
  @HiveField(9) int streakDays;
  @HiveField(10) int totalMealsTracked;

  UserProfile({
    required this.name,
    required this.age,
    required this.genderStr,
    required this.weightKg,
    required this.healthGoalStr,
    required this.healthConditionStr,
    required this.dailyBudgetNaira,
    this.onboardingComplete = false,
    DateTime? createdAt,
    this.streakDays = 0,
    this.totalMealsTracked = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Gender get gender => genderStr == 'female' ? Gender.female : Gender.male;

  HealthGoal get healthGoal {
    switch (healthGoalStr) {
      case 'lose': return HealthGoal.loseWeight;
      case 'gain': return HealthGoal.gainWeight;
      default: return HealthGoal.maintain;
    }
  }

  HealthCondition get healthCondition {
    switch (healthConditionStr) {
      case 'diabetes': return HealthCondition.diabetes;
      case 'hypertension': return HealthCondition.hypertension;
      case 'both': return HealthCondition.both;
      default: return HealthCondition.none;
    }
  }

  /// Estimated daily calorie target
  int get dailyCalorieTarget {
    // Mifflin-St Jeor Equation (simplified)
    double bmr = gender == Gender.male
        ? (10 * weightKg) + (6.25 * 170) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * 160) - (5 * age) - 161;

    double multiplier = 1.375; // lightly active
    switch (healthGoal) {
      case HealthGoal.loseWeight:
        return (bmr * multiplier - 400).round();
      case HealthGoal.gainWeight:
        return (bmr * multiplier + 300).round();
      default:
        return (bmr * multiplier).round();
    }
  }

  bool get hasDiabetes =>
      healthCondition == HealthCondition.diabetes ||
      healthCondition == HealthCondition.both;

  bool get hasHypertension =>
      healthCondition == HealthCondition.hypertension ||
      healthCondition == HealthCondition.both;

  /// Budget per meal (breakfast:20%, lunch:45%, dinner:35%)
  int get breakfastBudget => (dailyBudgetNaira * 0.20).round();
  int get lunchBudget => (dailyBudgetNaira * 0.45).round();
  int get dinnerBudget => (dailyBudgetNaira * 0.35).round();
}


// ─────────────────────────────────────────
// lib/models/meal_plan.dart
// ─────────────────────────────────────────

class MealItem {
  final String foodId;
  final String foodName;
  final String emoji;
  final String servingSize;
  final int calories;
  final int priceNaira;
  final int healthScore;
  final String? pairingNote; // e.g. "Add beans to reduce GI spike"

  const MealItem({
    required this.foodId,
    required this.foodName,
    required this.emoji,
    required this.servingSize,
    required this.calories,
    required this.priceNaira,
    required this.healthScore,
    this.pairingNote,
  });
}

class Meal {
  final String type; // breakfast, lunch, dinner
  final List<MealItem> items;
  final String explanation;
  final String smartPairingTip;

  const Meal({
    required this.type,
    required this.items,
    required this.explanation,
    required this.smartPairingTip,
  });

  int get totalCalories => items.fold(0, (s, i) => s + i.calories);
  int get totalCost => items.fold(0, (s, i) => s + i.priceNaira);
  int get avgHealthScore {
    if (items.isEmpty) return 0;
    return (items.fold(0, (s, i) => s + i.healthScore) / items.length).round();
  }

  String get displayName {
    switch (type) {
      case 'breakfast': return '🌅 Breakfast';
      case 'lunch': return '☀️ Lunch';
      case 'dinner': return '🌙 Dinner';
      default: return '🍽 Meal';
    }
  }
}

class DailyMealPlan {
  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final DateTime date;
  final int overallHealthScore;
  final String dailyAdvice;

  const DailyMealPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.date,
    required this.overallHealthScore,
    required this.dailyAdvice,
  });

  int get totalCalories =>
      breakfast.totalCalories + lunch.totalCalories + dinner.totalCalories;

  int get totalCost =>
      breakfast.totalCost + lunch.totalCost + dinner.totalCost;
}


// ─────────────────────────────────────────
// lib/models/pairing_suggestion.dart
// ─────────────────────────────────────────

class PairingSuggestion {
  final String baseFood;
  final String baseFoodEmoji;
  final List<String> pairWith;
  final List<String> pairEmojis;
  final String reason;
  final String beforeGlycemic; // e.g. "High spike"
  final String afterGlycemic;  // e.g. "Medium spike"
  final int healthScoreImprovement; // 0–50
  final String quickTip;

  const PairingSuggestion({
    required this.baseFood,
    required this.baseFoodEmoji,
    required this.pairWith,
    required this.pairEmojis,
    required this.reason,
    required this.beforeGlycemic,
    required this.afterGlycemic,
    required this.healthScoreImprovement,
    required this.quickTip,
  });
}
