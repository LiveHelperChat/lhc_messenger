import 'package:flutter/material.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/utils.dart';

class ServerItemWidget extends StatelessWidget {
  ServerItemWidget(
      {Key? key,
      this.server,
      required this.onMenuSelected,
      required this.menuBuilder})
      : super(key: key);

  final Server? server;

  final ValueChanged<ServerItemMenuOption> onMenuSelected;

  final List<PopupMenuEntry<ServerItemMenuOption>>
      menuBuilder; // for populating the menu

  @override
  Widget build(BuildContext context) {
    var labelStyle = TextStyle(fontSize: 12, color: Colors.grey);

    return new SizedBox(
        height: 150.0,
        child: new Container(
            padding: const EdgeInsets.all(4.0),
            child: new Card(
                color: Theme.of(context).cardColor,
                child: new Container(
                    decoration: new BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(4.0)),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          server!.servername!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.00,
                          ),
                        ),
                        server!.isLoggedIn
                            ? Text("Logged In",
                                style: TextStyle(color: Colors.green))
                            : Text("Logged Out",
                                style: TextStyle(color: Colors.redAccent)),
                        Divider(),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.00),
                          child: Text(
                            "${server!.url}",
                            style: labelStyle,
                            softWrap: true,
                            maxLines: 2,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text("${server!.username}"),
                                  Text(
                                    "username",
                                    style: labelStyle,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                      "${server!.firstname} ${server!.surname}"),
                                  Text("operator name", style: labelStyle),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )))));
  }
}
