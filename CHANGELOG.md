# Changelog - SleepBetter Breathing App

All notable changes to this project will be documented in this file.

## [v3.7] - 2025-10-30

### Critical Fixes

#### 10-Minute Timer Fix
- **Fixed session timer displaying 9:46 instead of 10:00**
  - Root cause: `Math.floor()` truncated partial cycles, losing 14 seconds
  - Solution: Changed to `Math.round()` for accurate cycle rounding
  - Restored original timing values: 0.65 + 1.75 + 7.60 = **10.00 minutes exactly**
  - Session now shows **600 seconds (10:00)** precisely
  - Calculation breakdown:
    - Block 1 (Warm-up): 0.65 min = 39s (4-4-5 pattern, 3 cycles)
    - Block 2 (Transition): 1.75 min = 105s (4-5-6 pattern, 7 cycles)
    - Block 3 (Main): 7.60 min = 456s (4-7-8 pattern, 24 cycles)

### Design Improvements

#### Session Timer Pill (Top)
- **Improved proportions** following UI design principles:
  - Changed from 30% width (136px) × 32px height (bad: 4.25:1 ratio, stretched)
  - To 100px width × 40px height (good: 2.5:1 ratio, balanced)
  - Compact width fits "10:00" content snugly
  - Substantial height provides visual weight
  - Fully rounded ends (radius = height/2)
