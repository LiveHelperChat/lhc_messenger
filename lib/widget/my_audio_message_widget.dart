import 'package:flutter/material.dart';
import 'package:livehelp/model/message.dart';
import 'package:voice_message_package/voice_message_package.dart';

//a widget which will be return when the message type is audio
class MyAudioMessageWidget extends StatelessWidget {
  const MyAudioMessageWidget({super.key, required this.message,required this.link,});
  final Message message;
  final String link;
  @override
  Widget build(BuildContext context) {
    return VoiceMessageView(
      controller: VoiceController(
        audioSrc: link,
        maxDuration: const Duration(seconds: 30),
        isFile: false,
        onComplete: () {
          /// do something on complete
        },
        onPause: () {
          /// do something on pause
        },
        onPlaying: () {
          /// do something on playing
        },
        onError: (err) {
          /// do somethin on error
        },
      ),
    );
  }
}
