// Effects.mc
// Utility drawing helpers for SleepBetter visual effects.

using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.Math;

module Effects {

    function drawBackground(dc, cx, cy, radius, accentColor, backgroundColor) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        dc.clear();

        // Soft vignette with concentric circles for depth
        dc.setColor(accentColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(radius.toNumber());
        dc.drawCircle(cx.toNumber(), cy.toNumber(), (radius * 1.2).toNumber());

        dc.setPenWidth((radius * 0.6).toNumber());
        dc.drawCircle(cx.toNumber(), cy.toNumber(), (radius * 0.8).toNumber());
    }

    function drawProgressRing(dc, cx, cy, radius, thickness, progress, trackColor, fillColor) {
        var clamped = progress;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }

        dc.setPenWidth(thickness.toNumber());
        dc.setColor(trackColor, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(cx.toNumber(), cy.toNumber(), radius.toNumber());

        if (clamped <= 0.0) {
            return;
        }

        var sweep = 360.0 * clamped;
        dc.setColor(fillColor, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(
            cx.toNumber(),
            cy.toNumber(),
            radius.toNumber(),
            Gfx.ARC_CLOCKWISE,
            90,
            (90 - sweep).toNumber()
        );
    }

    function drawSphere(dc, cx, cy, radius, coreColor, rimColor, highlightColor) {
        var r = radius.toNumber();

        dc.setColor(coreColor, coreColor);
        dc.fillCircle(cx.toNumber(), cy.toNumber(), r);

        dc.setColor(rimColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth((radius * 0.2).toNumber());
        dc.drawCircle(cx.toNumber(), cy.toNumber(), r);

        dc.setColor(highlightColor, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth((radius * 0.12).toNumber());
        dc.drawArc(
            (cx - radius * 0.3).toNumber(),
            (cy - radius * 0.3).toNumber(),
            (radius * 0.6).toNumber(),
            Gfx.ARC_CLOCKWISE,
            180,
            360
        );
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
