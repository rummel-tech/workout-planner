# Workout Planner - UI Specification

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Navigation Structure

```
App Launch
│
├── [Not Authenticated]
│   ├── /welcome → WelcomeScreen
│   │   ├── → /login
│   │   └── → /register
│   │
│   ├── /login → LoginScreen
│   │   ├── → /forgot (password reset)
│   │   ├── → /register (new user)
│   │   └── → /home (success)
│   │
│   ├── /register → RegisterScreen (2-step)
│   │   └── → /login (success)
│   │
│   └── /forgot → ForgotPasswordScreen
│       └── → /login
│
└── [Authenticated]
    ├── /setup → SetupWizardScreen (first-time only)
    │   └── → /home
    │
    └── /home → HomeScreen (Main App)
        │
        ├── Tab 0: Dashboard
        │   ├── Readiness Card
        │   ├── Quick Stats Row
        │   ├── Today's Workout → DayEditScreen
        │   ├── Tomorrow Preview
        │   └── FAB → QuickLogSheet
        │       ├── → HealthMetricsScreen
        │       ├── → StrengthMetricsScreen
        │       └── → SwimMetricsScreen
        │
        ├── Tab 1: Weekly Plan
        │   └── Day Card → DayEditScreen
        │       └── Workout → WorkoutDetailScreen
        │
        ├── Tab 2: Goals
        │   ├── Goal List
        │   ├── Create Goal (inline)
        │   └── Goal → GoalPlansScreen
        │
        └── Tab 3: Profile
            ├── User Info Card
            ├── Theme Settings
            ├── Sync Health Data (action)
            └── AI Coach → ChatScreen
```

---

## Screen Specifications

### Welcome Screen

**Route:** `/welcome`
**Purpose:** Landing page for unauthenticated users

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│         [App Logo]              │
│                                 │
│      Workout Planner            │
│   AI-Powered Fitness Coach      │
│                                 │
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │ 🤖 AI Coach             │    │
│  │ Personalized guidance   │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 📊 Smart Planning       │    │
│  │ Readiness-based workouts│    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 📈 Performance Insights │    │
│  │ Track your progress     │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │      Get Started        │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │      Sign In            │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Components:**
- App logo and title
- 3 feature highlight cards
- Primary CTA: "Get Started" → Register
- Secondary CTA: "Sign In" → Login

---

### Login Screen

**Route:** `/login`
**Purpose:** User authentication

**Layout:**
```
┌─────────────────────────────────┐
│  ←                              │
├─────────────────────────────────┤
│                                 │
│         Welcome Back            │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Email                   │    │
│  │ user@example.com        │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Password            👁  │    │
│  │ ••••••••                │    │
│  └─────────────────────────┘    │
│                                 │
│  Forgot Password?               │
│                                 │
│  ┌─────────────────────────┐    │
│  │        Sign In          │    │
│  └─────────────────────────┘    │
│                                 │
│  ────────── OR ──────────       │
│                                 │
│  ┌─────────────────────────┐    │
│  │ [G] Continue with Google│    │
│  └─────────────────────────┘    │
│                                 │
│  Don't have an account?         │
│  Sign Up                        │
│                                 │
└─────────────────────────────────┘
```

**Components:**
- Email text field (validated)
- Password field with visibility toggle
- "Forgot Password" link
- Sign In button
- Google Sign-In button
- Link to Register

**Validation:**
- Email: Valid email format
- Password: Non-empty

**Error States:**
- Invalid credentials → Show inline error
- Connection error → Show "Check your connection" message

---

### Register Screen

**Route:** `/register`
**Purpose:** New user registration (2-step process)

**Step 1 - Code Validation:**
```
┌─────────────────────────────────┐
│  ←                              │
├─────────────────────────────────┤
│                                 │
│        Create Account           │
│         Step 1 of 2             │
│                                 │
│  Enter your registration code   │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Registration Code       │    │
│  │ ABC123                  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │       Continue          │    │
│  └─────────────────────────┘    │
│                                 │
│  Don't have a code?             │
│  Join Waitlist                  │
│                                 │
└─────────────────────────────────┘
```

