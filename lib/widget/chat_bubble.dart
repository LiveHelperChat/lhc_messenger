import 'package:flutter/material.dart';
import 'package:livehelp/model/model.dart';
import 'package:intl/intl.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class Bubble extends StatelessWidget {
  Bubble({required this.message});

  final Message message;


  @override
  Widget build(BuildContext context) {
    var dateFormatter = new DateFormat("HH:mm, dd/MM/yy");

    final bg = message.user_id == 0 || (message.is_owner == 2)
        ? Colors.black12
        : message.user_id! > 0
        ? Colors.white
        : Colors.greenAccent;
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
      topLeft:Radius.circular(10.0),
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
                child: Html(
                    data: message.msg,
                    onLinkTap: (url, _, __) {
                      _launchURL(url);
                    }
                  /*data: "<main>${message.msg}</main>",
                  customRender: {
                    "main": (RenderContext ctx, Widget child, attributes, e) {
                      return SelectableLinkify(
                          onOpen: (l) => _launchURL(l.url),
                          text: e.text,
                          style: TextStyle(fontSize: 16));
                    },
                  },*/
                ),
              ),
              // positioned at bottom but object renderer needs it to calculate
              // width of the column
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Text(
                    dateFormatter.format(
                        DateTime.fromMillisecondsSinceEpoch(
                            message.time! * 1000)),
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 10.0,
                    )),
              ),
            ],
          ),
        )
      ],
    );
  }

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

