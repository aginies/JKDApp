import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Communications;
import Toybox.Activity;
import Toybox.ActivityRecording;

class JKDStandaloneView extends WatchUi.View {
    private var _series as JKDSeries.Series;
    private var _session = null;
    private var _comboIndex = 0;
    private var _heartRate = 0;
    private var _sessionMinHR = 0;
    private var _sessionMaxHR = 0;
    private var _hrTimer;
    private var _showDetail = false;
    private var _scrollOffset = 0;
    private var _maxScroll = 0;
    private var _lineHeight = 20;
    private var _scrollDir = 1; 
    private var _pauseTicks = 0;
    private var _autoAdvanceTicks = 0;
    private var _tickCount = 0;
    private var _isWaitingForTts = false;
    private var _repCount = 0;

    function initialize(series as JKDSeries.Series) {
        View.initialize();
        _series = series;
        JKDSettings.currentView = self;
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        var info = Sensor.getInfo();
        if (info != null && info.heartRate != null) {
            _heartRate = info.heartRate;
            _sessionMinHR = _heartRate;
            _sessionMaxHR = _heartRate;
        }
        _hrTimer = new Timer.Timer();
    }

    function onShow() {
        JKDSettings.currentView = self;
        _hrTimer.start(method(:onAnimate), 100, true);
        
        // Start activity recording
        if (Toybox has :ActivityRecording) {
            if (_session == null || (_session != null && !_session.isRecording())) {
                var sport = Activity.SPORT_GENERIC;
                if (Activity has :SPORT_MARTIAL_ARTS) {
                    sport = Activity.SPORT_MARTIAL_ARTS;
                }
                
                _session = ActivityRecording.createSession({
                    :name => "JKD: " + _series.title,
                    :sport => sport,
                    :subSport => Activity.SUB_SPORT_GENERIC
                });
                _session.start();
                vibrate();
            }
        }
        
        sendComboToPhone(); // Send initial combo
    }

    function onHide() {
        _hrTimer.stop();
        JKDSettings.currentView = null;
        
        // Stop and save activity recording
        if (_session != null && _session.isRecording()) {
            _session.stop();
            _session.save();
            _session = null;
            vibrate();
        }
    }

