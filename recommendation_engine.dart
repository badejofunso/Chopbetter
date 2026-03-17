// ─────────────────────────────────────────
// lib/services/recommendation_engine.dart
// Core meal recommendation logic
// ─────────────────────────────────────────

import '../data/food_database.dart';
import '../models/food_model.dart';
import '../models/user_profile.dart';
import 'food_pairing_service.dart';

// Import meal_plan models directly here
class MealItem {
  final String foodId;
  final String foodName;
  final String emoji;
  final String servingSize;
  final int calories;
  final int priceNaira;
  final int healthScore;
  final String? pairingNote;

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
  final String type;
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
// The Recommendation Engine
// ─────────────────────────────────────────

class RecommendationEngine {
  final UserProfile profile;

  RecommendationEngine(this.profile);

  /// Generate a full daily meal plan
  DailyMealPlan generateDailyPlan() {
    final breakfast = _buildMeal('breakfast', profile.breakfastBudget);
    final lunch = _buildMeal('lunch', profile.lunchBudget);
    final dinner = _buildMeal('dinner', profile.dinnerBudget);

    final overallScore = ((breakfast.avgHealthScore +
                lunch.avgHealthScore +
                dinner.avgHealthScore) /
            3)
        .round();

    return DailyMealPlan(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      date: DateTime.now(),
      overallHealthScore: overallScore,
      dailyAdvice: _generateDailyAdvice(overallScore),
    );
  }

  Meal _buildMeal(String mealType, int budget) {
    // Step 1: Get all foods suitable for this meal and within budget
    List<FoodItem> candidates = FoodDatabase.forMeal(mealType)
        .where((f) => f.priceNaira <= budget)
        .toList();

    if (candidates.isEmpty) {
      candidates = FoodDatabase.forMeal(mealType).take(3).toList();
    }

    // Step 2: Apply health condition filters
    if (profile.hasDiabetes) {
      candidates.sort((a, b) {
        final giScore = _giPriority(a.glycemicImpact)
            .compareTo(_giPriority(b.glycemicImpact));
        if (giScore != 0) return giScore;
        return b.fiberLevel.compareTo(a.fiberLevel);
      });
    }
    if (profile.hasHypertension) {
      candidates.sort((a, b) => b.fiberLevel.compareTo(a.fiberLevel));
    }
    if (profile.healthGoal == HealthGoal.loseWeight) {
      candidates.sort((a, b) => a.calories.compareTo(b.calories));
    }

    // Step 3: Pick a base food (carb or protein)
    FoodItem? baseFood;
    List<FoodItem> carbFoods = candidates.where((f) => f.typeStr == 'carb').toList();
    List<FoodItem> proteinFoods = candidates.where((f) => f.typeStr == 'protein').toList();

    baseFood = carbFoods.isNotEmpty ? carbFoods.first : candidates.first;
    int remainingBudget = budget - baseFood.priceNaira;

    List<MealItem> items = [_toMealItem(baseFood)];

    // Step 4: CRITICAL — apply smart pairing (no naked carbs!)
    if (baseFood.typeStr == 'carb') {
      // Must add a protein pairing
      final pairingIds = baseFood.goodPairingIds;
      FoodItem? protein = pairingIds
          .map(FoodDatabase.getById)
          .whereType<FoodItem>()
          .where((f) =>
              f.typeStr == 'protein' &&
              f.priceNaira <= remainingBudget)
          .firstOrNull;

      protein ??= proteinFoods
          .where((f) => f.priceNaira <= remainingBudget)
          .firstOrNull;

      if (protein != null) {
        items.add(_toMealItem(protein, pairingNote:
            '+ ${protein.name} reduces blood sugar spike'));
        remainingBudget -= protein.priceNaira;
      }

      // Try to add a vegetable
      FoodItem? veg = pairingIds
          .map(FoodDatabase.getById)
          .whereType<FoodItem>()
          .where((f) =>
              f.typeStr == 'vegetable' &&
              f.priceNaira <= remainingBudget)
          .firstOrNull;

      veg ??= candidates
          .where((f) =>
              f.typeStr == 'vegetable' &&
              f.priceNaira <= remainingBudget)
          .firstOrNull;

      if (veg != null) {
        items.add(_toMealItem(veg,
            pairingNote: '+ ${veg.name} adds fibre & micronutrients'));
      }
    }

    // Step 5: Generate smart pairing tip
    final check = FoodPairingService.checkMealBalance(
        items.map((i) => FoodDatabase.getById(i.foodId)).whereType<FoodItem>().toList());

    String pairingTip = check.isBalanced
        ? '✅ Great combination! Protein + fibre keeps blood sugar stable.'
        : check.suggestions.isNotEmpty
            ? check.suggestions.first
            : '💡 This meal is balanced for your health goal.';

    String explanation = _generateMealExplanation(mealType, items, profile);

    return Meal(
      type: mealType,
      items: items,
      explanation: explanation,
      smartPairingTip: pairingTip,
    );
  }

