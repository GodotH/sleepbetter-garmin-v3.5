// ErrorHandler.mc
// Simple logging utility for SleepBetter diagnostics.

using Toybox.System;
using Toybox.Lang;

module ErrorHandler {

    function log(tag, message) {
        System.println("[SleepBetter/" + tag + "] " + message);
    }

    function logError(tag, err) {
        System.println("[SleepBetter/" + tag + "] ERROR: " + err);
    }
}
