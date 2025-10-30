# Device Scaling Documentation
# 4-7-8 Breathing App - Multi-Device Support

**Version**: v3.8
**Date**: 2025-10-30
**Purpose**: Document screen sizes and proportional scaling logic for multi-device support

---

## Overview

This app uses **dynamic, proportional scaling** based on device screen size to ensure consistent visual appearance across different Garmin watches. All UI elements (sphere, progress ring, text) scale relative to the device's screen dimensions.

---

## Supported Devices (Target)

### Primary Device: Garmin Venu 3
- **Screen Size**: 454×454 pixels
- **Shape**: Circular AMOLED
- **Touch**: Yes
- **Status**: Primary development and testing device
- **PRD Reference**: All measurements based on Venu 3

### Future Devices (Planned)
- **Venu 2/2S**: 416×416 / 360×360 pixels
- **Forerunner 965**: 454×454 pixels
- **Epix (Gen 2)**: 416×416 pixels
- **Other AMOLED watches**: Various sizes

---

## Scaling Philosophy

### Core Principle
**All UI elements scale proportionally to screen size**, not absolute pixel values.

**Why?**
- Maintains visual consistency across devices
- Future-proof for new watch models
- No hardcoded pixel values
- Clean, maintainable code

### Scaling Approach
1. **Reference Dimension**: Use minimum of width/height
2. **Percentage-Based**: Express all sizes as percentages of reference
3. **Maintain Ratios**: Keep proportions between elements constant

---

## Venu 3 Reference Measurements

### Screen Properties
```monkey
Width:  454px
Height: 454px
Center: (227, 227)
Min Dimension: 454px (circular, so width == height)
```

### Progress Ring
```monkey
// Reference: Full screen, touching edges
_progressRadius = (minDim / 2.0) - 8;  // 219px
_progressThickness = 10.0;              // 10px stroke

// Scaling logic:
// - Radius: 48.2% of screen width (219/454 = 0.482)
// - Thickness: 2.2% of screen width (10/454 = 0.022)
// - Margin: 1.8% from edge (8/454 = 0.018)

// Direction (v3.8):
// - Starts at 12 o'clock position (top of screen)
// - Fills clockwise like an analog clock
// - Uses ARC_COUNTER_CLOCKWISE with reversed angle calculation
//   (startAngle = 90°, endAngle = 90 - degrees)
```

**PRD Note**: PRD mentions "44 radius units" but this is ambiguous.
Current implementation (48.2% of screen) matches HTML prototype and provides better visual balance.

**v3.8 Update**: Fixed progress ring direction to match intuitive analog clock behavior.

### Breathing Sphere
```monkey
// Reference: Scales from 33% to 55% of progress ring radius
_sphereMax = _progressRadius * 0.55;   // 120px (55% of ring radius)
_sphereMin = _sphereMax * 0.33;        // 40px (33% of max sphere)

// Scaling logic:
// - Max size: 26.4% of screen width (120/454 = 0.264)
// - Min size: 8.8% of screen width (40/454 = 0.088)
// - Range: 33% to 100% of max radius
```

**PRD Requirement**: Sphere scales 0.33x to 1.0x ✓

### Font Sizes (Relative)
```monkey
// Fonts scale automatically based on Garmin's font system
FONT_SIZE_TITLE = Gfx.FONT_SMALL;            // Title text
FONT_SIZE_PILL = Gfx.FONT_TINY;              // Pill button text
FONT_SIZE_PHASE_WATERMARK = Gfx.FONT_LARGE;  // Phase watermark
FONT_SIZE_COUNTDOWN = Gfx.FONT_NUMBER_THAI_HOT; // Countdown number
FONT_SIZE_TIMER = Gfx.FONT_SMALL;            // Session timer
FONT_SIZE_PATTERN = Gfx.FONT_TINY;           // Pattern display
```

**Note**: Garmin's built-in fonts automatically scale for different screen sizes.

---

## Scaling Calculations (Code Reference)

### File: `SleepBetterView.mc` → `onLayout()`

```monkey
function onLayout(dc) {
    // Get device screen dimensions
    _width = dc.getWidth();    // e.g., 454px on Venu 3
    _height = dc.getHeight();  // e.g., 454px on Venu 3

    // Calculate center point
    _centerX = _width / 2.0;   // 227px
    _centerY = _height / 2.0;  // 227px

    // Use minimum dimension as reference (handles rectangular screens)
    var minDim = (_width < _height) ? _width : _height;

    // --- PROGRESS RING SCALING ---
    // Full screen ring touching edges
    // Formula: (screen_width / 2) - stroke_margin
    _progressRadius = (minDim / 2.0) - 8;  // 219px on Venu 3
    _progressThickness = 10.0;              // Fixed 10px stroke

    // --- SPHERE SCALING ---
    // Sphere sized relative to progress ring
    // Max: 55% of ring radius (large, prominent)
    // Min: 33% of max sphere (maintains PRD requirement)
    _sphereMax = _progressRadius * 0.55;   // 120px on Venu 3
    _sphereMin = _sphereMax * 0.33;        // 40px on Venu 3
    _currentRadius = _sphereMin;           // Start at minimum

    WatchUi.requestUpdate();
}
```

### Scaling Percentages Summary