  MealItem _toMealItem(FoodItem food, {String? pairingNote}) => MealItem(
        foodId: food.id,
        foodName: food.name,
        emoji: food.emoji,
        servingSize: food.servingSize,
        calories: food.calories,
        priceNaira: food.priceNaira,
        healthScore: food.healthScore,
        pairingNote: pairingNote,
      );

  int _giPriority(GlycemicImpact gi) {
    switch (gi) {
      case GlycemicImpact.low: return 0;
      case GlycemicImpact.medium: return 1;
      case GlycemicImpact.high: return 2;
    }
  }

  String _generateMealExplanation(
      String mealType, List<MealItem> items, UserProfile profile) {
    String base = '';
    switch (mealType) {
      case 'breakfast':
        base = 'A balanced breakfast to start your day with steady energy.';
      case 'lunch':
        base = 'A filling lunch within your ₦${profile.lunchBudget} budget.';
      case 'dinner':
        base = 'A light dinner that won\'t overload your system at night.';
      default:
        base = 'A balanced Nigerian meal.';
    }

    if (profile.hasDiabetes) {
      base += ' Low-GI foods selected to prevent blood sugar spikes.';
    }
    if (profile.hasHypertension) {
      base += ' Heart-friendly selection — low sodium, high potassium.';
    }
    if (profile.healthGoal == HealthGoal.loseWeight) {
      base += ' Lower-calorie options chosen to support your weight loss goal.';
    }

    return base;
  }

  String _generateDailyAdvice(int score) {
    if (score >= 80) {
      return '🌟 Excellent eating today! Your meals are well-balanced with good protein, fibre, and low-GI choices. Keep it up!';
    } else if (score >= 65) {
      return '👍 Good effort! Your meals are mostly balanced. Try adding more vegetables to boost your score further.';
    } else if (score >= 50) {
      return '💡 Fair. Remember to always pair your carbs with protein or fibre to prevent blood sugar spikes.';
    } else {
      return '⚠️ Your meals need improvement. Focus on adding beans or vegetables to each carb-heavy meal.';
    }
  }
}


// ─────────────────────────────────────────
// lib/services/health_scoring_service.dart
// Health score calculation (0–100)
// ─────────────────────────────────────────

class HealthScoringService {
  /// Score a full daily meal plan (0–100)
  static int scoreDailyPlan(DailyMealPlan plan) {
    int score = 0;

    // Breakfast weight: 25%, Lunch: 40%, Dinner: 35%
    score += (plan.breakfast.avgHealthScore * 0.25).round();
    score += (plan.lunch.avgHealthScore * 0.40).round();
    score += (plan.dinner.avgHealthScore * 0.35).round();

    // Bonus: variety of food types across the day
    final allFoodIds = [
      ...plan.breakfast.items,
      ...plan.lunch.items,
      ...plan.dinner.items,
    ].map((i) => i.foodId).toSet();

    if (allFoodIds.length >= 5) score += 5;
    if (allFoodIds.length >= 8) score += 5;

    return score.clamp(0, 100);
  }

  /// Score a single meal (0–100)
  static MealScore scoreMeal(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return MealScore(
        score: 0,
        breakdown: {},
        label: 'Empty',
        color: 0xFFE0E0E0,
        advice: 'No meal data.',
      );
    }

    int score = 40; // base
    Map<String, int> breakdown = {};

    // Fibre score (max +20)
    double avgFiber = foods.map((f) => f.fiberLevel).reduce((a, b) => a + b) / foods.length;
    int fiberScore = (avgFiber * 2).round().clamp(0, 20);
    breakdown['Fibre'] = fiberScore;
    score += fiberScore;

