# SleepBetter UI Issues - Root Cause Analysis

**Date**: 2025-10-20
**Status**: App runs but UI is completely wrong
**Severity**: HIGH - Visual design does not match prototype at all

---

## Executive Summary

The SleepBetter app compiles and runs successfully in the simulator, but the **visual interface is completely wrong**. While the functionality works (tap handling, breathing animation, timer), the UI looks nothing like the original crimson-themed, minimalist HTML prototype.

---

## Visual Comparison

### **What We Expected** (HTML Prototype)
- **Clean minimalist design** with dark crimson gradient background
- **Large animated breathing sphere** in the center (smooth expansion/contraction)
- **Subtle progress ring** around the sphere (thin, barely visible)
- **Large countdown number** overlaid on sphere
- **Small labels** for phase names (Inhale/Hold/Exhale) above sphere
- **"Tap to Begin" hint** at bottom
- **Elegant typography** with proper sizing hierarchy
- **Total time display** at top (small, subtle)
- **Pattern display** (4-7-8) below sphere (small, subtle)
- **No visible UI elements** except sphere, ring, and text
- **Deep red color scheme** (#120404 background, #E43A3A accents)

### **What We Got** (MonkeyC in Simulator)
- ❌ **Cluttered screen** with too many visible labels
- ❌ **Title "4-7-8 Breathing"** prominently displayed at top (should be subtle)
- ❌ **"0:49" time** displayed as large text (should be small at top)
- ❌ **"Exhale" phase** label too prominent
- ❌ **Huge "3" countdown** - Good! (This part is correct)
- ❌ **"4-3-5" pattern** displayed prominently (should be subtle)
- ❌ **"Tap to Begin" at bottom** - Good placement but timing is wrong
- ❌ **Wrong layout structure** - Labels are from XML layout, overlaying the canvas
- ❌ **Black background** instead of deep crimson gradient
- ❌ **No visible breathing sphere animation** (or it's obscured)
- ❌ **Text hierarchy wrong** - Everything is same importance

---

## Root Causes Identified

### 🔴 **Issue #1: XML Layout Interference**

**File**: [resources/layouts/main_layout.xml](resources/layouts/main_layout.xml)

**Problem**: The MonkeyC app uses a declarative XML layout that places labels at fixed positions. These labels are **always visible** and **overlay the canvas**, creating visual clutter.

**HTML Prototype Approach**:
```html
<!-- HTML uses absolute positioning and hides/shows elements dynamically -->
<div class="overlay" id="mainOverlay" style="display:none">
  <div class="watermark">INHALE</div>
  <div class="count">0</div>
</div>
```

**MonkeyC Current Approach**:
```xml
<!-- XML layout - elements are ALWAYS visible -->
<label id="TitleLabel" x="center" y="10%" text="@Strings.AppName" />
<label id="TotalLabel" x="center" y="20%" text="0:00" />
<label id="PhaseLabel" x="center" y="32%" text="@Strings.PhasePrepare" />
<label id="CountdownLabel" x="center" y="45%" text="0" />
<label id="BlockLabel" x="center" y="58%" text="" />
<label id="HintLabel" x="center" y="88%" text="@Strings.TapInstruction" />
```

**Root Cause**: XML layout doesn't support dynamic show/hide or z-index stacking like HTML/CSS. All labels are rendered in a fixed layer, causing them to obstruct the breathing sphere and create a cluttered appearance.

---

### 🔴 **Issue #2: Canvas-Based Drawing Not Used Correctly**

**File**: [source/SleepBetterView.mc](source/SleepBetterView.mc)

**Problem**: The view renders everything via `_render(dc)` method using Graphics primitives, but this **doesn't interact** with the XML layout labels. The canvas drawing happens **behind** the label layer.

**Current Architecture**:
```
Z-Index Stack (front to back):
1. XML Layout Labels (always visible, always on top)
2. Canvas Graphics (sphere, progress ring, effects)
3. Background color
```

**HTML Prototype Architecture**:
```
Z-Index Stack (front to back):
1. Countdown number (z-index: 2)
2. Watermark/phase label (z-index: 1, opacity: 0.16)
3. Sphere (centered, scales with animation)
4. Progress ring (subtle, barely visible)
5. Background gradient
```

**Root Cause**: MonkeyC's UI system separates "layout elements" (XML) from "canvas drawing" (Graphics). The prototype's layered approach with dynamic visibility doesn't translate directly.

---

### 🔴 **Issue #3: Visual Hierarchy Broken**

**Problem**: In the HTML prototype, elements have carefully tuned:
- **Opacity levels** (e.g., phase label at 16% opacity = watermark effect)
- **Font sizes** (countdown is huge, everything else is small)
- **Z-index stacking** (countdown overlays sphere, phase label is behind)
- **Dynamic visibility** (elements show/hide based on state)

**MonkeyC Implementation**:
- All labels have **equal visual weight**
- No opacity control on XML labels (full opacity always)
- No z-index control (XML layer is always on top)
- Labels can change TEXT but not VISIBILITY or POSITION

**Example from HTML**:
```css
.watermark {
  opacity: .16;  /* Almost invisible watermark effect */
  z-index: 1;    /* Behind countdown */
}
.count {
  font-size: clamp(40px,10vw,62px);  /* HUGE countdown */
  opacity: 1;    /* Fully visible */
  z-index: 2;    /* In front of watermark */
}
```

**MonkeyC Limitation**:
```xml
<!-- No opacity, no z-index control -->
<label id="PhaseLabel" color="0xFFE5E5" font="Gfx.FONT_MEDIUM" />
<label id="CountdownLabel" color="0xFFE5E5" font="Gfx.FONT_NUMBER_HOT" />
```

---

### 🔴 **Issue #4: Missing Dynamic State Management**

**HTML Prototype Behavior**:
```javascript
// Idle state: Only play button visible
startOverlay.style.display = 'grid';
mainOverlay.style.display = 'none';

// Running state: Countdown and phase visible, play button hidden
startOverlay.style.display = 'none';
mainOverlay.style.display = 'grid';
```

**MonkeyC Current Behavior**:
```monkey-c
// Labels are always visible, only TEXT changes
_pillText = Rez.Strings.TapInstruction;  // Text changes
_phaseText = Rez.Strings.PhaseInhale;    // Text changes

// No mechanism to hide/show labels completely
```

**Root Cause**: The view updates label TEXT but not label VISIBILITY. In idle state, labels like "Prepare" and "0" are visible when they should be hidden.

---

### 🔴 **Issue #5: Wrong Background Color**

**Expected** (HTML Prototype):
```css
background: linear-gradient(180deg, var(--crimson-900), var(--crimson-950));
/* --crimson-900: #3A0C0C */
/* --crimson-950: #120404 */
```

**Current** (MonkeyC):
```monkey-c
dc.setColor(Gfx.COLOR_TRANSPARENT, COLOR_BACKGROUND);
// COLOR_BACKGROUND = 0x120404  /* Correct color */
dc.clear();
```

**Issue**: The background IS set to correct color (0x120404 = #120404), but the **simulator might be using default watch face background** or the color appears different due to layering issues.

---

### 🔴 **Issue #6: Progress Ring Too Prominent**

**Expected** (HTML Prototype):
```css
stroke: var(--ring-bg);  /* rgba(198,38,38,.22) - Very subtle */
stroke-width: 10;
```

**Current** (MonkeyC):
```monkey-c
const COLOR_RING_TRACK = 0x2D0A0A;  /* Solid color, not transparent */
dc.setPenWidth(thickness.toNumber());  /* 12px default */
```

**Issue**: The progress ring is **too visible** compared to prototype. Should be barely noticeable.

---

### 🔴 **Issue #7: Typography Doesn't Match**

**HTML Prototype**:
- Uses **Montserrat font** (web font)
- Carefully sized with `clamp()` functions
- Specific font weights (300, 500, 600, 800)
- Letter-spacing adjustments

**MonkeyC**:
- Uses **system fonts only** (Gfx.FONT_LARGE, FONT_MEDIUM, etc.)
- No custom fonts supported
- No letter-spacing control
- Font sizes are fixed

**Root Cause**: Garmin MonkeyC doesn't support custom web fonts or fine-grained typography control. This is a **platform limitation** we must work around.

---

## Critical Issues Summary

| Issue | Severity | Fixable? | Effort |
|-------|----------|----------|--------|
| #1: XML Layout Interference | HIGH | ✅ Yes | Medium - Remove XML labels, draw text on canvas |
| #2: Canvas vs Layout Separation | HIGH | ✅ Yes | Medium - Render all UI via canvas drawing |
| #3: Visual Hierarchy Broken | HIGH | ⚠️ Partial | High - Simulate opacity with color mixing |
| #4: No Dynamic State Visibility | HIGH | ✅ Yes | Low - Control what gets drawn in _render() |
| #5: Wrong Background Color | MEDIUM | ✅ Yes | Low - Verify background rendering |
| #6: Progress Ring Too Prominent | MEDIUM | ✅ Yes | Low - Adjust colors and thickness |
| #7: Typography Mismatch | LOW | ❌ No | N/A - Platform limitation |

---

## Recommended Solution: Canvas-Only Rendering

### **Current Architecture** (Broken):
```
XML Layout (always visible)
    ↓
Canvas Drawing (obscured by labels)
    ↓
Background
```

### **Proposed Architecture** (Matches HTML):
```
Canvas Drawing (everything):
    - Background (crimson gradient simulation)
    - Progress ring (subtle)
    - Breathing sphere (animated)
    - Countdown (large, conditional visibility)
    - Phase label (watermark effect, conditional)
    - Hints (conditional)
    - Total time (small, conditional)
    - Pattern display (small, conditional)
```

### **Implementation Plan**:

1. **Remove XML layout completely** - Don't use `main_layout.xml` at all
2. **Draw everything on canvas** - Use `dc.drawText()` for all text
3. **Implement visibility logic** - Only draw elements when appropriate
4. **Simulate opacity** - Mix colors to create semi-transparent effects
5. **Control z-order** - Draw elements in correct order (background → ring → sphere → text)
6. **Match HTML states** - Idle, Intro, Running, Paused, Complete

---

## Lessons Learned for Next Time

### ⚠️ **Critical Mistakes Made**

1. **Assumed XML layout would work like HTML/CSS** - Wrong! XML is static, no dynamic styling
2. **Didn't test visual appearance early** - Should have checked simulator immediately after first build
3. **Followed documentation blindly** - Project docs said "use layouts" but didn't account for visual requirements
4. **No visual regression testing** - Should have compared prototype screenshot side-by-side from start

### ✅ **What to Do Differently**

1. **Test in simulator IMMEDIATELY** after first successful compile
   - Visual check beats code review for UI issues
   - Simulator shows real rendering behavior

2. **For UI-heavy apps, prefer canvas-only rendering**
   - XML layouts are for simple text-heavy apps (settings, lists)
   - Canvas gives full control like HTML Canvas API

3. **Create reference screenshots early**
   - Take screenshot of HTML prototype
   - Take screenshot after each MonkeyC build
   - Use visual diff tools

4. **Prototype the UI first, then add logic**
   - Build static "hello world" with correct visual layout
   - Then add animations and interaction
   - Don't assume "it will look right when done"

5. **Understand platform limitations upfront**
   - MonkeyC != JavaScript/HTML
   - No CSS, no opacity, no z-index
   - System fonts only
   - Research these BEFORE porting

6. **Read Garmin UI examples more carefully**
   - Look at sample apps that draw custom graphics
   - Don't copy text-heavy app patterns for graphical apps

### 📋 **Checklist for Future Garmin Projects**

- [ ] Identify if app is UI-heavy (graphics/animations) or data-heavy (lists/forms)
- [ ] If UI-heavy: Plan for canvas-only rendering from start
- [ ] If data-heavy: XML layouts are fine
- [ ] Create visual mockup/prototype first
- [ ] Build "UI shell" first (static, no logic)
- [ ] Test visual appearance in simulator
- [ ] ONLY THEN add animations and logic
- [ ] Test visual appearance after EVERY major change
- [ ] Keep screenshots for regression testing
- [ ] Document platform limitations discovered
- [ ] Compare with reference design frequently

---

## Next Steps

1. ✅ **Create backup branch** (current UI state preserved)
2. ✅ **Document this analysis** (this file)
3. ⚠️ **Refactor to canvas-only rendering**:
   - Remove XML layout usage
   - Implement `_drawUI(dc)` method with all UI elements
   - Add state-based visibility logic
   - Match HTML visual hierarchy
4. ⚠️ **Test each change in simulator** (incremental commits)
5. ⚠️ **Compare with prototype** until perfect match (within platform constraints)

---

## Platform Constraints (Cannot Fix)

These are Garmin MonkeyC limitations we must accept:

1. ❌ **No custom fonts** - Must use system fonts
2. ❌ **No true transparency** - Can simulate with color mixing
3. ❌ **No gradients** - Can fake with concentric circles
4. ❌ **No blur effects** - Must omit or simulate with manual drawing
5. ❌ **Limited animation control** - Frame-by-frame drawing instead of CSS transitions

---

**Conclusion**: The app WORKS functionally but looks TERRIBLE visually because we used XML layouts like a traditional app instead of treating it as a graphics-heavy canvas app. The fix requires refactoring the entire rendering pipeline to draw everything on canvas, which will give us the control needed to match the HTML prototype's appearance.

---

**Document Created By**: Claude Code Agent
**Date**: 2025-10-20 17:30
**Purpose**: Root cause analysis before UI refactoring
**Status**: READY TO FIX
