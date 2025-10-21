# PRD Update - Implementation Plan
# Align Current Code with PRD Specifications

**Version**: v.01-beta → v1.0.0
**Date**: 2025-10-21
**Timestamp**: 2025-10-21T12:51:00Z
**Status**: Planning Phase
**Target**: v1.0.0 PRD Compliance
**Current Codebase**: v.01-beta (working, needs PRD alignment)

---

## Gap Analysis: PRD vs Current Implementation

### ✅ IMPLEMENTED (Correct)
1. **Session Duration**: 10 minutes total ✓
2. **Progress Ring Timing**: Matches numerical timer, pauses when paused ✓
3. **Single-tap interaction**: Tap to start/pause/resume ✓
4. **Back button**: Exit/reset ✓
5. **Breathing animations**: Sphere scales with ease-in-out ✓
6. **Canvas-only rendering**: No XML dependencies ✓
7. **AMOLED optimization**: Pure blacks (#120404) ✓

### ❌ NOT IMPLEMENTED (Missing/Incorrect)

#### 1. Session Structure (CRITICAL)
**PRD Requirement**:
- Warm-up: 1.5 minutes (4-4-5 pattern)
- Transition: 1.5 minutes (4-5-6 pattern)
- Main: 7 minutes (4-7-8 pattern)

**Current Implementation**:
- Ramp: 1 minute (4-4-5 pattern)
- Main: 9 minutes (4-7-8 pattern)
- **MISSING**: 4-5-6 transition phase

**Impact**: Session phases don't match PRD
**Priority**: HIGH

---

#### 2. Intro Sequence Timing (CRITICAL)
**PRD Requirement**: 5.5 seconds total
1. Play button fadeout (0.3s)
2. Sphere appears with pulse (1.6s cycle)
3. "Get Ready" message (4.5s total)
4. "Inhale" splash (1s)
5. Begin session

**Current Implementation**:
- `INTRO_DURATION = 2.0` seconds
- No "Get Ready" message
- No "Inhale" splash
- Intro animation too short

**Impact**: Intro experience doesn't match PRD
**Priority**: HIGH

---

#### 3. Outro Sequence Timing (CRITICAL)
**PRD Requirement**: 16 seconds total
1. Sphere/halo fade (4s)
2. Red circle appears (3s delay)
3. Transform to outro screen (7s)
4. "Well Done" text (9s)
5. Heart message reveal (15s)

**Current Implementation**:
- `OUTRO_DURATION = 3.5` seconds
- No phased animations
- No heart message
- Outro too short

**Impact**: Outro experience doesn't match PRD
**Priority**: MEDIUM

---

#### 4. Color Verification (MEDIUM)
**PRD Requirements**:
- Primary: #8B0000 (Dark Red)
- Background gradient: #1b0708 to #150506
- Text: #F6ECEC (Light)
- Muted text: #C9B5B5
- Countdown white: #FFFFFF

**Current Implementation** (need verification):
```monkey
COLOR_BACKGROUND = 0x120404         // Should be #1b0708 or #150506?
COLOR_BACKGROUND_ACCENT = 0x3A0C0C  // Verify
COLOR_TEXT_PRIMARY = 0xF7EDED       // Close to #F6ECEC ✓
COLOR_TEXT_MUTED = 0xCBB3B3         // Close to #C9B5B5 ✓
```

**Impact**: Visual accuracy
**Priority**: MEDIUM

---

#### 5. Progress Ring Radius ✅ (CORRECT - Keep Dynamic Scaling)
**PRD Requirement**: 44 radius units

**Current Implementation** (CORRECT):
```monkey
_progressRadius = (minDim / 2.0) - 8;  // ~219px on 454px screen
```

**Analysis**:
- 454px screen → 219px radius (48.2% of screen width)
- PRD "44 units" is ambiguous - likely meant as percentage or ratio
- **Current dynamic scaling is CORRECT and should be kept**
- Scales proportionally for multi-device support
- Matches HTML prototype visual appearance

**Decision**: ✅ **Keep dynamic scaling - DO NOT change to hardcoded pixels**

**Rationale**:
1. Multi-device support requires dynamic sizing
2. Visual balance maintained across screen sizes
3. Future-proof for new watch models
4. See [DEVICE-SCALING.md](DEVICE-SCALING.md) for full documentation

**Impact**: None - current implementation is optimal
**Priority**: N/A (no changes needed)

---

#### 6. Sphere Scaling Range (VERIFY)
**PRD Requirement**: 0.33x to 1.0x

**Current Implementation**:
```monkey
_sphereMax = _progressRadius * 0.55;   // ~120px
_sphereMin = _sphereMax * 0.25;        // ~30px
// Ratio: 30/120 = 0.25x to 1.0x (not 0.33x)
```

**Impact**: Minimum sphere slightly smaller than PRD
**Priority**: LOW

---

## Implementation Plan

### Phase 1: Session Structure Fix (CRITICAL)
**File**: `BreathingController.mc`

**Changes**:
1. Update `getDefaultPlan()`:
   ```monkey
   return [
       {
           "label" => "Warm-up 4-4-5",
           "minutes" => 1.5,
           "pattern" => { "inhale" => 4.0, "hold" => 4.0, "exhale" => 5.0 }
       },
       {
           "label" => "Transition 4-5-6",
           "minutes" => 1.5,
           "pattern" => { "inhale" => 4.0, "hold" => 5.0, "exhale" => 6.0 }
       },
       {
           "label" => "Main 4-7-8",
           "minutes" => 7.0,
           "pattern" => { "inhale" => 4.0, "hold" => 7.0, "exhale" => 8.0 }
       }
   ];
   ```

**Testing**: Verify total duration = 10 minutes

---

### Phase 2: Intro Sequence Fix (CRITICAL)
**File**: `SleepBetterView.mc`

**Changes**:
1. Update `INTRO_DURATION = 5.5` (from 2.0)
2. Add intro sub-states:
   - 0.0-0.3s: Play button fadeout
   - 0.3-4.5s: "Get Ready" message
   - 4.5-5.5s: "Inhale" splash
3. Update `_updateIntro()` to handle phased animations
4. Add resource strings for "Get Ready" and "Inhale"

**Files to modify**:
- `SleepBetterView.mc`: Intro logic
- `resources/strings.xml`: Add new strings

---

### Phase 3: Outro Sequence Fix (MEDIUM)
**File**: `SleepBetterView.mc`

**Changes**:
1. Update `OUTRO_DURATION = 16.0` (from 3.5)
2. Add outro sub-states:
   - 0.0-4.0s: Sphere/halo fade
   - 4.0-7.0s: Red circle appears
   - 7.0-9.0s: "Well Done" text
   - 9.0-15.0s: Heart message reveal
3. Update `_updateComplete()` to handle phased animations
4. Add resource strings for heart message

**Files to modify**:
- `SleepBetterView.mc`: Outro logic
- `Effects.mc`: Phased outro rendering
- `resources/strings.xml`: Add heart message

---

### Phase 4: Color Verification (MEDIUM)
**File**: `SleepBetterView.mc`

**Changes**:
1. Verify/update colors to match PRD exactly:
   ```monkey
   COLOR_BACKGROUND = 0x1b0708;          // PRD gradient start
   COLOR_BACKGROUND_ACCENT = 0x8B0000;   // PRD primary red
   COLOR_TEXT_PRIMARY = 0xF6ECEC;        // PRD light text
   COLOR_TEXT_MUTED = 0xC9B5B5;          // PRD muted text
   ```

2. Test on simulator for visual accuracy

---

### Phase 5: Sphere Scaling Fix (LOW)
**File**: `SleepBetterView.mc`

**Changes**:
1. Update sphere scaling to 0.33x minimum:
   ```monkey
   _sphereMin = _sphereMax * 0.33;  // From 0.25
   ```

2. Test breathing animation smoothness

---

### Phase 6: Documentation & Testing
1. Update git tags with new version
2. Test all phases on simulator
3. Verify 10-minute session timing
4. Screenshot comparison with HTML prototype
5. Battery usage test (target < 2% per session)

---

## Files to Backup Before Changes

```
SleepBetter/Garmin/V3-CL/
├── source/
│   ├── BreathingController.mc  (Phase 1)
│   ├── SleepBetterView.mc      (Phases 2, 3, 4, 5)
│   └── Effects.mc              (Phase 3)
└── resources/
    └── strings.xml             (Phases 2, 3)
```

**Backup command**:
```bash
cd SleepBetter/Garmin/V3-CL
git stash push -m "Pre-PRD-update backup"
git tag -a v1.0.0-pre-prd-update -m "Backup before PRD alignment"
```

---

## Success Criteria

### Must Have (v1.0.0 Release)
- [ ] Session: 1.5min (4-4-5) + 1.5min (4-5-6) + 7min (4-7-8) = 10min
- [ ] Intro: 5.5 seconds with "Get Ready" and "Inhale" messages
- [ ] Outro: 16 seconds with phased animations and heart message
- [ ] Colors: Match PRD exactly (#8B0000, #1b0708, etc.)
- [ ] Sphere: 0.33x to 1.0x scaling range
- [ ] Progress ring: Matches timer, pauses correctly
- [ ] Build: Successful on Venu3 simulator
- [ ] Battery: < 2% drain per 10-minute session

### Nice to Have (Future)
- [ ] Haptic feedback for breathing phases
- [ ] Heart rate tracking
- [ ] Session history in Garmin Connect

---

## Risk Assessment

### High Risk
1. **Intro/Outro timing**: Complex phased animations may cause stuttering
   - **Mitigation**: Use simple alpha fades, test on device

2. **Session structure**: Adding 4-5-6 phase changes total cycle count
   - **Mitigation**: Recalculate in `_rebuildPlan()`, verify total = 10min

### Medium Risk
1. **Color changes**: May look different on physical device vs simulator
   - **Mitigation**: Test on actual Venu3 hardware

2. **Performance**: Longer intro/outro may impact battery
   - **Mitigation**: Profile battery usage, optimize animations

### Low Risk
1. **Sphere scaling**: Minor visual change
   - **Mitigation**: A/B test 0.25x vs 0.33x

---

## Timeline Estimate

- **Phase 1** (Session Structure): 30 minutes
- **Phase 2** (Intro Sequence): 1-2 hours
- **Phase 3** (Outro Sequence): 1-2 hours
- **Phase 4** (Color Verification): 30 minutes
- **Phase 5** (Sphere Scaling): 15 minutes
- **Phase 6** (Testing): 1 hour

**Total**: 4-6 hours

---

## Next Steps

1. ✅ Create backup (git stash + tag)
2. Implement Phase 1 (session structure)
3. Build and test
4. Implement Phase 2 (intro)
5. Build and test
6. Continue through phases sequentially
7. Final integration test
8. Tag v1.0.0 release
