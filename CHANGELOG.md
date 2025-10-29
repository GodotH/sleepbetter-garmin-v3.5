# Changelog - SleepBetter Breathing App

All notable changes to this project will be documented in this file.

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
