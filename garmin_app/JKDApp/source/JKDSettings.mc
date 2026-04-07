import Toybox.Application;
import Toybox.Communications;

module JKDSettings {
    enum {
        MODE_SEQUENTIAL,
        MODE_RANDOM
    }

    enum {
        LANG_EN,
        LANG_FR
    }

    var trainingMode = MODE_SEQUENTIAL;
    var autoAdvanceSec = 0; // 0, 2, 3, 5
    var forceLargeText = false;
    var enableBeep = false;
    var enableVoice = false;
    var language = LANG_EN;

    // Reference to the active training view so onPhoneAppMessage can call back into it.
    var currentView = null;

    function loadSettings() {
        var s = Application.Storage.getValue("trainingMode");
        trainingMode = (s != null) ? s : MODE_SEQUENTIAL;
        s = Application.Storage.getValue("autoAdvanceSec");
        autoAdvanceSec = (s != null) ? s : 0;
        s = Application.Storage.getValue("enableBeep");
        enableBeep = (s != null) ? s : false;
        s = Application.Storage.getValue("enableVoice");
        enableVoice = (s != null) ? s : false;
        s = Application.Storage.getValue("language");
        language = (s != null) ? s : LANG_EN;
        s = Application.Storage.getValue("forceLargeText");
        forceLargeText = (s != null) ? s : false;
    }

    function saveSettings() {
        Application.Storage.setValue("trainingMode", trainingMode);
        Application.Storage.setValue("autoAdvanceSec", autoAdvanceSec);
        Application.Storage.setValue("enableBeep", enableBeep);
        Application.Storage.setValue("enableVoice", enableVoice);
        Application.Storage.setValue("language", language);
        Application.Storage.setValue("forceLargeText", forceLargeText);
    }
}

// Shared communication listener used by both JKDRemoteApp and JKDStandaloneView
class CommListener extends Communications.ConnectionListener {
    function initialize() { ConnectionListener.initialize(); }
    function onComplete() { }
    function onError() { }
}