- **Styling**:
  - Black background (#000000)
  - Pure red border (2px, #FF0000)
  - Pure red text (#FF0000)
  - Layered on top of animated rings for maximum visibility

#### Phase Countdown Pill (Bottom) - Unified Styling
- **Changed from crimson styling to match session timer**:
  - Background: Crimson fill → **Black (#000000)**
  - Text: Black → **Pure red (#FF0000)**
  - Border: Crimson → **Pure red (#FF0000)**
  - Retained drop shadow (3px offset) for depth
- **Visual cohesion**: Both pills now share identical color scheme
  - Creates professional, consistent design language
  - Clear hierarchy through positioning, not color variation
  - Unified red-on-black theme throughout interface

### Technical Implementation

#### Files Modified
- `source/BreathingController.mc`:
  - Changed `Math.floor()` to `Math.round()` in cycle calculation (line 355)
  - Restored timing: 0.65, 1.75, 7.60 minutes in `getDefaultPlan()`
  - Updated documentation comments with correct timing breakdown

- `source/SleepBetterView.mc`:
  - Session timer pill: Improved proportions (100×40px, lines 893-894)
  - Session timer pill: Black bg, red border, red text (lines 899-905)
  - Phase countdown pill: Unified styling with timer (lines 779-792)
  - Added comprehensive code comments documenting design decisions

- `PRD.md`:
  - Updated version to v3.7
  - Corrected session structure timing (lines 27-34)
  - Updated UI component specifications (lines 49-61)

### User Experience Impact
- **Timer accuracy**: Session now runs exactly 10:00 as intended
- **Visual balance**: Pills have proper proportions, not stretched or thin
- **Design cohesion**: Unified styling creates professional appearance
- **Readability**: Red text on black background has excellent contrast
- **Hierarchy**: Both pills stand out clearly against dark interface

### Testing
- ✅ Build successful on MonkeyC compiler
- ✅ Verified on Garmin Venu 3 simulator (454×454px)
- ✅ Session duration: Exactly 600 seconds (10:00)
- ✅ Timer pill proportions: Balanced 2.5:1 ratio
- ✅ Unified styling: Both pills match perfectly
- ✅ All animations smooth and professional

---

## [v3.6] - 2025-10-29

### Major UX & Visual Enhancements

#### Start Screen Redesign (Golden Ratio)
- **Applied golden ratio principles** for harmonious visual balance:
  - App title positioned at φ point from top (0.236 of screen height)
  - "4-7-8 breathing" positioned at φ point from bottom (0.764)
  - Session duration positioned using nested golden ratio (0.882)
  - Creates naturally pleasing, mathematically balanced layout
- **Cleaner hierarchy**: Removed subtitle clutter, replaced "Tap to Begin" with technique name
- **Result**: Professional, zen-like aesthetic that feels intentional and refined

#### Phase Countdown Circular Pill
- **Premium circular design** wrapping the countdown number:
  - Perfectly round pill (28px radius) for elegant appearance
  - Filled with crimson color (same as border) for unified appearance
  - Crimson border ring (2px) matching sphere rim color
  - Muted text color (COLOR_TEXT_MUTED) for readability against crimson background
  - **Subtle pulse effect**: Pill pulses to pure red when countdown resets to "0" (first 15% of phase)
- **Visual cohesion**: Blends seamlessly with breathing sphere and progress ring
- **Purpose**: Makes countdown stand out while remaining understated
- **Pulse feedback**: Elegant visual indicator of phase transitions
- **Result**: No longer looks "lonely" - now feels intentional and polished

#### Session Timer Color Enhancement
- **Changed session timer** (10:00 countdown at top) to **pure red** (0xFF0000)
- Matches phase watermark color for visual consistency
- High visibility and emphasis on remaining time
- Creates clear visual hierarchy: red timer (important) vs muted pill countdown (subtle)

#### Intro Sequence Improvements
- **Redesigned intro messages** with better flow:
  - Phase 1 (0.8-5.4s): "Get Ready" with gentle pulse (4.6s)
  - Phase 2 (5.4-10.0s): "Relax now" with gentle pulse (4.6s)
  - Removed "Inhale" splash - session starts immediately after intro
  - Equal time distribution for both messages
  - Total intro duration: 10 seconds

#### Phase Watermark Enhancements
- **Added smooth fade-in animation** (0.6s duration)
  - Fades from background color to pure red on each phase change
  - Uses easeOutQuad easing for natural appearance
  - Eliminates jarring sudden appearance
  - Implemented via color interpolation (MonkeyC has no native opacity)

- **Reduced font size** from `FONT_NUMBER_HOT` to `FONT_NUMBER_MEDIUM`
  - Less visually overwhelming
  - Better balance with other UI elements
  - Still clearly readable

- **Improved layering**
  - Phase watermark now renders ON TOP of all other elements
  - Previously appeared behind progress ring
  - Creates proper visual hierarchy

#### Start Screen Redesign
- **Complete visual overhaul** with premium aesthetics:
  - App title "SleepBetter" at top (12% from top)
  - Subtitle "4-7-8 Breathing" below title (18% from top)
  - Circular play button in center with:
    - Refined proportions (35% of sphere max size)
    - Outer accent ring (2px stroke in pure red)
    - Filled circle in crimson red
    - Centered play triangle with proper alignment
  - "Tap to Begin" instruction below (82% from top)
  - Session duration "10 min session" at bottom (90% from top)
  - Removed old pulsing sphere design
  - Clean, minimal, professional appearance

#### Breathing Screen Smooth Fade-In
- **Added 1-second smooth fade-in** after intro completes:
  - All elements fade in together (sphere, ring, text, watermark)
  - Uses `easeOutCubic` easing for natural, polished appearance
  - Color interpolation simulates opacity (MonkeyC has no native opacity)
  - Eliminates jarring sudden appearance
- **Layered fade effects**: Session fade-in + phase watermark fade-in work together
- **Result**: Seamless, cinematic transition from intro to breathing session

#### Screen Wake Lock
- **Implemented screen stay-awake** during active session
  - Uses `Attention.backlight(true)` when session starts
  - Prevents screen from sleeping during breathing exercise
  - Released when session completes or resets to idle
  - Ensures uninterrupted breathing experience

### Technical Implementation

#### New Features
- **Golden ratio layout**: Applied φ (1.618) calculations for start screen positioning
- **Circular pill component**: 28px radius circle filled with crimson for phase countdown
- **Pill pulse effect**: Subtle pure red pulse on countdown reset to "0" (first 15% of phase)
- **Session fade-in system**: `_sessionFadeIn` variable tracking 1s animation
- **Color interpolation**: `_interpolateColor()` helper for smooth fade effects
- **Phase watermark fade**: `_phaseChangeFadeIn` variable for 0.6s transitions
- **Idle screen redesign**: `_drawIdleScreen()` with golden ratio positioning
- **Session timer color**: Pure red (0xFF0000) for high visibility and emphasis
- **Countdown pill styling**: Crimson fill + matching border + muted text for readability

#### Files Modified
- `resources/strings/strings.xml`:
  - Changed `IntroJustRelax` to `IntroRelaxNow` ("Relax now")
  - Removed `IntroInhale` string (no longer used)

- `source/SleepBetterView.mc`:
  - **Golden ratio layout**: Updated `_drawIdleScreen()` with φ positioning (lines 634-696)
  - **Circular pill**: Redesigned `_drawCountdown()` with unified crimson fill (lines 762-809)
  - **Pill pulse effect**: Added zero-reset detection and pure red pulse animation (lines 772-787)
  - **Session timer color**: Changed to pure red (0xFF0000) in `_drawTimers()` (line 879)
  - **Pill text color**: Kept muted (COLOR_TEXT_MUTED) for readability (line 775)
  - **Session fade-in**: Added `_sessionFadeIn` variable (line 100)
  - **Color interpolation**: Created `_interpolateColor()` helper (lines 549-564)
  - **Fade animations**: Updated `_updateRunning()` for session fade (lines 364-370)
  - **Graphics fade**: Applied fade to sphere, ring, guide in `_render()` (lines 555-581)
  - **Text fade**: Updated `_drawPhaseWatermark()`, `_drawCountdown()`, `_drawTimers()` (lines 735-900)
  - **Intro timeline**: Updated intro logic (lines 311-340)
  - **Phase watermark**: Changed font to `FONT_NUMBER_MEDIUM` (line 72)
  - **Layering**: Reordered drawing for watermark on top (lines 624-627)
  - **Screen wake**: Added backlight control in `_beginSession()`, `_enterComplete()`, `_resetToIdle()`

#### Testing
- ✅ Build successful on MonkeyC compiler
- ✅ Loaded and verified on Garmin Venu 3 simulator (454×454px)
- ✅ Golden ratio layout creates harmonious start screen
- ✅ Circular pill wraps countdown elegantly
- ✅ Breathing screen fades in smoothly (1s duration)
- ✅ Phase watermark fades in on transitions (0.6s duration)
- ✅ Phase watermark renders on top of all elements
- ✅ Intro sequence flows naturally ("Get Ready" → "Relax now")
- ✅ Screen stays awake during entire session
- ✅ All animations are smooth, polished, and professional

### User Experience Impact
- **Start screen**: Mathematically balanced layout feels intentional and refined
- **Phase countdown pill**: No longer lonely - unified crimson design feels purposeful
- **Pill pulse effect**: Subtle red flash on phase reset provides elegant feedback
- **Session timer**: Pure red color creates emphasis and matches visual theme
- **Text readability**: Muted pill countdown text remains readable against crimson
- **Session start**: Smooth fade-in creates cinematic, premium transition
- **Intro**: More calming and meditative with "Relax now" message
- **Phase transitions**: Smoother and less jarring with dual fade effects
- **Visual hierarchy**: Crystal clear - red timer (important) vs muted pill (subtle)
- **Usability**: Screen no longer goes dark during breathing session
- **Overall**: App now feels cohesive, polished, and professionally designed

### Design Philosophy
v3.6 represents a commitment to **premium design principles**:
- **Golden ratio** for natural, pleasing proportions
- **Circular elements** creating visual rhythm (play button, sphere, pill)
- **Smooth animations** eliminating jarring transitions
- **Subtle depth** through layered fade effects
- **Intentional minimalism** - every element serves a purpose
- **Visual cohesion** - all elements work together harmoniously

---

## [v3.5.1] - 2025-10-28

### Interface Refinements

#### Layout Reorganization
- **Removed pattern label (4-7-8)** from bottom display
  - Simplifies interface by removing redundant information
  - Pattern info still visible in top session timer context

- **Repositioned phase countdown** to bottom location
  - Moved from center to bottom (where pattern label was)
  - Creates cleaner visual hierarchy with phase watermark in center
  - Countdown now positioned below breathing sphere

#### Countdown Styling Updates
- **Reduced countdown font** to `FONT_MEDIUM` for subtlety
  - Previous: Large number font (`FONT_NUMBER_HOT`)
  - Now: Standard medium font for less visual weight

- **Changed countdown color** to muted gray
  - Previous: Bright white (`COLOR_TEXT_PRIMARY`)
  - Now: Soft gray (`COLOR_TEXT_MUTED` - 0xC9B5B5)
  - Creates better contrast hierarchy with phase watermark

### Visual Hierarchy (Final)
- **Top**: Session countdown timer (10:00 → 0:00) in muted gray
- **Center**: Phase watermark ("INHALE", "HOLD", "EXHALE") in bright red
- **Bottom**: Phase countdown (0-8) in muted gray, medium font
- **Removed**: Pattern label no longer displayed

---

## [v3.5] - 2025-10-28

### Major UI & Timing Updates

#### Session Timing Changes
- **Updated session structure** to match PRD requirements:
  - Block 1 (Warm-up 4-4-5): 1.5 minutes (was 0.65 min)
  - Block 2 (Transition 4-5-6): 1.5 minutes (was 1.75 min)
  - Block 3 (Main 4-7-8): 7.0 minutes (was 7.6 min)
  - Total duration: ~9.77 minutes (586 seconds)

#### Timer Display Improvements
- **Inverted session countdown timer**: Now counts DOWN from 10:00 to 0:00 instead of counting up
  - More intuitive for users to see remaining time at a glance
  - Implementation in `_formatSessionCountdown()` method
  - Applied in `_drawTimers()` display

#### Phase Countdown Fix
- **Fixed phase countdown display** to show complete range (e.g., 0-8 for 8-second phases)
  - Previous behavior: Showed 0-7 for 8-second phase (incomplete)
  - New behavior: Shows 0, 1, 2, 3, 4, 5, 6, 7, 8 (complete range)
  - Applied timing formula: `elapsed * (duration + 1) / duration`
  - Ensures final target number displays correctly for all phase durations (4s, 5s, 6s, 7s, 8s)

#### Visual Design Updates
- **Phase watermark text** ("INHALE", "HOLD", "EXHALE"):
  - Changed font from `FONT_LARGE` to `FONT_NUMBER_HOT` for better visibility
  - Changed color from `COLOR_WATERMARK` (0xFF6B6B) to pure red (0xFF0000)
  - Creates stronger visual hierarchy with countdown overlay

### Technical Details

#### Files Modified
- `source/BreathingController.mc`:
  - Updated `getDefaultPlan()` with new timing structure
  - Updated documentation comments with new session plan breakdown

- `source/SleepBetterView.mc`:
  - Added `_formatSessionCountdown()` method for inverted timer display
  - Updated `_formatCountdownUp()` with corrected scaling formula
  - Modified `_drawTimers()` to use countdown format
  - Changed `FONT_SIZE_PHASE_WATERMARK` from `FONT_LARGE` to `FONT_NUMBER_HOT`
  - Updated `_drawPhaseWatermark()` to use pure red (0xFF0000)

#### Testing
- ✅ Build successful on MonkeyC compiler
- ✅ Loaded and verified on Garmin Venu 3 simulator (454×454px)
- ✅ Session timing displays correctly
- ✅ Phase countdowns show complete range (0-8, 0-7, etc.)
- ✅ Inverted session timer counts down properly
- ✅ Visual design changes applied correctly

### Notes
- Pulse ring implementation kept as-is (looks good on device)
- All changes tested and verified on simulator
- Documentation updated to reflect current implementation

---

## [Previous Versions]

Earlier version history available in git commits and PRD documents.