**Step 2 - Account Details:**
```
┌─────────────────────────────────┐
│  ←                              │
├─────────────────────────────────┤
│                                 │
│        Create Account           │
│         Step 2 of 2             │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Full Name              │    │
│  │ John Doe               │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Email                  │    │
│  │ user@example.com       │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Password            👁  │    │
│  │ ••••••••               │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ Confirm Password    👁  │    │
│  │ ••••••••               │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Create Account      │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Validation:**
- Code: 6+ characters
- Email: Valid email format
- Password: 8+ characters
- Confirm: Must match password

---

### Setup Wizard Screen

**Route:** `/setup`
**Purpose:** First-time configuration (4 pages)

**Page 1 - API Configuration:**
```
┌─────────────────────────────────┐
│                                 │
│        Setup Wizard             │
│         Page 1 of 4             │
│  ○ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─     │
│                                 │
│  API Endpoint                   │
│                                 │
│  ┌─────────────────────────┐    │
│  │ http://localhost:8000   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Test Connection     │    │
│  └─────────────────────────┘    │
│                                 │
│  ✓ Connection successful        │
│                                 │
├─────────────────────────────────┤
│              [Next →]           │
└─────────────────────────────────┘
```

**Page 2 - AI Provider:**
```
┌─────────────────────────────────┐
│                                 │
│        Setup Wizard             │
│         Page 2 of 4             │
│  ─ ─ ○ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─     │
│                                 │
│  AI Provider                    │
│                                 │
│  ○ None                         │
│  ● OpenAI                       │
│  ○ Anthropic                    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ API Key                 │    │
│  │ sk-...                  │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  [← Back]          [Next →]     │
└─────────────────────────────────┘
```

**Page 3 - HealthKit:**
```
┌─────────────────────────────────┐
│                                 │
│        Setup Wizard             │
│         Page 3 of 4             │
│  ─ ─ ─ ─ ○ ─ ─ ─ ─ ─ ─ ─ ─     │
│                                 │
│  Health Data Integration        │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Enable HealthKit    [●] │    │
│  └─────────────────────────┘    │
│                                 │
│  Sync data from Apple Health    │
│  including HRV, heart rate,     │
│  sleep, and workouts.           │
│                                 │
├─────────────────────────────────┤
│  [← Back]          [Next →]     │
└─────────────────────────────────┘
```

**Page 4 - Review:**
```
┌─────────────────────────────────┐
│                                 │
│        Setup Wizard             │
│         Page 4 of 4             │
│  ─ ─ ─ ─ ─ ─ ○ ─ ─ ─ ─ ─ ─     │
│                                 │
│  Review Configuration           │
│                                 │
│  API: http://localhost:8000     │
│  AI: OpenAI                     │
│  HealthKit: Enabled             │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Save & Continue     │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  [← Back]                       │
└─────────────────────────────────┘
```

---

### Home Dashboard

**Route:** `/home` (Tab 0)
**Purpose:** Daily overview and quick access

**Layout:**
```
┌─────────────────────────────────┐
│  Tuesday, January 15      ⚙️    │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │     READINESS           │    │
│  │        ┌───┐            │    │
│  │        │72%│            │    │
│  │        └───┘            │    │
│  │      (green)            │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌───────┬───────┬───────┐     │
│  │ Sleep │  HRV  │  RHR  │     │
│  │ 7.5h  │ 48ms  │ 58bpm │     │
│  └───────┴───────┴───────┘     │
│                                 │
│  ┌─────────────────────────┐    │
│  │ TODAY'S WORKOUT         │    │
│  │ ┌─────────────────────┐ │    │
│  │ │ 💪 Upper Body       │ │    │
│  │ │ Push • 60 min       │ │    │
│  │ │ Strength Goal       │ │    │
│  │ └─────────────────────┘ │    │
│  │ Bench, OHP, Dips...     │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ TOMORROW                │    │
│  │ 🏊 Swim • Endurance    │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  [🏠] [📅] [🎯] [👤]    [+]    │
└─────────────────────────────────┘
```

**Components:**
- Header: Date + settings icon
- Readiness badge (circular, color-coded)
- Quick stats row (3 metrics)
- Today's workout card (tappable)
- Tomorrow preview (compact)
- Bottom nav: 4 tabs + FAB

**Readiness Colors:**
| Score | Color | Hex |
|-------|-------|-----|
| ≥ 70% | Green | #4CAF50 |
| 40-69% | Orange | #FF9800 |
| < 40% | Red | #F44336 |

---

### Weekly Plan Screen

**Route:** `/home` (Tab 1)
**Purpose:** 7-day workout overview

**Layout:**
```
┌─────────────────────────────────┐
│  Weekly Plan              ⚙️    │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │ MON │ Upper Body    💪  │    │
│  │     │ Push              │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ TUE │ Swim          🏊  │    │
│  │     │ Endurance         │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ WED │ Mobility      🧘  │    │
│  │     │ Recovery          │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ THU │ Run           🏃  │    │
│  │     │ Zone 2            │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ FRI │ Lower Body    💪  │    │
│  │     │ Legs              │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ SAT │ Murph Prep   🎖️   │    │
│  │     │                   │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ SUN │ Rest          😴  │    │
│  │     │                   │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  [🏠] [📅] [🎯] [👤]    [+]    │
└─────────────────────────────────┘
```

**Workout Type Icons:**
| Type | Icon |
|------|------|
| strength | 💪 |
| run | 🏃 |
| swim | 🏊 |
| murph | 🎖️ |
| mobility | 🧘 |
| bike | 🚴 |
| yoga | 🧘 |
| cardio | ❤️ |
| rest | 😴 |

---

### Day Edit Screen

**Route:** (modal/push from dashboard or weekly)
**Purpose:** Edit single day's workout

**Layout:**
```
┌─────────────────────────────────┐
│  ← Monday, Jan 15        💾    │
├─────────────────────────────────┤
│                                 │
│  Day Title                      │
│  ┌─────────────────────────┐    │
│  │ Upper Body Strength     │    │
│  └─────────────────────────┘    │
│                                 │
│  WORKOUTS                       │
│  ┌─────────────────────────┐    │
│  │ 💪 Push Day             │    │
│  │ Focus: Chest/Shoulders  │    │
│  │ Time: 60 min            │    │
│  │ Goal: Strength Goal     │    │
│  │                    [✏️]  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │      + Add Workout      │    │
│  └─────────────────────────┘    │
│                                 │
│  NOTES                          │
│  ┌─────────────────────────┐    │
│  │ Focus on form today     │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

