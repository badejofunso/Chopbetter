// ─────────────────────────────────────────
// lib/screens/onboarding_screen.dart
// 5-step onboarding flow
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _nameController = TextEditingController();
  int _age = 30;
  String _gender = 'male';
  double _weight = 70.0;
  String _healthGoal = 'maintain';
  String _healthCondition = 'none';
  int _dailyBudget = 1500;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitProfile() async {
    final profile = UserProfile(
      name: _nameController.text.trim().isEmpty ? 'Friend' : _nameController.text.trim(),
      age: _age,
      genderStr: _gender,
      weightKg: _weight,
      healthGoalStr: _healthGoal,
      healthConditionStr: _healthCondition,
      dailyBudgetNaira: _dailyBudget,
    );

    await context.read<AppProvider>().saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton.icon(
                          onPressed: _prevPage,
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        )
                      else
                        const SizedBox(width: 80),
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 5,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.border,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3,
                        ),
                      ),
                      Text(
                        '${_currentPage + 1}/5',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 5,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _NameAgePage(
                    nameController: _nameController,
                    age: _age,
                    gender: _gender,
                    onAgeChanged: (v) => setState(() => _age = v),
                    onGenderChanged: (v) => setState(() => _gender = v),
                  ),
                  _WeightGoalPage(
                    weight: _weight,
                    goal: _healthGoal,
                    onWeightChanged: (v) => setState(() => _weight = v),
                    onGoalChanged: (v) => setState(() => _healthGoal = v),
                  ),
                  _HealthConditionPage(
                    condition: _healthCondition,
                    onChanged: (v) => setState(() => _healthCondition = v),
                  ),
                  _BudgetPage(
                    budget: _dailyBudget,
                    onChanged: (v) => setState(() => _dailyBudget = v),
                  ),
                ],
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == 4 ? '🚀 Generate My Meal Plan' : 'Continue',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (_currentPage < 4) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 0: Welcome ───
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text('🥗', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'ChopBetter',
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Eat smart. Live well.\nNaija style. 🇳🇬',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...[
            ('🥗', 'Smart Nigerian Meals', 'Personalized to your budget and health'),
            ('🔄', 'Food Pairing Science', 'No more naked carbs or sugar spikes'),
            ('💰', 'Budget Optimizer', 'Best nutrition within your ₦ budget'),
            ('📊', 'Health Scoring', 'See exactly how healthy your meals are'),
          ].map((item) => _FeatureRow(
                emoji: item.$1,
                title: item.$2,
                subtitle: item.$3,
              )),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureRow({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Name, Age, Gender ───
class _NameAgePage extends StatelessWidget {
  final TextEditingController nameController;
  final int age;
  final String gender;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onGenderChanged;

  const _NameAgePage({
    required this.nameController,
    required this.age,
    required this.gender,
    required this.onAgeChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Tell us about yourself', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('We\'ll personalize your meal plan',
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          _Label('Your Name'),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Emeka, Ngozi, Musa...',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _Label('Your Age'),
          _SliderField(
            value: age.toDouble(),
            min: 10,
            max: 80,
            label: '$age years',
            onChanged: (v) => onAgeChanged(v.round()),
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),

          _Label('Gender'),
          Row(children: [
            Expanded(
              child: _OptionCard(
                label: '👨 Male',
                isSelected: gender == 'male',
                onTap: () => onGenderChanged('male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OptionCard(
                label: '👩 Female',
                isSelected: gender == 'female',
                onTap: () => onGenderChanged('female'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Step 2: Weight & Goal ───
class _WeightGoalPage extends StatelessWidget {
  final double weight;
  final String goal;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onGoalChanged;

  const _WeightGoalPage({
    required this.weight,
    required this.goal,
    required this.onWeightChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Your body & goal', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('We\'ll calculate your calorie target',
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          _Label('Current Weight'),
          _SliderField(
            value: weight,
            min: 30,
            max: 150,
            label: '${weight.round()} kg',
            onChanged: onWeightChanged,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 28),

          _Label('Health Goal'),
          _GoalOption(
            emoji: '🏃',
            title: 'Lose Weight',
            subtitle: 'Reduce calories, lighter meals',
            value: 'lose',
            group: goal,
            onChanged: onGoalChanged,
          ),
          _GoalOption(
            emoji: '⚖️',
            title: 'Maintain Weight',
            subtitle: 'Balanced, nutritious meals',
            value: 'maintain',
            group: goal,
            onChanged: onGoalChanged,
          ),
          _GoalOption(
            emoji: '💪',
            title: 'Gain Weight',
            subtitle: 'Higher calories, more protein',
            value: 'gain',
            group: goal,
            onChanged: onGoalChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Health Condition ───
class _HealthConditionPage extends StatelessWidget {
  final String condition;
  final ValueChanged<String> onChanged;

  const _HealthConditionPage({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Any health conditions?', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('We\'ll tailor your meals to manage your condition',
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This app is not medical advice. Always consult your doctor.',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: const Color(0xFF7B6000)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _ConditionOption(
            emoji: '✅',
            title: 'None / Healthy',
            subtitle: 'No known health conditions',
            value: 'none',
            group: condition,
            onChanged: onChanged,
          ),
          _ConditionOption(
            emoji: '🩸',
            title: 'Diabetes',
            subtitle: 'Low-GI foods, prevent blood sugar spikes',
            value: 'diabetes',
            group: condition,
            onChanged: onChanged,
          ),
          _ConditionOption(
            emoji: '❤️',
            title: 'Hypertension',
            subtitle: 'Heart-friendly, low sodium foods',
            value: 'hypertension',
            group: condition,
            onChanged: onChanged,
          ),
          _ConditionOption(
            emoji: '⚕️',
            title: 'Both',
            subtitle: 'Diabetes and hypertension management',
            value: 'both',
            group: condition,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Budget ───
class _BudgetPage extends StatelessWidget {
  final int budget;
  final ValueChanged<int> onChanged;

  const _BudgetPage({required this.budget, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Daily food budget', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('We\'ll suggest affordable meals within your budget',
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: [
                  Text(
                    '₦${budget.toString()}',
                    style: GoogleFonts.fraunces(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'per day',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          Slider(
            value: budget.toDouble(),
            min: 300,
            max: 5000,
            divisions: 47,
            label: '₦$budget',
            activeColor: AppColors.primary,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₦300', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
              Text('₦5,000+', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 24),

          // Budget presets
          Text('Quick select:', style: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [500, 800, 1000, 1500, 2000, 3000].map((b) {
              return GestureDetector(
                onTap: () => onChanged(b),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: budget == b ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: budget == b ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '₦$b',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: budget == b ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Budget tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              budget < 600
                  ? '💡 Tip: With ₦$budget/day, focus on garri + groundnuts, beans, and cheap vegetables like ugwu.'
                  : budget < 1500
                      ? '💡 Tip: With ₦$budget/day you can have balanced meals. Try akara + pap, beans + yam, and seasonal vegetables.'
                      : '💡 Great budget! You can afford variety — rotate between mackerel, eggs, and different vegetables daily.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.primaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final double value, min, max;
  final String label;
  final ValueChanged<double> onChanged;
  final Color color;

  const _SliderField({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Text('${max.round()}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String emoji, title, subtitle, value, group;
  final ValueChanged<String> onChanged;

  const _GoalOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primaryDark : AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ConditionOption extends _GoalOption {
  const _ConditionOption({
    required super.emoji,
    required super.title,
    required super.subtitle,
    required super.value,
    required super.group,
    required super.onChanged,
  });
}
