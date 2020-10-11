import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:async_loader/async_loader.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';

import 'department_hours.dart';

class ServerDetails extends StatefulWidget {
  ServerDetails({this.server});
  final Server server;
  @override
  _ServerDetailsState createState() => new _ServerDetailsState();
}

class _ServerDetailsState extends State<ServerDetails> {
  DatabaseHelper _dbHelper;
  ServerApiClient _serverRequest;

  Server _localServer;
  List<Server> listServers = new List<Server>();
  List<Department> userDepartments = new List<Department>();
  Department _department;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  bool _onlineHoursActive = false;

  bool _isLoading = false;

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;

  String _fcmToken;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _serverRequest = ServerApiClient(httpClient: http.Client());
    _localServer = widget.server;

    // _syncServerData();
  }

  @override
  Widget build(BuildContext context) {
    _fcmToken = context.bloc<FcmTokenBloc>().token;
    // print('$_fcmToken');

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
                child: new Text("Re-Sync"),
                onPressed: () {
                  _isLoading = true;
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
                  )
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
    _isLoading = false;
  }

  Future<Null> _syncServerData() async {
    if (_localServer != null) {
      var user = await _serverRequest.getUserFromServer(_localServer);

      if (user != null) {
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

      await _dbHelper.upsertServer(_localServer, "id=?", [_localServer.id]);

      // fetch departments
      List<Department> listDepts =
          await _serverRequest.getUserDepartments(_localServer);

      if (listDepts is List) {
        setState(() {
          userDepartments = listDepts;
          if (userDepartments.length > 0) {
            _department = userDepartments.elementAt(0);
            _checkActiveHours();
          }
        });
      }
    }
  }

  void _checkActiveHours() {
    setState(() {
      _onlineHoursActive = _department.online_hours_active;
    });
  }

  void _refreshServerData() {
    _serverRequest
        .fetchInstallationId(_localServer, _fcmToken, "add")
        .then((server) {
      _localServer = server;
      _dbHelper.upsertServer(_localServer, "${Server.columns['db_id']} = ?",
          ['${_localServer.id}']);
      setState(() {
        _isLoading = false;
      });
    });
  }
}
