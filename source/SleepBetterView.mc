// ============================================================================
// SleepBetterView.mc
// 4-7-8 Breathing App - Main View Controller
// ============================================================================
// VERSION: v.02c (HTML prototype timing corrections)
// TIMESTAMP: 25-1022-21:20
// DEVICE: Garmin Venu 3 (454×454px)
// ============================================================================
//
// DESCRIPTION:
//   Renders the breathing session UI with dynamic, multi-device scaling.
//   All UI elements (sphere, progress ring, text) scale proportionally based
//   on device screen size for consistent appearance across watch models.
//
// KEY FEATURES:
//   - Canvas-only rendering (no XML layout)
//   - Dynamic scaling for multi-device support
//   - Single-tap interaction model
//   - AMOLED-optimized (pure blacks)
//   - Smooth animations with easing functions
//
// SCALING PHILOSOPHY:
//   See DEVICE-SCALING.md for comprehensive scaling documentation.
//   All sizes calculated relative to screen dimensions, not hardcoded pixels.
//
// ============================================================================

using Toybox.Attention;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

module AppState {
    enum {
        STATE_IDLE,
        STATE_INTRO_PULSE,
        STATE_RUNNING,
        STATE_PAUSED,
        STATE_COMPLETE
    }
}

class SleepBetterView extends WatchUi.View {
    const TIMER_INTERVAL_MS = 100;
    const INTRO_DURATION = 10.0;  // HTML prototype: ~9.7s (two 3s pulse cycles)
    const OUTRO_DURATION = 7.0;   // HTML prototype: ~6.6s (concise completion)
    const GUIDE_DURATION = 0.8;
    const IDLE_PULSE_PERIOD = 6.0;
    const MAX_DELTA = 0.5;

    // Colors matching HTML prototype exactly (PRD-compliant)
    const COLOR_BACKGROUND = 0x1B0708;          // PRD gradient start (#1B0708)
    const COLOR_BACKGROUND_ACCENT = 0x8B0000;  // PRD primary red (#8B0000)
    const COLOR_TEXT_PRIMARY = 0xF6ECEC;       // PRD light text (#F6ECEC)
    const COLOR_TEXT_MUTED = 0xC9B5B5;         // PRD muted text (#C9B5B5)
    const COLOR_RING_TRACK = 0x1A0505;         // Much darker - barely visible (was 0x2D0A0A)
    const COLOR_RING_FILL = 0xFF0000;          // Pure red #FF0000
    const COLOR_GUIDE = 0xFF6B6B;              // --watermark
    const COLOR_SPHERE_CORE = 0x1F0606;        // Even darker - almost black with crimson tint (was 0x2A0808)
    const COLOR_SPHERE_RIM = 0xE43A3A;         // --crimson-500 (bright crimson rim)
    const COLOR_SPHERE_HIGHLIGHT = 0xFF7373;   // rgba(255,115,115) highlight
    const COLOR_PILL_BACKGROUND = 0x7A1515;    // rgba(198,38,38,.14) approx
    const COLOR_PILL_BORDER = 0xC62626;        // --crimson-600
    const COLOR_OVERLAY_FILL = 0x140707;       // rgba(20,7,7,.85) approx
    const COLOR_WATERMARK = 0xFF6B6B;          // Phase watermark color

    // Font constants for canvas text rendering
    const FONT_SIZE_TITLE = Gfx.FONT_SMALL;
    const FONT_SIZE_PILL = Gfx.FONT_TINY;
    const FONT_SIZE_PHASE_WATERMARK = Gfx.FONT_LARGE;
    const FONT_SIZE_COUNTDOWN = Gfx.FONT_NUMBER_THAI_HOT;
    const FONT_SIZE_TIMER = Gfx.FONT_SMALL;
    const FONT_SIZE_PATTERN = Gfx.FONT_TINY;

    private var _controller;
    private var _timer;
    private var _state;
    private var _lastTickMs;
    private var _sessionState;
    private var _lastPhase;

    private var _width;
    private var _height;
    private var _centerX;
    private var _centerY;
    private var _sphereMin;
    private var _sphereMax;
    private var _progressRadius;
    private var _progressThickness;

    private var _currentRadius;
    private var _progressValue;
    private var _introElapsed;
    private var _outroElapsed;
    private var _guideElapsed;
    private var _idleElapsed;

    private var _pillText;
    private var _phaseText;
    private var _countdownText;
    private var _totalText;
    private var _blockText;
    private var _introMessage;  // Current intro message to display
    private var _outroPhase;  // Track outro animation phase (0-4)

