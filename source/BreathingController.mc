// ============================================================================
// BreathingController.mc
// 4-7-8 Breathing App - Session State Machine
// ============================================================================
// VERSION: v.02.5
// TIMESTAMP: 25-1026-00:00
// DEVICE: Garmin Venu 3 (454×454px)
// ============================================================================
//
// DESCRIPTION:
//   Orchestrates breathing session phases, timing, and state transitions.
//   Manages session plan execution with configurable breathing patterns.
//
// CURRENT SESSION PLAN (v.03):
//   - Block 1: 0.65 min / 39s (4-4-5 pattern, 3 cycles)
//   - Block 2: 1.75 min / 105s (4-5-6 pattern, 7 cycles)
//   - Block 3: 7.60 min / 456s (4-7-8 pattern, 24 cycles)
//   - Total: 10.00 minutes / 600 seconds exactly
//
// TIMING BREAKDOWN:
//   - 4-4-5: 13s/cycle × 3 = 39s (exactly 0.65 min)
//   - 4-5-6: 15s/cycle × 7 = 105s (exactly 1.75 min)
//   - 4-7-8: 19s/cycle × 24 = 456s (exactly 7.60 min)
//
// ============================================================================

using Toybox.Lang;
using Toybox.Math;
using Toybox.System;

module BreathingPhase {
    enum {
        PHASE_PREPARE,
        PHASE_INHALE,
        PHASE_HOLD,
        PHASE_EXHALE,
        PHASE_COMPLETE
    }
}

class BreathingController {
    private var _plan;
    private var _blocks;

    private var _blockIndex;
    private var _cycleIndex;
    private var _phaseIndex;

    private var _phase;
    private var _phaseDuration;
    private var _phaseElapsed;

    private var _sessionElapsed;
    private var _sessionDuration;

    private var _running;
    private var _paused;
    private var _hasStarted;

    function initialize() {
        _plan = getDefaultPlan();
        _rebuildPlan();
    }

    function reset() {
        _running = false;
        _paused = false;
        _hasStarted = false;

        _blockIndex = 0;
        _cycleIndex = 0;
        _phaseIndex = 0;

        _phase = BreathingPhase.PHASE_PREPARE;
        _phaseDuration = 0.01;
        _phaseElapsed = 0.0;

        _sessionElapsed = 0.0;
    }

    function setPlan(plan) {
        if (plan == null || plan.size() == 0) {
            System.println("BreathingController: empty plan provided, falling back to default.");
            _plan = getDefaultPlan();
        } else {
            _plan = plan;
        }
        _rebuildPlan();
    }

    function getPlan() { return _plan; }

    function start() {
        if (_blocks == null || _blocks.size() == 0) {
            _rebuildPlan();
        }

        _hasStarted = true;
        _running = true;
        _paused = false;

        _blockIndex = 0;
        _cycleIndex = 0;
        _phaseIndex = 0;

        _phase = BreathingPhase.PHASE_INHALE;
        _phaseDuration = _durationForPhase(_phase);
        _phaseElapsed = 0.0;
        _sessionElapsed = 0.0;
    }

    function pause() { if (_running) { _paused = true; } }
    function resume() { if (_running && _paused) { _paused = false; } }
    function stop() { _running = false; _paused = false; }

    function isRunning() { return _running && !_paused && _phase != BreathingPhase.PHASE_COMPLETE; }
    function isPaused() { return _paused; }
    function hasStarted() { return _hasStarted; }
    function isComplete() { return _phase == BreathingPhase.PHASE_COMPLETE; }

    function getSessionDuration() { return _sessionDuration; }
    function getSessionElapsed() { return _sessionElapsed; }
    function getPhase() { return _phase; }
    function getPhaseDuration() { return _phaseDuration; }
    function getPhaseElapsed() { return _phaseElapsed; }

    function getPhaseProgress() {
        if (_phaseDuration <= 0.0) { return 1.0; }
        var progress = _phaseElapsed / _phaseDuration;
        if (progress < 0.0) { progress = 0.0; }
        if (progress > 1.0) { progress = 1.0; }
        return progress;
    }

    function getPhaseRemaining() {
        var remaining = _phaseDuration - _phaseElapsed;
        if (remaining < 0.0) { remaining = 0.0; }
        return remaining;
    }