---

### Goals Screen

**Route:** `/home` (Tab 2)
**Purpose:** View and manage fitness goals

**Layout:**
```
┌─────────────────────────────────┐
│  Goals                    [+]   │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │ 💪 Strength             │    │
│  │ Deadlift 315 lbs        │    │
│  │ Due: Jun 1, 2024        │    │
│  │ 2 plans                 │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🏃 Running              │    │
│  │ 5K under 25 min         │    │
│  │ Due: Mar 15, 2024       │    │
│  │ 1 plan                  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🏊 Swimming             │    │
│  │ 1000m under 18 min      │    │
│  │ Due: Apr 1, 2024        │    │
│  │ 0 plans                 │    │
│  └─────────────────────────┘    │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  [🏠] [📅] [🎯] [👤]    [+]    │
└─────────────────────────────────┘
```

---

### Chat Screen

**Route:** (push from profile or AI Coach card)
**Purpose:** AI coaching conversation

**Layout:**
```
┌─────────────────────────────────┐
│  ← AI Coach                     │
├─────────────────────────────────┤
│                                 │
│           ┌─────────────────┐   │
│           │ Should I do a   │   │
│           │ hard workout    │   │
│           │ today?          │   │
│           └─────────────────┘   │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Based on your readiness │    │
│  │ score of 72% and your   │    │
│  │ good HRV reading, today │    │
│  │ would be appropriate    │    │
│  │ for moderate to high    │    │
│  │ intensity training...   │    │
│  └─────────────────────────┘    │
│                                 │
│           ┌─────────────────┐   │
│           │ What exercises  │   │
│           │ should I focus  │   │
│           │ on?             │   │
│           └─────────────────┘   │
│                                 │
│  ┌─────────────────────────┐    │
│  │ Given your strength     │    │
│  │ goal of 315lb deadlift, │    │
│  │ I'd recommend...        │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  ┌─────────────────────┐ [➤]   │
│  │ Type a message...   │        │
│  └─────────────────────┘        │
└─────────────────────────────────┘
```

