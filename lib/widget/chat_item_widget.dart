import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/utils.dart';

class ChatItemWidget extends StatelessWidget {
  ChatItemWidget(
      {Key? key,
      required this.server,
      required this.chat,
      required this.onMenuSelected,
      required this.menuBuilder})
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

    List<Widget> subjects = [];

    if (chat.subject_front != "") {
      List<String> subjectsList = chat.subject_front!.split("||");
      subjectsList.forEach((element) {
        subjects.add(Container(
          color: Colors.transparent,
          margin: const EdgeInsets.only(
            right: 4.0,
          ),
          child: new Container(
              decoration: new BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(5.0),
                    topRight: const Radius.circular(5.0),
                    bottomRight: const Radius.circular(5.0),
                    bottomLeft: const Radius.circular(5.0),
                  )),
              child: Container(
                  margin: const EdgeInsets.all(4.0),
                  child: new Center(
                    child: new Text(element,
                        style: TextStyle(fontSize: 12.0, color: Colors.white)),
                  ))),
        ));
      });
    }

    if (chat.aicon_front != "") {
      List<String> aicons = chat.aicon_front!.split("||");
      aicons.forEach((element) {
        subjects.add(Container(
          color: Colors.transparent,
          margin: const EdgeInsets.only(
            right: 4.0,
          ),
          child: new Container(
              decoration: new BoxDecoration(
                  color: Colors.grey,
                  borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(5.0),
                    topRight: const Radius.circular(5.0),
                    bottomRight: const Radius.circular(5.0),
                    bottomLeft: const Radius.circular(5.0),
                  )),
              child: Container(
                  margin: const EdgeInsets.all(4.0),
                  child: new Center(
                    child: new Text(element,
                        style: TextStyle(fontSize: 12.0, color: Colors.white)),
                  ))),
        ));
      });
    }

    return SizedBox(
        height: 160.0,
        child: Container(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
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
                            Icons.person,
                            color: (chat.user_status_front == 0
                                ? Colors.green.shade400
                                : (chat.user_status_front == 2
                                    ? Colors.yellow.shade400
                                    : Colors.red.shade400)),
                          ),
                        ),
                        Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              AnimatedDefaultTextStyle(
                                style: styling,
                                duration: kThemeChangeDuration,
                                child: Text(chat.nick ?? "",
                                    textAlign: TextAlign.left,
                                    style: styling.copyWith(
                                        color: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Row(children: <Widget>[
                                AnimatedDefaultTextStyle(
                                    duration: kThemeChangeDuration,
                                    child: Text(chat.country_name ?? ""),
                                    textAlign: TextAlign.left,
                                    style: styling.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 14.0,
                                    )),
                                new Expanded(
                                  child: new Container(
                                    height: 20.0,
                                    child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: subjects),
                                  ),
                                )
                              ]),
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
                    Expanded(
                        child: Row(
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
                          (chat.status == 5 && chat.user_id == null
                              ? Icons.android
                              : Icons.people),
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
                              child: Row(
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
                                        chat.time! * 1000)),
                                textAlign: TextAlign.end,
                                style: styling.copyWith(
                                  color: Colors.black87,
                                  fontSize: 12.0,
                                ),
                              ),
                              new Text(
                                timeFormatter.format(
                                    new DateTime.fromMillisecondsSinceEpoch(
                                        chat.time! * 1000)),
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
                ))));
  }

  Color? backColor(BuildContext context) {
    if (chat.status == 2) return Colors.red[50];
    if (chat.has_unread_messages == 1)
      return Colors.yellow.shade300;
    else
      return Theme.of(context).cardColor;
  }
}