    function getSessionProgress() {
        if (_sessionDuration <= 0.0) {
            System.println("ERROR: _sessionDuration is 0!");
            return 0.0;
        }
        var progress = _sessionElapsed / _sessionDuration;
        if (progress < 0.0) { progress = 0.0; }
        if (progress > 1.0) { progress = 1.0; }

        // Log every 10 seconds for debugging
        var elapsedInt = _sessionElapsed.toNumber();
        if (elapsedInt > 0 && elapsedInt % 10 == 0) {
            System.println("Progress: " + elapsedInt + "/" + _sessionDuration.toNumber() + "s = " + (progress * 100).toNumber() + "%");
        }
        return progress;
    }

    function getCurrentPattern() {
        var block = _currentBlock();
        if (block != null && block.hasKey("pattern")) {
            return block["pattern"];
        }
        return null;
    }

    function getCurrentBlockLabel() {
        var block = _currentBlock();
        if (block != null && block.hasKey("label")) {
            return block["label"];
        }
        return "";
    }

    function advance(dt) {
        if (!_running || _paused || dt <= 0.0) {
            return _buildState(false, false, false);
        }

        _phaseElapsed += dt;
        _sessionElapsed += dt;
        if (_sessionElapsed > _sessionDuration) {
            _sessionElapsed = _sessionDuration;
        }

        var phaseChanged = false;
        var blockChanged = false;
        var cycleChanged = false;

        while (_phase != BreathingPhase.PHASE_COMPLETE && _phaseElapsed >= _phaseDuration) {
            _phaseElapsed -= _phaseDuration;
            if (_phaseElapsed < 0.0) { _phaseElapsed = 0.0; }

            var change = _advancePhase();
            if (change["phaseChanged"]) { phaseChanged = true; }
            if (change["blockChanged"]) { blockChanged = true; }
            if (change["cycleChanged"]) { cycleChanged = true; }

            if (_phase == BreathingPhase.PHASE_COMPLETE) {
                break;
            }
        }

        return _buildState(phaseChanged, blockChanged, cycleChanged);
    }

    // ----- Internal helpers -------------------------------------------------

    private function _buildState(phaseChanged, blockChanged, cycleChanged) {
        var state = {
            "phase" => _phase,
            "phaseProgress" => getPhaseProgress(),
            "phaseRemaining" => getPhaseRemaining(),
            "phaseDuration" => _phaseDuration,
            "sessionElapsed" => _sessionElapsed,
            "sessionDuration" => _sessionDuration,
            "sessionProgress" => getSessionProgress(),
            "blockIndex" => _blockIndex,
            "cycleIndex" => _cycleIndex,
            "phaseChanged" => phaseChanged,
            "blockChanged" => blockChanged,
            "cycleChanged" => cycleChanged,
            "isComplete" => (_phase == BreathingPhase.PHASE_COMPLETE)
        };

        var block = _currentBlock();
        if (block != null) {
            state["blockLabel"] = block.hasKey("label") ? block["label"] : "";
            state["blockDuration"] = block.hasKey("blockDuration") ? block["blockDuration"] : 0.0;
            state["cyclesInBlock"] = block.hasKey("cycles") ? block["cycles"] : 0;
            if (block.hasKey("pattern")) {
                var pattern = block["pattern"];
                state["pattern"] = pattern;
                state["inhale"] = pattern["inhale"];
                state["hold"] = pattern["hold"];
                state["exhale"] = pattern["exhale"];
            }
        }

        return state;
    }

    private function _advancePhase() {
        var change = {
            "phaseChanged" => false,
            "blockChanged" => false,
            "cycleChanged" => false
        };

        _phaseIndex += 1;
        if (_phaseIndex > 2) {
            _phaseIndex = 0;
            _cycleIndex += 1;
            change["cycleChanged"] = true;

            var block = _currentBlock();
            var cycles = (block != null && block.hasKey("cycles")) ? block["cycles"] : 1;
            if (_cycleIndex >= cycles) {
                _blockIndex += 1;
                _cycleIndex = 0;
                change["blockChanged"] = true;

                if (_blockIndex >= _blocks.size()) {
                    _setComplete();
                    change["phaseChanged"] = true;
                    return change;
                }
            }
        }

        _setPhase(_phaseForIndex(_phaseIndex));
        change["phaseChanged"] = true;
        return change;
    }

    private function _setPhase(newPhase) {
        _phase = newPhase;
        if (_phase == BreathingPhase.PHASE_COMPLETE) {
            _phaseDuration = 0.01;
            _phaseElapsed = 0.0;
            _running = false;
            _paused = false;
            return;
        }

        _phaseDuration = _durationForPhase(newPhase);
        if (_phaseDuration <= 0.0) {
            _phaseDuration = 1.0;
        }
    }

