import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:livehelp/model/model.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubbleCustom extends StatelessWidget {
  ChatBubbleCustom({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    var dateFormatter = new DateFormat("HH:mm, dd/MM/yy");

    final bg = message.user_id == 0 || (message.is_owner == 2)
        ? Colors.grey[100]
        : message.user_id! > 0
        ? Colors.white
        : Colors.blueGrey[200];
    final align = message.user_id == 0 || (message.is_owner == 2)
        ? CrossAxisAlignment.start
        : message.user_id! > 0
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.center;

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
            if (message.msg != null && message.msg!.isNotEmpty) {
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
                  child: Html(
                    data: message.msg,
                    onLinkTap: (url, attributes, element) {
                      _launchURL(url);
                    },
                  ),
                ),
                // positioned at bottom but object renderer needs it to calculate
                // width of the column
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
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
          ),
        )
      ],
    );
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

  _launchURL(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}