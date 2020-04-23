import 'package:flutter/material.dart';
import 'package:livehelp/model/message.dart';
import 'package:intl/intl.dart';

class Bubble extends StatelessWidget {
  Bubble({this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    var dateFormatter = new DateFormat("HH:mm, dd/MM/yy");
    TextStyle styling = new TextStyle(
      fontFamily: 'Roboto',
    );
    final bg = message.user_id == 0
        ? Theme.of(context).primaryColorLight
        : message.user_id > 0 ? Colors.white : Colors.greenAccent;
    final align = message.user_id == 0
        ? CrossAxisAlignment.start
        : message.user_id > 0
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center;

    final radius = message.user_id == 0
        ? const BorderRadius.only(
            topRight: const Radius.circular(10.0),
            bottomLeft: const Radius.circular(10.0),
            bottomRight: const Radius.circular(10.0),
          )
        : message.user_id > 0
            ? const BorderRadius.only(
                topLeft: const Radius.circular(10.0),
                bottomLeft: const Radius.circular(10.0),
                bottomRight: const Radius.circular(10.0),
              )
            : const BorderRadius.only(
                topRight: const Radius.circular(10.0),
                bottomRight: const Radius.circular(10.0),
                topLeft: const Radius.circular(10.0),
                bottomLeft: const Radius.circular(10.0),
              );

    return new Column(
      crossAxisAlignment: align,
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: new Text(message.name_support),
        ),
        new Container(
          constraints: const BoxConstraints(minWidth: 50.0),
          margin: const EdgeInsets.all(3.0),
          padding: const EdgeInsets.all(8.0),
          decoration: new BoxDecoration(
            boxShadow: [
              new BoxShadow(
                  blurRadius: .5,
                  spreadRadius: 1.0,
                  color: Colors.black.withOpacity(.12))
            ],
            color: bg,
            borderRadius: radius,
          ),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: new SelectableText(
                  message.msg,
                  textAlign: TextAlign.left,
                ),
              ), // positioned at bottom but object renderer needs it to calculate
              // width of the column
              new Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: new Text(
                    dateFormatter.format(
                        new DateTime.fromMillisecondsSinceEpoch(
                            message.time * 1000)),
                    style: new TextStyle(
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
}
