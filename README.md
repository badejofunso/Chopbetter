# 🥗 ChopBetter — Flutter App

> **Affordable Nigerian food & healthy lifestyle recommendation app**
> Built for low-income users, low-end Android devices, and offline-first use.

---

## 📱 App Screenshots Summary

| Screen | Description |
|--------|-------------|
| Onboarding | 5-step setup: name, age/gender, weight/goal, health condition, budget |
| Home | Greeting, health score, water tracker, daily advice, today's meal plan |
| Meals | 3-tab view (Breakfast/Lunch/Dinner) with detailed food cards |
| Smart Pairing | Food selector → before/after GI comparison → pairing science |
| Budget | Live slider → meal plan per budget bracket |
| Progress | Health score ring, stats, daily health tips |

---

## 🚀 STEP-BY-STEP SETUP GUIDE

### Prerequisites

Install these first (one-time):

#### 1. Install Flutter SDK
```bash
# Option A: Download from flutter.dev
# Go to: https://flutter.dev/docs/get-started/install/windows
# Download flutter_windows_3.x.x-stable.zip
# Extract to C:\flutter (Windows) or ~/flutter (Mac/Linux)

# Add to PATH (Windows — System > Environment Variables > Path):
# C:\flutter\bin

# Verify:
flutter --version
```

#### 2. Install Android Studio
```
1. Download from: https://developer.android.com/studio
2. Install Android SDK (during setup)
3. Install Flutter + Dart plugins:
   File > Settings > Plugins > Search "Flutter" > Install
```

#### 3. Accept Android licenses
```bash
flutter doctor --android-licenses
# Press 'y' to accept all
```

#### 4. Verify everything works
```bash
flutter doctor
# Should show: [✓] Flutter, [✓] Android toolchain, [✓] Android Studio
```

---

### Project Setup

#### Step 1: Create new Flutter project
```bash
flutter create chopbetter
cd chopbetter
```

#### Step 2: Replace files
Copy all provided files into the `chopbetter/` folder:
```
chopbetter/
├── pubspec.yaml              ← Replace this file
└── lib/
    ├── main.dart             ← Replace this file
    ├── models/
    │   ├── food_model.dart
    │   └── user_profile.dart
    ├── data/
    │   └── food_database.dart
    ├── services/
    │   ├── food_pairing_service.dart
    │   └── recommendation_engine.dart  (also contains budget + health scoring)
    ├── theme/
    │   └── app_theme.dart
    ├── providers/
    │   └── app_provider.dart
    ├── widgets/
    │   └── app_widgets.dart
    └── screens/
        ├── onboarding_screen.dart
        └── home_screen.dart  (contains all 5 screens)
```

#### Step 3: Create asset folders
```bash
mkdir -p lib/assets/images
mkdir -p lib/assets/icons
mkdir -p lib/assets/lottie
```

#### Step 4: Install dependencies
```bash
flutter pub get
```

#### Step 5: Generate Hive adapters
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

### Running the App

#### On Android Emulator
```bash
# Start an emulator first in Android Studio (AVD Manager)
# Then:
flutter run
```

#### On Physical Android Phone
```bash
# 1. Enable Developer Options on phone:
#    Settings > About Phone > Tap "Build Number" 7 times
# 2. Enable USB Debugging:
#    Settings > Developer Options > USB Debugging > ON
# 3. Connect phone via USB cable
# 4. Accept "Trust this computer" on phone
# 5. Run:
flutter run
```

#### Check connected devices
```bash
flutter devices
# Should show your phone or emulator
```

---

### Building Release APK

#### Debug APK (for testing, larger size):
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK (optimized, production-ready):
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Split APKs by architecture (RECOMMENDED — smaller files):
```bash
flutter build apk --split-per-abi
# Creates 3 APKs for different processor types:
# app-armeabi-v7a-release.apk  (older phones)
# app-arm64-v8a-release.apk    (most modern phones — USE THIS)
# app-x86_64-release.apk       (emulators)
```

#### Install APK directly to connected phone:
```bash
flutter install
```

#### Share APK via WhatsApp/USB:
```
The APK file is at:
build/app/outputs/flutter-apk/app-release.apk

Copy to phone and open to install.
Make sure "Install from unknown sources" is enabled in phone settings.
```

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                    # Entry point, navigation shell
│
├── models/                      # Data models (pure Dart)
│   ├── food_model.dart          # FoodItem with all nutritional data
│   └── user_profile.dart        # UserProfile + MealPlan types
│
├── data/                        # Static data (works offline)
│   └── food_database.dart       # 40+ Nigerian foods with prices
│
├── services/                    # Business logic
│   ├── recommendation_engine.dart  # Meal generation + budget + health scoring
│   └── food_pairing_service.dart   # Smart pairing algorithm
│
├── providers/                   # State management (Provider)
│   └── app_provider.dart        # Global app state
│
├── theme/                       # Design system
│   └── app_theme.dart           # Colors, typography, spacing
│
├── widgets/                     # Reusable UI components
│   └── app_widgets.dart         # MealCard, HealthScoreRing, WaterTracker...
│
└── screens/                     # Full screens
    ├── onboarding_screen.dart   # 5-step onboarding
    └── home_screen.dart         # Home + Meals + Pairing + Budget + Progress
