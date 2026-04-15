import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Communications;
import Toybox.ActivityRecording;
import Toybox.Activity;

class JKDWarmupView extends WatchUi.View {
    private var _timer;
    private var _session = null;

    private var _workDuration;
    private var _restDuration;
    private var _totalDurationMinutes;

    private var _isPaused = false;
    private var _isWorkPeriod = true;
    private var _secondsRemaining = 0;
    private var _currentRound = 0;
    private var _totalRounds = 0;
    private var _workoutSequence = null;
    private var _tickCount = 0;
    private var _finished = false;

    function initialize(totalDurationMinutes, workDuration, restDuration) {
        View.initialize();
        _totalDurationMinutes = totalDurationMinutes;
        _workDuration = workDuration;
        _restDuration = restDuration;
        _timer = new Timer.Timer();

        // Build exercise pool from enabled categories
        var pool = new [0];
        if (JKDSettings.warmupCatSquats) {
            pool = pool.add("Squat Classical");
            pool = pool.add("Squat Low");
            pool = pool.add("Squat Jump");
        }
        if (JKDSettings.warmupCatPushups) {
            pool = pool.add("Push-up Classical");
            pool = pool.add("Push-up Diamond");
            pool = pool.add("Push-up Wide");
        }
        if (JKDSettings.warmupCatCrunches) {
            pool = pool.add("Abdominaux");
            pool = pool.add("Abdos Leg 90");
            pool = pool.add("Ciseaux");
        }
        if (JKDSettings.warmupCatJumpingJacks) {
            pool = pool.add("Jumping Jacks");
        }
        if (JKDSettings.warmupCatBurpees) {
            pool = pool.add("Burpees");
        }
        if (JKDSettings.warmupCatMtnClimbers) {
            pool = pool.add("Mountain Climbers");
        }
        if (JKDSettings.warmupCatLunges) {
            pool = pool.add("Lunges");
        }
        // Fallback: if everything is disabled, use a default
        if (pool.size() == 0) {
            pool = pool.add("Jumping Jacks");
        }

        // Build random sequence
        var totalSeconds = totalDurationMinutes * 60;
        var roundDuration = workDuration + restDuration;
        _totalRounds = totalSeconds / roundDuration;
        if (_totalRounds < 4) { _totalRounds = 4; }
        _workoutSequence = new [_totalRounds];

        // Always start with a Jumping Jack or Squat if either category is enabled
        var starters = new [0];
        if (JKDSettings.warmupCatJumpingJacks) { starters = starters.add("Jumping Jacks"); }
        if (JKDSettings.warmupCatSquats) {
            starters = starters.add("Squat Classical");
            starters = starters.add("Squat Low");
            starters = starters.add("Squat Jump");
        }
        var lastIdx = -1;
        if (starters.size() > 0) {
            var startIdx = Math.rand() % starters.size();
            _workoutSequence[0] = starters[startIdx];
            // find lastIdx in pool to avoid repeat
            for (var k = 0; k < pool.size(); k++) {
                if (pool[k].equals(_workoutSequence[0])) { lastIdx = k; }
            }
        }

        var startI = (starters.size() > 0) ? 1 : 0;
        for (var i = startI; i < _totalRounds; i++) {
            var idx = Math.rand() % pool.size();
            var tries = 0;
            while (pool.size() > 1 && idx == lastIdx && tries < 5) {
                idx = Math.rand() % pool.size();
                tries++;
            }
            lastIdx = idx;
            _workoutSequence[i] = pool[idx];
        }

        _secondsRemaining = workDuration;
    }

    // Mirror JKDStandaloneView.onShow: just start the timer and recording
    function onShow() {
        JKDSettings.currentView = self;

        if (Toybox has :ActivityRecording) {
            _session = ActivityRecording.createSession({
                :name => "JKD Warmup",
                :sport => Activity.SPORT_GENERIC,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            _session.start();
        }

        _timer.start(method(:onAnimate), 100, true);
    }

    function onHide() {
        _timer.stop();
        JKDSettings.currentView = null;
        if (_session != null && _session.isRecording()) {
            _session.stop();
            _session.save();
            _session = null;
        }
    }

    // Mirror JKDStandaloneView.onAnimate: all state updates here
    function onAnimate() {
        if (_isPaused || _finished) {
            WatchUi.requestUpdate();
            return;
        }

        _tickCount++;
        if (_tickCount >= 10) {
            _tickCount = 0;
            if (_secondsRemaining > 0) {
                _secondsRemaining--;
                // 3-2-1 countdown beeps only during work to announce upcoming rest
                if (_isWorkPeriod && _secondsRemaining > 0 && _secondsRemaining <= 3) {
                    if (Attention has :playTone) {
                        Attention.playTone(Attention.TONE_KEY);
                    }
                }
            } else {
                advancePeriod();
            }
        }
        WatchUi.requestUpdate();
    }

    function advancePeriod() {
        if (_isWorkPeriod) {
            // Work → Rest: short beep (rest begins)
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_LOUD_BEEP);
            }
            _isWorkPeriod = false;
            _secondsRemaining = _restDuration;
            buzz(false);
            if (JKDSettings.enableVoice) {
                var text = "Rest";
                if (_currentRound < _totalRounds - 1) {
                    text = text + ". Next: " + _workoutSequence[_currentRound + 1];
                }
                Communications.transmit({"speak" => text}, null, new CommListener());
            }
        } else {
            _currentRound++;
            if (_currentRound < _totalRounds) {
                // Rest → Work: long tone to announce exercise restart
                if (Attention has :playTone) {
                    Attention.playTone(Attention.TONE_START);
                }
                _isWorkPeriod = true;
                _secondsRemaining = _workDuration;
                buzz(true);
                if (JKDSettings.enableVoice) {
                    Communications.transmit({"speak" => _workoutSequence[_currentRound]}, null, new CommListener());
                }
            } else {
                _finished = true;
                buzz(false);
                if (JKDSettings.enableVoice) {
                    Communications.transmit({"speak" => "Warmup complete"}, null, new CommListener());
                }
                if (_session != null && _session.isRecording()) {
                    _session.stop();
                    _session.save();
                    _session = null;
                }
            }
        }
    }

