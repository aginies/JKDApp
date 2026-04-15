import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class JKDWarmupSetupView extends WatchUi.View {
    private var _durations = [5, 8, 10, 15, 20];
    private var _works     = [20, 25, 30, 35, 40];
    private var _rests     = [10, 15];

    private var _durIdx  = 2;
    private var _workIdx = 0;
    private var _restIdx = 0;

    // Item indices:
    // 0=START, 1=Duration, 2=Work, 3=Rest,
    // 4=Squats, 5=Push-ups, 6=Crunches,
    // 7=Jump.Jacks, 8=Burpees, 9=Mtn.Climb, 10=Lunges
    private var _selected = 0;
    private var _numItems = 11;
    private var _scrollOffset = 0; // index of first visible item

    function initialize() {
        View.initialize();
        for (var i = 0; i < _durations.size(); i++) {
            if (_durations[i] == JKDSettings.warmupDuration) { _durIdx = i; }
        }
        for (var i = 0; i < _works.size(); i++) {
            if (_works[i] == JKDSettings.warmupWork) { _workIdx = i; }
        }
        for (var i = 0; i < _rests.size(); i++) {
            if (_rests[i] == JKDSettings.warmupRest) { _restIdx = i; }
        }
    }

    function selectNext() {
        _selected = (_selected + 1) % _numItems;
        _scrollToSelected();
        WatchUi.requestUpdate();
    }

    function selectPrev() {
        _selected = (_selected - 1 + _numItems) % _numItems;
        _scrollToSelected();
        WatchUi.requestUpdate();
    }

    // Keep selected item inside the visible window
    function _scrollToSelected() {
        if (_selected < _scrollOffset) {
            _scrollOffset = _selected;
        } else if (_selected >= _scrollOffset + _visibleCount()) {
            _scrollOffset = _selected - _visibleCount() + 1;
        }
    }

    function _visibleCount() {
        return 5; // items visible at once
    }

    function _labelFor(idx) {
        if (idx == 0)  { return "START"; }
        if (idx == 1)  { return "Duration"; }
        if (idx == 2)  { return "Work"; }
        if (idx == 3)  { return "Rest"; }
        if (idx == 4)  { return "Squats"; }
        if (idx == 5)  { return "Push-ups"; }
        if (idx == 6)  { return "Crunches"; }
        if (idx == 7)  { return "Jump.Jacks"; }
        if (idx == 8)  { return "Burpees"; }
        if (idx == 9)  { return "Mtn.Climb"; }
        return "Lunges";
    }

    function _valueFor(idx) {
        if (idx == 0)  { return ""; }
        if (idx == 1)  { return JKDSettings.warmupDuration.toString() + " min"; }
        if (idx == 2)  { return JKDSettings.warmupWork.toString() + " sec"; }
        if (idx == 3)  { return JKDSettings.warmupRest.toString() + " sec"; }
        if (idx == 4)  { return JKDSettings.warmupCatSquats       ? "On" : "Off"; }
        if (idx == 5)  { return JKDSettings.warmupCatPushups      ? "On" : "Off"; }
        if (idx == 6)  { return JKDSettings.warmupCatCrunches     ? "On" : "Off"; }
        if (idx == 7)  { return JKDSettings.warmupCatJumpingJacks ? "On" : "Off"; }
        if (idx == 8)  { return JKDSettings.warmupCatBurpees      ? "On" : "Off"; }
        if (idx == 9)  { return JKDSettings.warmupCatMtnClimbers  ? "On" : "Off"; }
        return JKDSettings.warmupCatLunges ? "On" : "Off";
    }

    function onAction() {
        if (_selected == 0) {
            var view = new JKDWarmupView(
                JKDSettings.warmupDuration,
                JKDSettings.warmupWork,
                JKDSettings.warmupRest);
            WatchUi.pushView(view, new JKDWarmupDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (_selected == 1) {
            _durIdx = (_durIdx + 1) % _durations.size();
            JKDSettings.warmupDuration = _durations[_durIdx];
            JKDSettings.saveSettings();
        } else if (_selected == 2) {
            _workIdx = (_workIdx + 1) % _works.size();
            JKDSettings.warmupWork = _works[_workIdx];
            JKDSettings.saveSettings();
        } else if (_selected == 3) {
            _restIdx = (_restIdx + 1) % _rests.size();
            JKDSettings.warmupRest = _rests[_restIdx];
            JKDSettings.saveSettings();
        } else if (_selected == 4) {
            JKDSettings.warmupCatSquats = !JKDSettings.warmupCatSquats;
            JKDSettings.saveSettings();
        } else if (_selected == 5) {
            JKDSettings.warmupCatPushups = !JKDSettings.warmupCatPushups;
            JKDSettings.saveSettings();
        } else if (_selected == 6) {
            JKDSettings.warmupCatCrunches = !JKDSettings.warmupCatCrunches;
            JKDSettings.saveSettings();
        } else if (_selected == 7) {
            JKDSettings.warmupCatJumpingJacks = !JKDSettings.warmupCatJumpingJacks;
            JKDSettings.saveSettings();
        } else if (_selected == 8) {
            JKDSettings.warmupCatBurpees = !JKDSettings.warmupCatBurpees;
            JKDSettings.saveSettings();
        } else if (_selected == 9) {
            JKDSettings.warmupCatMtnClimbers = !JKDSettings.warmupCatMtnClimbers;
            JKDSettings.saveSettings();
        } else if (_selected == 10) {
            JKDSettings.warmupCatLunges = !JKDSettings.warmupCatLunges;
            JKDSettings.saveSettings();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 8, Graphics.FONT_XTINY, "WARM UP SETUP",
            Graphics.TEXT_JUSTIFY_CENTER);

        var itemH      = 40;
        var listTop    = 30;
        var listBottom = h - 20;
        var visible    = _visibleCount();
        var end        = _scrollOffset + visible;
        if (end > _numItems) { end = _numItems; }

        for (var i = _scrollOffset; i < end; i++) {
            var row = i - _scrollOffset;
            var y   = listTop + row * itemH;
            var mid = y + itemH / 2;

            if (i == _selected) {
                // Bright highlight: white background, black text
                var hlColor = (i == 0) ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE;
                dc.setColor(hlColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, y, w, itemH);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(12, mid, Graphics.FONT_SMALL, _labelFor(i),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var val = _valueFor(i);
            if (!val.equals("")) {
                var valColor;
                if (i == _selected) {
                    valColor = Graphics.COLOR_BLACK;
                } else if (val.equals("Off")) {
                    valColor = Graphics.COLOR_RED;
                } else if (val.equals("On")) {
                    valColor = Graphics.COLOR_GREEN;
                } else {
                    valColor = Graphics.COLOR_YELLOW;
                }
                dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w - 12, mid, Graphics.FONT_SMALL, val,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Scroll indicators
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        if (_scrollOffset > 0) {
            dc.drawText(cx, listTop - 12, Graphics.FONT_XTINY, "^",
                Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (end < _numItems) {
            dc.drawText(cx, listBottom + 2, Graphics.FONT_XTINY, "v",
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class JKDWarmupSetupDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() {
        _view.onAction();
        return true;
    }

    function onNextPage() {
        _view.selectNext();
        return true;
    }

    function onPreviousPage() {
        _view.selectPrev();
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