    private var _phaseLabel;
    private var _countdownLabel;
    private var _totalLabel;
    private var _blockLabel;
    private var _hintLabel;

    function initialize() {
        View.initialize();

        _controller = new BreathingController();
        _timer = null;
        _state = AppState.STATE_IDLE;
        _lastTickMs = 0;
        _sessionState = null;
        _lastPhase = BreathingPhase.PHASE_PREPARE;

        _width = 0;
        _height = 0;
        _centerX = 0.0;
        _centerY = 0.0;
        _sphereMin = 60.0;
        _sphereMax = 120.0;
        _progressRadius = 140.0;
        _progressThickness = 12.0;

        _currentRadius = _sphereMin;
        _progressValue = 0.0;
        _introElapsed = 0.0;
        _outroElapsed = 0.0;
        _guideElapsed = GUIDE_DURATION;
        _idleElapsed = 0.0;

        _pillText = WatchUi.loadResource(Rez.Strings.TapInstruction);
        _phaseText = WatchUi.loadResource(Rez.Strings.PhasePrepare);
        _countdownText = "0";
        _totalText = "0:00";
        _blockText = "";
        _introMessage = "";
        _outroPhase = 0;

        // XML labels removed - now using canvas rendering
    }

    // ========================================================================
    // DYNAMIC SCALING - Multi-Device Support
    // ========================================================================
    // This function calculates all UI element sizes based on device screen
    // dimensions. Never use hardcoded pixel values - always calculate relative
    // to screen size for consistent appearance across different watch models.
    //
    // VENU 3 REFERENCE (454×454px):
    //   - Progress Ring: 219px radius (48.2% of screen width)
    //   - Sphere Max: 120px radius (26.4% of screen width)
    //   - Sphere Min: 40px radius (8.8% of screen width)
    //
    // See DEVICE-SCALING.md for comprehensive scaling documentation.
    // ========================================================================
    function onLayout(dc) {
        // Get device screen dimensions (varies by watch model)
        _width = dc.getWidth();    // e.g., 454px on Venu 3
        _height = dc.getHeight();  // e.g., 454px on Venu 3

        // Calculate center point
        _centerX = _width / 2.0;   // e.g., 227px on Venu 3
        _centerY = _height / 2.0;  // e.g., 227px on Venu 3

        // Use minimum dimension as reference (handles rectangular screens)
        var minDim = (_width < _height) ? _width : _height;  // 454px on Venu 3

        // ---------------------------------------------------------------------
        // PROGRESS RING SCALING (Dynamic)
        // ---------------------------------------------------------------------
        // Formula: (screen_width / 2) - margin
        // Result: Ring touches or nearly touches screen edges
        // Venu 3: (454 / 2) - 8 = 219px (48.2% of screen)
        //
        _progressRadius = (minDim / 2.0) - 8;  // 219px on Venu 3
        _progressThickness = 10.0;              // 10px stroke (2.2% of screen)

        // ---------------------------------------------------------------------
        // BREATHING SPHERE SCALING (Dynamic, Relative to Ring)
        // ---------------------------------------------------------------------
        // Max: 55% of ring radius (large, prominent sphere)
        // Min: 33% of max sphere (PRD requirement: 0.33x-1.0x range)
        //
        // Venu 3:
        //   Max: 219 * 0.55 = 120px (26.4% of screen)
        //   Min: 120 * 0.33 = 40px (8.8% of screen)
        //
        _sphereMax = _progressRadius * 0.55;   // 120px on Venu 3
        _sphereMin = _sphereMax * 0.33;        // 40px on Venu 3 (PRD compliant)
        _currentRadius = _sphereMin;           // Start at minimum size

        WatchUi.requestUpdate();
    }

    function onShow() {
        _startTimer();
        _lastTickMs = System.getTimer();
        WatchUi.requestUpdate();
    }

    function onHide() {
        _stopTimer();
    }

    function onUpdate(dc) {
        try {
            _render(dc);
        } catch (ex) {
            ErrorHandler.logError("SleepBetterView.onUpdate", ex);
            _resetToIdle();
        }
        // Timer already calls requestUpdate() - no need for duplicate call here
    }

    function onTap(type) {
        if (_state == AppState.STATE_IDLE) {
            _startIntro();
        } else if (_state == AppState.STATE_INTRO_PULSE) {
            _beginSession();
        } else if (_state == AppState.STATE_RUNNING) {
            _enterPause();
        } else if (_state == AppState.STATE_PAUSED) {
            _resumeSession();
        } else if (_state == AppState.STATE_COMPLETE) {
            _resetToIdle();
        }
        return true;
    }

