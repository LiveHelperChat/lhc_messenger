import 'package:livehelp/utils/function_utils.dart';

class MessageData {
  String? messageText;
  String? link;
  MessageMediaType mediaType;

  MessageData({
    this.messageText,
    this.link,
    required this.mediaType,
  });

  @override
  String toString() {
    return 'MessageData{messageText: $messageText, link: $link, mediaType: $mediaType}';
  }
}
