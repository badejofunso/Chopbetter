// ─────────────────────────────────────────
// lib/services/food_pairing_service.dart
// Smart food pairing algorithm
// Core rule: never serve "naked carbs"
// ─────────────────────────────────────────

import '../data/food_database.dart';
import '../models/food_model.dart';
import '../models/user_profile.dart';

class FoodPairingService {
  /// All pairing rules — maps a base carb to its best partners
  static const Map<String, _PairingRule> _rules = {
    'white_rice': _PairingRule(
      must: ['beans'],
      recommended: ['ugu_greens', 'tomato_stew', 'spinach'],
      avoid: [],
      explanation: 'Plain white rice has a very high glycemic index (GI 73). '
          'Adding beans drops the combined GI to ~45 because beans\' '
          'soluble fibre slows glucose absorption. Always eat rice with beans!',
      diabetesWarning: 'Rice + beans is the minimum — also add a leafy vegetable.',
    ),
    'garri': _PairingRule(
      must: ['groundnuts'],
      recommended: ['milk', 'beans', 'moi_moi'],
      avoid: [],
      explanation: 'Garri soaked in water is pure starch — very high GI. '
          'Groundnuts add protein and fat that dramatically slow sugar release. '
          'Milk adds protein. Together they turn a dangerous meal into a balanced one.',
      diabetesWarning: 'Avoid eba (fried garri with hot water) as a daily meal if diabetic.',
    ),
    'yam': _PairingRule(
      must: ['egg'],
      recommended: ['ugu_greens', 'tomato_sauce', 'beans'],
      avoid: [],
      explanation: 'Boiled yam has moderate GI (54). Adding egg provides protein '
          'that slows digestion. Vegetable sauce adds fibre and micronutrients.',
      diabetesWarning: 'Boil or steam yam. Fried yam drastically increases GI.',
    ),
    'plantain_ripe': _PairingRule(
      must: ['beans'],
      recommended: ['egg', 'ugu_greens'],
      avoid: [],
      explanation: 'Ripe plantain is higher in sugar. Pairing with beans provides '
          'protein + fibre that offset the sugar spike. Classic Nigerian combo!',
      diabetesWarning: 'Prefer unripe plantain which has lower GI. Boil, don\'t fry.',
    ),
    'plantain_unripe': _PairingRule(
      must: [],
      recommended: ['beans', 'egg', 'ugu_greens'],
      avoid: [],
      explanation: 'Unripe plantain is already low GI due to resistant starch. '
          'Still pair with protein for a complete meal.',
      diabetesWarning: null,
    ),
    'pap': _PairingRule(
      must: ['akara'],
      recommended: ['moi_moi', 'milk', 'egg'],
      avoid: [],
      explanation: 'Pap (ogi) alone is mostly starch. Akara or moi moi adds '
          'significant protein and fibre to create a balanced breakfast.',
      diabetesWarning: 'Add moi moi over akara as moi moi is steamed (lower fat).',
    ),
    'oats': _PairingRule(
      must: [],
      recommended: ['egg', 'milk', 'groundnuts', 'banana'],
      avoid: [],
      explanation: 'Oats already have excellent fibre (beta-glucan). '
          'Adding egg or milk makes it a complete breakfast with protein.',
      diabetesWarning: null,
    ),
    'corn': _PairingRule(
      must: ['groundnuts'],
      recommended: ['ube', 'coconut'],
      avoid: [],
      explanation: 'Traditional Nigerian combination! Groundnuts add protein and '
          'fat that turn corn into a balanced snack instead of a sugar spike.',
      diabetesWarning: null,
    ),
  };

  /// Get pairing suggestion for a given food
  static PairingSuggestionResult? getPairingSuggestion(
    String foodId,
    UserProfile profile,
  ) {
    final rule = _rules[foodId];
    final baseFood = FoodDatabase.getById(foodId);
    if (rule == null || baseFood == null) return null;

    final mustFoods = rule.must
        .map(FoodDatabase.getById)
        .whereType<FoodItem>()
        .toList();

    final recommendedFoods = rule.recommended
        .map(FoodDatabase.getById)
        .whereType<FoodItem>()
        .toList();

    String warning = '';
    if (profile.hasDiabetes && rule.diabetesWarning != null) {
      warning = '⚠️ Diabetes tip: ${rule.diabetesWarning}';
    }
    if (profile.hasHypertension) {
      warning += warning.isNotEmpty ? '\n' : '';
      warning += '💙 Hypertension: Use little or no salt. Limit palm oil.';
    }

    // Calculate health score improvement
    int baseFoodScore = baseFood.healthScore;
    int pairedScore = baseFoodScore;
    for (final f in mustFoods) {
      pairedScore = ((pairedScore + f.healthScore) / 2).round() + 10;
    }
    pairedScore = pairedScore.clamp(0, 100);

    return PairingSuggestionResult(
      baseFood: baseFood,
      mustPairFoods: mustFoods,
      recommendedFoods: recommendedFoods,
      explanation: rule.explanation,
      healthWarning: warning.isNotEmpty ? warning : null,
      scoreBeforePairing: baseFoodScore,
      scoreAfterPairing: pairedScore,
      glycemicBefore: _glycemicLabel(baseFood.glycemicImpact),
      glycemicAfter: mustFoods.isNotEmpty
          ? _reducedGlycemicLabel(baseFood.glycemicImpact)
          : _glycemicLabel(baseFood.glycemicImpact),
    );
  }