    // Protein score (max +20)
    bool hasGoodProtein = foods.any((f) => f.proteinLevel >= 6.0);
    int proteinScore = hasGoodProtein ? 20 : foods.any((f) => f.proteinLevel >= 3.0) ? 10 : 0;
    breakdown['Protein'] = proteinScore;
    score += proteinScore;

    // GI score (max +20, penalty for high GI)
    double avgGI = foods.fold(0.0, (s, f) {
      switch (f.glycemicImpact) {
        case GlycemicImpact.low: return s + 30;
        case GlycemicImpact.medium: return s + 55;
        case GlycemicImpact.high: return s + 75;
      }
    }) / foods.length;

    int giScore = avgGI < 40 ? 20 : avgGI < 60 ? 10 : -10;
    breakdown['Glycemic'] = giScore.clamp(0, 20);
    score += giScore;

    // Vegetable bonus (max +10)
    bool hasVeg = foods.any((f) => f.typeStr == 'vegetable');
    breakdown['Vegetables'] = hasVeg ? 10 : 0;
    if (hasVeg) score += 10;

    // Naked carb penalty (-10)
    bool hasNakedCarb = foods.any((f) => f.typeStr == 'carb') &&
        !foods.any((f) => f.proteinLevel > 5.0 || f.fiberLevel > 5.0);
    if (hasNakedCarb) {
      score -= 10;
      breakdown['Naked Carb Penalty'] = -10;
    }

    score = score.clamp(0, 100);

    return MealScore(
      score: score,
      breakdown: breakdown,
      label: _scoreLabel(score),
      color: _scoreColor(score),
      advice: _scoreAdvice(score),
    );
  }

  static String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 35) return 'Needs Work';
    return 'Poor';
  }

  static int _scoreColor(int score) {
    if (score >= 80) return 0xFF2E7D32; // dark green
    if (score >= 65) return 0xFF558B2F; // green
    if (score >= 50) return 0xFFF9A825; // amber
    if (score >= 35) return 0xFFE65100; // orange
    return 0xFFB71C1C; // red
  }

  static String _scoreAdvice(int score) {
    if (score >= 80) return '🌟 Excellent balance of protein, fibre, and low-GI foods!';
    if (score >= 65) return '👍 Good meal! Add more vegetables to improve further.';
    if (score >= 50) return '💡 Add beans or vegetables to this meal for better balance.';
    if (score >= 35) return '⚠️ Missing protein or fibre — blood sugar spike risk!';
    return '🔴 Naked carbs! Add protein (beans/egg/fish) immediately.';
  }
}

class MealScore {
  final int score;
  final Map<String, int> breakdown;
  final String label;
  final int color; // ARGB int
  final String advice;

  const MealScore({
    required this.score,
    required this.breakdown,
    required this.label,
    required this.color,
    required this.advice,
  });
}


// ─────────────────────────────────────────
// lib/services/budget_service.dart
// Budget calculation and optimization
// ─────────────────────────────────────────

class BudgetService {
  /// Generate budget-optimized meal plan
  static BudgetPlan optimize(int totalBudgetNaira, UserProfile profile) {
    final breakfastBudget = (totalBudgetNaira * 0.20).round();
    final lunchBudget = (totalBudgetNaira * 0.45).round();
    final dinnerBudget = (totalBudgetNaira * 0.35).round();

    final breakfastOptions = _getMealOptions('breakfast', breakfastBudget, profile);
    final lunchOptions = _getMealOptions('lunch', lunchBudget, profile);
    final dinnerOptions = _getMealOptions('dinner', dinnerBudget, profile);

    return BudgetPlan(
      totalBudget: totalBudgetNaira,
      breakfastBudget: breakfastBudget,
      lunchBudget: lunchBudget,
      dinnerBudget: dinnerBudget,
      breakfastOptions: breakfastOptions,
      lunchOptions: lunchOptions,
      dinnerOptions: dinnerOptions,
    );
  }

