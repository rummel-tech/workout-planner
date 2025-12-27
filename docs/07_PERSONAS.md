# Workout Planner - User Personas

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Overview

This document defines user personas for the Workout Planner platform. These personas inform design decisions and serve as the basis for test scenarios.

---

## Primary Persona: Active Fitness Enthusiast

### Profile

| Attribute | Value |
|-----------|-------|
| **Name** | Alex Chen |
| **Age** | 32 |
| **Occupation** | Software Engineer |
| **Location** | Urban |
| **Fitness Level** | Intermediate to Advanced |
| **Device** | iPhone 15 Pro, Apple Watch Series 9 |

### Goals

- Optimize training based on recovery data
- Prevent overtraining and burnout
- Track progress toward strength goals
- Maintain work-life-fitness balance

### Behaviors

- Works out 5-6 times per week
- Mixes strength training, running, and swimming
- Uses Apple Watch for all workouts
- Checks readiness score every morning
- Reviews weekly plan on Sunday evenings

### Pain Points

- Previous apps didn't adapt to recovery status
- Spreadsheets for tracking are tedious
- Generic workout plans don't account for fatigue
- Hard to know when to push vs. rest

### Feature Usage

| Feature | Frequency | Importance |
|---------|-----------|------------|
| Readiness Score | Daily | Critical |
| Weekly Planning | Weekly | High |
| HealthKit Sync | Automatic | Critical |
| AI Coach Chat | 2-3x/week | Medium |
| Strength Logging | 3x/week | High |
| Goal Tracking | Weekly | Medium |

### Test Scenarios

```yaml
persona: alex_chen
scenarios:
  - id: AC-001
    name: Morning readiness check
    given: Alex opens app at 6:30 AM
    when: Home dashboard loads
    then:
      - Readiness score displays within 2 seconds
      - Score reflects last night's sleep and HRV
      - Today's workout adjusts based on readiness

  - id: AC-002
    name: Log strength workout
    given: Alex completes bench press sets
    when: Uses quick log to record sets
    then:
      - Each set saved with weight/reps
      - 1RM calculated and displayed
      - Progress toward strength goal updated

  - id: AC-003
    name: Ask AI about workout intensity
    given: Readiness score is 55% (orange)
    when: Alex asks "Should I do heavy squats today?"
    then:
      - AI acknowledges moderate readiness
      - Suggests reduced intensity or alternative
      - References specific readiness components

  - id: AC-004
    name: HealthKit auto-sync
    given: Alex completed run with Apple Watch
    when: Opens app within 15 minutes
    then:
      - Run data appears in workout history
      - Heart rate data synced
      - No manual entry required

  - id: AC-005
    name: Weekly plan review
    given: Sunday evening
    when: Alex views weekly plan
    then:
      - All 7 days visible with workout types
      - Can tap to edit any day
      - Changes persist after editing
```

---

## Secondary Persona: Goal-Oriented Beginner

### Profile

| Attribute | Value |
|-----------|-------|
| **Name** | Jordan Taylor |
| **Age** | 28 |
| **Occupation** | Marketing Manager |
| **Location** | Suburban |
| **Fitness Level** | Beginner |
| **Device** | iPhone 14, No wearable |

### Goals

- Build consistent workout habit
- Complete first 5K run
- Learn proper workout structure
- Stay motivated with guidance

### Behaviors

- Works out 3-4 times per week (target)
- Primarily running and bodyweight exercises
- Manually logs health metrics
- Relies heavily on AI coach for guidance
- Checks app daily for motivation

### Pain Points

- Overwhelmed by complex fitness programs
- Unsure about proper form and progression
- Inconsistent motivation
- No wearable device for automatic tracking

### Feature Usage

| Feature | Frequency | Importance |
|---------|-----------|------------|
| AI Coach Chat | Daily | Critical |
| Goal Tracking | Daily | Critical |
| Weekly Planning | Weekly | High |
| Manual Health Logging | 3x/week | Medium |
| Readiness Score | Daily | Medium |
| Workout Detail | Per workout | High |

### Test Scenarios

