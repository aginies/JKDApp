import Toybox.WatchUi;
import Toybox.Graphics;

class JKDWarmupItem extends WatchUi.CustomMenuItem {
    private var _label;

    function initialize(id, label) {
        CustomMenuItem.initialize(id, {});
        _label = label;
    }

    function drawFitnessIcon(dc, x, y, size) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        
        // Draw a simple dumbbell icon
        var r = size / 4;
        dc.drawLine(x - size/2, y, x + size/2, y); // Bar
        dc.fillRectangle(x - size/2, y - r, 4, size/2); // Left plate
        dc.fillRectangle(x + size/2 - 4, y - r, 4, size/2); // Right plate
        
        dc.setPenWidth(1);
    }

    function draw(dc) {
        var screenWidth = dc.getWidth();
        var centerY = dc.getHeight() / 2;
        
        if (isFocused()) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, screenWidth, dc.getHeight());
        }

        // Draw Icon
        drawFitnessIcon(dc, 25, centerY, 16);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(45, centerY, Graphics.FONT_SMALL, _label, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, centerY, Graphics.FONT_XTINY, "Warmup", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
