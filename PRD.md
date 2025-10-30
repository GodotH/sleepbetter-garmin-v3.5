# Product Requirements Document (PRD)
# 4-7-8 Breathing App for Garmin Venu3

## Product Overview
Port of a web-based 4-7-8 breathing technique app to Garmin Venu3 smartwatch, maintaining the minimalist red-themed night interface and single-tap interaction model.

## Version
**Current**: v3.6 - Premium Design Release (Golden Ratio + Color Hierarchy)
**Target**: v1.0.0 - Initial Release (No haptic, no HR tracking)

---

## Core Features

### 0. START SCREEN (v3.6)
- **Golden ratio layout** for harmonious visual balance
- App title "SleepBetter" at φ point from top (0.236)
- Technique name "4-7-8 breathing" at φ point from bottom (0.764)
- Session duration "10 min session" at nested φ (0.882)
- **Premium circular play button** in center:
  - 35% of max sphere size
  - Crimson filled circle with 2px red accent ring
  - Centered white play triangle
- Single tap to start session

### 1. Session Structure
- **Total Duration**: 10 minutes
- **Phases**:
  1. **Warm-up**: 1.5 minutes (4-4-5 pattern)
  2. **Transition**: 1.5 minutes (4-5-6 pattern)
  3. **Main**: 7 minutes (4-7-8 pattern)
- **Pattern Format**: Inhale-Hold-Exhale seconds

### 2. Visual Elements

#### Color Palette (Night Vision Red)
- **Primary**: #8B0000 (Dark Red)
- **Background gradient**: #1b0708 to #150506
- **Text**: #F6ECEC (Light)
- **Muted text**: #C9B5B5
- **Countdown white**: #FFFFFF

#### Core UI Components (v3.6+ Implementation)
- **Breathing sphere**: Scales 0.33x to 1.0x (center of screen)
- **Progress ring**: 44 radius units (around sphere)
- **Phase watermark**: "INHALE/HOLD/EXHALE" in center (pure red #FF0000, FONT_NUMBER_MEDIUM)
  - Smooth 0.6s fade-in on phase transitions
  - Renders on TOP of all elements
- **Session timer pill**: Top position, counts DOWN 10:00→0:00
  - Compact horizontal pill (100×40px, 2.5:1 ratio)
  - Black background (#000000)
  - Pure red border (2px, #FF0000)
  - Pure red text (#FF0000)
  - Layered on top of animated rings
- **Phase countdown pill**: Bottom position, 0-8 display
  - Circular pill (28px radius)
  - Black background (#000000) - matches timer pill
  - Pure red border (2px, #FF0000) - matches timer pill
  - Pure red text (#FF0000) - matches timer pill
  - Subtle drop shadow (3px offset) for depth
  - Unified styling with session timer for visual cohesion
- **Pattern display**: REMOVED (simplified interface)
- **Phase pill indicator**: Current breathing phase

### 3. Interaction Model

#### Single Touch Control
- **Tap to start**: From intro screen
- **Tap to pause**: During session
- **Tap to resume**: When paused
- **Back button**: Exit/Reset session
- **No other controls**: Keep it simple

### 4. Animation Sequences

#### Intro (10 seconds) - v3.6
1. Play button fadeout (0.8s)
2. "Get Ready" message with gentle pulse (4.6s)
3. "Relax now" message with gentle pulse (4.6s)
4. Begin session with 1s smooth fade-in

#### Breathing Animations
- **Inhale**: Sphere scales up (ease-in-out)
- **Hold**: Sphere subtle pulse at max size
- **Exhale**: Sphere scales down (ease-in-out)

#### Outro (16 seconds)
1. Sphere/halo fade (4s)
2. Red circle appears (3s delay)
3. Transform to outro screen (7s)
4. "Well Done" text (9s)
5. Heart message reveal (15s)

### 5. Display Requirements
- **Always-On**: Screen stays active during entire session
- **AMOLED Optimization**: Pure blacks for battery efficiency
- **Resolution**: 454×454 pixels
- **Touch Target**: Entire screen is touch-active

---

## Future Features (v2.0)
- Heart rate monitoring via optical sensor
- Session data recording to Garmin Connect
- Breathing quality score
- Haptic feedback for breathing phases

---

## Technical Constraints
- **Memory limit**: 4MB app size
- **Battery**: Optimize for 10-minute always-on session
- **No network connectivity required**
- **No persistent storage in v1.0**

---

## Success Criteria
- Session completes in exactly 10 minutes
- Progress ring matches numerical timer at all times
- 100% progress ring = 10:00 session time
- Pause freezes both timer and progress ring
- Visual match to HTML prototype (95%+ similarity)
- Smooth animations with no stuttering
- Battery drain < 2% per session
