// ─────────────────────────────────────────
// lib/main.dart
// ChopBetter — Entry point
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode (optimized for phones)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ChopBetterApp(),
    ),
  );
}

class ChopBetterApp extends StatelessWidget {
  const ChopBetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChopBetter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRoot(),
    );
  }
}

// ─────────────────────────────────────────
// AppRoot — decides onboarding vs main app
// ─────────────────────────────────────────
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.isOnboarded) {
          return const OnboardingScreen();
        }
        return const MainShell();
      },
    );
  }
}

// ─────────────────────────────────────────
// MainShell — Bottom navigation + screens
// ─────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', emoji: '🏠'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Meals', emoji: '🍽'),
    _NavItem(icon: Icons.swap_horiz_rounded, label: 'Pairing', emoji: '🔄'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', emoji: '💰'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Progress', emoji: '📊'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: IndexedStack(
            index: provider.currentNavIndex,
            children: const [
              HomeScreen(),
              _MealsShell(),
              _PairingShell(),
              _BudgetShell(),
              _ProgressShell(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final selected = provider.currentNavIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setNavIndex(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryContainer
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  item.icon,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String emoji;
  const _NavItem({required this.icon, required this.label, required this.emoji});
}

// ─── Screen shells (import wrappers) ───

class _MealsShell extends StatelessWidget {
  const _MealsShell();
  @override
  Widget build(BuildContext context) {
    return const MealRecommendationScreen();
  }
}

class _PairingShell extends StatelessWidget {
  const _PairingShell();
  @override
  Widget build(BuildContext context) {
    return const SmartPairingScreen();
  }
}

class _BudgetShell extends StatelessWidget {
  const _BudgetShell();
  @override
  Widget build(BuildContext context) {
    return const BudgetPlannerScreen();
  }
}

class _ProgressShell extends StatelessWidget {
  const _ProgressShell();
  @override
  Widget build(BuildContext context) {
    return const ProgressTrackerScreen();
  }
}

// ─── Import screens here so main.dart compiles ───
import 'screens/home_screen.dart' show MealRecommendationScreen, SmartPairingScreen, BudgetPlannerScreen, ProgressTrackerScreen;