**Message Styles:**
- User messages: Right-aligned, primary color background
- Assistant messages: Left-aligned, surface color background

---

### Profile Screen

**Route:** `/home` (Tab 3)
**Purpose:** User profile and settings

**Layout:**
```
┌─────────────────────────────────┐
│  Profile                        │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │   [Avatar]              │    │
│  │   John Doe              │    │
│  │   john@example.com      │    │
│  │                    [✏️]  │    │
│  └─────────────────────────┘    │
│                                 │
│  SETTINGS                       │
│  ┌─────────────────────────┐    │
│  │ 🎨 Appearance       [>] │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🔄 Sync Health Data [>] │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🤖 AI Coach         [>] │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ ⚙️ Configuration    [>] │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │       Sign Out          │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│  [🏠] [📅] [🎯] [👤]    [+]    │
└─────────────────────────────────┘
```

---

### Quick Log Sheet

**Trigger:** FAB on main screen
**Purpose:** Fast metric logging

**Layout:**
```
┌─────────────────────────────────┐
│  ─────                          │
│                                 │
│  Quick Log                      │
│                                 │
│  ┌─────────────────────────┐    │
│  │ ❤️ Health Metrics       │    │
│  │ HRV, Sleep, Weight...   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 💪 Strength Metrics     │    │
│  │ Log lifts & PRs         │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🏊 Swim Metrics         │    │
│  │ Distance, pace, stroke  │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

---

## Design System

### Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 32sp | Bold | Screen titles |
| Headline | 24sp | SemiBold | Section headers |
| Title | 20sp | Medium | Card titles |
| Body | 16sp | Regular | Body text |
| Label | 14sp | Medium | Labels, buttons |
| Caption | 12sp | Regular | Secondary text |

### Colors

**Light Theme:**
| Role | Color |
|------|-------|
| Primary | #1976D2 (Blue) |
| Secondary | #424242 |
| Surface | #FFFFFF |
| Background | #FAFAFA |
| Error | #D32F2F |
| Success | #388E3C |

**Dark Theme:**
| Role | Color |
|------|-------|
| Primary | #90CAF9 |
| Secondary | #B0BEC5 |
| Surface | #1E1E1E |
| Background | #121212 |
| Error | #EF5350 |
| Success | #66BB6A |

### Spacing

| Name | Value | Usage |
|------|-------|-------|
| xs | 4dp | Tight spacing |
| sm | 8dp | Between related items |
| md | 16dp | Standard padding |
| lg | 24dp | Section spacing |
| xl | 32dp | Major sections |

### Components

**Buttons:**
- Primary: Filled, primary color
- Secondary: Outlined, primary color
- Text: No background, primary color

**Cards:**
- Elevation: 1dp (default), 4dp (elevated)
- Border radius: 12dp
- Padding: 16dp

**Input Fields:**
- Outlined style
- Border radius: 8dp
- Height: 56dp
