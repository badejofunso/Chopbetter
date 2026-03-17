// ─────────────────────────────────────────
// lib/screens/home_screen.dart
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final plan = provider.dailyPlan;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.warmGradient),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.greetingMessage,
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        provider.healthGoalLabel,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => provider.generateDailyPlan(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Stats row ──
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            emoji: '❤️',
                            label: 'Health Score',
                            value: '${provider.dailyHealthScore}/100',
                            valueColor: provider.dailyHealthScore >= 70
                                ? AppColors.scoreExcellent
                                : AppColors.scoreFair,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            emoji: '🔥',
                            label: 'Calories',
                            value: plan != null ? '${plan.totalCalories}' : '--',
                            valueColor: AppColors.accentLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            emoji: '💰',
                            label: 'Total Cost',
                            value: plan != null ? '₦${plan.totalCost}' : '--',
                            valueColor: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Water tracker ──
                    WaterTracker(
                      currentCups: provider.waterCupsToday,
                      totalCups: 8,
                      onAdd: provider.addWaterCup,
                      onRemove: provider.removeWaterCup,
                    ),
                    const SizedBox(height: 20),

                    // ── Daily advice ──
                    if (plan != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plan.dailyAdvice,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Today's plan header ──
                    const SectionHeader(
                      title: "Today's Meal Plan",
                      subtitle: "Personalized for your health & budget",
                    ),

                    // ── Meal cards or loading ──
                    if (provider.isGeneratingPlan) ...[
                      const SkeletonLoader(height: 200, borderRadius: 16),
                      const SizedBox(height: 12),
                      const SkeletonLoader(height: 200, borderRadius: 16),
                      const SizedBox(height: 12),
                      const SkeletonLoader(height: 200, borderRadius: 16),
                    ] else if (plan != null) ...[
                      MealCard(meal: plan.breakfast),
                      MealCard(meal: plan.lunch),
                      MealCard(meal: plan.dinner),
                    ] else
                      EmptyStateWidget(
                        emoji: '🍽',
                        title: 'No plan yet',
                        subtitle: 'Tap refresh to generate your meal plan',
                        buttonLabel: 'Generate Plan',
                        onButton: provider.generateDailyPlan,
                      ),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────
// lib/screens/meal_recommendation_screen.dart
// ─────────────────────────────────────────

class MealRecommendationScreen extends StatefulWidget {
  const MealRecommendationScreen({super.key});

  @override
  State<MealRecommendationScreen> createState() => _MealRecommendationScreenState();
}

class _MealRecommendationScreenState extends State<MealRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final plan = provider.dailyPlan;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Meal Recommendations'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: provider.generateDailyPlan,
                tooltip: 'Regenerate',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: '🌅 Breakfast'),
                Tab(text: '☀️ Lunch'),
                Tab(text: '🌙 Dinner'),
              ],
            ),
          ),
          body: provider.isGeneratingPlan
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Generating your personalized plan...'),
                    ],
                  ),
                )
              : plan == null
                  ? EmptyStateWidget(
                      emoji: '🍽',
                      title: 'No meals yet',
                      subtitle: 'Complete onboarding to get your personalized plan',
                      buttonLabel: 'Generate',
                      onButton: provider.generateDailyPlan,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _MealDetailView(meal: plan.breakfast),
                        _MealDetailView(meal: plan.lunch),
                        _MealDetailView(meal: plan.dinner),
                      ],
                    ),
        );
      },
    );
  }
}

class _MealDetailView extends StatelessWidget {
  final dynamic meal; // Meal type

  const _MealDetailView({required this.meal});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MealCard(meal: meal),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────
// lib/screens/smart_pairing_screen.dart
// ─────────────────────────────────────────

import '../services/food_pairing_service.dart';
import '../data/food_database.dart';

class SmartPairingScreen extends StatefulWidget {
  const SmartPairingScreen({super.key});

  @override
  State<SmartPairingScreen> createState() => _SmartPairingScreenState();
}

class _SmartPairingScreenState extends State<SmartPairingScreen> {
  String? _selectedFoodId;

