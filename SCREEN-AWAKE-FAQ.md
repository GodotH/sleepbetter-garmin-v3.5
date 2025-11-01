# Screen Wake FAQ - Garmin Connect IQ Apps
## Keeping the Display Awake During Long Sessions

**Version**: v3.9
**Date**: 2025-10-30
**App**: SleepBetter 4-7-8 Breathing App for Garmin Venu 3
**Purpose**: Document lessons learned about preventing screen sleep/dimming on Garmin watches

---

## The Challenge

When developing a 10-minute breathing exercise app for Garmin watches, we needed the screen to stay **fully bright and awake** throughout the entire session. This proved more complex than expected due to device power management and burn-in protection.

---

## Key Findings

### What DOESN'T Work

❌ **`onEnterSleep()` returning false alone**
- While this prevents the watch from entering full sleep mode
- It does NOT prevent the screen from dimming after a few seconds
- User will see: bright → dim → bright → dim cycle

❌ **Single `Attention.backlight(true)` call**
- Only turns on backlight once at session start
- Screen will still dim/sleep after device timeout period
- Not sufficient for long sessions (10+ minutes)

❌ **Infrequent periodic backlight calls (30+ seconds)**
- Screen dims between calls
- Creates jarring bright → dim → bright transitions
- Poor user experience

### What DOES Work

✅ **Ultra-Aggressive Periodic Backlight Refresh (5 seconds)**
- Call `Attention.backlight(true)` every 5 seconds
- Prevents screen from entering dim phase entirely
- Keeps consistent brightness throughout session
- Exception handling for graceful degradation

---

## The Solution

### Implementation Pattern

```monkeyc
// In your View class

private var _backlightRefreshTimer;  // Track time since last refresh

function initialize() {
    WatchUi.View.initialize();
    _backlightRefreshTimer = 0.0;
}

private function _updateRunning(dt) {
    // Ultra-aggressive backlight refresh to prevent screen dimming
    // Strategy: Call backlight(true) every 5 seconds
    // - Eliminates even brief 1-second dim phases
    // - Keeps screen consistently bright throughout entire session
    // - Exception handling for BacklightOnTooLongException (burn-in protection)
    // - Graceful degradation: catches exceptions and continues

    _backlightRefreshTimer += dt;
    if (_backlightRefreshTimer >= 5.0) {
        try {
            Attention.backlight(true);
            _backlightRefreshTimer = 0.0;
        } catch (ex) {
            // Catch BacklightOnTooLongException (burn-in protection)
            // Also handles simulator's 1-min cumulative limit
            // Reset timer to retry - exception is expected and harmless
            _backlightRefreshTimer = 0.0;
        }
    }

    // ... rest of your update logic
}

// Also implement these for complete screen wake control
function onEnterSleep() {
    // Block sleep during active session
    if (_state == AppState.STATE_RUNNING) {
        WatchUi.requestUpdate();
        return false;  // Prevent sleep mode
    }
    return true;  // Allow sleep when idle
}

function onExitSleep() {
    WatchUi.requestUpdate();
}
```

### Why 5 Seconds?

Through iterative testing on real hardware:

| Interval | Result |
|----------|--------|
| 30 seconds | Screen dims for 20+ seconds between refreshes |
| 6 seconds | Screen dims for ~1 second between refreshes |
| **5 seconds** | **No visible dimming - consistent brightness** ✅ |
| < 5 seconds | May trigger burn-in protection on some devices |

**Optimal**: 5 seconds provides the best balance between:
- Preventing screen dimming
- Avoiding burn-in protection limits
- Battery efficiency
- Consistent user experience

---

## Evolution of Our Approach

### Iteration 1: Only `onEnterSleep()`
```monkeyc
function onEnterSleep() {
    return false;  // Block sleep
}
```
**Result**: Screen stayed "awake" but still dimmed after 5-10 seconds. Not acceptable.

### Iteration 2: 30-Second Periodic Refresh
```monkeyc
if (_backlightRefreshTimer >= 30.0) {
    Attention.backlight(true);
    _backlightRefreshTimer = 0.0;
}
```
**Result**: Bright → dim → bright → dim cycle every 30 seconds. Jarring experience.