    function togglePause() {
        _isPaused = !_isPaused;
        buzz(false);
        WatchUi.requestUpdate();
    }

    function buzz(strong) {
        if (Attention has :vibrate) {
            if (strong) {
                Attention.vibrate([new Attention.VibeProfile(100, 500)]);
            } else {
                Attention.vibrate([new Attention.VibeProfile(50, 200),
                                   new Attention.VibeProfile(0, 100),
                                   new Attention.VibeProfile(50, 200)]);
            }
        }
    }

    function onUpdate(dc) {
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        if (_finished) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM, "Done!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 20, Graphics.FONT_SMALL, "Press Back", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var color = _isWorkPeriod ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        if (_isPaused) { color = Graphics.COLOR_YELLOW; }

        // Outer ring: total workout progress (like series ring)
        var radius = (w < h ? w : h) / 2 - 6;
        var totalSec = _totalRounds * (_workDuration + _restDuration);
        var workElapsed = _isWorkPeriod ? (_workDuration - _secondsRemaining) : _workDuration;
        var elapsed = _currentRound * (_workDuration + _restDuration) + workElapsed;
        if (!_isWorkPeriod) {
            elapsed = _currentRound * (_workDuration + _restDuration) + _workDuration + (_restDuration - _secondsRemaining);
        }
        var totalProgress = elapsed.toFloat() / totalSec.toFloat();
        var totalSweep = -(totalProgress * 360);

        dc.setPenWidth(8);
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, radius);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90 + totalSweep);

        // Inner arc: current period countdown
        var innerRadius = radius - 14;
        var roundLimit = _isWorkPeriod ? _workDuration : _restDuration;
        var periodProgress = _secondsRemaining.toFloat() / roundLimit.toFloat();
        var periodSweep = -(periodProgress * 360);

        dc.setPenWidth(6);
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, innerRadius);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, innerRadius, Graphics.ARC_CLOCKWISE, 90, 90 + periodSweep);
        dc.setPenWidth(1);

        // Round counter (top) — small dark pill background
        var counterText = (_currentRound + 1).toString() + "/" + _totalRounds.toString();
        var bgW = 44;
        var bgH = 16;
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - bgW / 2, 3, bgW, bgH, 6);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 4, Graphics.FONT_XTINY, counterText, Graphics.TEXT_JUSTIFY_CENTER);

        // Phase label — moved higher during rest to leave room for Next block
        var phase = _isWorkPeriod ? "WORK" : "REST";
        if (_isPaused) { phase = "PAUSED"; }
        var phaseY = (_isWorkPeriod || _isPaused) ? cy - 55 : cy - 72;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, phaseY, Graphics.FONT_XTINY, phase, Graphics.TEXT_JUSTIFY_CENTER);

        // Exercise name (work) or next exercise (rest)
        if (_isWorkPeriod) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 38, Graphics.FONT_SMALL,
                _workoutSequence[_currentRound], Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_currentRound < _totalRounds - 1) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 55, Graphics.FONT_XTINY, "Next",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 38, Graphics.FONT_SMALL,
                _workoutSequence[_currentRound + 1], Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Countdown
        dc.drawText(cx, cy - 10, Graphics.FONT_NUMBER_MEDIUM,
            _secondsRemaining.toString(),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Time remaining
        var remaining = totalSec - elapsed;
        if (remaining < 0) { remaining = 0; }
        var remMin = remaining / 60;
        var remSec = remaining - remMin * 60;
        var remStr = remMin.toString() + ":" + remSec.format("%02d");
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 62, Graphics.FONT_TINY, remStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class JKDWarmupDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    function onSelect() {
        _view.togglePause();
        return true;
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
