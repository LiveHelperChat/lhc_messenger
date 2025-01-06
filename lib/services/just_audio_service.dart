import 'dart:async';

import 'package:just_audio/just_audio.dart';

//class to handle the audio play using just_audio player to avoid conflict if more audio files played at once
//the extra functionality it contains is debounce
class JustAudioService {
  static final JustAudioService _singleton = JustAudioService._internal();

  factory JustAudioService() {
    return _singleton;
  }

  JustAudioService._internal();

  AudioPlayer audio = AudioPlayer();
  Timer? _debounce;
  String? currentSource;
  Future<bool> play(String source, {Duration? position}) async {
    this.currentSource = source;
    Completer<bool> completer = Completer<bool>();
    await stop();

    bool isAlreadyPlay = false;
    if (_debounce == null) {
      isAlreadyPlay = true;

      _playSource(source, position: position).then(
        (value) {
          if (!completer.isCompleted) completer.complete(value);
        },
      );
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!isAlreadyPlay) {
        _playSource(source, position: position).then(
          (value) {
            if (!completer.isCompleted) completer.complete(value);
          },
        );
      }
      _debounce = null;
    });

    return completer.future;
  }

  Future<bool> _playSource(String source, {Duration? position}) async {
    try {
      late AudioSource audioSource;
      if (source.startsWith("https")) {
        audioSource = LockCachingAudioSource(Uri.parse(source));
      } else {
        audioSource = AudioSource.file(source);
      }

      await audio.setAudioSource(audioSource);
      if (position != null) {
        audio.seek(position);
      }
      await audio.play();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() => audio.stop();
}
