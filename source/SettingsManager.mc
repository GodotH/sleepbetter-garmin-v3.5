// SettingsManager.mc
// Persistent settings for SleepBetter (haptics, plan overrides, etc.)

using Toybox.Application;
using Toybox.Lang;

module SettingsManager {
    const KEY_HAPTICS = "sleepbetter_haptics";

    function isHapticsEnabled() {
        var stored = Application.Storage.getValue(KEY_HAPTICS);
        if (stored == null) {
            return true; // Default enabled
        }
        return stored;
    }

    function setHapticsEnabled(enabled) {
        Application.Storage.setValue(KEY_HAPTICS, enabled);
    }
}
