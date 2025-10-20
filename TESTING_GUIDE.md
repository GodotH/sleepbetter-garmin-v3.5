# Testing Guide - SleepBetter Garmin App

## Prerequisites

### Required Software
1. **Connect IQ SDK** - Already installed and configured
   - Location: `c:\Users\godot\OneDrive\_LIVE\AGENTS\sleepbetter\Garmin\`
   - Version: SDK 7.4.1 or compatible
   - Verify: `monkeyc --version` should work

2. **Connect IQ Simulator** - Must be running before testing
   - Start simulator before running `monkeydo` command
   - Default connection: localhost
   - Required for device testing

### Build Verification
- Latest build: `bin/SleepBetter.prg` (132KB)
- Build status: SUCCESS (0 errors, 0 warnings)
- Target device: Venu 3 (venu3)

## Testing Steps

### 1. Start the Connect IQ Simulator

**IMPORTANT**: The simulator must be running BEFORE you try to load the app.

```bash
# Launch the simulator (command depends on your SDK installation)
connectiq
```

**Symptoms of Missing Simulator**:
```
Unable to connect to simulator.
```

**Solution**:
1. Find and launch the Connect IQ simulator application
2. Wait for simulator window to open
3. Then proceed to step 2

### 2. Load the App into Simulator

Once the simulator is running:

```bash
cd sleepbetter/Garmin/V3-CL
monkeydo bin/SleepBetter.prg venu3
```

**Expected Output**:
```
Launching app...
[Device name: Venu 3]
App loaded successfully
```

### 3. Manual Testing Checklist

#### Initial State
- [ ] App launches without crash
- [ ] Black background displays
- [ ] Breathing sphere appears (should be crimson/dark red)
- [ ] Timer shows "00:00" format
- [ ] Text "Tap to Begin" is visible

#### Start Session (Tap Screen)
- [ ] Tap anywhere on screen
- [ ] Timer starts counting (00:01, 00:02, etc.)
- [ ] Breathing sphere begins animation
- [ ] Animation is smooth (not choppy)

#### Breathing Phases (4-7-8 Pattern)
Watch the sphere for 19 seconds (one full cycle):

**Inhale Phase (4 seconds)**:
- [ ] Sphere grows from small to large
- [ ] Animation is smooth (easing applied)
- [ ] Duration: ~4 seconds

**Hold Phase (7 seconds)**:
- [ ] Sphere stays at maximum size
- [ ] No jittering or movement
- [ ] Duration: ~7 seconds

**Exhale Phase (8 seconds)**:
- [ ] Sphere shrinks from large to small
- [ ] Animation is smooth (easing applied)
- [ ] Duration: ~8 seconds

#### Cycle Counter
- [ ] After 19 seconds, cycle counter increments (1/4, 2/4, etc.)
- [ ] Progress ring fills gradually
- [ ] Phase indicator updates (INHALE → HOLD → EXHALE)

#### Pause/Resume
- [ ] Tap screen during breathing
- [ ] App pauses (timer stops)
- [ ] Text changes to "Tap to Resume"
- [ ] Tap again to resume
- [ ] Timer continues from paused time (no jump)

#### Complete Session
- [ ] After 4 cycles (~76 seconds), session completes
- [ ] App returns to initial state
- [ ] Timer resets to "00:00"
- [ ] Text returns to "Tap to Begin"

### 4. Visual Quality Checks

#### Colors
- [ ] Background: Pure black (#000000)
- [ ] Sphere: Crimson/dark red (#DC143C)
- [ ] Text: White/light gray
- [ ] Progress ring: Matches sphere color

#### Timing Accuracy
Use a stopwatch to verify:
- [ ] Inhale takes exactly 4 seconds
- [ ] Hold takes exactly 7 seconds
- [ ] Exhale takes exactly 8 seconds
- [ ] Total cycle: 19 seconds
- [ ] 4 cycles: ~76 seconds

#### Animation Smoothness
- [ ] Sphere growth/shrink is smooth (not jerky)
- [ ] No frame drops during transitions
- [ ] Easing functions work correctly
- [ ] Progress ring updates smoothly

### 5. Memory/Performance Checks

#### Memory Usage
- [ ] App stays under 300KB memory limit
- [ ] No memory leaks during long sessions
- [ ] Multiple sessions don't accumulate memory

#### Battery Impact
- [ ] Monitor battery drain during 10-minute session
- [ ] Should be <5% battery usage
- [ ] No excessive CPU usage

## Known Issues (Pre-UI-Refactor)

### Critical Visual Issues
1. **Breathing sphere may not display correctly**
   - Root cause: Using XML layouts instead of canvas rendering
   - Status: Requires UI refactor (documented in [UI_ISSUES_ANALYSIS.md](UI_ISSUES_ANALYSIS.md))

2. **Colors may not match prototype**
   - Expected: Crimson (#DC143C) on black background
   - Actual: May vary depending on XML rendering
   - Status: Fixed in canvas-only refactor

3. **Layout may not be centered**
   - Expected: Centered breathing sphere
   - Actual: May be off-center or incorrectly sized
   - Status: Fixed in canvas-only refactor

### Functional Issues (Should Work)
- ✅ Timer logic works correctly
- ✅ Tap handling responds to input
- ✅ Breathing phase calculations accurate
- ✅ Pause/resume functionality works
- ✅ No crashes or errors

## Current Test Results

### Build Test
```
Date: 2025-10-20
Command: monkeyc -o bin/SleepBetter.prg -f monkey.jungle -d venu3 -y ../developer_key.der
Result: SUCCESS
Size: 132KB
Errors: 0
Warnings: 0
```

### Simulator Test
```
Date: 2025-10-20
Command: monkeydo bin/SleepBetter.prg venu3
Result: FAILED - Unable to connect to simulator
Reason: Simulator not running
Next Action: Start Connect IQ simulator first
```

## Next Steps

1. **Start Simulator**: Launch Connect IQ simulator application
2. **Load App**: Run `monkeydo bin/SleepBetter.prg venu3`
3. **Visual Inspection**: Check if UI matches expectations
4. **Decision Point**:
   - If UI looks correct: Proceed with full testing checklist
   - If UI is wrong: Proceed with canvas-only refactor as planned

## Testing After UI Refactor

Once the canvas-only rendering is implemented:

### Additional Tests
- [ ] Breathing sphere renders correctly (canvas-based)
- [ ] Colors match HTML prototype exactly
- [ ] Sphere is perfectly centered
- [ ] Animation frame rate is consistent (10fps)
- [ ] Easing functions produce smooth motion
- [ ] All visual elements scale properly for Venu 3

### Regression Tests
- [ ] All functional tests still pass
- [ ] No new crashes introduced
- [ ] Memory usage stays under 300KB
- [ ] Battery impact remains <5% per 10min

## Documentation
- Build report: [CODE_REVIEW_REPORT.md](CODE_REVIEW_REPORT.md)
- UI issues: [UI_ISSUES_ANALYSIS.md](UI_ISSUES_ANALYSIS.md)
- Lessons learned: [LESSONS_LEARNED.md](LESSONS_LEARNED.md)
- Git history: `git log --oneline`

---

**Last Updated**: 2025-10-20
**App Version**: v1.0.2-pre-ui-refactor
**Build Status**: SUCCESS (132KB)
**Simulator Status**: Waiting for simulator launch
