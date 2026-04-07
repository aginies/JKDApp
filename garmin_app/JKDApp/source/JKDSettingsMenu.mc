import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;

class JKDSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Settings"});
        
        var modeLabel = (JKDSettings.trainingMode == JKDSettings.MODE_SEQUENTIAL) ? "Sequential" : "Random";
        addItem(new WatchUi.MenuItem("Mode", modeLabel, :mode, null));
        
        var timerLabel = (JKDSettings.autoAdvanceSec == 0) ? "Manual" : JKDSettings.autoAdvanceSec + "s";
        addItem(new WatchUi.MenuItem("Auto-Advance", timerLabel, :timer, null));
        
        var beepLabel = JKDSettings.enableBeep ? "On" : "Off";
        addItem(new WatchUi.MenuItem("Beep", beepLabel, :beep, null));

        var voiceLabel = JKDSettings.enableVoice ? "On" : "Off";
        addItem(new WatchUi.MenuItem("Voice Coaching", voiceLabel, :voice, null));

        var langLabel = (JKDSettings.language == JKDSettings.LANG_EN) ? "English" : "Français";
        addItem(new WatchUi.MenuItem("Language", langLabel, :lang, null));

        var textLabel = JKDSettings.forceLargeText ? "Large" : "Dynamic";
        addItem(new WatchUi.MenuItem("Text Size", textLabel, :text, null));

        addItem(new WatchUi.MenuItem("Developed by", "ginies.org", :credit, null));
    }
}

class JKDSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        
        if (id == :mode) {
            if (JKDSettings.trainingMode == JKDSettings.MODE_SEQUENTIAL) {
                JKDSettings.trainingMode = JKDSettings.MODE_RANDOM;
                item.setSubLabel("Random");
            } else {
                JKDSettings.trainingMode = JKDSettings.MODE_SEQUENTIAL;
                item.setSubLabel("Sequential");
            }
            JKDSettings.saveSettings();
        } else if (id == :timer) {
            if (JKDSettings.autoAdvanceSec == 0) {
                JKDSettings.autoAdvanceSec = 2;
                item.setSubLabel("2s");
            } else if (JKDSettings.autoAdvanceSec == 2) {
                JKDSettings.autoAdvanceSec = 3;
                item.setSubLabel("3s");
            } else if (JKDSettings.autoAdvanceSec == 3) {
                JKDSettings.autoAdvanceSec = 5;
                item.setSubLabel("5s");
            } else {
                JKDSettings.autoAdvanceSec = 0;
                item.setSubLabel("Manual");
            }
            JKDSettings.saveSettings();
        } else if (id == :beep) {
            JKDSettings.enableBeep = !JKDSettings.enableBeep;
            item.setSubLabel(JKDSettings.enableBeep ? "On" : "Off");
            JKDSettings.saveSettings();
        } else if (id == :voice) {
            JKDSettings.enableVoice = !JKDSettings.enableVoice;
            item.setSubLabel(JKDSettings.enableVoice ? "On" : "Off");
            JKDSettings.saveSettings();
            // Notify paired phone of new coaching voice state
            Communications.transmit(
                {"coachingVoice" => JKDSettings.enableVoice}, null, new CommListener()
            );
        } else if (id == :lang) {
            if (JKDSettings.language == JKDSettings.LANG_EN) {
                JKDSettings.language = JKDSettings.LANG_FR;
                item.setSubLabel("Français");
            } else {
                JKDSettings.language = JKDSettings.LANG_EN;
                item.setSubLabel("English");
            }
            JKDSettings.saveSettings();
        } else if (id == :text) {
            JKDSettings.forceLargeText = !JKDSettings.forceLargeText;
            item.setSubLabel(JKDSettings.forceLargeText ? "Large" : "Dynamic");
            JKDSettings.saveSettings();
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
