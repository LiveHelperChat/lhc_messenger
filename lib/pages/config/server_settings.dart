// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/utils/utils.dart';

import 'department_hours.dart';

class ServerSettings extends StatefulWidget {
  ServerSettings({this.server});
  final Server? server;
  @override
  _ServerDetailsState createState() => new _ServerDetailsState();
}

class _ServerDetailsState extends State<ServerSettings> {
  Future<dynamic>? _myInitState;

  DatabaseHelper? _dbHelper;
  ServerApiClient? _serverRequest;

  Server? _localServer;
  List<Server> listServers = List<Server>.empty();
  List<Department> userDepartments = List<Department>.empty();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;
  bool _pushEnabled = false;

  ValueChanged<TimeOfDay>? selectTime;

  TimeOfDay? selectedTime;

  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _serverRequest = ServerApiClient(httpClient: http.Client());
    _localServer = widget.server;

    _getNotification();
    _myInitState = _initAsyncloader();
  }

  _getNotification() async {
    var status = await _notificationStatus();
    setState(() {
      _pushEnabled = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    _fcmToken = context.read<FcmTokenBloc>().token;

    Widget loadingIndicator =
        _isLoading ? const CircularProgressIndicator() : Container();
    var scaff = Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        appBar: AppBar(
          title:
              Text(widget.server!.servername!), // new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            /* new Offstage(
                offstage:_isLoading,
                child: new IconButton(
                    icon: new CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      ),onPressed: null,)),  */
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.transparent),
                ), // This replaces `textColor`
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    )
                  : const Text("Re-Sync"),
              onPressed: _isLoading
                  ? null // Disable the button if loading
                  : () {
                      setState(() {
                        _isLoading = true;
                      });
                      _refreshServerData();
                      _initAsyncloader();
                    },
            )
          ],
        ),
        body: Stack(children: <Widget>[
          SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Padding(
                      padding: EdgeInsets.only(left: 16.00, top: 16.00),
                      child: Text(
                        "SERVER INFO",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 8.00),
                    child: Text('${_localServer?.url}'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16.00, top: 16.00),
                    child: Text(
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
                              TokenInheritedWidget(
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
    return FutureBuilder<dynamic>(
        future: _myInitState,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          print(snapshot.hasData);
          print(snapshot.data);
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Something is wrong'),
              ),
            );
          } else if (snapshot.hasData) {
            return scaff;
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        });
  }

  Future<dynamic> _initAsyncloader() async {
    print("_initAsyncloader start");
    _isLoading = true;
    //  await _fetchServerDetails();
    await _syncServerData();
    setState(() {
      _isLoading = false;
      print("_isLoading setState false");
    });
    return Future.value("complete");
  }

  Future<void> _syncServerData() async {
    print("_syncServerData function");
    if (_localServer != null) {
      var user = await _serverRequest!.getUserFromServer(_localServer!);
      print("_localServer function");
      if (mounted) {
        setState(() {
          _localServer!.userid = user['id'];
          _localServer!.firstname = user['name'];
          _localServer!.surname = user['surname'];
          _localServer!.operatoremail = user['email'];
          _localServer!.job_title = user['job_title'];
          _localServer!.all_departments = user['all_departments'];
          _localServer!.departments_ids = user['departments_ids'];
        });
      }

      await _dbHelper!.upsertServer(_localServer!, "id=?", [_localServer!.id]);
    }
  }

  void _refreshServerData() async {
    Server server = await _serverRequest!
        .fetchInstallationId(_localServer!, _fcmToken!, "add");

    var twilioEnabled = await _serverRequest!.isExtensionInstalled(server, "twilio");
    server.twilioInstalled = twilioEnabled;

    var fbEnabled = await _serverRequest!.isExtensionInstalled(server, "fbmessenger");
    server.fbInstalled = fbEnabled;


    await _dbHelper!.upsertServer(
        server, "${Server.columns['db_id']} = ?", ['${server.id}']);

    setState(() {
      _localServer = server;
      _isLoading = false;
    });
  }

  // Future<bool> _toggleNotification() async {
  //   return _serverRequest!.togglePushNotification(_localServer!);
  // }

  Future<bool> _notificationStatus() async {
    return _serverRequest!.pushNotificationStatus(_localServer!);
  }
}