```yaml
persona: jordan_taylor
scenarios:
  - id: JT-001
    name: First-time setup without wearable
    given: Jordan installs app for first time
    when: Completes setup wizard
    then:
      - Can skip HealthKit setup
      - App works without wearable
      - Manual logging options available

  - id: JT-002
    name: Create first running goal
    given: Jordan wants to run 5K
    when: Creates new goal
    then:
      - Can set goal type "Running"
      - Can set target "5 km"
      - Can set deadline date
      - Goal appears in goals list

  - id: JT-003
    name: Ask AI for beginner guidance
    given: Jordan is new to structured workouts
    when: Asks "What should I do for my first workout?"
    then:
      - AI provides beginner-friendly advice
      - Suggests starting with warmup
      - Recommends appropriate intensity
      - Encourages consistency over intensity

  - id: JT-004
    name: Manual health metric entry
    given: Jordan checked weight this morning
    when: Uses quick log for health metrics
    then:
      - Can enter weight in preferred unit
      - Can select date (today or past)
      - Entry saved and visible in history

  - id: JT-005
    name: View workout detail with instructions
    given: Scheduled strength workout today
    when: Views workout detail
    then:
      - Warmup section visible
      - Each exercise has clear parameters
      - Can understand what to do
```

---

## Tertiary Persona: Competitive Athlete

### Profile

| Attribute | Value |
|-----------|-------|
| **Name** | Sam Rivera |
| **Age** | 38 |
| **Occupation** | Firefighter |
| **Location** | Urban |
| **Fitness Level** | Advanced |
| **Device** | iPhone 15, Apple Watch Ultra 2 |

### Goals

- Complete Murph under 40 minutes
- Qualify for local CrossFit competition
- Maintain tactical fitness for work
- Optimize recovery between training sessions

### Behaviors

- Trains 6 days per week, twice some days
- Tracks every workout in detail
- Monitors HRV religiously
- Uses vest for Murph training
- Plans training in 8-12 week cycles

### Pain Points

- Need detailed performance tracking
- Want to see long-term progress trends
- Recovery is critical for job performance
- Generic apps don't support Murph-specific tracking

### Feature Usage

| Feature | Frequency | Importance |
|---------|-----------|------------|
| Murph Logging | 1-2x/week | Critical |
| Readiness Score | Daily (morning) | Critical |
| Strength Logging | 4x/week | High |
| Swim Logging | 2x/week | High |
| Progress Charts | Weekly | High |
| HealthKit Sync | Continuous | Critical |

### Test Scenarios

```yaml
persona: sam_rivera
scenarios:
  - id: SR-001
    name: Log complete Murph workout
    given: Sam just finished Murph with vest
    when: Uses Murph logging
    then:
      - Can enter run 1 time
      - Can enter partition scheme (20-10-5)
      - Can enter run 2 time
      - Can enter vest weight (20 lbs)
      - Total time calculated
      - PR detected if applicable

  - id: SR-002
    name: View Murph progress over time
    given: Sam has logged 12 Murph workouts
    when: Views Murph progress
    then:
      - Total attempts displayed
      - Best time highlighted
      - Trend visible (improving/declining)
      - Vest vs. no-vest comparison available

  - id: SR-003
    name: Morning readiness check before double session
    given: Sam has morning and afternoon sessions planned
    when: Checks readiness at 5 AM
    then:
      - Score reflects overnight recovery
      - HRV trend visible
      - Sleep quality factored in
      - Can decide on session intensity

  - id: SR-004
    name: Log detailed strength session
    given: Sam doing heavy squat day
    when: Logs multiple sets across exercises
    then:
      - Can log each set separately
      - Set number tracked
      - 1RM updates after each set
      - Progress toward strength goal visible

  - id: SR-005
    name: Ask AI about periodization
    given: Sam is 6 weeks out from competition
    when: Asks "How should I taper for my competition?"
    then:
      - AI acknowledges competition goal
      - Suggests periodization strategy
      - Considers current training load
      - References readiness trends
```

---

## Edge Case Persona: Minimal Tech User

### Profile

| Attribute | Value |
|-----------|-------|
| **Name** | Pat Morgan |
| **Age** | 55 |
| **Occupation** | Teacher |
| **Location** | Rural |
| **Fitness Level** | Beginner-Intermediate |
| **Device** | Older Android phone, No wearable |

### Goals

- Stay healthy and active
- Simple workout tracking
- Don't want complexity

### Behaviors

- Exercises 3 times per week
- Walking and light weights
- Prefers simple interfaces
- Minimal phone usage

### Pain Points

- Technology can be confusing
- Small text hard to read
- Too many features overwhelming
- Slow data connection

### Test Scenarios

