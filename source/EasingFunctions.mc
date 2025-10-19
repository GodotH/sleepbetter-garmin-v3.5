// EasingFunctions.mc
// Animation easing utilities for smooth transitions

using Toybox.Lang;
using Toybox.Math;

// Module containing easing functions
module EasingFunctions {

    // Smoothstep easing (approximates cubic-bezier ease-in-out)
    // Returns smoothed value between 0.0 and 1.0
    function smoothstep(t) {
        if (t <= 0.0) { return 0.0; }
        if (t >= 1.0) { return 1.0; }
        return t * t * (3.0 - 2.0 * t);
    }

    // Ease-in-out using cosine interpolation
    function easeInOutCosine(t) {
        if (t <= 0.0) { return 0.0; }
        if (t >= 1.0) { return 1.0; }
        return (1.0 - Math.cos(t * Math.PI)) / 2.0;
    }

    // Ease-out cubic (fast start, slow end)
    function easeOutCubic(t) {
        if (t <= 0.0) { return 0.0; }
        if (t >= 1.0) { return 1.0; }
        var t1 = 1.0 - t;
        return 1.0 - (t1 * t1 * t1);
    }

    // Ease-in cubic (slow start, fast end)
    function easeInCubic(t) {
        if (t <= 0.0) { return 0.0; }
        if (t >= 1.0) { return 1.0; }
        return t * t * t;
    }
}
