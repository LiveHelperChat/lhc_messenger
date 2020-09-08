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
    var timeFormatter = new DateFormat("HH:mm");
    TextStyle styling = new TextStyle(
      fontFamily: 'Roboto',
    );

    var popupMenuBtn = new PopupMenuButton<ChatItemMenuOption>(
        onSelected: (ChatItemMenuOption result) {
      onMenuSelected(result);
    }, itemBuilder: (BuildContext context) {
      return menuBuilder;
    });

    return new SizedBox(
        height: 160.0,
        child: new Container(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: new Container(
                decoration: new BoxDecoration(
                    color: backColor(context),
                    borderRadius: BorderRadius.circular(4.0)
                ),
                padding: const EdgeInsets.all(8.0),
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new Container(
                          margin:
                          const EdgeInsetsDirectional.only(end: 16.0),
                          width: 40.0,
                          child: new Icon(
                            Icons.person,
                            color: (chat.user_status_front == 0 ? Colors.green.shade400 : (chat.user_status_front  == 2 ? Colors.yellow.shade400 : Colors.red.shade400)),
                          ),
                        ),
                        Expanded(
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
                                      duration: kThemeChangeDuration,
                                      child: Text(chat.country_name ?? ""),
                                      textAlign: TextAlign.left,
                                      style: styling.copyWith(
                                        color: Colors.teal.shade400,
                                        fontSize: 14.0,
                                      )),
                                ])),
                        Align(
                          alignment: Alignment.topRight,
                          child: popupMenuBtn,
                        ),
                      ],
                    ),
                    new Divider(),
                    Expanded(
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: new AnimatedDefaultTextStyle(
                                style: styling,
                                duration: kThemeChangeDuration,
                                child: new Text(chat.ip ?? "",
                                    textAlign: TextAlign.left,
                                    style: styling.copyWith(
                                      color: Colors.black54,
                                      fontSize: 14.0,
                                    )),

                              ),
                            ),
                            Text(
                              "ID: ${chat.id}",
                              textAlign: TextAlign.end,
                              style: styling.copyWith(
                                color: Colors.black87,
                                fontSize: 12.0,
                              ),
                            )
                          ],
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        new Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        Text(
                          ' ${chat.owner ?? "-"}',
                          textAlign: TextAlign.end,
                          style: styling.copyWith(
                            color: Colors.black87,
                            fontSize: 14.0,
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Icon(
                                  Icons.home,
                                  size: 14,
                                  color: Theme.of(context).primaryColor,
                                ),
                                Text(
                                  ' ${chat.department_name ?? ""}',
                                  textAlign: TextAlign.end,
                                  style: styling.copyWith(
                                    color: Colors.black87,
                                    fontSize: 14.0,
                                  ),
                                )
                              ],
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  new Icon(
                                    Icons.web,
                                    size: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Text(' ${server.servername}',
                                      textAlign: TextAlign.left,
                                      style: styling.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                        Spacer(),
                        Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Text(
                                dateFormatter.format(
                                    new DateTime.fromMillisecondsSinceEpoch(
                                        chat.time * 1000)),
                                textAlign: TextAlign.end,
                                style: styling.copyWith(
                                  color: Colors.black87,
                                  fontSize: 12.0,
                                ),
                              ),
                              new Text(
                                timeFormatter.format(
                                    new DateTime.fromMillisecondsSinceEpoch(
                                        chat.time * 1000)),
                                textAlign: TextAlign.end,
                                style: styling.copyWith(
                                  color: Colors.black87,
                                  fontSize: 12.0,
                                ),
                              ),
                            ]),
                      ],
                    ),
                  ],
                )
            )
              )
            );
  }

  Color backColor(BuildContext context){
    if(chat.status == 2) return Colors.red[200];
    if(chat.has_unread_messages == 1)
     return Colors.yellow.shade300;
      else return Theme.of(context).cardColor;
  }
}
