import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:async_loader/async_loader.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';

import 'department_hours.dart';

class ServerSettings extends StatefulWidget {
  ServerSettings({this.server});
  final Server server;
  @override
  _ServerDetailsState createState() => new _ServerDetailsState();
}

class _ServerDetailsState extends State<ServerSettings> {
  DatabaseHelper _dbHelper;
  ServerApiClient _serverRequest;

  Server _localServer;
  List<Server> listServers = new List<Server>();
  List<Department> userDepartments = new List<Department>();

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  bool _isLoading = false;
  bool _pushEnabled = false;

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;

  String _fcmToken;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _serverRequest = ServerApiClient(httpClient: http.Client());
    _localServer = widget.server;

    _getNotification();
  }

  _getNotification() async {
    var status = await _notificationStatus();
    setState(() {
      _pushEnabled = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    _fcmToken = context.bloc<FcmTokenBloc>().token;
    
    Widget loadingIndicator =
        _isLoading ? new CircularProgressIndicator() : new Container();
    var scaff = new Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        appBar: new AppBar(
          title:
              new Text(widget.server.servername), // new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            /* new Offstage(
                offstage:_isLoading,
                child: new IconButton(
                    icon: new CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      ),onPressed: null,)),  */

            FlatButton(
                shape:
                    CircleBorder(side: BorderSide(color: Colors.transparent)),
                textColor: Colors.white,
                child: _isLoading
                    ? CircularProgressIndicator(
                        backgroundColor: Colors.white,
                      )
                    : Text("Re-Sync"),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _refreshServerData();
                  _initAsyncloader();
                }),
          ],
        ),
        body: new Stack(children: <Widget>[
          new SingleChildScrollView(
            child: new Container(
              decoration: BoxDecoration(color: Colors.white),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(left: 16.00, top: 16.00),
                      child: new Text(
                        "SERVER INFO",
                        textAlign: TextAlign.left,
                        style: new TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 8.00),
                    child: new Text('${_localServer?.url}'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 16.00),
                    child: new Text(
                      "OPERATOR INFO",
                      textAlign: TextAlign.left,
                      style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 8.00),
                    child: Text(
                        '${_localServer?.firstname} ${_localServer?.surname}'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 8.00),
                    child: Text('${_localServer?.operatoremail}'),
                  ),
                  Divider(),
                  ListTile(
                    title: Text("Department Options"),
                    subtitle: Text("Manage department working hours"),
                    trailing: IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(FadeRoute(
                          builder: (BuildContext context) =>
                              new TokenInheritedWidget(
                                  token: _fcmToken,
                                  child: DepartmentHours(
                                    server: _localServer,
                                  )),
                          settings: new RouteSettings(
                            name: AppRoutes.login,
                          ),
                        ));
                      },
                    ),
                  ),
                  Divider(),
                  /*  ListTile(
                      title: Text("Push Notification"),
                      trailing: Switch(
                        value: _pushEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _isLoading = false;
                          });
                          bool status = await _toggleNotification();
                          setState(() {
                            _pushEnabled = status;
                            _isLoading = false;
                          });
                        },
                      )), */
                ],
              ),
            ),
          ),
          Center(child: loadingIndicator),
        ]));

    var _asyncLoader = new AsyncLoader(
      key: _asyncLoaderState,
      initState: () async => await _initAsyncloader(),
      renderLoad: () => new Scaffold(
        body: new Center(child: new CircularProgressIndicator()),
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

  Future<Null> _initAsyncloader() async {
    _isLoading = true;
    //  await _fetchServerDetails();
    await _syncServerData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<Null> _syncServerData() async {
    if (_localServer != null) {
      var user = await _serverRequest.getUserFromServer(_localServer);

      if (user != null) {
        if (mounted) {
          setState(() {
            _localServer.userid = user['id'];
            _localServer.firstname = user['name'];
            _localServer.surname = user['surname'];
            _localServer.operatoremail = user['email'];
            _localServer.job_title = user['job_title'];
            _localServer.all_departments = user['all_departments'];
            _localServer.departments_ids = user['departments_ids'];
          });
        }
      }

      await _dbHelper.upsertServer(_localServer, "id=?", [_localServer.id]);
    }
  }

  void _refreshServerData() async {
    Server server = await _serverRequest.fetchInstallationId(
        _localServer, _fcmToken, "add");

    var twilioEnabled =
        await _serverRequest.isExtensionInstalled(server, "twilio");
    server.twilioInstalled = twilioEnabled;
    await _dbHelper.upsertServer(
        server, "${Server.columns['db_id']} = ?", ['${server.id}']);

    setState(() {
      _localServer = server;
      _isLoading = false;
    });
  }

  Future<bool> _toggleNotification() async {
    return _serverRequest.togglePushNotification(_localServer);
  }

  Future<bool> _notificationStatus() async {
    return _serverRequest.pushNotificationStatus(_localServer);
  }
}
