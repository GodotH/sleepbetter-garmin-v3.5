// SleepBetterApp.mc
// Main application entry point for SleepBetter breathing app

// CRITICAL: Use correct import pattern (no aliases for Application)
using Toybox.Application;
using Toybox.WatchUi;

// Application class - extends Application.AppBase (NOT App.AppBase)
class SleepBetterApp extends Application.AppBase {

    // Constructor
    function initialize() {
        AppBase.initialize();
    }

    // App lifecycle - called when app starts
    function onStart(state) {
        // No initialization needed yet
    }

    // App lifecycle - called when app stops
    function onStop(state) {
        // Cleanup will be handled in view
    }

    // Return initial view and input delegate
    function getInitialView() {
        var view = new SleepBetterView();
        var delegate = new SleepBetterInputDelegate(view);
        return [view, delegate];
    }
}

// Input delegate to handle tap events
class SleepBetterInputDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Handle screen taps
    function onTap(clickEvent) {
        return _view.onTap(clickEvent.getType());
    }
}
