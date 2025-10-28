// Effects.mc
// Utility drawing helpers for SleepBetter visual effects.

using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Math;

module Effects {

    function drawBackground(dc, cx, cy, radius, accentColor, backgroundColor) {
        // UI-review.md: Draw at least two large, low-alpha circles in crimson tones
        // to approximate the HTML prototype's layered radial gradients
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        // Large gradient-like circles for depth (70% and 50% of screen)
        var x = cx.toNumber();
        var y = cy.toNumber();

        // Outer circle (70% of screen, very subtle)
        dc.setColor(0x2A0808, Gfx.COLOR_TRANSPARENT);  // Very dark crimson with low alpha feel
        dc.fillCircle(x, y, (radius * 0.70).toNumber());

        // Inner circle (50% of screen, slightly brighter)
        dc.setColor(0x3A0C0C, Gfx.COLOR_TRANSPARENT);  // Crimson-900 from HTML
        dc.fillCircle(x, y, (radius * 0.50).toNumber());
    }

    function drawProgressRing(dc, cx, cy, radius, thickness, progress, trackColor, fillColor) {
        // UI-review.md: HTML prototype keeps track visible but hides the progress arc
        // We draw only the dark track ring, skip the bright arc to match prototype
        var clamped = progress;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }

        var x = cx.toNumber();
        var y = cy.toNumber();
        var r = radius.toNumber();
        var t = thickness.toNumber();

        // Background track only (matches HTML prototype track-only appearance)
        dc.setPenWidth(t);
        dc.setColor(trackColor, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);

        // SKIP progress arc drawing - UI-review.md specifies hiding the arc
        // Progress value is still tracked internally for stats/timing
        // but not rendered visually to match HTML prototype aesthetic
    }

    function drawSphere(dc, cx, cy, radius, coreColor, rimColor) {
        // Simplified dual-tone sphere (core + rim) to avoid flat disk look
        var x = cx.toNumber();
        var y = cy.toNumber();
        var r = radius.toNumber();

        // Safety check for valid radius
        if (r < 1) { r = 1; }

        // 1. Draw dark core circle (90% of radius)
        var coreRadius = (r * 0.90).toNumber();
        if (coreRadius < 1) { coreRadius = 1; }
        dc.setColor(coreColor, coreColor);
        dc.fillCircle(x, y, coreRadius);

        // 2. Draw rim (outer circle) for depth
        var rimWidth = (r * 0.12).toNumber();
        if (rimWidth < 1) { rimWidth = 1; }
        if (rimWidth > 20) { rimWidth = 20; }
        dc.setColor(rimColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(rimWidth);
        dc.drawCircle(x, y, r);

    }

    function drawGuide(dc, cx, cy, baseRadius, ratio, color) {
        var clamped = ratio;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }

        var outer = baseRadius + (baseRadius * 0.6 * clamped);
        var pen = (baseRadius * 0.25 * (1.0 - clamped));
        if (pen < 3.0) { pen = 3.0; }

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(pen.toNumber());
        dc.drawCircle(cx.toNumber(), cy.toNumber(), outer.toNumber());
    }

    function drawPlayHint(dc, cx, cy, radius, color) {
        var size = radius * 0.5;
        var left = cx - (size * 0.6);
        var top = cy - (size * 0.6);
        var bottom = cy + (size * 0.6);

        var points = [
            [left.toNumber(), top.toNumber()],
            [(left + size).toNumber(), cy.toNumber()],
            [left.toNumber(), bottom.toNumber()]
        ];

        dc.setColor(color, color);
        dc.fillPolygon(points);
    }

    function drawOutro(dc, cx, cy, width, height, ratio, headline, message, overlayColor, textColor) {
        var clamped = ratio;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }
        var boxWidth = (width.toFloat() * 0.78);
        var boxHeight = (height.toFloat() * 0.32);
        var corner = 18.0;

        var left = cx - (boxWidth / 2.0);
        var top = cy - (boxHeight / 2.0);

        dc.setColor(overlayColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(left.toNumber(), top.toNumber(), boxWidth.toNumber(), boxHeight.toNumber(), corner.toNumber());

        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            cx.toNumber(),
            (top + boxHeight * 0.35).toNumber(),
            Gfx.FONT_LARGE,
            headline,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        dc.drawText(
            cx.toNumber(),
            (top + boxHeight * 0.65).toNumber(),
            Gfx.FONT_MEDIUM,
            message,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }
}
