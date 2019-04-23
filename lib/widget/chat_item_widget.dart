import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/utils/enum_menu_options.dart';

class ChatItemWidget extends StatelessWidget {
  ChatItemWidget(
      {Key key,
      this.server,
      this.chat,
      @required this.onMenuSelected,
      @required this.menuBuilder})
      : super(key: key);

  final Chat chat;
  final Server server;

  final ValueChanged<ChatItemMenuOption> onMenuSelected;


  final List<PopupMenuEntry<ChatItemMenuOption>>
      menuBuilder; // for populating the menu

  @override
  Widget build(BuildContext context) {
    var dateFormatter = new DateFormat("dd/MM/yy");
    var timeFormatter =  new DateFormat("HH:mm");
    TextStyle styling = new TextStyle(
      fontFamily: 'Roboto',
    );

// This menu button widget updates a _selection field (of type WhyFarther,
// not shown here).
    var popupMenuBtn = new PopupMenuButton<ChatItemMenuOption>(
        onSelected: (ChatItemMenuOption result) {
      onMenuSelected(result);
    }, itemBuilder: (BuildContext context) {
      return menuBuilder;
    });

    return new SizedBox(
        height: 200.0,
        child: new Container(

            padding: const EdgeInsets.all(4.0),
            child: new Card(
                color: Theme.of(context).cardColor,
                child: new Container(
                    decoration: new BoxDecoration(
                      color:chat.has_unread_messages == 1 ? Theme.of(context).primaryColorLight : Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Container(
                              margin:
                                  const EdgeInsetsDirectional.only(end: 16.0),
                              width: 40.0,
                              child: new Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            new Expanded(
                                child: new Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                  new AnimatedDefaultTextStyle(
                                    style: styling,
                                    duration: kThemeChangeDuration,
                                    child: new Text(chat.nick,
                                        textAlign: TextAlign.left,
                                        style: styling.copyWith(
                                            color: Colors.black,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  new AnimatedDefaultTextStyle(
                                    style: styling,
                                    duration: kThemeChangeDuration,
                                    child: new Text(chat.ip??"",
                                        textAlign: TextAlign.left,
                                        style: styling.copyWith(
                                          color: Colors.grey,
                                          fontSize: 14.0,
                                        )),
                                  )
                                ])),

                            popupMenuBtn,


                          ],
                        ),
                        new Text(
                            'Department: ${chat.department_name ?? ""}',
                            textAlign: TextAlign.left,
                            style: styling.copyWith(color: Colors.black)),
                        new Divider(),
                        new Expanded(
                            child: new Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Expanded(
                              child: new Text(chat.country_name??""),
                            ),

                            new Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  new Text(
                                  timeFormatter.format(
                                      new DateTime.fromMillisecondsSinceEpoch(
                                          chat.time * 1000)),
                                  textAlign: TextAlign.end,
                                  style: styling.copyWith(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                                  new Text(
                                    dateFormatter.format(
                                        new DateTime.fromMillisecondsSinceEpoch(
                                            chat.time * 1000)),
                                    textAlign: TextAlign.end,
                                    style: styling.copyWith(
                                      color: Colors.grey,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  new Align(
                                      alignment: Alignment.bottomLeft,
                                      child: new Text(
                                        "ID: ${chat.id}",
                                        textAlign: TextAlign.end,
                                        style: styling.copyWith(
                                          color: Colors.grey,
                                          fontSize: 12.0,
                                        ),
                                      ))
                                ]),

                          ],
                        )),
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Expanded(
                              child: new Text('SERVER: ${server.servername}',
                                  textAlign: TextAlign.left,
                                  style: styling.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    )))));
  }
}