  /// Check if a list of foods forms a healthy combination
  static MealHealthCheck checkMealBalance(List<FoodItem> foods) {
    final hasCarb = foods.any((f) => f.typeStr == 'carb');
    final hasProtein = foods.any((f) => f.typeStr == 'protein' || f.proteinLevel > 5);
    final hasFiber = foods.any((f) => f.fiberLevel > 4.0);
    final hasVeg = foods.any((f) => f.typeStr == 'vegetable');

    List<String> warnings = [];
    List<String> suggestions = [];

    if (hasCarb && !hasProtein) {
      warnings.add('⚠️ No protein source! Naked carbs cause blood sugar spikes.');
      suggestions.add('Add beans, egg, or fish to this meal.');
    }
    if (hasCarb && !hasFiber) {
      warnings.add('⚠️ Low fibre! Sugar will absorb quickly.');
      suggestions.add('Add vegetables or beans to slow sugar absorption.');
    }
    if (!hasVeg && foods.length > 1) {
      suggestions.add('💚 Consider adding ugwu or spinach for micronutrients.');
    }

    double avgGI = foods.isEmpty
        ? 0
        : foods.map(_giScore).reduce((a, b) => a + b) / foods.length;

    int score = 50;
    if (hasProtein) score += 15;
    if (hasFiber) score += 15;
    if (hasVeg) score += 10;
    if (avgGI < 40) score += 10;
    if (avgGI > 65) score -= 20;
    if (warnings.isNotEmpty) score -= 10;

    return MealHealthCheck(
      isBalanced: warnings.isEmpty,
      hasProtein: hasProtein,
      hasFiber: hasFiber,
      hasVegetable: hasVeg,
      warnings: warnings,
      suggestions: suggestions,
      healthScore: score.clamp(0, 100),
      averageGI: avgGI,
    );
  }

  static double _giScore(FoodItem f) {
    switch (f.glycemicImpact) {
      case GlycemicImpact.low: return 30.0;
      case GlycemicImpact.medium: return 55.0;
      case GlycemicImpact.high: return 75.0;
    }
  }

  static String _glycemicLabel(GlycemicImpact gi) {
    switch (gi) {
      case GlycemicImpact.low: return '🟢 Low spike';
      case GlycemicImpact.medium: return '🟡 Medium spike';
      case GlycemicImpact.high: return '🔴 High spike';
    }
  }

  static String _reducedGlycemicLabel(GlycemicImpact original) {
    switch (original) {
      case GlycemicImpact.high: return '🟡 Reduced to Medium';
      case GlycemicImpact.medium: return '🟢 Reduced to Low';
      default: return '🟢 Low spike';
    }
  }

  /// All predefined pairings for the Smart Pairing Screen
  static List<PairingSuggestionResult> getAllPairings(UserProfile profile) {
    return _rules.keys
        .map((id) => getPairingSuggestion(id, profile))
        .whereType<PairingSuggestionResult>()
        .toList();
  }
}

// ─── Supporting classes ───

class _PairingRule {
  final List<String> must;        // required pairings
  final List<String> recommended; // optional but beneficial
  final List<String> avoid;       // foods to avoid with this
  final String explanation;
  final String? diabetesWarning;

  const _PairingRule({
    required this.must,
    required this.recommended,
    required this.avoid,
    required this.explanation,
    this.diabetesWarning,
  });
}

class PairingSuggestionResult {
  final FoodItem baseFood;
  final List<FoodItem> mustPairFoods;
  final List<FoodItem> recommendedFoods;
  final String explanation;
  final String? healthWarning;
  final int scoreBeforePairing;
  final int scoreAfterPairing;
  final String glycemicBefore;
  final String glycemicAfter;

  const PairingSuggestionResult({
    required this.baseFood,
    required this.mustPairFoods,
    required this.recommendedFoods,
    required this.explanation,
    this.healthWarning,
    required this.scoreBeforePairing,
    required this.scoreAfterPairing,
    required this.glycemicBefore,
    required this.glycemicAfter,
  });

  int get improvement => scoreAfterPairing - scoreBeforePairing;
}

class MealHealthCheck {
  final bool isBalanced;
  final bool hasProtein;
  final bool hasFiber;
  final bool hasVegetable;
  final List<String> warnings;
  final List<String> suggestions;
  final int healthScore;
  final double averageGI;

  const MealHealthCheck({
    required this.isBalanced,
    required this.hasProtein,
    required this.hasFiber,
    required this.hasVegetable,
    required this.warnings,
    required this.suggestions,
    required this.healthScore,
    required this.averageGI,
  });
}
