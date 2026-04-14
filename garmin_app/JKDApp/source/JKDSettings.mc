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
    var mirrorMode = false;

    // Warmup settings
    var warmupDuration = 10; // minutes: 5, 8, 10, 15, 20
    var warmupWork = 20;     // seconds: 20, 25, 30, 35, 40
    var warmupRest = 10;     // seconds: 10, 15

    // Warmup exercise categories (all on by default)
    var warmupCatSquats         = true;
    var warmupCatPushups        = true;
    var warmupCatCrunches       = true;
    var warmupCatJumpingJacks   = true;
    var warmupCatBurpees        = true;
    var warmupCatMtnClimbers    = true;
    var warmupCatLunges         = true;

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
        s = Application.Storage.getValue("mirrorMode");
        mirrorMode = (s != null) ? s : false;
        s = Application.Storage.getValue("warmupDuration");
        warmupDuration = (s != null) ? s : 10;
        s = Application.Storage.getValue("warmupWork");
        warmupWork = (s != null) ? s : 20;
        s = Application.Storage.getValue("warmupRest");
        warmupRest = (s != null) ? s : 10;
        s = Application.Storage.getValue("warmupCatSquats");
        warmupCatSquats = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatPushups");
        warmupCatPushups = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatCrunches");
        warmupCatCrunches = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatJumpingJacks");
        warmupCatJumpingJacks = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatBurpees");
        warmupCatBurpees = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatMtnClimbers");
        warmupCatMtnClimbers = (s != null) ? s : true;
        s = Application.Storage.getValue("warmupCatLunges");
        warmupCatLunges = (s != null) ? s : true;
    }

    function saveSettings() {
        Application.Storage.setValue("trainingMode", trainingMode);
        Application.Storage.setValue("autoAdvanceSec", autoAdvanceSec);
        Application.Storage.setValue("enableBeep", enableBeep);
        Application.Storage.setValue("enableVoice", enableVoice);
        Application.Storage.setValue("language", language);
        Application.Storage.setValue("forceLargeText", forceLargeText);
        Application.Storage.setValue("mirrorMode", mirrorMode);
        Application.Storage.setValue("warmupDuration", warmupDuration);
        Application.Storage.setValue("warmupWork", warmupWork);
        Application.Storage.setValue("warmupRest", warmupRest);
        Application.Storage.setValue("warmupCatSquats",       warmupCatSquats);
        Application.Storage.setValue("warmupCatPushups",      warmupCatPushups);
        Application.Storage.setValue("warmupCatCrunches",     warmupCatCrunches);
        Application.Storage.setValue("warmupCatJumpingJacks", warmupCatJumpingJacks);
        Application.Storage.setValue("warmupCatBurpees",      warmupCatBurpees);
        Application.Storage.setValue("warmupCatMtnClimbers",  warmupCatMtnClimbers);
        Application.Storage.setValue("warmupCatLunges",       warmupCatLunges);
    }
}

// Shared communication listener used by both JKDRemoteApp and JKDStandaloneView
class CommListener extends Communications.ConnectionListener {
    function initialize() { ConnectionListener.initialize(); }
    function onComplete() { }
    function onError() { }
}
