import Toybox.WatchUi;
import Toybox.Graphics;

class JKDSettingsItem extends WatchUi.CustomMenuItem {
    private var _label;
    private var _id;

    function initialize(id, label) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        _id = id;
    }

    function drawGear(dc, x, y, size) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var radius = size / 2;
        dc.setPenWidth(2);
        dc.drawCircle(x, y, radius - 2);
        dc.drawCircle(x, y, 2);
        
        // Draw 8 teeth
        for (var i = 0; i < 8; i++) {
            var angle = i * (Math.PI / 4);
            var x1 = x + (radius - 4) * Math.cos(angle);
            var y1 = y + (radius - 4) * Math.sin(angle);
            var x2 = x + radius * Math.cos(angle);
            var y2 = y + radius * Math.sin(angle);
            dc.drawLine(x1, y1, x2, y2);
        }
        dc.setPenWidth(1);
    }

    function draw(dc) {
        var screenWidth = dc.getWidth();
        var centerY = dc.getHeight() / 2;
        
        if (isFocused()) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, screenWidth, dc.getHeight());
        }

        // Draw Gear Icon
        drawGear(dc, 25, centerY, 16);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(45, centerY, Graphics.FONT_SMALL, _label, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        
        var value = "";
        if (_id == :item_settings) {
            value = ">";
        }
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, centerY, Graphics.FONT_XTINY, value, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