    // ---------------------------------------------------------------------
    // Timer handling

    private function _startTimer() {
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(method(:onTimer), TIMER_INTERVAL_MS, true);
        }
    }

    private function _stopTimer() {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimer() as Void {
        var now = System.getTimer();
        var deltaMs = now - _lastTickMs;
        if (deltaMs < 0) { deltaMs = 0; }
        _lastTickMs = now;

        var dt = deltaMs.toFloat() / 1000.0;
        if (dt > MAX_DELTA) { dt = MAX_DELTA; }

        _advanceState(dt);
        WatchUi.requestUpdate();
    }

    private function _advanceState(dt) {
        if (_state == AppState.STATE_IDLE) {
            _updateIdle(dt);
        } else if (_state == AppState.STATE_INTRO_PULSE) {
            _updateIntro(dt);
        } else if (_state == AppState.STATE_RUNNING) {
            _updateRunning(dt);
        } else if (_state == AppState.STATE_PAUSED) {
            _updatePaused(dt);
        } else if (_state == AppState.STATE_COMPLETE) {
            _updateComplete(dt);
        }
    }

    // ---------------------------------------------------------------------
    // State updates

    private function _updateIdle(dt) {
        _idleElapsed += dt;
        if (_idleElapsed > IDLE_PULSE_PERIOD) {
            _idleElapsed -= IDLE_PULSE_PERIOD;
        }

        var pulse = (Math.sin((_idleElapsed / IDLE_PULSE_PERIOD) * (Math.PI * 2.0)) + 1.0) / 2.0;
        var eased = EasingFunctions.smoothstep(pulse);
        // INTRO SCREEN: Full-screen circle with subtle pulse (90% of screen radius)
        _currentRadius = _progressRadius * 0.90 + (_progressRadius * 0.05 * eased);
        _progressValue = 0.0;

        _phaseText = WatchUi.loadResource(Rez.Strings.PhasePrepare);
        _countdownText = "0";
        _totalText = "0:00";
        _blockText = "";
        _pillText = WatchUi.loadResource(Rez.Strings.TapInstruction);
    }

    private function _updateIntro(dt) {
        _introElapsed += dt;
        if (_introElapsed > INTRO_DURATION) {
            _beginSession();
            return;
        }

        // HTML Prototype Timeline (~9.7s):
        // 0.0-0.8s: Play button fadeout
        // 0.8-7.0s: "Get Ready" with gentle 6s pulse (two 3s cycles)
        // 7.0-7.9s: Transition period (sphere settles)
        // 7.9-9.7s: "Inhale" splash

        if (_introElapsed < 0.8) {
            // Phase 1: Play button fadeout
            _introMessage = "";
            _currentRadius = _sphereMin;
        } else if (_introElapsed < 7.0) {
            // Phase 2: "Get Ready" with gentle 6s pulse (two 3s cycles)
            _introMessage = WatchUi.loadResource(Rez.Strings.IntroGetReady);
            var pulseTime = _introElapsed - 0.8;  // 0.8 to 7.0 = 6.2s
            var cycleRatio = pulseTime / 6.2;  // Normalize to 0-1
            var cycleProgress = (cycleRatio * 2.0);  // Scale to 0-2 for two cycles
            // Create triangle wave: 0->1->0->1->0
            var waveValue = cycleProgress % 1.0;
            if ((cycleProgress.toNumber() % 2) == 1) {
                waveValue = 1.0 - waveValue;  // Reverse second cycle
            }
            var eased = EasingFunctions.easeInOutQuad(waveValue);
            _currentRadius = _sphereMin + ((_sphereMax * 0.55) * eased);  // Gentle pulse to 55% max
        } else if (_introElapsed < 7.9) {
            // Phase 3: Transition - sphere settles to min
            _introMessage = "";
            var settleRatio = (_introElapsed - 7.0) / 0.9;
            _currentRadius = _sphereMin + ((_sphereMax * 0.55) * (1.0 - settleRatio));
        } else {
            // Phase 4: "Inhale" splash
            _introMessage = WatchUi.loadResource(Rez.Strings.IntroInhale);
            _currentRadius = _sphereMax * 0.4;
        }

        _pillText = "";  // No pill during intro
        _phaseText = "";  // No phase watermark during intro
    }

    private function _updateRunning(dt) {
        var state = _controller.advance(dt);
        if (state != null) {
            _applySessionState(state);
            if (state["isComplete"]) {
                _enterComplete();
                return;
            }
        }
        _guideElapsed += dt;
        if (_guideElapsed > GUIDE_DURATION) {
            _guideElapsed = GUIDE_DURATION;
        }
    }

    private function _updatePaused(dt) {
        _idleElapsed += dt;
        var pulse = (Math.sin((_idleElapsed / (IDLE_PULSE_PERIOD * 1.5)) * (Math.PI * 2.0)) + 1.0) / 2.0;
        var eased = EasingFunctions.easeInOutCosine(pulse);
        var variation = (_sphereMax - _sphereMin) * 0.08 * eased;
        _currentRadius = _sphereMin + variation;
        _pillText = WatchUi.loadResource(Rez.Strings.PillPaused);
    }

    private function _updateComplete(dt) {
        _outroElapsed += dt;

        // HTML Prototype Timeline (~6.6s total):
        // 0.0-1.2s: Sphere fade (phase 0)
        // 1.2-2.2s: Outro heart screen appears (phase 1)
        // 2.2-4.6s: "Well Done" text shows (phase 2)
        // 4.6-6.0s: "Well Done" fades out (phase 3)
        // 6.0-6.6s: Heart message reveals (phase 4)

        if (_outroElapsed < 1.2) {
            _outroPhase = 0;  // Sphere fade
            var fadeRatio = _outroElapsed / 1.2;
            _currentRadius = _sphereMax * (1.0 - fadeRatio);
        } else if (_outroElapsed < 2.2) {
            _outroPhase = 1;  // Outro heart screen appears
            _currentRadius = 0.0;
        } else if (_outroElapsed < 4.6) {
            _outroPhase = 2;  // "Well Done" visible
            _currentRadius = 0.0;
        } else if (_outroElapsed < 6.0) {
            _outroPhase = 3;  // "Well Done" fading out
            _currentRadius = 0.0;
        } else {
            _outroPhase = 4;  // Heart message
            _currentRadius = 0.0;
        }
    }

    private function _applySessionState(state) {
        _sessionState = state;

        var phase = state["phase"];
        if (state["phaseChanged"]) {
            _handlePhaseChange(phase);
        }

        _progressValue = state["sessionProgress"];

        var phaseProgress = state["phaseProgress"];
        var eased = EasingFunctions.easeInOutQuad(phaseProgress);  // Matches HTML prototype

        if (phase == BreathingPhase.PHASE_INHALE) {
            _currentRadius = _sphereMin + ((_sphereMax - _sphereMin) * eased);
            _pillText = WatchUi.loadResource(Rez.Strings.PillInhale);
        } else if (phase == BreathingPhase.PHASE_HOLD) {
            _currentRadius = _sphereMax;
            _pillText = WatchUi.loadResource(Rez.Strings.PillHold);
        } else if (phase == BreathingPhase.PHASE_EXHALE) {
            var inverse = 1.0 - eased;
            _currentRadius = _sphereMin + ((_sphereMax - _sphereMin) * inverse);
            _pillText = WatchUi.loadResource(Rez.Strings.PillExhale);
        } else if (phase == BreathingPhase.PHASE_PREPARE) {
            _currentRadius = _sphereMin;
            _pillText = WatchUi.loadResource(Rez.Strings.PillReady);
        }

        _phaseText = _phaseString(phase);
        _countdownText = _formatCountdown(state["phaseRemaining"]);
        _totalText = _formatElapsed(state["sessionElapsed"]);

        if (state.hasKey("pattern")) {
            var inhale = state["inhale"].toNumber();
            var hold = state["hold"].toNumber();
            var exhale = state["exhale"].toNumber();
            _blockText = inhale + "-" + hold + "-" + exhale;
        } else {
            _blockText = "";
        }
    }

    private function _handlePhaseChange(phase) {
        _guideElapsed = 0.0;
        _lastPhase = phase;
    }


    private function _startIntro() {
        _controller.reset();
        _state = AppState.STATE_INTRO_PULSE;
        _introElapsed = 0.0;
        _guideElapsed = GUIDE_DURATION;
        _pillText = WatchUi.loadResource(Rez.Strings.PillReady);
        _phaseText = WatchUi.loadResource(Rez.Strings.PhasePrepare);
        _countdownText = "0";
        _totalText = "0:00";
    }

    private function _beginSession() {
        _controller.start();
        _state = AppState.STATE_RUNNING;
        _introElapsed = INTRO_DURATION;
        _lastPhase = BreathingPhase.PHASE_INHALE;
        _sessionState = null;
        _guideElapsed = 0.0;
        _pillText = WatchUi.loadResource(Rez.Strings.PillInhale);
    }

    private function _enterPause() {
        _controller.pause();
        _state = AppState.STATE_PAUSED;
        _pillText = WatchUi.loadResource(Rez.Strings.PillPaused);
    }

    private function _resumeSession() {
        _controller.resume();
        _state = AppState.STATE_RUNNING;
        _pillText = _phaseString(_controller.getPhase());
        _lastTickMs = System.getTimer();
    }

    private function _enterComplete() {
        _controller.stop();
        _state = AppState.STATE_COMPLETE;
        _outroElapsed = 0.0;
        _outroPhase = 0;  // Reset outro phase
        _pillText = WatchUi.loadResource(Rez.Strings.PillComplete);
        _countdownText = "0";
    }

    private function _resetToIdle() {
        _controller.reset();
        _state = AppState.STATE_IDLE;
        _sessionState = null;
        _progressValue = 0.0;
        _introElapsed = 0.0;
        _outroElapsed = 0.0;
        _guideElapsed = GUIDE_DURATION;
        _idleElapsed = 0.0;
        _lastPhase = BreathingPhase.PHASE_PREPARE;
        _pillText = WatchUi.loadResource(Rez.Strings.TapInstruction);
        _phaseText = WatchUi.loadResource(Rez.Strings.PhasePrepare);
        _countdownText = "0";
        _totalText = "0:00";
        _blockText = "";
    }

    // ---------------------------------------------------------------------
    // Rendering

    private function _render(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, COLOR_BACKGROUND);
        dc.clear();

        Effects.drawBackground(dc, _centerX, _centerY, _progressRadius, COLOR_BACKGROUND_ACCENT, COLOR_BACKGROUND);
        Effects.drawProgressRing(dc, _centerX, _centerY, _progressRadius, _progressThickness, _progressValue, COLOR_RING_TRACK, COLOR_RING_FILL);

        // NO guide circles, NO glow effects - just clean sphere
        Effects.drawSphere(dc, _centerX, _centerY, _currentRadius, COLOR_SPHERE_CORE, COLOR_SPHERE_RIM, COLOR_SPHERE_HIGHLIGHT);

        // MINIMAL UI - only show what's needed for each state
        if (_state == AppState.STATE_IDLE) {
            // Idle: NO title, just tap hint
            Effects.drawPlayHint(dc, _centerX, _centerY, _currentRadius, COLOR_TEXT_MUTED);
        } else if (_state == AppState.STATE_INTRO_PULSE) {
            // Intro: Show intro message (Get Ready / Inhale)
            if (_introMessage != null && _introMessage.length() > 0) {
                dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(
                    _centerX.toNumber(),
                    _centerY.toNumber(),
                    Gfx.FONT_LARGE,
                    _introMessage,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
                );
            }
        } else if (_state == AppState.STATE_RUNNING || _state == AppState.STATE_PAUSED) {
            // Session: ONLY countdown (large number) and timer above
            _drawCountdown(dc);
            _drawSessionTimer(dc);
        } else if (_state == AppState.STATE_COMPLETE) {
            // Complete: Phased outro animation
            _drawOutro(dc);
        }
    }

    private function _drawPill(dc, text) {
        var pillWidth = _width * 0.52;
        if (pillWidth < 160.0) { pillWidth = 160.0; }
        var pillHeight = _height * 0.11;
        if (pillHeight < 48.0) { pillHeight = 48.0; }
        var pillX = _centerX - (pillWidth / 2.0);
        var pillY = _height * 0.74;
        var radius = pillHeight / 2.0;

        dc.setColor(COLOR_PILL_BACKGROUND, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX.toNumber(), pillY.toNumber(), pillWidth.toNumber(), pillHeight.toNumber(), radius.toNumber());

        dc.setColor(COLOR_PILL_BORDER, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(pillX.toNumber(), pillY.toNumber(), pillWidth.toNumber(), pillHeight.toNumber(), radius.toNumber());

        dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            (pillY + (pillHeight / 2.0)).toNumber(),
            Gfx.FONT_MEDIUM,
            text,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    // Canvas text rendering methods
    private function _drawTitle(dc) {
        dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            (_height * 0.04).toNumber(),
            Gfx.FONT_TINY,  // Use smaller font to fit full title
            "4-7-8 Red Breathing",
            Gfx.TEXT_JUSTIFY_CENTER
        );
    }

    private function _drawPhaseWatermark(dc) {
        // Only show during active session
        if (_state != AppState.STATE_RUNNING && _state != AppState.STATE_PAUSED) {
            return;
        }

        // Phase watermark appears behind countdown with low opacity
        // MonkeyC doesn't support alpha in colors directly, so we use a dimmer version
        dc.setColor(COLOR_WATERMARK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            _centerY.toNumber(),
            FONT_SIZE_PHASE_WATERMARK,
            _phaseText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _drawCountdown(dc) {
        // Large countdown number in center
        dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            _centerY.toNumber(),
            FONT_SIZE_COUNTDOWN,
            _countdownText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _drawSessionTimer(dc) {
        // Timer above sphere
        var totalY = _centerY - (_sphereMax * 1.15);
        dc.setColor(COLOR_TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            totalY.toNumber(),
            Gfx.FONT_SMALL,
            _totalText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _drawOutro(dc) {
        // HTML Prototype phases
        if (_outroPhase <= 0) {
            // Phase 0: Sphere fading (0-1.2s)
            // Sphere already rendered in main render function
        } else if (_outroPhase == 1) {
            // Phase 1: Outro heart screen appearing (1.2-2.2s)
            // Draw full-screen semi-transparent background
            dc.setColor(0x140707, Gfx.COLOR_TRANSPARENT);  // rgba(20,7,7,.85) from HTML
            dc.fillCircle(_centerX.toNumber(), _centerY.toNumber(),
                         (_progressRadius * 0.9).toNumber());
        } else if (_outroPhase == 2 || _outroPhase == 3) {
            // Phase 2-3: "Well Done" text (2.2-6.0s)
            dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                _centerX.toNumber(),
                _centerY.toNumber(),
                Gfx.FONT_LARGE,
                WatchUi.loadResource(Rez.Strings.OutroWellDone),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
        } else {
            // Phase 4: Heart message (6.0s+)
            dc.setColor(COLOR_TEXT_PRIMARY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                _centerX.toNumber(),
                (_centerY - 30).toNumber(),
                Gfx.FONT_LARGE,
                WatchUi.loadResource(Rez.Strings.OutroWellDone),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
            dc.setColor(COLOR_TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(
                _centerX.toNumber(),
                (_centerY + 30).toNumber(),
                Gfx.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.OutroHeart),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
        }

        // Show completion stats below
        _drawSessionTimer(dc);
    }

    private function _drawTimers(dc) {
        // Total timer (above sphere)
        var totalY = _centerY - (_sphereMax * 1.35);
        dc.setColor(COLOR_TEXT_MUTED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            totalY.toNumber(),
            FONT_SIZE_TIMER,
            _totalText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Pattern display (below sphere)
        if (_blockText != null && _blockText.length() > 0) {
            var patternY = _centerY + (_sphereMax * 1.35);
            dc.drawText(
                _centerX.toNumber(),
                patternY.toNumber(),
                FONT_SIZE_PATTERN,
                _blockText,
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    private function _phaseString(phase) {
        if (phase == BreathingPhase.PHASE_INHALE) {
            return WatchUi.loadResource(Rez.Strings.PhaseInhale);
        } else if (phase == BreathingPhase.PHASE_HOLD) {
            return WatchUi.loadResource(Rez.Strings.PhaseHold);
        } else if (phase == BreathingPhase.PHASE_EXHALE) {
            return WatchUi.loadResource(Rez.Strings.PhaseExhale);
        } else if (phase == BreathingPhase.PHASE_COMPLETE) {
            return WatchUi.loadResource(Rez.Strings.PhaseComplete);
        }
        return WatchUi.loadResource(Rez.Strings.PhasePrepare);
    }

    private function _formatCountdown(seconds) {
        var s = seconds;
        if (s < 0.0) { s = 0.0; }
        var value = Math.ceil(s).toNumber();
        return value.toString();
    }

    private function _formatElapsed(elapsed) {
        if (elapsed < 0.0) { elapsed = 0.0; }
        var totalSeconds = Math.floor(elapsed).toNumber();
        var minutes = Math.floor(totalSeconds / 60).toNumber();
        var seconds = (totalSeconds - (minutes * 60)).toNumber();
        var secondsStr = seconds.toString();
        if (seconds < 10) {
            secondsStr = "0" + secondsStr;
        }
        return minutes.toString() + ":" + secondsStr;
    }
}


