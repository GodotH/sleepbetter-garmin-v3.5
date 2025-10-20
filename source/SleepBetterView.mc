// SleepBetterView.mc
// Renders the SleepBetter breathing session UI and handles interaction.

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
    const INTRO_DURATION = 2.0;
    const OUTRO_DURATION = 3.5;
    const GUIDE_DURATION = 0.8;
    const IDLE_PULSE_PERIOD = 6.0;
    const MAX_DELTA = 0.5;

    const COLOR_BACKGROUND = 0x120404;
    const COLOR_BACKGROUND_ACCENT = 0x2A0909;
    const COLOR_TEXT_PRIMARY = 0xFFE5E5;
    const COLOR_TEXT_MUTED = 0xC7A9A9;
    const COLOR_RING_TRACK = 0x2D0A0A;
    const COLOR_RING_FILL = 0xE43A3A;
    const COLOR_GUIDE = 0xFF6B6B;
    const COLOR_SPHERE_CORE = 0x9E1D1D;
    const COLOR_SPHERE_RIM = 0xE45454;
    const COLOR_SPHERE_HIGHLIGHT = 0xFF9999;
    const COLOR_PILL_BACKGROUND = 0x7A1515;
    const COLOR_PILL_BORDER = 0xE43A3A;
    const COLOR_OVERLAY_FILL = 0x401010;

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

        _pillText = Rez.Strings.TapInstruction;
        _phaseText = Rez.Strings.PhasePrepare;
        _countdownText = "0";
        _totalText = "0:00";
        _blockText = "";

        // XML labels removed - now using canvas rendering
    }

    function onLayout(dc) {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2.0;
        _centerY = _height / 2.0;

        var minDim = (_width < _height) ? _width : _height;
        _progressRadius = minDim * 0.42;
        _progressThickness = minDim * 0.08;
        if (_progressThickness < 10.0) { _progressThickness = 10.0; }
        _sphereMax = _progressRadius - (_progressThickness * 1.1);
        if (_sphereMax < 80.0) { _sphereMax = 80.0; }
        _sphereMin = _sphereMax * 0.55;
        if (_sphereMin < 40.0) { _sphereMin = 40.0; }
        _currentRadius = _sphereMin;

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
        _currentRadius = _sphereMin + (_sphereMin * 0.2 * eased);
        _progressValue = 0.0;

        _phaseText = Rez.Strings.PhasePrepare;
        _countdownText = "0";
        _totalText = "0:00";
        _blockText = "";
        _pillText = Rez.Strings.TapInstruction;
    }

    private function _updateIntro(dt) {
        _introElapsed += dt;
        if (_introElapsed > INTRO_DURATION) {
            _beginSession();
            return;
        }

        var ratio = _introElapsed / INTRO_DURATION;
        if (ratio < 0.0) { ratio = 0.0; }
        if (ratio > 1.0) { ratio = 1.0; }
        var eased = EasingFunctions.easeInCubic(ratio);

        _currentRadius = _sphereMin + ((_sphereMax * 0.4) * eased);
        _pillText = Rez.Strings.PillReady;
        _phaseText = Rez.Strings.PhasePrepare;
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
        _pillText = Rez.Strings.PillPaused;
    }

    private function _updateComplete(dt) {
        _outroElapsed += dt;
        if (_outroElapsed > OUTRO_DURATION) {
            _outroElapsed = OUTRO_DURATION;
        }
        var ratio = _outroElapsed / OUTRO_DURATION;
        var eased = EasingFunctions.easeOutCubic(1.0 - ratio);
        _currentRadius = _sphereMin + ((_sphereMax - _sphereMin) * 0.15 * eased);
        _pillText = Rez.Strings.PillComplete;
    }

    private function _applySessionState(state) {
        _sessionState = state;

        var phase = state["phase"];
        if (state["phaseChanged"]) {
            _handlePhaseChange(phase);
        }

        _progressValue = state["sessionProgress"];

        var phaseProgress = state["phaseProgress"];
        var eased = EasingFunctions.smoothstep(phaseProgress);

        if (phase == BreathingPhase.PHASE_INHALE) {
            _currentRadius = _sphereMin + ((_sphereMax - _sphereMin) * eased);
            _pillText = Rez.Strings.PillInhale;
        } else if (phase == BreathingPhase.PHASE_HOLD) {
            _currentRadius = _sphereMax;
            _pillText = Rez.Strings.PillHold;
        } else if (phase == BreathingPhase.PHASE_EXHALE) {
            var inverse = 1.0 - eased;
            _currentRadius = _sphereMin + ((_sphereMax - _sphereMin) * inverse);
            _pillText = Rez.Strings.PillExhale;
        } else if (phase == BreathingPhase.PHASE_PREPARE) {
            _currentRadius = _sphereMin;
            _pillText = Rez.Strings.PillReady;
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
        _pillText = Rez.Strings.PillReady;
        _phaseText = Rez.Strings.PhasePrepare;
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
        _pillText = Rez.Strings.PillInhale;
    }

    private function _enterPause() {
        _controller.pause();
        _state = AppState.STATE_PAUSED;
        _pillText = Rez.Strings.PillPaused;
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
        _pillText = Rez.Strings.PillComplete;
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
        _pillText = Rez.Strings.TapInstruction;
        _phaseText = Rez.Strings.PhasePrepare;
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

        if (_guideElapsed < GUIDE_DURATION) {
            var guideRatio = 1.0 - (_guideElapsed / GUIDE_DURATION);
            Effects.drawGuide(dc, _centerX, _centerY, _currentRadius, guideRatio, COLOR_GUIDE);
        }

        Effects.drawSphere(dc, _centerX, _centerY, _currentRadius, COLOR_SPHERE_CORE, COLOR_SPHERE_RIM, COLOR_SPHERE_HIGHLIGHT);

        if (_state == AppState.STATE_IDLE) {
            Effects.drawPlayHint(dc, _centerX, _centerY, _currentRadius, COLOR_TEXT_MUTED);
        }

        if (_state == AppState.STATE_COMPLETE) {
            var outroRatio = _outroElapsed / OUTRO_DURATION;
            Effects.drawOutro(dc, _centerX, _centerY, _width, _height, outroRatio, Rez.Strings.OutroHeadline, Rez.Strings.OutroMessage, COLOR_OVERLAY_FILL, COLOR_TEXT_PRIMARY);
        }

        _drawPill(dc, _pillText);
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

    // _updateLabels() and _setLabel() removed - using canvas rendering

    private function _phaseString(phase) {
        if (phase == BreathingPhase.PHASE_INHALE) {
            return Rez.Strings.PhaseInhale;
        } else if (phase == BreathingPhase.PHASE_HOLD) {
            return Rez.Strings.PhaseHold;
        } else if (phase == BreathingPhase.PHASE_EXHALE) {
            return Rez.Strings.PhaseExhale;
        } else if (phase == BreathingPhase.PHASE_COMPLETE) {
            return Rez.Strings.PhaseComplete;
        }
        return Rez.Strings.PhasePrepare;
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


