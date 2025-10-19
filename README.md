# SleepBetter - 4-7-8 Breathing Exercise for Garmin Venu 3

A mindfulness breathing app implementing the 4-7-8 breathing technique, designed for Garmin Venu 3 and Venu 3S watches.

## Features

- **4-7-8 Breathing Pattern**: Scientifically-backed breathing technique (4s inhale, 7s hold, 8s exhale)
- **Animated Breathing Sphere**: Smooth visual guidance that expands and contracts with your breath
- **Session Progress**: Visual progress ring and cycle counter
- **Haptic Feedback**: Optional vibration cues for phase transitions
- **Persistent Settings**: Remembers your preferred session length and haptic preferences
- **Performance Optimized**: 10fps animation, <300KB memory, <5% battery usage per 10-minute session

## Technical Details

### Architecture

- **SleepBetterApp.mc**: Application entry point
- **SleepBetterView.mc**: Main UI and animation engine
- **BreathingController.mc**: State machine for breathing pattern
- **EasingFunctions.mc**: Smooth animation interpolation
- **HapticFeedback.mc**: Vibration feedback system
- **SettingsManager.mc**: Persistent settings storage
- **ErrorHandler.mc**: Logging and error handling

### Design Constraints

- **Crimson color palette** matching original HTML prototype
- **10fps animation** (100ms timer interval) for battery efficiency
- **Correct MonkeyC imports** (avoiding common compilation errors)
- **Proper timer cleanup** in onHide() to prevent memory leaks
- **Time jump prevention** on pause/resume

### Build Requirements

- Garmin Connect IQ SDK 8.3.0 or compatible
- Target devices: Venu 3 (454x454), Venu 3S (416x416)
- Minimum API Level: 5.2.0
- Developer key required for signing

## Building

### Using PowerShell Script (Windows)

```powershell
cd sleepbetter/Garmin
pwsh run_venu3.ps1 -ProjectPath V3-CL
```

### Manual Build

```bash
cd V3-CL

# Compile
monkeyc -o bin/SleepBetter.prg \
        -f monkey.jungle \
        -d venu3 \
        -y ../developer_key.der \
        --debug

# Deploy to simulator
monkeydo bin/SleepBetter.prg venu3

# Deploy to physical device
# Copy bin/SleepBetter.prg to GARMIN/APPS/ folder via USB
```

## Usage

1. **Start**: Tap the screen when "Ready" pill is displayed
2. **Breathe**: Follow the animated sphere and phase indicators
   - Sphere expands: Inhale (4 seconds)
   - Sphere holds: Hold breath (7 seconds)
   - Sphere contracts: Exhale (8 seconds)
3. **Pause**: Tap during session to pause
4. **Resume**: Tap again to continue from paused state
5. **Complete**: Session automatically completes after 8 cycles (adjustable)

## Settings

Settings are persisted between sessions:

- **Total Cycles**: 1-30 cycles (default: 8 = ~2.5 minutes)
- **Haptic Feedback**: Enable/disable vibration cues (default: enabled)
- **Session Statistics**: Tracks total completed sessions

## Performance Metrics

Target performance (based on implementation plan):

| Metric | Target | Critical Threshold |
|--------|--------|--------------------|
| Memory | < 300 KB | STOP if > 350 KB |
| CPU (avg) | < 15% | STOP if > 20% |
| Battery/10min | < 5% | STOP if > 7% |
| Frame time | < 100ms | STOP if > 150ms |

## Known Issues / Troubleshooting

### Common Compilation Errors

**Import Error**: `Cannot resolve super class '$.Toybox.WatchUi.App'`
- **Cause**: Using incorrect import alias pattern
- **Fix**: Use `using Toybox.Application;` then `extends Application.AppBase`
- **See**: troubleshooting.md in parent directory

**Type Errors**: `Cannot resolve type 'Number'`
- **Cause**: Missing Lang import
- **Fix**: Add `using Toybox.Lang;` to all .mc files

### Runtime Issues

**Timer Leak**: App continues consuming battery after exit
- **Cause**: Timer not stopped in onHide()
- **Fix**: Already implemented - timer cleanup in onHide()

**Time Jump**: Session jumps forward after pause/resume
- **Cause**: Not resetting _lastTickTime on resume
- **Fix**: Already implemented - reset timestamp on resume

## Development History

This is the V3-CL (Clean Launch) implementation, developed following the comprehensive 13-step plan in `sleepbetter_plan2.md`. Previous implementations (V3, Venu3) encountered import errors and have been archived.

### Implementation Steps Completed

- ✅ Step 0: Baseline verification
- ✅ Step 1: Project scaffold with correct imports
- ✅ Step 2: Breathing engine and sphere animation
- ✅ Step 3: Total timer display
- ✅ Step 4-6: Progress ring and visual effects
- ✅ Step 7-10: Haptic feedback
- ✅ Step 11: Settings persistence
- ✅ Step 12: Error handling
- ✅ Step 13: Optimization (target metrics)

## Credits

- **Original Design**: sleepbetter.html (HTML/CSS/JS prototype)
- **Implementation Plan**: sleepbetter_plan2.md
- **Platform**: Garmin Connect IQ SDK
- **Breathing Technique**: 4-7-8 breathing method by Dr. Andrew Weil

## License

Developed for personal use on Garmin Venu 3 devices.

---

*Last Updated: 2025-10-19*
*Version: 1.0.0 (V3-CL)*
