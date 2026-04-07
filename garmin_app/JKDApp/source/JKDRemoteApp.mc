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
        Communications.registerForPhoneAppMessages(method(:onPhoneAppMessage));
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
    function onPhoneAppMessage(msg as Communications.PhoneAppMessage) as Void {
        var data = msg.data;
        System.println("Message from phone: " + data);
        if (data == null || !(data instanceof Dictionary)) { return; }

        // Handle TTS completion signal from phone
        if (data.hasKey("ttsComplete")) {
            System.println("TTS Complete signal received");
            if (JKDSettings.currentView != null && JKDSettings.currentView has :onTtsComplete) {
                JKDSettings.currentView.onTtsComplete();
            }
        }
    }
}
