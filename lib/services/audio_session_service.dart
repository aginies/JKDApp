import 'package:audio_session/audio_session.dart' as aud_session;
import 'package:audioplayers/audioplayers.dart' as aud_play;
import 'package:flutter/foundation.dart';

/// Service to manage global audio focus and session configuration.
/// This ensures the app can mix with background music and "duck" it
/// when playing TTS or sound effects.
class AudioSessionService {
  static Future<void> init() async {
    try {
      final session = await aud_session.AudioSession.instance;
      
      // Configure global audio session using audio_session package
      await session.configure(aud_session.AudioSessionConfiguration(
        avAudioSessionCategory: aud_session.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: 
            aud_session.AVAudioSessionCategoryOptions.mixWithOthers | 
            aud_session.AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: aud_session.AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: aud_session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: aud_session.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        androidAudioAttributes: const aud_session.AndroidAudioAttributes(
          contentType: aud_session.AndroidAudioContentType.speech,
          flags: aud_session.AndroidAudioFlags.none,
          usage: aud_session.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: aud_session.AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));

      // We DON'T call session.setActive(true) globally here anymore.
      // Instead, we let the underlying engines (TTS, Audioplayers) 
      // manage their own focus activation/deactivation cycles.

      // Configure audioplayers global context for consistency
      await aud_play.AudioPlayer.global.setAudioContext(aud_play.AudioContext(
        iOS: aud_play.AudioContextIOS(
          category: aud_play.AVAudioSessionCategory.playback,
          options: {
            aud_play.AVAudioSessionOptions.mixWithOthers,
            aud_play.AVAudioSessionOptions.duckOthers,
          },
        ),
        android: aud_play.AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: aud_play.AndroidContentType.speech,
          usageType: aud_play.AndroidUsageType.media,
          audioFocus: aud_play.AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));

      debugPrint('AudioSessionService: Successfully initialized with ducking support.');
    } catch (e) {
      debugPrint('AudioSessionService Error: $e');
    }
  }

  /// Acquire (or hold) audio focus for the duration of a TTS session.
  /// Call once at session start (training, warmup) and pair with a single
  /// [releaseFocus] at session end. Holding the session prevents the
  /// per-utterance focus release inside flutter_tts from un-ducking
  /// background music between spoken lines.
  static Future<void> acquireFocus() async {
    try {
      final session = await aud_session.AudioSession.instance;
      await session.setActive(true);
      debugPrint('AudioSessionService: Focus acquired.');
    } catch (e) {
      debugPrint('AudioSessionService Acquire Error: $e');
    }
  }

  /// Manually release audio focus (useful if ducking gets stuck)
  static Future<void> releaseFocus() async {
    try {
      final session = await aud_session.AudioSession.instance;
      await session.setActive(false);
      debugPrint('AudioSessionService: Focus released.');
    } catch (e) {
      debugPrint('AudioSessionService Release Error: $e');
    }
  }
}