    private function _setComplete() {
        _phase = BreathingPhase.PHASE_COMPLETE;
        _phaseDuration = 0.01;
        _phaseElapsed = 0.0;
        _sessionElapsed = _sessionDuration;
        _running = false;
        _paused = false;
    }

    private function _phaseForIndex(index) {
        if (index == 0) { return BreathingPhase.PHASE_INHALE; }
        if (index == 1) { return BreathingPhase.PHASE_HOLD; }
        if (index == 2) { return BreathingPhase.PHASE_EXHALE; }
        return BreathingPhase.PHASE_PREPARE;
    }

    private function _currentBlock() {
        if (_blocks != null && _blockIndex >= 0 && _blockIndex < _blocks.size()) {
            return _blocks[_blockIndex];
        }
        return null;
    }

    private function _durationForPhase(phase) {
        var pattern = getCurrentPattern();
        if (pattern == null) { return 1.0; }

        if (phase == BreathingPhase.PHASE_INHALE) {
            return pattern["inhale"];
        } else if (phase == BreathingPhase.PHASE_HOLD) {
            return pattern["hold"];
        } else if (phase == BreathingPhase.PHASE_EXHALE) {
            return pattern["exhale"];
        }
        return 1.0;
    }

    private function _rebuildPlan() {
        _blocks = [];
        _sessionDuration = 0.0;

        if (_plan == null) {
            _plan = getDefaultPlan();
        }

        System.println("=== REBUILDING SESSION PLAN ===");
        for (var i = 0; i < _plan.size(); i += 1) {
            var block = _plan[i];
            if (block == null || !block.hasKey("pattern")) { continue; }

            var pattern = block["pattern"];
            if (pattern == null) { continue; }

            var inhale = _safeFloat(pattern, "inhale", 4.0);
            var hold = _safeFloat(pattern, "hold", 4.0);
            var exhale = _safeFloat(pattern, "exhale", 5.0);
            var cycleDuration = inhale + hold + exhale;
            if (cycleDuration <= 0.0) { cycleDuration = 1.0; }

            var minutes = _safeFloat(block, "minutes", 1.0);
            var blockSeconds = minutes * 60.0;
            if (blockSeconds <= 0.0) { blockSeconds = cycleDuration; }

            var cyclesFloat = blockSeconds / cycleDuration;
            var cycles = Math.round(cyclesFloat).toNumber();
            if (cycles < 1) { cycles = 1; }

            var blockDuration = cycleDuration * cycles;
            _sessionDuration += blockDuration;

            System.println("Block " + i + ": " + inhale + "-" + hold + "-" + exhale +
                          " | " + cycles + " cycles | " + blockDuration + "s");

            var meta = {
                "label" => block.hasKey("label") ? block["label"] : "",
                "pattern" => {
                    "inhale" => inhale,
                    "hold" => hold,
                    "exhale" => exhale
                },
                "cycles" => cycles,
                "cycleDuration" => cycleDuration,
                "blockDuration" => blockDuration
            };

            _blocks.add(meta);
        }

        System.println("TOTAL SESSION DURATION: " + _sessionDuration + " seconds (" + (_sessionDuration / 60.0) + " minutes)");
        System.println("================================");
        reset();
    }

    private function _safeFloat(src, key, fallback) {
        if (src != null && src.hasKey(key)) {
            var raw = src[key];
            if (raw != null) {
                if (raw instanceof Float) { return raw; }
                if (raw instanceof Number) { return (raw).toFloat(); }
            }
        }
        return fallback;
    }

    // Default session plan: 1.5min warmup + 1.5min transition + 7.0min main = 10 minutes exact
    function getDefaultPlan() {
        return [
            {
                "label" => "Warm-up 4-4-5",
                "minutes" => 0.65,
                "pattern" => { "inhale" => 4.0, "hold" => 4.0, "exhale" => 5.0 }
            },
            {
                "label" => "Transition 4-5-6",
                "minutes" => 1.75,
                "pattern" => { "inhale" => 4.0, "hold" => 5.0, "exhale" => 6.0 }
            },
            {
                "label" => "Main 4-7-8",
                "minutes" => 7.60,
                "pattern" => { "inhale" => 4.0, "hold" => 7.0, "exhale" => 8.0 }
            }
        ];
    }
}
