import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

class JKDSeriesItem extends WatchUi.CustomMenuItem {
    private var _title;
    private var _count;
    private var _scrollX = 0;
    private var _scrollDir = -1;
    private var _lastTick = 0;

    function initialize(id, title, count) {
        CustomMenuItem.initialize(id, {});
        _title = title;
        _count = count;
    }

    function drawIcon(dc, x, y, type) {
        dc.setPenWidth(2);
        if (type.equals("punch")) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x - 8, y - 6, 16, 12, 3);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(x - 8, y - 6, 16, 12);
        } else if (type.equals("kick")) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x - 4, y - 8, x - 4, y + 4);
            dc.drawLine(x - 4, y + 4, x + 6, y + 8);
        } else {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(x, y, 8);
            dc.drawLine(x - 5, y, x + 5, y);
            dc.drawLine(x, y - 5, x, y + 5);
        }
        dc.setPenWidth(1);
    }

    function draw(dc) {
        var screenWidth = dc.getWidth();
        var centerY = dc.getHeight() / 2;
        var font = Graphics.FONT_SMALL;
        var countFont = Graphics.FONT_XTINY;
        
        var countStr = _count + " moves";
        var countWidth = dc.getTextWidthInPixels(countStr, countFont);
        var titleWidth = dc.getTextWidthInPixels(_title, font);
        
        if (isFocused()) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, screenWidth, dc.getHeight());
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 15, centerY, countFont, countStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        var titleX = 20;
        var availableWidth = screenWidth - countWidth - titleX - 15; 
        
        dc.setClip(titleX, 0, availableWidth, dc.getHeight());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        if (titleWidth > availableWidth && isFocused()) {
            var now = System.getTimer();
            if (now - _lastTick > 30) { // Faster refresh (30ms)
                _scrollX += (_scrollDir * 4); // 4px per frame (much faster)
                var maxOffset = titleWidth - availableWidth + 10;
                if (_scrollX < -maxOffset) { _scrollDir = 1; }
                else if (_scrollX > 0) { _scrollDir = -1; }
                _lastTick = now;
            }
            dc.drawText(titleX + _scrollX, centerY, font, _title, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            _scrollX = 0;
            dc.drawText(titleX, centerY, font, _title, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.clearClip();
    }
}

class JKDAppMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        if (id instanceof $.Toybox.Lang.Number) {
            var seriesList = JKDSeries.getSeries();
            var selectedSeries = seriesList[id];
            var view = new JKDStandaloneView(selectedSeries);
            var delegate = new JKDStandaloneDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (id == :item_settings) {
            WatchUi.pushView(new JKDSettingsMenu(), new JKDSettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class JKDStandaloneDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    function onSelect() {
        _view.toggleDetail();
        return true;
    }
    function onNextPage() {
        if (_view.isShowingDetail()) {
            JKDSettings.mirrorMode = false;
            JKDSettings.saveSettings();
            WatchUi.requestUpdate();
        } else {
            _view.nextCombo();
        }
        return true;
    }
    function onPreviousPage() {
        if (_view.isShowingDetail()) {
            JKDSettings.mirrorMode = true;
            JKDSettings.saveSettings();
            WatchUi.requestUpdate();
        } else {
            _view.prevCombo();
        }
        return true;
    }
    function onKey(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_DOWN) {
            if (_view.isShowingDetail()) {
                JKDSettings.mirrorMode = false;
                JKDSettings.saveSettings();
                WatchUi.requestUpdate();
            } else {
                _view.nextCombo();
            }
            return true;
        } else if (key == WatchUi.KEY_UP) {
            if (_view.isShowingDetail()) {
                JKDSettings.mirrorMode = true;
                JKDSettings.saveSettings();
                WatchUi.requestUpdate();
            } else {
                _view.prevCombo();
            }
            return true;
        }
        return false;
    }
    function onBack() { return false; }
}
