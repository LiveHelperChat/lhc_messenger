// ignore_for_file: must_be_immutable


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:livehelp/widget/file_message_widget.dart';
import 'package:livehelp/widget/image_message_widget.dart';
import 'package:livehelp/widget/my_audio_message_widget.dart';

//class which return the widget depending on message type, like AudioMessageWidget for audio message type
class ChatBubbleExperiment extends StatelessWidget {
  ChatBubbleExperiment({required this.server,required this.chat,required this.message,});

  final Server? server;
  final Chat? chat;
  final Message message;
  MessageMediaType? messageMediaType;
  String link='';
  @override
  Widget build(BuildContext context) {
    if (messageMediaType == null) {
      messageMediaType = FunctionUtils.determineMessageMediaType(message.msg);

    }
    link=FunctionUtils.extractMediaLink(message.msg)??'';
    final messageDateTime =
        DateTime.fromMillisecondsSinceEpoch(message.time! * 1000);
    final now = DateTime.now();

    final String formattedTimestamp;
    if (DateUtils.isSameDay(messageDateTime, now)) {
      formattedTimestamp = DateFormat('HH:mm').format(messageDateTime);
    } else if (messageDateTime.year == now.year) {
      formattedTimestamp =
          DateFormat('HH:mm, dd/MM').format(messageDateTime);
    } else {
      formattedTimestamp =
          DateFormat('HH:mm, dd/MM/yy').format(messageDateTime);
    }

    final bg = message.user_id == 0 || (message.is_owner == 2)
        ? Colors.grey[300]
        : message.user_id! > 0
        ? Colors.blue[100]
        : Colors.grey[100];

    final del_st = message.user_id == 0 || (message.is_owner == 2)
        ? "0"
        : message.del_st;

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
        GestureDetector(
          onLongPress: () {
            if (messageMediaType == MessageMediaType.Text || message.msg != null) {
              _showCopyDialog(context, message.msg ?? "");
            }
          },
          child: Container(
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
                  child: messageMediaType == MessageMediaType.Text
                      ? Html(data: message.msg,)
                      : messageMediaType == MessageMediaType.Audio
                      ? MyAudioMessageWidget(
                    message: message, link: link,
                  )
                      : messageMediaType == MessageMediaType.Image
                      ? ImageMessageWidget(
                    message: message, link: link,
                  )
                      : messageMediaType == MessageMediaType.File
                      ? FileMessageWidget(
                    key: ValueKey(message.id.toString()),
                    message: message,
                  )
                      : Html(data: message.msg),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formattedTimestamp,
                            style: const TextStyle(color: Colors.black38, fontSize: 10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: statusChecks(del_st),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget statusChecks(String? s) {
    final st = int.tryParse(s ?? '');
    const sz = 14.0;
    switch (st) {
      case 1:
        return const Icon(Icons.done, size: sz, color: Colors.grey);
      case 2:
        return const Icon(Icons.done_all, size: sz, color: Colors.grey);
      case 3:
        return const Icon(Icons.done_all, size: sz, color: Colors.blue);
      default:
        return const Text('', style: TextStyle(color: Colors.black38, fontSize: 10));
    }
  }

  void _showCopyDialog(BuildContext context, String text) {
    // Strip HTML tags for clean copying
    String cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Message Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.copy),
                title: Text("Copy Text"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: cleanText));
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Message copied to clipboard"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}