```

---

## 🧠 Core Algorithm: Recommendation Engine

### How meals are generated:
1. **Filter** foods by meal type (breakfast/lunch/dinner)
2. **Filter** by budget (user's daily budget split 20/45/35%)
3. **Sort** by health condition:
   - Diabetes → prioritize low-GI foods, then high-fibre
   - Hypertension → prioritize potassium-rich, low-sodium foods
   - Lose weight → prioritize lower-calorie options
4. **Pick base food** (usually a carbohydrate staple)
5. **SMART PAIRING** — mandatory protein addition if base is a carb
6. **Add vegetable** from pairing recommendations if budget allows
7. **Check balance** — flag naked carbs, suggest fixes

### Health Score Formula (0-100):
```
Base: 40 points
+ Fibre: avg_fibre_level × 3 (max +20)
+ Protein: has_good_protein ? +20 : has_some_protein ? +10 : 0
+ Glycemic: low_GI +20, medium 0, high -10
+ Vegetables: has_veg ? +10 : 0
- Naked carb penalty: no protein AND no fibre → -10
Final: clamp(0, 100)
```

---

## 📊 Nigerian Food Database

| Food | Type | GI | Fibre | Protein | Price |
|------|------|----|-------|---------|-------|
| White Rice | Carb | High | Low | Low | ₦250 |
| Ofada Rice | Carb | Med | Med | Med | ₦350 |
| Garri | Carb | High | Low | Very Low | ₦100 |
| Yam (boiled) | Carb | Med | Med | Low | ₦200 |
| Unripe Plantain | Carb | **Low** | High | Low | ₦150 |
| Beans | Protein | **Low** | **Very High** | **High** | ₦200 |
| Egg (×2) | Protein | None | None | **High** | ₦150 |
| Mackerel | Protein | None | None | **Very High** | ₦300 |
| Moi Moi | Protein | Low | High | High | ₦200 |
| Akara | Protein | Low | Med | High | ₦150 |
| Groundnuts | Protein/Fat | Low | Med | High | ₦100 |
| Ugwu | Vegetable | Very Low | **Very High** | Med | ₦100 |
| Okra | Vegetable | Very Low | **Very High** | Low | ₦100 |
| Oatmeal | Carb | **Low** | **Very High** | Med | ₦200 |

---

## 🔮 Future Scaling Roadmap

### Phase 2 — Firebase Integration
```dart
// Add to pubspec.yaml:
firebase_core: ^2.x.x
cloud_firestore: ^4.x.x
firebase_auth: ^4.x.x

// Benefits:
// - Sync user data across devices
// - Store meal tracking history
// - Push notifications for meal reminders
```

### Phase 3 — AI Recommendations
```dart
// Connect to OpenAI or Google Gemini API:
// - Ask: "Give me a ₦800 Nigerian lunch for a diabetic"
// - Response: structured meal suggestion
// - Works when internet available, falls back to local engine offline
```

### Phase 4 — Real-Time Pricing API
```dart
// Partner with Nigerian market price APIs or build your own:
// - Crawl Jumia Food, Chowdeck, Glovo Nigeria prices
// - Update food prices weekly via background sync
// - Show price trends (cheap/normal/expensive indicator)
```

### Phase 5 — Community Features
```dart
// - Share meal photos
// - User-submitted local meal prices by area (Lagos vs Kano vs Enugu)
// - Community health score leaderboard
// - Recipe sharing with smart pairing validation
```

---

## ❓ Troubleshooting

### "Flutter not found" after installation
```bash
# Add to PATH in ~/.bashrc or ~/.zshrc:
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc
```

### Build failed — "SDK not found"
```bash
flutter doctor
# Follow any ✗ instructions shown
flutter doctor --android-licenses
```

### App crashes on launch
```bash
flutter clean
flutter pub get
flutter run
```

### "Hive adapters not generated"
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Phone not detected
```bash
# On phone: Settings > Developer Options > Revoke USB debugging > Re-enable
# Unplug and replug USB cable
adb devices  # Should show your device
```

---

## 📞 Support

Built specifically for Nigeria and developing countries.
All food prices are approximate 2024 Nigerian market rates.
Foods list focuses on affordable, locally available options.

> ⚠️ This app provides general nutrition guidance only.
> Always consult a doctor for medical conditions.
