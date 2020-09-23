import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:async_loader/async_loader.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/department.dart';
import 'package:livehelp/services/server_requests.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';

class ServerSettings extends StatefulWidget {
  ServerSettings({@required this.server});
  final Server server;
  @override
  _ServerSettingsState createState() => new _ServerSettingsState();
}

class _ServerSettingsState extends State<ServerSettings> {
  DatabaseHelper _dbHelper;
  ServerRequest _serverRequest;

  Server _localServer;
  List<Server> listServers = new List<Server>();
  List<Department> userDepartments = new List<Department>();
  Department _department;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  bool _onlineHoursActive = false;
  bool _sundayHoursActive = false;
  bool _mondayHoursActive = false;
  bool _tuesdayHoursActive = false;
  bool _wednesdayHoursActive = false;
  bool _thursdayHoursActive = false;
  bool _fridayHoursActive = false;
  bool _saturdayHoursActive = false;

  bool _isLoading = false;

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;

  String _fcmToken;

  @override
  void initState() {
    super.initState();
    _dbHelper = new DatabaseHelper();
    _serverRequest = new ServerRequest();
    _localServer = widget.server;

    /*
    if(widget.server == null)
      ()async=>await  _syncServerData();
    else {

      listServers.add(_localServer);
    }*/
  }

  /*
    new Theme(
      data: Theme.of(context).copyWith(
      canvasColor: Colors.blue.shade400,
      ),
      child: new DropdownButton(
      hint: new Text(
      "Select Server",
      style: new TextStyle(color: Colors.white),
      ),
      value: _localServer,
      items: listServers.map((srver) {
      return new DropdownMenuItem(
      value: srver,
      child: new Text(
      '${srver?.servername}',
      style: new TextStyle(color: Colors.white),
      ),
      );
      }).toList(),
      onChanged: _onServerListChanged), )
   */

  @override
  Widget build(BuildContext context) {
    final tokenInherited = TokenInheritedWidget.of(context);
    _fcmToken = tokenInherited?.token;

    Widget loadingIndicator =
        _isLoading ? new CircularProgressIndicator() : new Container();
    var scaff = new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title:
              new Text(widget.server.servername), // new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[],
        ),
        body: new Stack(children: <Widget>[
          new SingleChildScrollView(
            child: new Container(
              margin: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    title: new Text("Sound"),
                    trailing: new Checkbox(
                      value: _localServer.soundnotify == 1,
                      onChanged: (val) {
                        setState(() {
                          _localServer.soundnotify = val ? 1 : 0;
                        });
                        saveSetting(_localServer);
                      },
                    ),
                  ),
                  new ListTile(
                    title: new Text("Vibrate"),
                    trailing: new Checkbox(
                      value: _localServer.vibrate == 1,
                      onChanged: (val) {
                        setState(() {
                          _localServer.vibrate = val ? 1 : 0;
                        });
                        saveSetting(_localServer);
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          new Center(child: loadingIndicator),
        ]));

    var _asyncLoader = new AsyncLoader(
      key: _asyncLoaderState,
      initState: () {
        return null;
      },
      renderLoad: () => new Scaffold(
        body: Center(child: new CircularProgressIndicator()),
      ),
      renderError: ([error]) => new Scaffold(
        body: new Center(
          child: new Text('Something is wrong'),
        ),
      ),
      renderSuccess: ({data}) {
        return scaff;
      },
    );

    return _asyncLoader;
  }

  Future<Null> saveSetting(Server srvr) async {
    await _dbHelper
        .upsertServer(srvr, "${Server.columns['db_id']} = ?", [srvr.id]);
  }
}