### Iteration 3: 6-Second Refresh
```monkeyc
if (_backlightRefreshTimer >= 6.0) {
    Attention.backlight(true);
    _backlightRefreshTimer = 0.0;
}
```
**Result**: Much better! But still brief 1-second dim phases visible.

### Iteration 4: 5-Second Refresh (Final) ✅
```monkeyc
if (_backlightRefreshTimer >= 5.0) {
    try {
        Attention.backlight(true);
        _backlightRefreshTimer = 0.0;
    } catch (ex) {
        _backlightRefreshTimer = 0.0;
    }
}
```
**Result**: Perfect! No visible dimming. Screen stays consistently bright for full 10-minute session.

---

## Important Considerations

### Simulator vs Real Hardware

⚠️ **Simulator Limitation**:
- Garmin simulator enforces **1-minute cumulative backlight API limit**
- Your app may crash in simulator after ~60 seconds
- This is a **development environment restriction only**

✅ **Real Hardware**:
- No 1-minute limit on actual Garmin watches
- 5-second refresh works perfectly for 10+ minute sessions
- No crashes or exceptions observed
- Tested successfully on Garmin Venu 3

**Key Takeaway**: Don't panic if simulator crashes - test on real hardware!

### Burn-In Protection

AMOLED devices (like Venu 3) have burn-in protection:
- May throw `BacklightOnTooLongException` if backlight held too long
- This is device-specific and depends on Garmin's firmware
- **Solution**: Always wrap `Attention.backlight()` in try-catch
- Exception handling ensures graceful degradation

### Battery Impact

**5-second refresh over 10 minutes**:
- 120 backlight API calls per session
- Negligible battery impact compared to session itself
- AMOLED screens are efficient with pure blacks
- Estimated impact: < 2% battery per session

**Trade-off**: Small battery cost for significantly better UX.

---

## Testing Checklist

When implementing screen wake in your app:

### Simulator Testing
- [ ] App compiles successfully
- [ ] No immediate crashes (expect crash after ~60s - this is OK)
- [ ] Backlight refresh logic executes
- [ ] Exception handling works

### Real Hardware Testing (Critical!)
- [ ] Screen stays consistently bright throughout entire session
- [ ] No dimming phases visible
- [ ] No crashes or exceptions
- [ ] Full session completes successfully (10+ minutes)
- [ ] Battery drain is acceptable
- [ ] Works with different device brightness settings

### User Settings Compatibility
Test with various user settings:
- [ ] Display timeout set to 8 seconds (default)
- [ ] Display timeout set to 15 seconds
- [ ] Display timeout set to 30 seconds
- [ ] "During Activity" display settings
- [ ] Do Not Disturb mode enabled

---

## Common Pitfalls

### 1. Forgetting Exception Handling
```monkeyc
// ❌ BAD - will crash on some devices
Attention.backlight(true);

// ✅ GOOD - graceful degradation
try {
    Attention.backlight(true);
} catch (ex) {
    // Continue gracefully
}
```

### 2. Refresh Interval Too Long
```monkeyc
// ❌ BAD - visible dimming between calls
if (_timer >= 30.0) { ... }

// ✅ GOOD - no visible dimming
if (_timer >= 5.0) { ... }
```

### 3. Not Testing on Real Hardware
- **Never rely solely on simulator behavior**
- Simulator has artificial limits that don't exist on real devices
- Always test complete sessions on actual hardware

### 4. Calling Backlight on Every Frame
```monkeyc
// ❌ BAD - excessive API calls, may trigger protection
function onUpdate(dc) {
    Attention.backlight(true);  // Called 60 times per second!
}

// ✅ GOOD - timed refresh every 5 seconds
private function _updateRunning(dt) {
    _backlightRefreshTimer += dt;
    if (_backlightRefreshTimer >= 5.0) { ... }
}
```

---

## Alternative Approaches Considered

