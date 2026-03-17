// ─────────────────────────────────────────
// lib/providers/app_provider.dart
// Global app state using Provider
// ─────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/recommendation_engine.dart';

class AppProvider extends ChangeNotifier {
  // ─── User profile ───
  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get isOnboarded => _profile?.onboardingComplete ?? false;

  // ─── Daily meal plan ───
  DailyMealPlan? _dailyPlan;
  DailyMealPlan? get dailyPlan => _dailyPlan;

  // ─── Loading states ───
  bool _isGeneratingPlan = false;
  bool get isGeneratingPlan => _isGeneratingPlan;

  // ─── Bottom nav index ───
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // ─── Water intake today ───
  int _waterCupsToday = 0;
  int get waterCupsToday => _waterCupsToday;

  // ─── Selected budget for budget planner ───
  double _plannerBudget = 1500;
  double get plannerBudget => _plannerBudget;

  AppProvider() {
    _loadProfile();
  }

  // ─── Navigation ───
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ─── Profile management ───
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    _profile!.onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    // Save basic profile data to SharedPreferences
    await prefs.setString('user_name', profile.name);
    await prefs.setInt('user_age', profile.age);
    await prefs.setString('user_gender', profile.genderStr);
    await prefs.setDouble('user_weight', profile.weightKg);
    await prefs.setString('user_goal', profile.healthGoalStr);
    await prefs.setString('user_condition', profile.healthConditionStr);
    await prefs.setInt('user_budget', profile.dailyBudgetNaira);
    await prefs.setBool('onboarding_complete', true);
    notifyListeners();
    generateDailyPlan();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_complete') ?? false;
    if (onboarded) {
      _profile = UserProfile(
        name: prefs.getString('user_name') ?? 'User',
        age: prefs.getInt('user_age') ?? 30,
        genderStr: prefs.getString('user_gender') ?? 'male',
        weightKg: prefs.getDouble('user_weight') ?? 70.0,
        healthGoalStr: prefs.getString('user_goal') ?? 'maintain',
        healthConditionStr: prefs.getString('user_condition') ?? 'none',
        dailyBudgetNaira: prefs.getInt('user_budget') ?? 1500,
        onboardingComplete: true,
      );
      notifyListeners();
      generateDailyPlan();
    }
  }

  // ─── Plan generation ───
  Future<void> generateDailyPlan() async {
    if (_profile == null) return;
    _isGeneratingPlan = true;
    notifyListeners();

    // Small delay to show loading state (simulates lightweight computation)
    await Future.delayed(const Duration(milliseconds: 600));

    final engine = RecommendationEngine(_profile!);
    _dailyPlan = engine.generateDailyPlan();
    _isGeneratingPlan = false;
    notifyListeners();
  }

  // ─── Water tracking ───
  void addWaterCup() {
    if (_waterCupsToday < 8) {
      _waterCupsToday++;
      notifyListeners();
    }
  }

  void removeWaterCup() {
    if (_waterCupsToday > 0) {
      _waterCupsToday--;
      notifyListeners();
    }
  }

  // ─── Budget planner ───
  void updatePlannerBudget(double budget) {
    _plannerBudget = budget;
    notifyListeners();
  }

  // ─── Computed helpers ───
  String get greetingMessage {
    final hour = DateTime.now().hour;
    final name = _profile?.name.split(' ').first ?? '';
    if (hour < 12) return 'Good morning, $name! 🌅';
    if (hour < 17) return 'Good afternoon, $name! ☀️';
    return 'Good evening, $name! 🌙';
  }

  String get healthGoalLabel {
    switch (_profile?.healthGoal) {
      case HealthGoal.loseWeight: return '🏃 Lose Weight';
      case HealthGoal.gainWeight: return '💪 Gain Weight';
      default: return '⚖️ Maintain Weight';
    }
  }

  int get dailyHealthScore => _dailyPlan?.overallHealthScore ?? 0;

  double get waterProgress => _waterCupsToday / 8.0;
}
