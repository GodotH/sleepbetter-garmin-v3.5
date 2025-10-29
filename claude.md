# Claude Instructions - SleepBetter Breathing App

## Project Overview

**SleepBetter** is a Garmin Connect IQ app implementing the 4-7-8 breathing technique for the Garmin Venu 3 smartwatch (454×454px AMOLED display). The app provides a minimalist, red-themed night interface with animated breathing guidance through a 10-minute structured session featuring premium design principles including golden ratio layout and smooth cinematic transitions.

**Current Version**: v3.6
**Language**: MonkeyC (Garmin's proprietary language)
**Target Device**: Garmin Venu 3 (454×454 resolution)
**Development Platform**: Windows with Garmin Connect IQ SDK

**Design Highlights (v3.6)**:
- Golden ratio-based layout for natural visual harmony
- Circular pill design for phase countdown
- 1-second cinematic fade-in for breathing screen
- Smooth 0.6s phase watermark transitions
- Screen wake lock during active sessions

---

## Project Structure

```
v3.5/
├── source/                      # MonkeyC source files
│   ├── SleepBetterApp.mc       # Main app entry point
│   ├── SleepBetterView.mc      # UI rendering (canvas-based)
│   ├── BreathingController.mc  # Session timing and breathing patterns
│   ├── EasingFunctions.mc      # Animation easing functions
│   ├── Effects.mc              # Visual effects and animations
│   ├── SettingsManager.mc      # User preferences (future use)
│   └── ErrorHandler.mc         # Error handling utilities
├── resources/                   # App resources (icons, strings)
├── bin/                        # Compiled output (.prg files)
├── manifest.xml               # App metadata and permissions
├── monkey.jungle              # Build configuration
├── PRD.md                     # Product Requirements Document
├── CHANGELOG.md               # Version history and changes
├── LESSONS_LEARNED.md         # Development insights
└── claude.md                  # This file - AI assistant instructions

```

---

## Architecture Decisions

### Canvas-Based Rendering (Critical!)

This app uses **100% canvas-based rendering** with ZERO XML layouts. This is crucial because:

1. **Animated breathing sphere** requires frame-by-frame drawing
2. **Dynamic visibility** of UI elements based on app state
3. **Layered rendering** with specific z-order (background → sphere → text)
4. **Custom visual effects** not possible with XML layouts

**See**: [LESSONS_LEARNED.md](LESSONS_LEARNED.md) for detailed explanation of why XML layouts don't work for this app.

### Key Files and Responsibilities

#### SleepBetterView.mc (UI Layer)
- **Purpose**: All visual rendering and animation
- **Pattern**: Canvas-only drawing in `onUpdate(dc)` method
- **Key Methods**:
  - `_drawSphere()` - Animated breathing sphere (scales 0.33x to 1.0x)
  - `_drawProgressRing()` - Session progress visualization
  - `_drawPhaseWatermark()` - "INHALE/HOLD/EXHALE" center text
  - `_drawCountdown()` - Phase countdown (0-8 seconds)
  - `_drawTimers()` - Session countdown timer (10:00→0:00)
  - `_drawPhasePill()` - Current phase indicator pill
- **State-Driven Rendering**: UI elements drawn conditionally based on `_state` (IDLE/INTRO/RUNNING/PAUSED/OUTRO)

#### BreathingController.mc (Logic Layer)
- **Purpose**: Session timing, breathing pattern logic, state management
- **Session Structure**: 3-block structure (1.5min warmup + 1.5min transition + 7.0min main)
- **Patterns**: 4-4-5 (warmup) → 4-5-6 (transition) → 4-7-8 (main)
- **Key Methods**:
  - `getDefaultPlan()` - Returns session structure
  - `tick()` - Updates breathing state every frame
  - `getSessionState()` - Provides state data to view layer

#### EasingFunctions.mc & Effects.mc
- **Purpose**: Animation curves and visual effects
- **Usage**: Smooth sphere scaling during inhale/exhale phases
- **Note**: MonkeyC has no built-in easing, so we implement our own

---

## Development Workflow

### Build and Deploy Commands

#### Quick Full-Cycle Test (Recommended)
```bash
# Use the slash command (preferred method)
/garmin-simulator full-cycle
```

This command performs:
1. Kill any running simulator process
2. Compile the app with monkeyc
3. Deploy to simulator with monkeydo
4. Launch the Garmin simulator

#### Manual Build Steps

```bash
# 1. Navigate to project directory
cd "C:\Users\godot\OneDrive\_LIVE\AGENTS\sleepbetter\garmin\v3.5"

# 2. Compile the app
monkeyc -d venu3 -f monkey.jungle -o bin/SleepBetter.prg -y developer_key

# 3. Deploy to simulator
monkeydo bin/SleepBetter.prg venu3

# 4. Launch simulator (if not running)
start "" "C:\Users\godot\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22\bin\simulator.exe"
```

#### Simulator Management
```bash
# Check if simulator is running
tasklist | findstr simulator.exe

# Kill simulator process (if needed)
taskkill /F /IM simulator.exe

# Kill monkeydo process (if needed)
taskkill /F /IM monkeydo.exe
```

### Development Cycle

1. **Make code changes** in source/*.mc files
2. **Compile and deploy** using `/garmin-simulator full-cycle`
3. **Test visually** in simulator (454×454px Venu 3)
4. **Verify behavior**:
   - Tap to start session
   - Watch breathing sphere animation
   - Check timer countdown (10:00 → 0:00)
   - Verify phase countdown (0-8, etc.)
   - Test pause/resume functionality
5. **Iterate** as needed

### Git Workflow

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: description of changes"

# Push to GitHub
git push origin main
```

**Commit Message Convention**:
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code restructuring
- `docs:` - Documentation updates
- `style:` - Visual/UI changes

---

## Current Implementation (v3.6)

### Session Timing
- **Block 1 (Warmup)**: 1.5 minutes - 4-4-5 pattern (6 cycles)
- **Block 2 (Transition)**: 1.5 minutes - 4-5-6 pattern (6 cycles)
- **Block 3 (Main)**: 7.0 minutes - 4-7-8 pattern (22 cycles)
- **Total**: ~9.77 minutes (586 seconds)

### Visual Hierarchy
```
┌─────────────────────────────────┐
│   SESSION TIMER (top)           │  ← 10:00→0:00 (pure red #FF0000, FONT_SMALL)
│                                 │
│   PHASE WATERMARK (center)      │  ← INHALE/HOLD/EXHALE (red, FONT_NUMBER_MEDIUM)
│   ● BREATHING SPHERE            │  ← Scales 0.33x-1.0x with progress ring
│                                 │
│   PHASE COUNTDOWN PILL (bottom) │  ← 0-8 in circular pill (muted, with pulse)
└─────────────────────────────────┘
```

### Color Hierarchy (v3.6)
- **Background**: Pure black (0x000000) for AMOLED efficiency
- **Phase Watermark**: Pure red (0xFF0000) - high emphasis, smaller font (FONT_NUMBER_MEDIUM)
- **Session Timer**: Pure red (0xFF0000) - high visibility and emphasis
- **Breathing Sphere**: Dark red (0x8B0000)
- **Progress Ring**: Crimson red
- **Countdown Pill**: Crimson fill + border, muted text (0xC9B5B5) for readability
- **Text Primary**: Light gray (0xF6ECEC)

### Font Sizes (Garmin System Fonts)

- `FONT_NUMBER_MEDIUM` - Phase watermark (v3.6: reduced from HOT)
- `FONT_MEDIUM` - Phase countdown pill (subtle)
- `FONT_SMALL` - Session timer
- `FONT_TINY` - Phase pill, pattern label (when visible)

---

## Key Technical Details

### Phase Countdown Scaling Formula

The phase countdown (0-8, 0-7, etc.) uses a scaling formula to ensure the final target number displays:

```monkey-c
// For an 8-second phase, we want to show: 0, 1, 2, 3, 4, 5, 6, 7, 8
// Standard floor(elapsed) would only show: 0, 1, 2, 3, 4, 5, 6, 7 (misses 8!)
// Solution: Scale elapsed by (duration + 1) / duration

var scaledElapsed = elapsed * (duration + 1.0) / duration;
var value = Math.floor(scaledElapsed).toNumber();
```

**Why this works**: For duration=8, at elapsed=7.99s:
- Old: `floor(7.99) = 7` ❌
- New: `floor(7.99 * 9/8) = floor(8.99) = 8` ✅

### Inverted Session Timer

The session timer counts DOWN from 10:00 to 0:00 (more intuitive than counting up):

```monkey-c
private function _formatSessionCountdown(elapsed, totalDuration) {
    var remaining = totalDuration - elapsed;
    if (remaining < 0.0) { remaining = 0.0; }
    var minutes = Math.floor(remaining / 60).toNumber();
    var seconds = (Math.floor(remaining).toNumber() - (minutes * 60)).toNumber();
    return minutes.toString() + ":" + (seconds < 10 ? "0" : "") + seconds.toString();
}
```

### State Management

The app has 5 main states:
1. `STATE_IDLE` - Intro screen with play button
2. `STATE_INTRO` - "Get Ready" animation sequence (2.0s)
3. `STATE_RUNNING` - Active breathing session
4. `STATE_PAUSED` - Session paused (tap to resume)
5. `STATE_OUTRO` - "Well Done" completion sequence (3.5s)

UI elements render conditionally based on current state.

---

## Common Tasks

### Change Session Timing

Edit [BreathingController.mc:getDefaultPlan()](source/BreathingController.mc):

```monkey-c
function getDefaultPlan() {
    return [
        {
            "label" => "Warm-up 4-4-5",
            "minutes" => 1.5,  // ← Change duration here
            "pattern" => { "inhale" => 4.0, "hold" => 4.0, "exhale" => 5.0 }
        },
        // ... more blocks
    ];
}
```

### Adjust Visual Styling

Edit [SleepBetterView.mc](source/SleepBetterView.mc) constants:

```monkey-c
// Color constants
const COLOR_TEXT_PRIMARY = 0xF6ECEC;
const COLOR_TEXT_MUTED = 0xC9B5B5;
// ... modify as needed

// Font constants
const FONT_SIZE_COUNTDOWN = Gfx.FONT_MEDIUM;  // ← Change font size
const FONT_SIZE_PHASE_WATERMARK = Gfx.FONT_NUMBER_HOT;
// ... modify as needed
```

### Change Sphere Scaling Range

Edit [SleepBetterView.mc:_computeSphereRadius()](source/SleepBetterView.mc):

```monkey-c
var scale = 0.33 + (progress * 0.67);  // 0.33x to 1.0x range
// For different range, e.g., 0.5x to 1.0x:
// var scale = 0.5 + (progress * 0.5);
```

### Add New Visual Element

Add drawing method in [SleepBetterView.mc](source/SleepBetterView.mc):

```monkey-c
private function _drawMyElement(dc) {
    // 1. Check state if needed
    if (_state != AppState.STATE_RUNNING) { return; }

    // 2. Set color
    dc.setColor(0xFF0000, Gfx.COLOR_TRANSPARENT);

    // 3. Draw element
    dc.drawText(_centerX, _centerY, Gfx.FONT_SMALL, "Text", Gfx.TEXT_JUSTIFY_CENTER);
}
```

Then call in `onUpdate(dc)`:
```monkey-c
function onUpdate(dc) {
    // ... existing drawing code
    _drawMyElement(dc);  // Add here in correct z-order
}
```

---

## Testing Checklist

Before committing changes:

- [ ] **Build succeeds** without errors
- [ ] **Deploys to simulator** successfully
- [ ] **Visual appearance** matches design intent
- [ ] **Session timing** displays correctly (10:00 → 0:00)
- [ ] **Phase countdown** shows complete range (0-8 for 8s phases)
- [ ] **Sphere animation** is smooth (no stuttering)
- [ ] **Tap handling** works (start/pause/resume)
- [ ] **Intro sequence** plays correctly (2.0s)
- [ ] **Outro sequence** plays correctly (3.5s)
- [ ] **All states** transition properly

### Visual Regression Testing

Compare simulator screenshot with reference design:
1. Take screenshot of current implementation
2. Open reference screenshot (from PRD or previous version)
3. Compare side-by-side for visual discrepancies
4. Fix any issues before committing

---

## Platform Constraints (MonkeyC)

### What MonkeyC CAN'T Do
- ❌ No CSS-like opacity/transparency
- ❌ No gradients (must simulate with shapes)
- ❌ No custom fonts (system fonts only)
- ❌ No blur effects
- ❌ No z-index (draw order = code order)
- ❌ No dynamic styling on XML elements

### Workarounds
- **Transparency**: Mix colors manually (e.g., red at 50% = dark red)
- **Gradients**: Draw concentric circles with varying colors
- **Fonts**: Accept system font limitations
- **Z-order**: Draw background first, foreground last
- **Blur**: Omit or pre-render as bitmap

**See**: [LESSONS_LEARNED.md](LESSONS_LEARNED.md) for detailed explanation.

---

## Documentation Files

### PRD.md
Product Requirements Document defining all features, visual design, and success criteria. This is the **source of truth** for what the app should do.

### CHANGELOG.md
Version history documenting all changes. Update this file after every significant feature or fix:
```markdown
## [vX.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Modifications to existing features

### Fixed
- Bug fixes
```

### LESSONS_LEARNED.md
Critical insights from development, particularly around:
- Why canvas-based rendering is required
- Platform limitations and workarounds
- Visual testing best practices
- Common pitfalls to avoid

**Read this before making major architectural changes!**

---

## Debugging Tips

### Build Errors
```bash
# Check manifest.xml for valid XML syntax
# Check monkey.jungle for correct paths
# Verify all .mc files have proper syntax
```

### Simulator Not Launching
```bash
# Kill existing processes
taskkill /F /IM simulator.exe
taskkill /F /IM monkeydo.exe

# Restart simulator manually
start "" "C:\Users\godot\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.3.0-2025-09-22\bin\simulator.exe"
```

### Visual Issues
1. Check if element is being drawn (add debug log in method)
2. Verify z-order (draw order in `onUpdate()`)
3. Check color values (not 0x000000 on black background)
4. Verify font size (not too small to see)
5. Check position calculations (use `_centerX`, `_centerY`)

### Timing Issues
1. Verify `getDefaultPlan()` structure in BreathingController.mc
2. Check `_formatCountdownUp()` scaling formula
3. Ensure `tick()` is being called every frame
4. Verify state transitions in controller

---

## Performance Considerations

### Battery Optimization
- Use **pure black background** (0x000000) on AMOLED displays - pixels are off
- Minimize screen updates (only redraw when state changes)
- Avoid complex calculations in `onUpdate()` (pre-compute in `tick()`)

### Memory Management
- MonkeyC has **4MB app size limit**
- Keep bitmap resources minimal
- Use constants instead of repeated string literals
- Clean up objects when transitioning states

### Animation Smoothness
- Target 30 FPS minimum for smooth animations
- Keep `onUpdate()` fast (< 33ms per frame)
- Use easing functions for natural motion
- Test on actual device (simulator may be faster)

---

## Future Features (Roadmap)

### v2.0 (Planned)
- Heart rate monitoring via optical sensor
- Session data recording to Garmin Connect
- Breathing quality score
- Haptic feedback for breathing phases
- User settings (custom durations, patterns)

### v3.0 (Ideas)
- Multiple breathing techniques (box breathing, etc.)
- Custom session builder
- Sleep tracking integration
- Progress statistics

---

## Quick Reference

### File to Edit for...
- **Visual changes**: SleepBetterView.mc
- **Timing changes**: BreathingController.mc
- **Animation curves**: EasingFunctions.mc
- **Visual effects**: Effects.mc
- **App metadata**: manifest.xml

### Commands to Run
- **Build & test**: `/garmin-simulator full-cycle`
- **Git commit**: `git add . && git commit -m "message"`
- **Git push**: `git push origin main`

### Colors to Use
- Pure red: `0xFF0000` (emphasis)
- Dark red: `0x8B0000` (sphere)
- Muted gray: `0xC9B5B5` (timers)
- Light gray: `0xF6ECEC` (text)
- Black: `0x000000` (background)

### Fonts to Use
- Large numbers: `FONT_NUMBER_HOT`
- Standard text: `FONT_SMALL`, `FONT_MEDIUM`
- Small labels: `FONT_TINY`

---

## Contact and Support

- **GitHub Repository**: (add URL when available)
- **Garmin SDK Documentation**: https://developer.garmin.com/connect-iq/api-docs/
- **MonkeyC Language**: https://developer.garmin.com/connect-iq/monkey-c/

---

## Version 3.6 Key Changes

### Premium Design Enhancements

1. **Golden Ratio Layout** - Start screen uses φ (1.618) for harmonious positioning
2. **Circular Countdown Pill** - 28px radius circle with crimson border wraps phase number
3. **Color Hierarchy** - Session timer and phase watermark in pure red (#FF0000) for emphasis
4. **Cinematic Fade-In** - 1s smooth transition from intro to breathing screen
5. **Dual Fade System** - Session fade (1s) + phase watermark fade (0.6s) work together
6. **Screen Wake Lock** - Prevents screen sleep during active breathing session
7. **Pulse Effect** - Subtle red pulse on countdown reset to "0" (first 15% of phase)

### Technical Additions

- `_interpolateColor()` helper function for smooth color transitions
- `_sessionFadeIn` variable tracking 1-second fade animation
- `_phaseChangeFadeIn` variable tracking 0.6-second phase watermark fade
- Golden ratio calculations in `_drawIdleScreen()` (0.236, 0.764, 0.882)
- Circular pill rendering in `_drawCountdown()` with crimson fill + border
- Pulse detection using phaseProgress < 0.15 for countdown reset animation
- Fade application to all graphics (sphere, ring, guide, text)
- Phase watermark rendered on TOP of all layers

### Color Specifications (v3.6)

- **Session Timer**: Pure red (0xFF0000) - high visibility
- **Phase Watermark**: Pure red (0xFF0000) - emphasis, FONT_NUMBER_MEDIUM
- **Countdown Pill Background**: Crimson (COLOR_SPHERE_RIM) with fill
- **Countdown Pill Text**: Muted (0xC9B5B5) - readable against crimson
- **Pulse Effect**: Pure red (0xFF0000) flash on zero reset

### User Experience

- Start screen feels mathematically balanced and intentional
- Phase countdown no longer looks lonely - circular pill creates visual purpose
- Red session timer creates immediate visual hierarchy and emphasis
- Smooth transitions eliminate jarring visual changes
- Pulse effect provides subtle feedback on phase transitions
- All elements work together harmoniously
- Premium, polished, professional aesthetic throughout

---

**Last Updated**: 2025-10-29 (v3.6)
**Maintained By**: Development team
**Purpose**: AI assistant instructions for continuing development without losing context
