// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/utils.dart';

class OperatorItemWidget extends StatelessWidget {
  OperatorItemWidget(
      {Key? key,
      this.server,
      this.chat,
      required this.onMenuSelected,
      required this.menuBuilder})
      : super(key: key);

  final User? chat;
  final Server? server;

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

    //developer.log(jsonEncode(chat.toJson()), name: 'my.app.category');

    return new SizedBox(
        height: 100.0,
        child: new Container(
            padding: const EdgeInsets.only(top: 4.0),
            child: new Container(
                decoration: new BoxDecoration(
                    color: backColor(context),
                    borderRadius: BorderRadius.circular(4.0)),
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Divider(
                      thickness: 2,
                    ),
                    new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new Container(
                          margin: const EdgeInsetsDirectional.only(end: 16.0),
                          width: 40.0,
                          child: new Icon(
                            (chat?.hide_online == 1
                                ? Icons.flash_off
                                : Icons.flash_on),
                            color: chat?.hide_online == 1
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Expanded(
                            child: new Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              new AnimatedDefaultTextStyle(
                                style: styling,
                                duration: kThemeChangeDuration,
                                child: new Text(chat!.name_official!,
                                    textAlign: TextAlign.left,
                                    style: styling.copyWith(
                                        color: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold)),
                              ),
                              new AnimatedDefaultTextStyle(
                                  duration: kThemeChangeDuration,
                                  child: Text(chat!
                                      .last_msg!), // 'last  asd message asd ${chat.user_id ?? "-"}'
                                  textAlign: TextAlign.left,
                                  style: styling.copyWith(
                                    color: Colors.blue.shade400,
                                    fontSize: 14.0,
                                  )),
                            ])),
                        Align(
                          alignment: Alignment.topRight,
                          child: popupMenuBtn,
                        ),
                      ],
                    ),
                    Divider(
                      indent: 40,
                      endIndent: 40,
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
                                  Icons.web,
                                  size: 14,
                                  color: Theme.of(context).primaryColor,
                                ),
                                Text(' ${server!.servername}',
                                    textAlign: TextAlign.left,
                                    style: styling.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold))
                              ],
                            )
                          ],
                        ),
                        Spacer(),
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Icon(
                                Icons.chat,
                                size: 14,
                                color: Colors.green.shade400,
                              ),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                  child: Text(
                                    chat!.active_chats.toString(),
                                    textAlign: TextAlign.end,
                                    style: styling.copyWith(
                                      color: Colors.black87,
                                      fontSize: 14.0,
                                    ),
                                  )),
                              new Icon(
                                Icons.timer,
                                size: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                  child: Text(
                                    chat!.lastactivity_ago!,
                                    textAlign: TextAlign.end,
                                    style: styling.copyWith(
                                      color: Colors.black87,
                                      fontSize: 14.0,
                                    ),
                                  )),
                              new Icon(
                                Icons.home,
                                size: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                              Text(
                                chat!.departments_names!,
                                textAlign: TextAlign.end,
                                style: styling.copyWith(
                                  color: Colors.black87,
                                  fontSize: 14.0,
                                ),
                              )
                            ]),
                      ],
                    ),
                  ],
                ))));
  }

  Color backColor(BuildContext context) {
    if (chat!.has_unread == 1)
      return Colors.yellow.shade300;
    else
      return Theme.of(context).cardColor;
  }
}