    function onAnimate() {
        _tickCount++;
        
        if (_tickCount % 10 == 0) {
            var info = Sensor.getInfo();
            if (info != null && info.heartRate != null) {
                _heartRate = info.heartRate;
                if (_sessionMinHR == 0 || _heartRate < _sessionMinHR) { _sessionMinHR = _heartRate; }
                if (_heartRate > _sessionMaxHR) { _sessionMaxHR = _heartRate; }

                // Periodic HR transmission to phone (every 2 seconds to avoid flooding)
                if (_tickCount % 20 == 0) {
                    Communications.transmit({"hr" => _heartRate}, null, new CommListener());
                }
            }

            // If voice coaching was disabled while we were waiting, clear the flag
            if (!JKDSettings.enableVoice && _isWaitingForTts) {
                _isWaitingForTts = false;
            }

            // Auto-advance logic
            if (JKDSettings.autoAdvanceSec > 0) {
                // If voice is on, we MUST wait for the completion signal first.
                // If voice is off, we advance normally.
                if (!JKDSettings.enableVoice || !_isWaitingForTts) {
                    _autoAdvanceTicks++;
                    if (_autoAdvanceTicks >= JKDSettings.autoAdvanceSec) {
                        _autoAdvanceTicks = 0;
                        if (JKDSettings.enableBeep && Attention has :playTone) {
                            Attention.playTone(Attention.TONE_LOUD_BEEP);
                        }
                        nextCombo();
                    }
                }
            }

            if (_maxScroll > 0) {
                if (_pauseTicks > 0) {
                    _pauseTicks--;
                } else {
                    _scrollOffset += (_scrollDir * 25); 
                    if (_scrollOffset >= _maxScroll) {
                        _scrollOffset = _maxScroll;
                        _scrollDir = -1;
                        _pauseTicks = 1; 
                    } else if (_scrollOffset <= 0) {
                        _scrollOffset = 0;
                        _scrollDir = 1;
                        _pauseTicks = 1; 
                    }
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function toggleDetail() {
        _showDetail = !_showDetail;
        WatchUi.requestUpdate();
    }

    function isShowingDetail() {
        return _showDetail;
    }

    function toggleMirrorMode() {
        JKDSettings.mirrorMode = !JKDSettings.mirrorMode;
        JKDSettings.saveSettings();
        vibrate();
        WatchUi.requestUpdate();
    }

    function nextCombo() {
        var combos = _series.combos;
        if (JKDSettings.trainingMode == JKDSettings.MODE_RANDOM) {
            _comboIndex = Math.rand() % combos.size();
        } else {
            var nextIndex = _comboIndex + 1;
            if (nextIndex >= combos.size()) {
                _repCount++;
                nextIndex = 0;
            }
            _comboIndex = nextIndex;
        }
        _autoAdvanceTicks = 0;
        resetScroll();
        sendComboToPhone();
        WatchUi.requestUpdate();
    }

    function prevCombo() {
        var combos = _series.combos;
        if (JKDSettings.trainingMode == JKDSettings.MODE_RANDOM) {
            _comboIndex = Math.rand() % combos.size();
        } else {
            _comboIndex = (_comboIndex - 1);
            if (_comboIndex < 0) {
                _comboIndex = combos.size() - 1;
            }
        }
        _autoAdvanceTicks = 0;
        resetScroll();
        sendComboToPhone();
        WatchUi.requestUpdate();
    }

    function sendComboToPhone() {
        _autoAdvanceTicks = 0; // Reset timer when we show/start a new combo
        if (JKDSettings.enableVoice) {
            _isWaitingForTts = true;
            var comboText = _series.combos[_comboIndex].text;
            // Format for speech (strip + and -> for cleaner pronunciation)
            var cleanText = comboText;
            while (cleanText.find(" + ") != null) {
                var idx = cleanText.find(" + ");
                cleanText = cleanText.substring(0, idx) + ", " + cleanText.substring(idx + 3, cleanText.length());
            }
            while (cleanText.find(" -> ") != null) {
                var idx = cleanText.find(" -> ");
                cleanText = cleanText.substring(0, idx) + ", counter with " + cleanText.substring(idx + 4, cleanText.length());
            }
            
            Communications.transmit({"speak" => cleanText}, null, new CommListener());
        }
    }

    // Called by JKDRemoteApp.onPhoneAppMessage when the phone finishes TTS.
    // Starts the auto-advance countdown ONLY after pronunciation is complete.
    function onTtsComplete() {
        System.println("onTtsComplete called in View");
        _isWaitingForTts = false;
        _autoAdvanceTicks = 0; // Countdown starts from NOW
        vibrate();
        WatchUi.requestUpdate();
    }

    function resetScroll() {
        _scrollOffset = 0;
        _scrollDir = 1;
        _pauseTicks = 1;
    }

    function vibrate() {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }

    function getHRColor() {
        if (_heartRate == 0) { return Graphics.COLOR_WHITE; }
        var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        if (zones == null || zones.size() < 5) { return Graphics.COLOR_RED; }
        if (_heartRate < zones[1]) { return Graphics.COLOR_BLUE; }
        if (_heartRate < zones[2]) { return Graphics.COLOR_GREEN; }
        if (_heartRate < zones[3]) { return Graphics.COLOR_YELLOW; }
        if (_heartRate < zones[4]) { return Graphics.COLOR_ORANGE; }
        return Graphics.COLOR_RED;
    }

    function drawAngle(dc, x, y, size, angle) {
        if (angle == null) { return; }
        var r = size / 2;
        dc.setPenWidth(4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Map angles to coordinates (simplified logic from Flutter app)
        if (angle == 1) { // 225 -> 45
            _drawAngleLine(dc, x, y, r, 225, 45);
        } else if (angle == 2) { // 315 -> 135
            _drawAngleLine(dc, x, y, r, 315, 135);
        } else if (angle == 3) { // 180 -> 0
            _drawAngleLine(dc, x, y, r, 180, 0);
        } else if (angle == 4) { // 0 -> 180
            _drawAngleLine(dc, x, y, r, 0, 180);
        } else if (angle == 5) { // Center Thrust
            dc.drawCircle(x, y, 5);
            dc.fillCircle(x, y, 3);
        } else if (angle == 6 || angle == 7) { // Loaded Thrusts (L/R)
            var isLeft = (angle == 6);
            var start = isLeft ? [x - r * 0.7, y + r * 0.5] : [x + r * 0.7, y + r * 0.5];
            var mid = isLeft ? [x - r * 0.9, y + r * 0.1] : [x + r * 0.9, y + r * 0.1];
            var midPoint = isLeft ? [x - r * 0.2, y + r * 0.1] : [x + r * 0.2, y + r * 0.1];
            var end = isLeft ? [x + r * 0.6, y - r * 0.6] : [x - r * 0.6, y - r * 0.6];
            _drawBezier(dc, start, mid, midPoint);
            dc.drawLine(midPoint[0], midPoint[1], end[0], end[1]);
            _drawArrowHead(dc, midPoint[0], midPoint[1], end[0], end[1], 8);
        } else if (angle == 8) { // Vertical Down
            _drawAngleLine(dc, x, y, r, 270, 90);
        } else if (angle == 9) { // Uppercut Left
            _drawAngleCurve(dc, x, y, r, false);
        } else if (angle == 10) { // Uppercut Right
            _drawAngleCurve(dc, x, y, r, true);
        } else if (angle == 11) { // Thrust High Left
            _drawAngleLine(dc, x, y, r, 210, 30);
        } else if (angle == 12) { // Thrust High Right
            _drawAngleLine(dc, x, y, r, 330, 150);
        } else if (angle == 13) { // Abanico (Arc)
            dc.drawArc(x, y, r * 0.85, Graphics.ARC_CLOCKWISE, 180, 0);
        } else if (angle == 14) { // Pugno (Vertical + Circle)
            var startY = y - r * 0.85;
            var endY = y + r * 0.25;
            dc.drawLine(x, startY, x, endY);
            dc.drawCircle(x + r * 0.25, endY, r * 0.25);
            _drawArrowHead(dc, x, startY + 1, x, startY, 8);
        } else if (angle == 15) { // Backend (Double Curve)
            var pStart = [x - r * 0.4, y + r * 0.2];
            var pCtrl1 = [x - r * 0.9, y + r * 0.8];
            var pMid = [x, y + r * 0.9];
            var pCtrl2 = [x + r * 0.4, y + r * 0.8];
            var pEndStart = [x + r * 0.2, y + r * 0.4];
            var pFinal = [x + r * 0.9, y - r * 0.3];
            _drawBezier(dc, pStart, pCtrl1, pMid);
            _drawBezier(dc, pMid, pCtrl2, pEndStart);
            dc.drawLine(pEndStart[0], pEndStart[1], pFinal[0], pFinal[1]);
            _drawArrowHead(dc, pEndStart[0], pEndStart[1], pFinal[0], pFinal[1], 8);
        } else {
            // Fallback for complex ones: just show the number
            dc.drawText(x, y, Graphics.FONT_XTINY, "A" + angle, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setPenWidth(1);
    }

    function _drawAngleLine(dc, x, y, r, startAngleDeg, endAngleDeg) {
        var startRad = Math.toRadians(startAngleDeg);
        var endRad = Math.toRadians(endAngleDeg);

        var x1 = x + r * Math.cos(startRad);
        var y1 = y - r * Math.sin(startRad);
        var x2 = x + r * Math.cos(endRad);
        var y2 = y - r * Math.sin(endRad);

        dc.drawLine(x1, y1, x2, y2);
        _drawArrowHead(dc, x1, y1, x2, y2, 8);
    }

    function _drawArrowHead(dc, x1, y1, x2, y2, size) {
        var angle = Math.atan2(y2 - y1, x2 - x1);
        var x3 = x2 - size * Math.cos(angle - 0.5);
        var y3 = y2 - size * Math.sin(angle - 0.5);
        var x4 = x2 - size * Math.cos(angle + 0.5);
        var y4 = y2 - size * Math.sin(angle + 0.5);

        dc.fillPolygon([[x2, y2], [x3, y3], [x4, y4]]);
    }

    function _drawBezier(dc, p0, p1, p2) {
        var lastX = p0[0];
        var lastY = p0[1];
        var steps = 10;
        for (var i = 1; i <= steps; i++) {
            var t = i.toFloat() / steps.toFloat();
            var it = 1.0 - t;
            
            var currX = (it * it * p0[0] + 2 * it * t * p1[0] + t * t * p2[0]);
            var currY = (it * it * p0[1] + 2 * it * t * p1[1] + t * t * p2[1]);
            
            dc.drawLine(lastX, lastY, currX, currY);
            lastX = currX;
            lastY = currY;
        }
        return [lastX, lastY]; // Return end point for arrowhead
    }

    function _drawAngleCurve(dc, x, y, r, isRight) {
        var p1 = isRight ? [x - r * 0.8, y + r * 0.2] : [x + r * 0.8, y + r * 0.2];
        var ctrl = [x - r * 0.2, y + r * 1.0];
        var p2 = isRight ? [x + r * 0.8, y - r * 0.8] : [x - r * 0.8, y - r * 0.8];
        
        _drawBezier(dc, p1, ctrl, p2);
        
        // Arrowhead at the end, tangent from control point
        _drawArrowHead(dc, ctrl[0], ctrl[1], p2[0], p2[1], 8);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        if (_showDetail) { drawDetailView(dc, centerX, centerY, screenWidth, screenHeight); }
        else { drawMainView(dc, centerX, centerY, screenWidth, screenHeight); }
    }

    function drawCounterArrow(dc, x, y, size) {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x, y, x + size - 2, y);
        dc.drawLine(x + size - 2, y, x + size - 6, y - 4);
        dc.drawLine(x + size - 2, y, x + size - 6, y + 4);
        dc.setPenWidth(1);
    }

    function drawMainView(dc, centerX, centerY, screenWidth, screenHeight) {
        var radius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 2 - 6;
        var combos = _series.combos;
        var totalCombos = combos.size();
        var pFont = Graphics.FONT_XTINY;
        var textH = dc.getFontHeight(pFont);
        var pillY = 2;

        if (totalCombos > 0) {
            var progress = (_comboIndex + 1).toFloat() / totalCombos.toFloat();
            var startAngle = 90;
            var sweepAngle = -(progress * 360);
            dc.setPenWidth(8);
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(centerX, centerY, radius);
            dc.setPenWidth(12);
            var ringColor = Graphics.COLOR_ORANGE;
            if (progress < 0.33) {
                ringColor = Graphics.COLOR_RED;
            } else if (progress < 0.66) {
                ringColor = Graphics.COLOR_YELLOW;
            } else if (progress < 1.0) {
                ringColor = Graphics.COLOR_ORANGE;
            } else {
                ringColor = Graphics.COLOR_GREEN;
            }
            dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(
                centerX,
                centerY,
                radius,
                Graphics.ARC_CLOCKWISE,
                startAngle,
                startAngle + sweepAngle
            );
            var endRad = Math.toRadians(startAngle + sweepAngle);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(
                centerX + radius * Math.cos(endRad),
                centerY - radius * Math.sin(endRad),
                7
            );
            var startRad = Math.toRadians(startAngle);
            dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(
                centerX + radius * Math.cos(startRad),
                centerY - radius * Math.sin(startRad),
                6
            );

            var progressStr =
                (_comboIndex + 1).toString() + "/" + totalCombos.toString();
            var textW = dc.getTextWidthInPixels(progressStr, pFont);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(
                centerX - textW / 2 - 4,
                pillY,
                textW + 8,
                textH,
                4
            );
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                pillY,
                pFont,
                progressStr,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            // Phone Connectivity Indicator
            var settings = System.getDeviceSettings();
            if (settings.phoneConnected) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    screenWidth - 30,
                    pillY,
                    Graphics.FONT_XTINY,
                    "BT",
                    Graphics.TEXT_JUSTIFY_RIGHT
                );
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    screenWidth - 30,
                    pillY,
                    Graphics.FONT_XTINY,
                    "BT",
                    Graphics.TEXT_JUSTIFY_RIGHT
                );
            }

            // Recording Indicator (Red dot)
            if (_session != null && _session.isRecording()) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(screenWidth - 15, pillY + textH / 2, 4);
            }

            // Rep count
            if (_repCount > 0) {
                var repStr = "x" + _repCount.toString();
                var repW = dc.getTextWidthInPixels(repStr, pFont);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(4, pillY, repW + 8, textH, 4);
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(8, pillY, pFont, repStr, Graphics.TEXT_JUSTIFY_LEFT);
            }

            // Mirror mode indicator
            if (JKDSettings.mirrorMode) {
                var mirW = dc.getTextWidthInPixels("MIR", pFont);
                var mirY = screenHeight - textH - 6;
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(centerX - mirW / 2 - 4, mirY, mirW + 8, textH, 4);
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, mirY, pFont, "MIR", Graphics.TEXT_JUSTIFY_CENTER);
            }

            if (JKDSettings.autoAdvanceSec > 0) {
                var timerProgress =
                    _autoAdvanceTicks.toFloat() /
                    JKDSettings.autoAdvanceSec.toFloat();
                dc.setPenWidth(2);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(
                    centerX,
                    centerY,
                    radius - 10,
                    Graphics.ARC_CLOCKWISE,
                    startAngle,
                    startAngle - 360 * (1.0 - timerProgress)
                );
            }
            dc.setPenWidth(1);
        }

        // Heart Rate (bottom left)
        if (_heartRate > 0) {
            dc.setColor(getHRColor(), Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX - 50, screenHeight - 25, Graphics.FONT_TINY, _heartRate.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        }

        var combo = combos[_comboIndex];

        var comboText = combo.text;
        var rawLines = [];
        var rest = comboText;
        var index = rest.find(" + ");
        while (index != null) {
            rawLines.add(rest.substring(0, index));
            rest = rest.substring(index + 3, rest.length());
            index = rest.find(" + ");
        }
        rawLines.add(rest);

        var font = JKDSettings.forceLargeText
            ? Graphics.FONT_MEDIUM
            : rawLines.size() > 3
            ? Graphics.FONT_TINY
            : Graphics.FONT_SMALL;
        var lines = [];
        var maxWidth = screenWidth * 0.8;

        for (var i = 0; i < rawLines.size(); i++) {
            var line = rawLines[i];
            if (dc.getTextWidthInPixels(line, font) > maxWidth) {
                var arrowIdx = line.find(" -> ");
                if (arrowIdx != null) {
                    var part1 = line.substring(0, arrowIdx + 3);
                    var part2 = line.substring(arrowIdx + 4, line.length());
                    wrapLine(dc, part1, font, maxWidth, lines);
                    wrapLine(dc, part2, font, maxWidth, lines);
                } else {
                    wrapLine(dc, line, font, maxWidth, lines);
                }
            } else {
                lines.add(line);
            }
        }

        if (
            !JKDSettings.forceLargeText &&
            lines.size() > 5 &&
            font != Graphics.FONT_XTINY
        ) {
            font = Graphics.FONT_TINY;
        }

        var fontHeight = dc.getFontHeight(font);
        _lineHeight = (fontHeight * 0.95).toNumber();
        var totalHeight = lines.size() * _lineHeight;
        var topMargin = 35;
        var bottomMargin = 35;
        var visibleHeight = screenHeight - topMargin - bottomMargin;

        if (totalHeight > visibleHeight) {
            _maxScroll = totalHeight - visibleHeight;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            var barHeight =
                (visibleHeight.toFloat() *
                    (visibleHeight.toFloat() / totalHeight.toFloat())).toNumber();
            if (barHeight < 10) {
                barHeight = 10;
            }
            var barY =
                topMargin +
                (_scrollOffset.toFloat() /
                    (_maxScroll == 0 ? 1 : _maxScroll).toFloat() *
                    (visibleHeight - barHeight)).toNumber();
            dc.fillRectangle(screenWidth - 6, barY, 2, barHeight);
        } else {
            _maxScroll = 0;
            _scrollOffset = 0;
        }

        var startY =
            totalHeight < visibleHeight
                ? topMargin + (visibleHeight - totalHeight) / 2
                : topMargin - _scrollOffset;

        dc.setClip(0, topMargin, screenWidth, visibleHeight);

        if (_maxScroll > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            if (_scrollOffset > 5) {
                dc.drawLine(
                    centerX - 30,
                    topMargin + 2,
                    centerX + 30,
                    topMargin + 2
                );
            }
            if (_scrollOffset < _maxScroll - 5) {
                dc.drawLine(
                    centerX - 30,
                    topMargin + visibleHeight - 2,
                    centerX + 30,
                    topMargin + visibleHeight - 2
                );
            }
        }

        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            var currentY = startY + i * _lineHeight;
            if (
                currentY + _lineHeight < topMargin ||
                currentY > topMargin + visibleHeight
            ) {
                continue;
            }

            var words = [];
            var lineRest = line;
            var spaceIdx = lineRest.find(" ");
            while (spaceIdx != null) {
                words.add(lineRest.substring(0, spaceIdx));
                lineRest = lineRest.substring(spaceIdx + 1, lineRest.length());
                spaceIdx = lineRest.find(" ");
            }
            words.add(lineRest);

            var totalW = 0;
            var wordWidths = new [words.size()];
            var spaceW = dc.getTextWidthInPixels(" ", font);

            for (var j = 0; j < words.size(); j++) {
                wordWidths[j] = dc.getTextWidthInPixels(words[j], font);
                totalW += wordWidths[j];
                if (j < words.size() - 1) {
                    totalW += spaceW;
                }
            }

            var currentX = centerX - totalW / 2;
            for (var j = 0; j < words.size(); j++) {
                var word = words[j];
                
                // Skip "Angle" and the subsequent number if it's just a label
                if (word.equals("Angle")) {
                    continue;
                }
                // Check if it's just a number string following "Angle"
                var isNumber = true;
                var chars = word.toCharArray();
                for (var k = 0; k < chars.size(); k++) {
                    if (chars[k] < '0' || chars[k] > '9') {
                        isNumber = false;
                        break;
                    }
                }
                if (isNumber && j > 0 && words[j-1].equals("Angle")) {
                    continue;
                }

                if (JKDSettings.mirrorMode) {
                    if (word.equals("L")) {
                        word = "R";
                    } else if (word.equals("R")) {
                        word = "L";
                    }
                }
                var color = Graphics.COLOR_WHITE;

                if (word.equals("L")) {
                    color = Graphics.COLOR_BLUE;
                } else if (word.equals("R")) {
                    color = Graphics.COLOR_RED;
                } else if (word.equals("->")) {
                    drawCounterArrow(dc, currentX, currentY + fontHeight / 2, 14);
                    currentX += 14 + 8;
                    continue;
                } else if (
                    word.find("Jab") != null ||
                    word.find("Cross") != null ||
                    word.find("Hook") != null
                ) {
                    color = Graphics.COLOR_GREEN;
                } else if (line.find("->") != null) {
                    var arrowIdxInLine = line.find("->");
                    var wordIdxInLine = line.find(word);
                    if (wordIdxInLine != null && wordIdxInLine < arrowIdxInLine) {
                        color = Graphics.COLOR_YELLOW;
                    }
                }

                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(currentX, currentY, font, word, Graphics.TEXT_JUSTIFY_LEFT);
                currentX += wordWidths[j] + spaceW;
            }
        }
        dc.clearClip();

        // Draw Angle Diagram if available
        if (combo.angles.size() > 0) {
            var angleX = centerX;
            var angleY = centerY;
            var angleSize = 84;   // Increased from 60 (1.4x)
            
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(angleX, angleY, angleSize / 2 + 14);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawCircle(angleX, angleY, angleSize / 2 + 14);
            
            drawAngle(dc, angleX, angleY, angleSize, combo.angles[0]);
        }
    }

    function wrapLine(dc, line, font, maxWidth, linesArray) {
        var words = [];
        var lineRest = line;
        var spaceIdx = lineRest.find(" ");
        while (spaceIdx != null) {
            words.add(lineRest.substring(0, spaceIdx));
            lineRest = lineRest.substring(spaceIdx + 1, lineRest.length());
            spaceIdx = lineRest.find(" ");
        }
        words.add(lineRest);
        var currentLine = "";
        for (var j = 0; j < words.size(); j++) {
            var testLine =
                currentLine.length() == 0 ? words[j] : currentLine + " " + words[j];
            if (dc.getTextWidthInPixels(testLine, font) > maxWidth) {
                if (currentLine.length() > 0) {
                    linesArray.add(currentLine);
                }
                currentLine = words[j];
            } else {
                currentLine = testLine;
            }
        }
        if (currentLine.length() > 0) {
            linesArray.add(currentLine);
        }
    }

    function drawDetailView(dc, centerX, centerY, screenWidth, screenHeight) {
        var stats = System.getSystemStats();
        var battery = stats.battery.toNumber();
        var batteryStr = battery + "%";
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var clockStr = Lang.format("$1$:$2$", [now.hour.format("%02d"), now.min.format("%02d")]);
        var headerFont = Graphics.FONT_TINY;
        var clockWidth = dc.getTextWidthInPixels(clockStr, headerFont);
        var gap = 20;
        var headerX = (centerX / 2); 
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(headerX, 40, headerFont, clockStr, Graphics.TEXT_JUSTIFY_LEFT);
        var battX = headerX + clockWidth + gap;
        var battStrW = dc.getTextWidthInPixels(batteryStr, headerFont);
        if (dc has :drawBitmap2) {
            var gdc = dc as Graphics.Dc;
            var battIconWidth = 20;
            var battIconHeight = 10;
            var battIconX = battX + (battStrW / 2) - (battIconWidth / 2);
            var battIconY = 28; 
            gdc.setPenWidth(1);
            gdc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            gdc.drawRectangle(battIconX, battIconY, battIconWidth, battIconHeight);
            gdc.fillRectangle(battIconX + battIconWidth, battIconY + 2, 2, 4); 
            var battColor = (battery > 20) ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
            gdc.setColor(battColor, Graphics.COLOR_TRANSPARENT);
            var fillWidth = ((battIconWidth - 4) * (battery / 100.0)).toNumber();
            if (fillWidth > 0) { gdc.fillRectangle(battIconX + 2, battIconY + 2, fillWidth, battIconHeight - 4); }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(battX, 40, headerFont, batteryStr, Graphics.TEXT_JUSTIFY_LEFT);

        var hrColor = getHRColor();
        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawRectangle(centerX - 50, centerY + 30, 100, 4); 
        dc.fillRectangle(centerX - 50, centerY + 30, (_heartRate % 100), 4);
        dc.drawText(centerX, centerY - 45, Graphics.FONT_NUMBER_MEDIUM, _heartRate.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, centerY + 5, Graphics.FONT_TINY, "BPM", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var labelY = centerY - 25; 
        dc.drawText(centerX - 80, labelY - 20, Graphics.FONT_XTINY, "min", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX - 80, labelY + 5, Graphics.FONT_XTINY, _sessionMinHR.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX + 80, labelY - 20, Graphics.FONT_XTINY, "max", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX + 80, labelY + 5, Graphics.FONT_XTINY, _sessionMaxHR.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Mirror mode toggle
        var mirrorColor = JKDSettings.mirrorMode ? Graphics.COLOR_ORANGE : Graphics.COLOR_LT_GRAY;
        var mirrorLabel = JKDSettings.mirrorMode ? "MIRROR: ON" : "MIRROR: OFF";
        dc.setColor(mirrorColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 70, Graphics.FONT_SMALL, mirrorLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 45, Graphics.FONT_XTINY, "^ On  v Off", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

// CommListener is now defined in JKDSettings.mc (shared)