### Activity Recording Mode
Some apps record an activity to benefit from "During Activity" display settings:
- **Pros**: System handles screen wake automatically
- **Cons**:
  - Requires activity recording permissions
  - Shows up in user's activity history
  - Overkill for meditation/breathing apps
  - May confuse users

**Our Choice**: Periodic backlight refresh is simpler and more appropriate.

### WatchUi.requestUpdate() Only
Simply calling `requestUpdate()` frequently:
- **Result**: Does NOT prevent screen dimming
- System still applies power management rules
- Not a viable solution alone

**Our Choice**: Must combine with `Attention.backlight()` API.

---

## Device-Specific Notes

### Garmin Venu 3 (AMOLED)
- 5-second refresh works perfectly
- No burn-in protection exceptions observed
- Tested for full 10-minute sessions
- Battery impact: < 2% per session

### Expected Behavior on Other Devices
**Venu 2/2S (AMOLED)**:
- Should behave similarly to Venu 3
- May have slightly different burn-in thresholds
- Test on actual hardware to confirm

**Forerunner 965 (AMOLED)**:
- Same 454×454 display as Venu 3
- Expected to work identically

**MIP Displays (e.g., Fenix series)**:
- Different power characteristics
- May require different approach
- MIP screens always visible - dimming behaves differently

---

## FAQ

### Q: Why not just use `onEnterSleep()` returning false?
**A**: This prevents full sleep mode but doesn't prevent screen dimming. Users will still see brightness fluctuations.

### Q: Will this drain the battery significantly?
**A**: No. AMOLED displays with pure black backgrounds are very efficient. The 5-second refresh adds < 2% battery drain per 10-minute session.

### Q: What about screen burn-in?
**A**:
1. Our app uses pure black backgrounds (AMOLED efficient)
2. Content is constantly animating (breathing sphere)
3. Exception handling catches burn-in protection limits
4. 10-minute session is too short for burn-in concerns

### Q: Why does it crash in the simulator?
**A**: The simulator enforces a 1-minute cumulative backlight limit that doesn't exist on real hardware. This is a development tool limitation, not a real device issue.

### Q: Can I use a longer refresh interval to save battery?
**A**: You can, but user experience suffers:
- 10+ seconds: Visible dimming between refreshes
- 6 seconds: Brief 1-second dim phases
- 5 seconds: No visible dimming (optimal)

### Q: Does this work during "Sleep Mode" hours?
**A**: Yes, but user must manually start the session. The app cannot override system sleep schedules, but once started, it keeps the screen awake.

### Q: What if BacklightOnTooLongException occurs?
**A**: Our exception handling catches it gracefully. The timer resets and tries again after 5 seconds. The session continues normally.

---

## References

### Garmin Developer Documentation
- [Attention Module API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html)
- [WatchUi.View onEnterSleep()](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html#onEnterSleep-instance-method)
- [Getting the User's Attention](https://developer.garmin.com/connect-iq/core-topics/getting-the-users-attention/)

### Forum Discussions
- [onEnterSleep, DISPLAY_MODE_HIGH_POWER interaction](https://forums.garmin.com/developer/connect-iq/f/discussion/418349/)
- [Is it possible to refresh the screen to stay on longer](https://forums.garmin.com/developer/connect-iq/f/discussion/314782/)

### Related Documentation
- [PRD.md](PRD.md) - Product requirements with screen wake specifications
- [CHANGELOG.md](CHANGELOG.md) - Version history and implementation details
- [DEVICE-SCALING.md](DEVICE-SCALING.md) - Multi-device support documentation

---

## Summary

**The winning formula for Garmin screen wake**:

1. ✅ Call `Attention.backlight(true)` every **5 seconds**
2. ✅ Wrap in try-catch for exception handling
3. ✅ Implement `onEnterSleep()` returning false during active sessions
4. ✅ Test on **real hardware** (simulator will crash - this is OK)
5. ✅ Verify no visible dimming throughout entire session

**Result**: Consistent, bright screen experience for your users throughout long sessions, with minimal battery impact and graceful degradation.

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Tested On**: Garmin Venu 3 (firmware up to date)
**App Version**: SleepBetter v3.9
