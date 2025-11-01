// ============================================================================
// SleepBetterView.mc
// 4-7-8 Breathing App - Main View Controller
// ============================================================================
// VERSION: v3.6
// TIMESTAMP: 25-1029-12:00
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
    const COLOR_PILL_BACKGROUND = 0x7A1515;    // rgba(198,38,38,.14) approx
    const COLOR_PILL_BORDER = 0xC62626;        // --crimson-600
    const COLOR_OVERLAY_FILL = 0x140707;       // rgba(20,7,7,.85) approx
    const COLOR_WATERMARK = 0xFF6B6B;          // Phase watermark color

    // Font constants for canvas text rendering
    const FONT_SIZE_TITLE = Gfx.FONT_SMALL;
    const FONT_SIZE_PILL = Gfx.FONT_TINY;
    const FONT_SIZE_PHASE_WATERMARK = Gfx.FONT_NUMBER_MEDIUM;  // Reduced from FONT_NUMBER_HOT to FONT_NUMBER_MEDIUM
    const FONT_SIZE_COUNTDOWN = Gfx.FONT_MEDIUM;  // Reduced to FONT_MEDIUM for subtlety
    const FONT_SIZE_TIMER = Gfx.FONT_TINY;  // Smaller font for pattern pill
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
    private var _phaseChangeFadeIn;  // Track fade-in progress (0.0-1.0)
    private var _sessionFadeIn;      // Track session fade-in progress (0.0-1.0)
    private var _backlightRefreshTimer;  // Timer to refresh backlight periodically (screen wake)

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
        _sphereMin = 65.0;
        _sphereMax = 160.0;
        _progressRadius = 219.5;  // Touches screen edge (227 - 7.5)
        _progressThickness = 15.0;

        _currentRadius = _sphereMin;
        _progressValue = 0.0;
        _introElapsed = 0.0;
        _outroElapsed = 0.0;
        _guideElapsed = GUIDE_DURATION;
        _idleElapsed = 0.0;
        _phaseChangeFadeIn = 1.0;  // Start fully visible
        _sessionFadeIn = 0.0;      // Start invisible
        _backlightRefreshTimer = 0.0;  // Initialize backlight refresh timer

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
        // PROGRESS RING SCALING - TOUCHING SCREEN EDGE
        // ---------------------------------------------------------------------
        // Progress ring should touch the screen edge for maximum visual impact
        // Radius = half of screen width, minus half thickness to account for stroke
        //
        _progressThickness = 15.0;         // 15px stroke
        _progressRadius = (minDim / 2.0) - (_progressThickness / 2.0);  // 227 - 7.5 = 219.5px on Venu 3

        // ---------------------------------------------------------------------
        // BREATHING SPHERE SCALING - OPTIMIZED FOR VENU 3
        // ---------------------------------------------------------------------
        // Larger sphere for better visibility and impact
        // Venu 3 (454px):
        //   Max: 160px radius (35.2% of screen width)
        //   Min: 65px radius (14.3% of screen width)
        //   Ratio: 65/160 = 0.406 (40.6% of max)
        //
        _sphereMax = minDim * 0.352;   // 160px on Venu 3
        _sphereMin = _sphereMax * 0.406;        // 65px on Venu 3
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

    // Prevent screen sleep during active session (CRITICAL for screen wake)
    // Called when watch attempts to enter low-power sleep mode
    function onEnterSleep() {
        // Block sleep during active breathing session and intro
        if (_state == AppState.STATE_RUNNING || _state == AppState.STATE_INTRO_PULSE) {
            WatchUi.requestUpdate();  // Keep display active
            return false;  // Prevent sleep mode
        }
        // Allow sleep when idle, paused, or complete
        return true;
    }

    // Called when exiting sleep mode - refresh display
    function onExitSleep() {
        WatchUi.requestUpdate();
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
        // UI-review.md: Idle screen shows circle matching sphere diameter with play icon
        // Set radius to match sphere max size for proper visual consistency
        _currentRadius = _sphereMax + (_sphereMax * 0.08 * eased);  // Subtle pulse
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

        // Intro Timeline (~10s):
        // 0.0-0.8s: Play button fadeout
        // 0.8-5.4s: "Get Ready" with gentle pulse (first half - 4.6s)
        // 5.4-10.0s: "Relax now" with gentle pulse (second half - 4.6s)

        if (_introElapsed < 0.8) {
            // Phase 1: Play button fadeout
            _introMessage = "";
            _currentRadius = _sphereMin;
        } else if (_introElapsed < 5.4) {
            // Phase 2a: "Get Ready" with gentle pulse (first half - 4.6s)
            _introMessage = WatchUi.loadResource(Rez.Strings.IntroGetReady);
            var pulseTime = _introElapsed - 0.8;  // 0.8 to 5.4 = 4.6s
            // Create simple sinusoidal pulse for one cycle
            var cycles = (pulseTime / 4.6) * 1.0;  // 0-1 range for one cycle
            var angle = cycles * Math.PI;  // 0-π
            var wave = (Math.sin(angle) + 1.0) / 2.0;  // 0-1 range, normalized sine
            var eased = EasingFunctions.easeInOutQuad(wave);
            _currentRadius = _sphereMin + ((_sphereMax * 0.55) * eased);  // Gentle pulse to 55% max
        } else {
            // Phase 2b: "Relax now" with gentle pulse (second half - 4.6s)
            _introMessage = WatchUi.loadResource(Rez.Strings.IntroRelaxNow);
            var pulseTime = _introElapsed - 5.4;  // 5.4 to 10.0 = 4.6s
            // Create simple sinusoidal pulse for one cycle
            var cycles = (pulseTime / 4.6) * 1.0;  // 0-1 range for one cycle
            var angle = cycles * Math.PI;  // 0-π
            var wave = (Math.sin(angle) + 1.0) / 2.0;  // 0-1 range, normalized sine
            var eased = EasingFunctions.easeInOutQuad(wave);
            _currentRadius = _sphereMin + ((_sphereMax * 0.55) * eased);  // Gentle pulse to 55% max
        }

        _pillText = "";  // No pill during intro
        _phaseText = "";  // No phase watermark during intro
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

        // Fade in entire breathing screen over 1.0 second
        if (_sessionFadeIn < 1.0) {
            _sessionFadeIn += dt / 1.0;
            if (_sessionFadeIn > 1.0) {
                _sessionFadeIn = 1.0;
            }
        }

        // Fade in phase watermark over 0.6 seconds
        if (_phaseChangeFadeIn < 1.0) {
            _phaseChangeFadeIn += dt / 0.6;
            if (_phaseChangeFadeIn > 1.0) {
                _phaseChangeFadeIn = 1.0;
            }
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
        // Calculate elapsed from remaining: elapsed = duration - remaining
        var phaseElapsed = state["phaseDuration"] - state["phaseRemaining"];
        _countdownText = _formatCountdownUp(phaseElapsed, state["phaseDuration"]);
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
        _phaseChangeFadeIn = 0.0;  // Reset fade-in on phase change
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
        _sessionFadeIn = 0.0;  // Start fade-in animation
        _backlightRefreshTimer = 0.0;  // Reset timer for first immediate refresh
        _pillText = WatchUi.loadResource(Rez.Strings.PillInhale);

        // Initial backlight on (subsequent refreshes handled in _updateRunning every 3s)
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
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

        // Release screen wake lock
        if (Attention has :backlight) {
            Attention.backlight(false);
        }
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

        // Release screen wake lock
        if (Attention has :backlight) {
            Attention.backlight(false);
        }
    }

    // ---------------------------------------------------------------------
    // Helper Functions

    // Interpolate between two colors based on progress (0.0-1.0)
    private function _interpolateColor(colorFrom, colorTo, progress) {
        var rFrom = (colorFrom >> 16) & 0xFF;
        var gFrom = (colorFrom >> 8) & 0xFF;
        var bFrom = colorFrom & 0xFF;

        var rTo = (colorTo >> 16) & 0xFF;
        var gTo = (colorTo >> 8) & 0xFF;
        var bTo = colorTo & 0xFF;

        var r = (rFrom + ((rTo - rFrom) * progress)).toNumber();
        var g = (gFrom + ((gTo - gFrom) * progress)).toNumber();
        var b = (bFrom + ((bTo - bFrom) * progress)).toNumber();

        return (r << 16) | (g << 8) | b;
    }

    // ---------------------------------------------------------------------
    // Rendering

    private function _render(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, COLOR_BACKGROUND);
        dc.clear();

        // Skip all graphical objects during INTRO and IDLE - show only custom UI
        if (_state != AppState.STATE_INTRO_PULSE && _state != AppState.STATE_IDLE) {
            // Apply session fade-in effect to all elements
            var fadeProg = EasingFunctions.easeOutCubic(_sessionFadeIn);

            // Fade background
            var bgAccentFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_BACKGROUND_ACCENT, fadeProg);
            Effects.drawBackground(dc, _centerX, _centerY, _progressRadius, bgAccentFaded, COLOR_BACKGROUND);

            // Fade progress ring
            var ringTrackFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_RING_TRACK, fadeProg);
            var ringFillFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_RING_FILL, fadeProg);
            Effects.drawProgressRing(dc, _centerX, _centerY, _progressRadius, _progressThickness, _progressValue, ringTrackFaded, ringFillFaded);

            // Breath guide pulse (UI-review.md requirement #6)
            if (_state == AppState.STATE_RUNNING && _guideElapsed < GUIDE_DURATION) {
                var guideRatio = _guideElapsed / GUIDE_DURATION;
                // Invert ratio for EXHALE phase so pulse contracts instead of expands
                if (_sessionState != null && _sessionState["phase"] == BreathingPhase.PHASE_EXHALE) {
                    guideRatio = 1.0 - guideRatio;
                }
                var guideFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_GUIDE, fadeProg);
                Effects.drawGuide(dc, _centerX, _centerY, _currentRadius, guideRatio, guideFaded);
            }

            // Fade sphere
            var sphereCoreFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_SPHERE_CORE, fadeProg);
            var sphereRimFaded = _interpolateColor(COLOR_BACKGROUND, COLOR_SPHERE_RIM, fadeProg);
            Effects.drawSphere(dc, _centerX, _centerY, _currentRadius, sphereCoreFaded, sphereRimFaded);
        }

        // CLEAN MINIMAL UI - HTML prototype has NO header clutter
        if (_state == AppState.STATE_IDLE) {
            // Idle: Premium start screen
            _drawIdleScreen(dc);
        } else if (_state == AppState.STATE_INTRO_PULSE) {
            // Intro: Show intro message ONLY
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
            // MINIMAL HUD - Swapped pill positions for better UX
            // TOP: Phase countdown (0-8) - important real-time info
            // BOTTOM: Phase pattern (4-7-8) - contextual reference
            // Apply fade-in to text elements
            var fadeProg = EasingFunctions.easeOutCubic(_sessionFadeIn);
            _drawPhaseCountdownPill(dc, fadeProg);     // TOP: Phase countdown (0-8) - was bottom
            _drawPhasePatternPill(dc, fadeProg);       // BOTTOM: Phase pattern (4-7-8) - was top
            _drawPhaseWatermark(dc, fadeProg);         // Watermark ON TOP of all other layers
        } else if (_state == AppState.STATE_COMPLETE) {
            // Complete: Simplified outro
            _drawOutro(dc);
        }
    }

    private function _drawIdleScreen(dc) {
        // Full-screen start image (454×454) - no text needed
        // Image contains all branding: title, logo, and "click to start"
        // Clicking anywhere on screen will start the breathing session

        var startScreen = WatchUi.loadResource(Rez.Drawables.StartScreen);
        if (startScreen != null) {
            // Draw full-screen image at 0,0 - perfect fit for 454×454 display
            dc.drawBitmap(0, 0, startScreen);
        }
    }

    private function _drawPill(dc, text) {
        // UI-review.md: Reposition pill to y = height * 0.05 (just under title)
        // HTML prototype: centered at 18px from top with pill
        var pillWidth = _width * 0.35;  // Smaller, more compact
        if (pillWidth < 100.0) { pillWidth = 100.0; }
        var pillHeight = _height * 0.05;  // Compact height
        if (pillHeight < 24.0) { pillHeight = 24.0; }
        var pillX = _centerX - (pillWidth / 2.0);
        var pillY = _height * 0.05;  // UI-review.md: 5% from top
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
            "SleepBetter",
            Gfx.TEXT_JUSTIFY_CENTER
        );
    }

    private function _drawPhaseWatermark(dc, sessionFade) {
        // Only show during active session
        if (_state != AppState.STATE_RUNNING && _state != AppState.STATE_PAUSED) {
            return;
        }

        // Smooth fade-in effect by interpolating from background color to pure red
        // Background is 0x1B0708, target is 0xFF0000 (pure red)
        var fadeProgress = EasingFunctions.easeOutCubic(_phaseChangeFadeIn);
        var phaseFadedColor = _interpolateColor(COLOR_BACKGROUND, 0xFF0000, fadeProgress);

        // Apply session fade-in on top of phase fade-in
        var finalColor = _interpolateColor(COLOR_BACKGROUND, phaseFadedColor, sessionFade);

        dc.setColor(finalColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            _centerY.toNumber(),
            FONT_SIZE_PHASE_WATERMARK,
            _phaseText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _drawPhaseCountdownPill(dc, sessionFade) {
        // Phase countdown pill at TOP (0-8 seconds)
        // Shows real-time breathing phase progress - most important info
        // Black background, red border, red text for visual cohesion
        // Drop shadow (3px offset) adds subtle depth and visual separation
        var offset = _sphereMax * 1.0;
        var countdownY = _centerY - offset;  // TOP position (was + offset for bottom)

        // Circular pill dimensions (perfectly round)
        var pillRadius = 28.0;  // Slightly larger for better visibility
        var pillBorderWidth = 2;

        // Drop shadow - subtle offset below the pill for depth
        var shadowOffset = 3;
        var shadowColor = _interpolateColor(COLOR_BACKGROUND, 0x000000, sessionFade * 0.3);  // 30% opacity shadow
        dc.setColor(shadowColor, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX.toNumber(), (countdownY + shadowOffset).toNumber(), pillRadius.toNumber());

        // Black background circle - matches session timer pill
        var pillBgColor = _interpolateColor(COLOR_BACKGROUND, 0x000000, sessionFade);  // Pure black
        dc.setColor(pillBgColor, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX.toNumber(), countdownY.toNumber(), pillRadius.toNumber());

        // Red border ring - matches session timer pill
        var pillBorderColor = _interpolateColor(COLOR_BACKGROUND, 0xFF0000, sessionFade);  // Pure red border
        dc.setColor(pillBorderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(pillBorderWidth);
        dc.drawCircle(_centerX.toNumber(), countdownY.toNumber(), pillRadius.toNumber());

        // Red text - matches session timer pill
        var textColor = _interpolateColor(COLOR_BACKGROUND, 0xFF0000, sessionFade);  // Pure red text
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            countdownY.toNumber(),
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

    private function _drawPhasePatternPill(dc, sessionFade) {
        // Phase pattern pill at BOTTOM (4-7-8)
        // Shows current breathing pattern - contextual reference
        // Horizontal pill with black background and red border
        var offset = _sphereMax * 1.0;
        var patternY = _centerY + offset;  // BOTTOM position

        // Get pattern text from session state
        var patternText = _blockText;  // "4-7-8" format
        if (patternText == null || patternText.length() == 0) {
            patternText = "---";  // Fallback
        }

        // Pattern pill dimensions - reduced 20% with FONT_TINY
        var pillHeight = 44.8;  // 56px × 0.8 = 44.8px (20% reduction)
        var pillWidth = 123.2;  // 154px × 0.8 = 123.2px (20% reduction)
        var pillX = _centerX - (pillWidth / 2.0);
        var pillY = patternY - (pillHeight / 2.0);
        var radius = pillHeight / 2.0;

        // Drop shadow - subtle offset below the pill for depth
        var shadowOffset = 3;
        var shadowColor = _interpolateColor(COLOR_BACKGROUND, 0x000000, sessionFade * 0.3);  // 30% opacity
        dc.setColor(shadowColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX.toNumber(), (pillY + shadowOffset).toNumber(), pillWidth.toNumber(), pillHeight.toNumber(), radius.toNumber());

        // Black background pill
        var pillBgColor = _interpolateColor(COLOR_BACKGROUND, 0x000000, sessionFade);
        dc.setColor(pillBgColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX.toNumber(), pillY.toNumber(), pillWidth.toNumber(), pillHeight.toNumber(), radius.toNumber());

        // Red border ring
        var pillBorderColor = _interpolateColor(COLOR_BACKGROUND, 0xFF0000, sessionFade);
        dc.setColor(pillBorderColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(pillX.toNumber(), pillY.toNumber(), pillWidth.toNumber(), pillHeight.toNumber(), radius.toNumber());

        // Pattern text in pure red
        var textColor = _interpolateColor(COLOR_BACKGROUND, 0xFF0000, sessionFade);
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX.toNumber(),
            patternY.toNumber(),
            FONT_SIZE_TIMER,  // Same font size as countdown for consistency
            patternText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
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

    private function _formatCountdownUp(elapsed, duration) {
        // Count UP from 0 to target (e.g., 0→4, 0→7, 0→8)
        // Uses formula: T(sec)/(T(sec)+1) to ensure final number displays
        // For 8s duration: shows 0,1,2,3,4,5,6,7,8 (9 values across 8 seconds)
        if (elapsed == null || elapsed < 0.0) { elapsed = 0.0; }
        if (duration == null || duration <= 0.0) { duration = 1.0; }

        // Scale elapsed time to show final target number
        // Formula: elapsed * (duration + 1) / duration
        var scaledElapsed = elapsed * (duration + 1.0) / duration;
        var value = Math.floor(scaledElapsed).toNumber();
        var maxValue = Math.floor(duration).toNumber();

        // Cap at target to avoid showing values beyond duration
        if (value > maxValue) { value = maxValue; }
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

    private function _formatSessionCountdown(elapsed, totalDuration) {
        // Countdown from total duration to 0:00 (e.g., 10:00 → 0:00)
        var remaining = totalDuration - elapsed;
        if (remaining < 0.0) { remaining = 0.0; }
        var totalSeconds = Math.floor(remaining).toNumber();
        var minutes = Math.floor(totalSeconds / 60).toNumber();
        var seconds = (totalSeconds - (minutes * 60)).toNumber();
        var secondsStr = seconds.toString();
        if (seconds < 10) {
            secondsStr = "0" + secondsStr;
        }
        return minutes.toString() + ":" + secondsStr;
    }
}