  final List<Map<String, String>> _carbFoods = [
    {'id': 'white_rice', 'name': 'White Rice', 'emoji': '🍚'},
    {'id': 'garri', 'name': 'Garri', 'emoji': '🥣'},
    {'id': 'yam', 'name': 'Yam', 'emoji': '🍠'},
    {'id': 'plantain_ripe', 'name': 'Ripe Plantain', 'emoji': '🍌'},
    {'id': 'plantain_unripe', 'name': 'Unripe Plantain', 'emoji': '🍌'},
    {'id': 'pap', 'name': 'Ogi / Pap', 'emoji': '🍶'},
    {'id': 'oats', 'name': 'Oatmeal', 'emoji': '🥣'},
    {'id': 'corn', 'name': 'Boiled Corn', 'emoji': '🌽'},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final result = _selectedFoodId != null && provider.profile != null
            ? FoodPairingService.getPairingSuggestion(_selectedFoodId!, provider.profile!)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Smart Food Pairing'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intro card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔬 Food Pairing Science',
                        style: GoogleFonts.fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Never eat "naked carbs" — always pair your starchy foods with protein and fibre to prevent blood sugar spikes.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Food selector
                const SectionHeader(
                  title: 'Select a Base Food',
                  subtitle: 'See how to pair it properly',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _carbFoods.map((food) {
                    final selected = _selectedFoodId == food['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFoodId = food['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(food['emoji']!, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              food['name']!,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Pairing result
                if (result != null) ...[
                  const SectionHeader(title: 'Pairing Guide'),
                  _PairingResultCard(result: result),
                ] else ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        const Text('👆', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Select a food above to see\nhow to pair it properly',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PairingResultCard extends StatelessWidget {
  final PairingSuggestionResult result;
  const _PairingResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Before / After
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Before row
              _BeforeAfterRow(
                label: 'WITHOUT pairing',
                emoji: result.baseFood.emoji,
                name: result.baseFood.name,
                score: result.scoreBeforePairing,
                glycemic: result.glycemicBefore,
                isGood: false,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_downward_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              // After row
              _BeforeAfterRow(
                label: 'WITH smart pairing',
                emoji: result.baseFood.emoji,
                name: '${result.baseFood.name} + ${result.mustPairFoods.map((f) => f.name).join(' + ')}',
                score: result.scoreAfterPairing,
                glycemic: result.glycemicAfter,
                isGood: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Must pair foods
        if (result.mustPairFoods.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Always pair with:',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...result.mustPairFoods.map((food) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(food.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(food.name,
                                    style: GoogleFonts.outfit(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(food.description,
                                    style: GoogleFonts.outfit(
                                        fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 2),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              '₦${food.priceNaira}',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Explanation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 Why this pairing works',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                result.explanation,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        if (result.healthWarning != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Text(
              result.healthWarning!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFFE65100),
                height: 1.5,
              ),
            ),
          ),
        ],

        // Recommended pairings
        if (result.recommendedFoods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💚 Also great with:',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.recommendedFoods.map((f) => Chip(
                    label: Text('${f.emoji} ${f.name}'),
                    backgroundColor: AppColors.primaryContainer,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BeforeAfterRow extends StatelessWidget {
  final String label, emoji, name, glycemic;
  final int score;
  final bool isGood;

  const _BeforeAfterRow({
    required this.label,
    required this.emoji,
    required this.name,
    required this.score,
    required this.glycemic,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.scorePoor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isGood
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.scorePoor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isGood ? AppColors.primary : AppColors.scorePoor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score: $score',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isGood ? AppColors.scoreExcellent : AppColors.scorePoor,
                    ),
                  ),
                  GIChip(label: glycemic),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────
// lib/screens/budget_planner_screen.dart
// ─────────────────────────────────────────

import '../services/recommendation_engine.dart' show BudgetService;

class BudgetPlannerScreen extends StatelessWidget {
  const BudgetPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final budget = provider.plannerBudget;
        final feasibility = BudgetService.checkFeasibility(budget.round());
        final plan = provider.profile != null
            ? BudgetService.optimize(budget.round(), provider.profile!)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Budget Planner')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.greenGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '₦${budget.round()}',
                        style: GoogleFonts.fraunces(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'per day',
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: budget,
                        min: 300,
                        max: 5000,
                        divisions: 47,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        thumbColor: Colors.white,
                        onChanged: provider.updatePlannerBudget,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₦300', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                          Text('₦5,000', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Feasibility
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: feasibility.isFeasible
                        ? AppColors.primaryContainer
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: feasibility.isFeasible
                          ? AppColors.primary.withOpacity(0.3)
                          : const Color(0xFFFFB74D),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feasibility.message,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: feasibility.isFeasible
                              ? AppColors.primaryDark
                              : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feasibility.suggestion,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (plan != null) ...[
                  // Budget breakdown
                  const SectionHeader(title: 'Budget Breakdown'),
                  Row(
                    children: [
                      Expanded(child: _BudgetPill('🌅 Breakfast', '₦${plan.breakfastBudget}', AppColors.secondary)),
                      const SizedBox(width: 8),
                      Expanded(child: _BudgetPill('☀️ Lunch', '₦${plan.lunchBudget}', AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _BudgetPill('🌙 Dinner', '₦${plan.dinnerBudget}', AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Meal options
                  ...[
                    ('🌅 Breakfast Options', plan.breakfastOptions),
                    ('☀️ Lunch Options', plan.lunchOptions),
                    ('🌙 Dinner Options', plan.dinnerOptions),
                  ].map((section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.$1, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 10),
                      ...section.$2.map((opt) => _BudgetOptionCard(option: opt)),
                      const SizedBox(height: 16),
                    ],
                  )),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BudgetPill extends StatelessWidget {
  final String label, amount;
  final Color color;
  const _BudgetPill(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(amount, style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _BudgetOptionCard extends StatelessWidget {
  final dynamic option;
  const _BudgetOptionCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: option.label.contains('⭐') ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: option.label.contains('⭐')
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  option.emojis.join(' + ') + '  ' + option.foodNames.join(' + '),
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${option.totalCalories} kcal · Health score: ${option.healthScore}/100',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '₦${option.totalCost}',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────
// lib/screens/progress_tracker_screen.dart
// ─────────────────────────────────────────

class ProgressTrackerScreen extends StatelessWidget {
  const ProgressTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final score = provider.dailyHealthScore;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('My Progress')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health score card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Health Score',
                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              score >= 80
                                  ? '🌟 Excellent!'
                                  : score >= 65
                                      ? '👍 Good job!'
                                      : '💪 Keep going!',
                              style: GoogleFonts.fraunces(
                                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            if (profile != null)
                              Text(
                                '${profile.name} · ${provider.healthGoalLabel}',
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
                              ),
                          ],
                        ),
                      ),
                      HealthScoreRing(score: score, size: 100),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Daily stats
                const SectionHeader(title: 'Today\'s Stats'),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        emoji: '💧',
                        label: 'Water Cups',
                        value: '${provider.waterCupsToday}/8',
                        valueColor: const Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        emoji: '🔥',
                        label: 'Calories',
                        value: provider.dailyPlan != null
                            ? '${provider.dailyPlan!.totalCalories}'
                            : '--',
                        valueColor: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        emoji: '💰',
                        label: 'Spent Today',
                        value: provider.dailyPlan != null
                            ? '₦${provider.dailyPlan!.totalCost}'
                            : '--',
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Water tracker
                WaterTracker(
                  currentCups: provider.waterCupsToday,
                  totalCups: 8,
                  onAdd: provider.addWaterCup,
                  onRemove: provider.removeWaterCup,
                ),
                const SizedBox(height: 20),

                // Health tips
                const SectionHeader(title: '💡 Daily Health Tips'),
                ..._dailyTips.map((tip) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(tip.$1, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip.$2,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<(String, String)> _dailyTips = [
    ('🥗', 'Always add beans or vegetables to your rice or garri to prevent blood sugar spikes.'),
    ('💧', 'Drink 8 cups of water daily. Start with 2 cups before breakfast.'),
    ('🚶', 'A 20-minute walk after lunch reduces post-meal blood sugar by up to 30%.'),
    ('🌙', 'Eat dinner at least 2-3 hours before bed for better digestion.'),
    ('🥜', 'Groundnuts with garri or corn is a perfect, affordable protein-carb combo.'),
    ('🌿', 'Ugwu (pumpkin leaf) is a Nigerian superfood — cheap, iron-rich, and blood sugar-lowering.'),
  ];
}