```yaml
persona: pat_morgan
scenarios:
  - id: PM-001
    name: App works on older device
    given: Pat has older Android phone
    when: Launches app
    then:
      - App loads without crashing
      - Performance acceptable (< 5s load)
      - All core features functional

  - id: PM-002
    name: Simple weekly view
    given: Pat wants to see the week
    when: Views weekly plan
    then:
      - Clear, readable text
      - Simple layout
      - Can tap to see workout

  - id: PM-003
    name: Works with slow connection
    given: Pat has poor data connection
    when: Tries to save workout
    then:
      - Shows loading indicator
      - Retries on failure
      - Shows clear error if offline
```

---

## Persona-Based Test Matrix

| Test Area | Alex (Enthusiast) | Jordan (Beginner) | Sam (Athlete) | Pat (Minimal) |
|-----------|-------------------|-------------------|---------------|---------------|
| **Auth** | Google SSO | Email/password | Email/password | Email/password |
| **HealthKit** | Auto-sync | Skip setup | Auto-sync | N/A (Android) |
| **Readiness** | Daily check | Occasional | Multiple daily | Occasional |
| **Goals** | Multiple active | 1-2 goals | Performance goals | Simple goals |
| **Chat** | Moderate use | Heavy use | Technical questions | Minimal |
| **Logging** | Detailed | Simple | Very detailed | Simple |
| **Plans** | Weekly review | AI-suggested | Custom periodization | Simple weekly |

---

## Test Data Sets

### Alex Chen Test Data

```yaml
user:
  id: test-alex-chen
  email: alex.chen@test.com
  goals:
    - type: Strength
      target: "315 lbs"
      target_unit: lbs
      description: Deadlift 3 plates
    - type: Running
      target: "25 minutes"
      target_unit: min
      description: 5K PR
  health_samples:
    - Generate 30 days of HRV (range: 40-65ms)
    - Generate 30 days of RHR (range: 55-65bpm)
    - Generate 30 days of sleep (range: 6-8.5h)
  workouts:
    - 12 strength sessions
    - 8 run sessions
    - 4 swim sessions
```

### Jordan Taylor Test Data

```yaml
user:
  id: test-jordan-taylor
  email: jordan.taylor@test.com
  goals:
    - type: Running
      target: "5 km"
      target_unit: km
      description: Complete first 5K
  health_samples:
    - Manual entries only (sparse data)
  workouts:
    - 4 bodyweight sessions
    - 3 run sessions
```

### Sam Rivera Test Data

```yaml
user:
  id: test-sam-rivera
  email: sam.rivera@test.com
  goals:
    - type: Murph
      target: "40 minutes"
      target_unit: min
      description: Sub-40 Murph with vest
    - type: Strength
      target: "405 lbs"
      target_unit: lbs
      description: 4-plate deadlift
  health_samples:
    - Generate 90 days comprehensive data
  workouts:
    - 15 Murph sessions (with progress)
    - 30 strength sessions
    - 12 swim sessions
```

---

## Accessibility Considerations

| Persona | Accessibility Needs |
|---------|---------------------|
| Alex | None identified |
| Jordan | Clear instructions, encouraging language |
| Sam | Quick data entry, minimal taps |
| Pat | Large text, high contrast, simple navigation |

### Test Scenarios

```yaml
accessibility:
  - id: A11Y-001
    name: Screen reader compatibility
    given: User has VoiceOver enabled
    when: Navigates through home screen
    then: All elements properly labeled

  - id: A11Y-002
    name: Large text support
    given: User has system text size at largest
    when: Views any screen
    then: Text scales appropriately, no overlap

  - id: A11Y-003
    name: Color contrast
    given: User has reduced color sensitivity
    when: Views readiness score
    then: Score readable without relying on color alone
```

---

## Using Personas in Development

### Feature Prioritization

When evaluating new features, ask:
1. Does this help Alex optimize training? (Primary)
2. Does this help Jordan build habits? (Secondary)
3. Does this help Sam compete? (Tertiary)
4. Is it accessible to Pat? (Edge case)

### UI/UX Decisions

- Alex: Efficient, data-rich displays
- Jordan: Guided, encouraging, simple
- Sam: Detailed logging, performance metrics
- Pat: Large, clear, minimal

### Test Coverage

Ensure test suites cover scenarios for each persona:
- Unit tests: Core functionality for all
- Integration tests: Persona-specific workflows
- E2E tests: Complete user journeys per persona
