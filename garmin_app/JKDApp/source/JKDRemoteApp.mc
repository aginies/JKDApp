import Toybox.Application;
import Toybox.Communications;
import Toybox.WatchUi;

class JKDRemoteApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        JKDSettings.loadSettings();
        // Inform paired phone of current coaching voice state
        Communications.transmit(
            {"coachingVoice" => JKDSettings.enableVoice}, null, new CommListener()
        );
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new JKDSplashView() ];
    }

    // Handle messages from the phone companion app.
    function onPhoneAppMessage(msg) {
        var data = msg.data;
        if (data != null && data.hasKey("ttsComplete")) {
            if (JKDSettings.currentView != null) {
                JKDSettings.currentView.onTtsComplete();
            }
        }
    }
}