  static List<BudgetMealOption> _getMealOptions(
      String mealType, int budget, UserProfile profile) {
    final foods = FoodDatabase.forMeal(mealType)
        .where((f) => f.priceNaira <= budget)
        .toList();

    if (foods.isEmpty) return [];

    // Group into combinations
    List<BudgetMealOption> options = [];

    // Sort by health score descending
    foods.sort((a, b) => b.healthScore.compareTo(a.healthScore));

    // Option 1: Best single food within budget
    if (foods.isNotEmpty) {
      final best = foods.first;
      options.add(BudgetMealOption(
        foodIds: [best.id],
        foodNames: [best.name],
        emojis: [best.emoji],
        totalCost: best.priceNaira,
        totalCalories: best.calories,
        healthScore: best.healthScore,
        label: 'Simple Choice',
      ));
    }

    // Option 2: Paired combination (carb + protein within budget)
    final carbFoods = foods.where((f) => f.typeStr == 'carb').toList();
    final proteinFoods = foods.where((f) => f.typeStr == 'protein').toList();
    if (carbFoods.isNotEmpty && proteinFoods.isNotEmpty) {
      final carb = carbFoods.first;
      final remaining = budget - carb.priceNaira;
      final protein = proteinFoods
          .where((f) => f.priceNaira <= remaining)
          .firstOrNull;
      if (protein != null) {
        options.add(BudgetMealOption(
          foodIds: [carb.id, protein.id],
          foodNames: [carb.name, protein.name],
          emojis: [carb.emoji, protein.emoji],
          totalCost: carb.priceNaira + protein.priceNaira,
          totalCalories: carb.calories + protein.calories,
          healthScore: ((carb.healthScore + protein.healthScore) / 2 + 10).round(),
          label: '⭐ Best Balance',
        ));
      }
    }

    return options;
  }

  /// Check if budget is realistic
  static BudgetFeasibility checkFeasibility(int budget) {
    if (budget < 300) {
      return BudgetFeasibility(
        isFeasible: false,
        message: '₦${budget} is very low. Minimum recommended is ₦500/day for 3 meals.',
        suggestion: 'Consider garri + groundnuts (₦200), moi moi (₦200), and seasonal vegetables.',
        minimumRecommended: 500,
      );
    } else if (budget < 600) {
      return BudgetFeasibility(
        isFeasible: true,
        message: 'Tight but manageable with ₦${budget}/day.',
        suggestion: 'Focus on garri, beans, eggs, and affordable vegetables like ugwu.',
        minimumRecommended: 500,
      );
    } else if (budget < 1500) {
      return BudgetFeasibility(
        isFeasible: true,
        message: '₦${budget}/day is comfortable for nutritious Nigerian meals.',
        suggestion: 'You can afford variety — try rotating different proteins and vegetables.',
        minimumRecommended: 500,
      );
    } else {
      return BudgetFeasibility(
        isFeasible: true,
        message: '₦${budget}/day gives you excellent food options.',
        suggestion: 'Add fish (mackerel/catfish), ofada rice, and seasonal fruits to your routine.',
        minimumRecommended: 500,
      );
    }
  }
}

class BudgetPlan {
  final int totalBudget;
  final int breakfastBudget;
  final int lunchBudget;
  final int dinnerBudget;
  final List<BudgetMealOption> breakfastOptions;
  final List<BudgetMealOption> lunchOptions;
  final List<BudgetMealOption> dinnerOptions;

  const BudgetPlan({
    required this.totalBudget,
    required this.breakfastBudget,
    required this.lunchBudget,
    required this.dinnerBudget,
    required this.breakfastOptions,
    required this.lunchOptions,
    required this.dinnerOptions,
  });

  int get totalMinimumCost =>
      (breakfastOptions.firstOrNull?.totalCost ?? 0) +
      (lunchOptions.firstOrNull?.totalCost ?? 0) +
      (dinnerOptions.firstOrNull?.totalCost ?? 0);
}

class BudgetMealOption {
  final List<String> foodIds;
  final List<String> foodNames;
  final List<String> emojis;
  final int totalCost;
  final int totalCalories;
  final int healthScore;
  final String label;

  const BudgetMealOption({
    required this.foodIds,
    required this.foodNames,
    required this.emojis,
    required this.totalCost,
    required this.totalCalories,
    required this.healthScore,
    required this.label,
  });
}

class BudgetFeasibility {
  final bool isFeasible;
  final String message;
  final String suggestion;
  final int minimumRecommended;

  const BudgetFeasibility({
    required this.isFeasible,
    required this.message,
    required this.suggestion,
    required this.minimumRecommended,
  });
}