| Element | Formula | Venu 3 Value | % of Screen | Notes |
|---------|---------|--------------|-------------|-------|
| **Progress Ring Radius** | `(minDim/2) - 8` | 219px | 48.2% | Touches edges |
| **Progress Ring Thickness** | `10.0` | 10px | 2.2% | Fixed stroke |
| **Sphere Max** | `ringRadius * 0.55` | 120px | 26.4% | Inhale peak |
| **Sphere Min** | `sphereMax * 0.33` | 40px | 8.8% | Exhale/idle |
| **Sphere Range** | `min to max` | 40-120px | 0.33x-1.0x | PRD compliant |

---

## Multi-Device Adaptation Examples

### Example 1: Venu 2S (360×360px)

**Screen Properties**:
- Width: 360px
- Height: 360px
- Center: (180, 180)
- Min Dimension: 360px

**Calculated Sizes**:
```monkey
_progressRadius = (360 / 2.0) - 8 = 172px   // (47.8% of screen)
_progressThickness = 10.0px                  // (2.8% of screen)
_sphereMax = 172 * 0.55 = 95px              // (26.4% of screen)
_sphereMin = 95 * 0.33 = 31px               // (8.6% of screen)
```

**Result**: Proportions maintained! Sphere still 33%-100% of max.

---

### Example 2: Forerunner 965 (454×454px)

**Screen Properties**: Same as Venu 3

**Calculated Sizes**: Identical to Venu 3
```monkey
_progressRadius = 219px
_sphereMax = 120px
_sphereMin = 40px
```

**Result**: Perfect match!

---

### Example 3: Hypothetical Rectangular Device (390×390px)

**Screen Properties**:
- Width: 390px
- Height: 390px (assuming square for simplicity)
- Center: (195, 195)
- Min Dimension: 390px

**Calculated Sizes**:
```monkey
_progressRadius = (390 / 2.0) - 8 = 187px   // (47.9% of screen)
_sphereMax = 187 * 0.55 = 103px             // (26.4% of screen)
_sphereMin = 103 * 0.33 = 34px              // (8.7% of screen)
```

**Result**: Still proportional!

---

## Visual Consistency Verification

### Checklist for New Device Support

When adding support for a new device, verify:

1. **Progress Ring**:
   - [ ] Ring touches or nearly touches screen edges
   - [ ] Ring radius is ~48% of screen width
   - [ ] Ring thickness is ~2.2% of screen width
   - [ ] Ring is perfectly circular

2. **Breathing Sphere**:
   - [ ] Sphere max size is ~26% of screen width
   - [ ] Sphere min size is ~9% of screen width
   - [ ] Sphere scales smoothly from min to max
   - [ ] Sphere appears centered in ring

3. **Text Elements**:
   - [ ] Title text readable and proportional
   - [ ] Countdown number large and prominent
   - [ ] Pill text legible at top
   - [ ] Timer text visible above sphere

4. **Visual Balance**:
   - [ ] No clipping or overflow
   - [ ] Elements don't overlap inappropriately
   - [ ] Overall appearance matches Venu 3 proportions

---

## Code Maintainability

### Best Practices

1. **Never use hardcoded pixel values** for positioning/sizing
2. **Always calculate relative to screen dimensions**
3. **Use percentages in comments** to document intent
4. **Test on multiple screen sizes** via simulator
5. **Document scaling ratios** when changing layout

### Example: BAD vs GOOD

**BAD** (Hardcoded pixels):
```monkey
// Don't do this!
_sphereRadius = 120;  // Only works on 454px screens
_progressRadius = 219; // Breaks on smaller devices
```

**GOOD** (Dynamic scaling):
```monkey
// Do this!
_progressRadius = (minDim / 2.0) - 8;  // 48.2% of screen
_sphereMax = _progressRadius * 0.55;    // 55% of ring
```

---

## Testing Strategy

### Simulator Testing Matrix

| Device | Screen | Status | Notes |
|--------|--------|--------|-------|
| Venu 3 | 454×454 | ✓ Primary | Reference device |
| Venu 2 | 416×416 | ⏳ TODO | Slightly smaller |
| Venu 2S | 360×360 | ⏳ TODO | Significantly smaller |
| Forerunner 965 | 454×454 | ⏳ TODO | Same size, different model |
| Epix Gen 2 | 416×416 | ⏳ TODO | Same as Venu 2 |

### Visual Regression Testing

For each new device:
1. Take screenshots at key states (idle, session, outro)
2. Measure element sizes as % of screen width
3. Compare percentages to Venu 3 reference
4. Verify ±2% tolerance for layout consistency

---

## Future Enhancements

### Planned Improvements

1. **Adaptive Font Scaling**:
   - Use screen-relative font sizes instead of fixed Garmin fonts
   - Calculate optimal text size based on available space

2. **Smart Margins**:
   - Adjust margins based on screen shape (circular vs square)
   - Account for bezels and safe zones

3. **Resolution Awareness**:
   - Optimize line thickness for high-DPI screens
   - Adjust anti-aliasing based on pixel density

4. **Layout Presets**:
   - Define layout configs per device family
   - Override specific values for edge cases

---

## References

### Code Files
- [SleepBetterView.mc:124-143](SleepBetter/Garmin/V3-CL/source/SleepBetterView.mc#L124-L143) - `onLayout()` scaling logic
- [Effects.mc](SleepBetter/Garmin/V3-CL/source/Effects.mc) - Rendering functions
- [PRD.md](PRD.md) - Product requirements

### Garmin Documentation
- [Connect IQ Device Specs](https://developer.garmin.com/connect-iq/compatible-devices/)
- [Graphics API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html)

---

**Version History**:
- v3.8 (2025-10-30): Updated progress ring direction documentation
- v.01-beta (2025-10-21): Initial scaling documentation for Venu 3
