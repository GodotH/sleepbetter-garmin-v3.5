// Effects.mc
// Utility drawing helpers for SleepBetter visual effects.

using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Math;

module Effects {

    function drawBackground(dc, cx, cy, radius, accentColor, backgroundColor) {
        // HTML prototype uses solid deep black-crimson background
        // Very subtle radial gradients (10% opacity) - too subtle for MonkeyC to simulate well
        // Using solid background for clean, dark look
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        // No accent circles - keep it simple and dark like HTML prototype
    }

    function drawProgressRing(dc, cx, cy, radius, thickness, progress, trackColor, fillColor) {
        var clamped = progress;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }

        var x = cx.toNumber();
        var y = cy.toNumber();
        var r = radius.toNumber();
        var t = thickness.toNumber();

        // Background track
        dc.setPenWidth(t);
        dc.setColor(trackColor, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);

        if (clamped <= 0.0) {
            return;
        }

        var sweep = 360.0 * clamped;
        var endAngle = (90 - sweep).toNumber();

        // Glow layer (slightly larger, dimmer) for depth
        dc.setColor(0x7E1717, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(t + 4);
        dc.drawArc(x, y, r + 2, Gfx.ARC_CLOCKWISE, 90, endAngle);

        // Main progress arc (pure red)
        dc.setColor(fillColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(t);
        dc.drawArc(x, y, r, Gfx.ARC_CLOCKWISE, 90, endAngle);
    }

    function drawSphere(dc, cx, cy, radius, coreColor, rimColor, highlightColor) {
        var x = cx.toNumber();
        var y = cy.toNumber();
        var r = radius.toNumber();

        // Layer 1: Shadow ring (darker, slightly larger) for depth
        dc.setColor(0x2A0909, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawCircle(x, y, r + 4);

        // Layer 2: Core sphere (filled)
        dc.setColor(coreColor, coreColor);
        dc.fillCircle(x, y, r);

        // Layer 3: Rim gradient (simulate with concentric circles)
        dc.setColor(rimColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(x, y, r);
        dc.setPenWidth(1);
        dc.drawCircle(x, y, r - 1);

        // Layer 4: Highlight (top-left quadrant) for 3D effect
        var highlightRadius = (radius * 0.4).toNumber();
        var highlightX = (cx - radius * 0.3).toNumber();
        var highlightY = (cy - radius * 0.3).toNumber();

        dc.setColor(highlightColor, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(highlightX, highlightY, highlightRadius);
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
