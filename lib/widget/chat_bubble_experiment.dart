// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:livehelp/widget/file_message_widget.dart';
import 'package:livehelp/widget/image_message_widget.dart';
import 'package:livehelp/widget/my_audio_message_widget.dart';
import 'package:flutter/services.dart';

//class which returns the widget depending on message type, like AudioMessageWidget for audio message type
class ChatBubbleExperiment extends StatelessWidget {
  ChatBubbleExperiment({required this.server, required this.chat, required this.message});

  final Server? server;
  final Chat? chat;
  final Message message;
  MessageMediaType? messageMediaType;
  String link = '';

  @override
  Widget build(BuildContext context) {

    if (messageMediaType == null) {
      messageMediaType = FunctionUtils.determineMessageMediaType(message.msg);
    }
    link = FunctionUtils.extractMediaLink(message.msg) ?? '';
    var dateFormatter = DateFormat("HH:mm, dd/MM/yy");

    final bg = message.user_id == 0 || (message.is_owner == 2)
        ? Colors.black12
        : message.user_id! > 0
        ? Colors.white
        : Colors.greenAccent;

    final align = message.user_id == 0 || (message.is_owner == 2)
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;

    final radius = message.user_id == 0 || (message.is_owner == 2)
        ? const BorderRadius.only(
      topRight: Radius.circular(10.0),
      bottomLeft: Radius.circular(10.0),
      bottomRight: Radius.circular(10.0),
    )
        : message.user_id! > 0
        ? const BorderRadius.only(
      topLeft: Radius.circular(10.0),
      bottomLeft: Radius.circular(10.0),
      bottomRight: Radius.circular(10.0),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(10.0),
      bottomRight: Radius.circular(10.0),
      topLeft: Radius.circular(10.0),
      bottomLeft: Radius.circular(10.0),
    );

    final margin = message.user_id == 0 || (message.is_owner == 2)
        ? const EdgeInsets.only(right: 40.0)
        : const EdgeInsets.only(left: 40.0);

    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(message.name_support!),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 50.0),
          margin: margin,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                child: _buildMessageContent(context),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(
                      message.time! * 1000)),
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // For regular text messages, use a custom approach to make HTML content selectable
    if (messageMediaType == MessageMediaType.Text) {
      return GestureDetector(
        onLongPress: () {
          _showCopyDialog(context, message.msg);
        },
        child: Html(
          data: message.msg ?? '',
        ),
      );
    } else if (messageMediaType == MessageMediaType.Audio) {
      return MyAudioMessageWidget(
        message: message,
        link: link,
      );
    } else if (messageMediaType == MessageMediaType.Image) {
      return ImageMessageWidget(
        message: message,
        link: link,
      );
    } else if (messageMediaType == MessageMediaType.File) {
      return FileMessageWidget(
        key: ValueKey(message.id.toString()),
        message: message,
      );
    } else {
      // For other types of messages that don't have dedicated widgets
      return GestureDetector(
        onLongPress: () {
          _showCopyDialog(context, message.msg);
        },
        child: Html(
          data: message.msg ?? '',
        ),
      );
    }
  }

  void _showCopyDialog(String? htmlMessage) {
    final String plainText = FunctionUtils.stripHtmlTags(htmlMessage ?? '');

    showDialog(
      context: globalContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message Text'),
          content: SingleChildScrollView(
            child: SelectableText(plainText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: plainText));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  // Use the provided BuildContext for showing dialog
  void _showCopyDialog(BuildContext context, String? htmlMessage) {
    final String plainText = FunctionUtils.stripHtmlTags(htmlMessage ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Message Text'),
          content: SingleChildScrollView(
            child: SelectableText(plainText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: plainText));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }
}