import 'dart:convert';

import 'package:flutter/material.dart';
//plugin imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:after_layout/after_layout.dart';

import 'package:livehelp/pages/servers_manage.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/data/database.dart';

import 'package:livehelp/utils/notification_helper.dart';

void main() async {
      runApp(
        MaterialApp(
      title: 'Live Helper Chat',
      theme: new ThemeData(
        primarySwatch:  Colors.indigo,
        scaffoldBackgroundColor: Colors.white70,
      ),
       home:  MyHomePage(title: "Login",)
     )
     );
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  
  State<MyHomePage> createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with AfterLayoutMixin<MyHomePage>, RouteAware {

  final GlobalKey<_MyHomePageState> homePageStateKey =  GlobalKey<_MyHomePageState>();

  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  DatabaseHelper _dbHelper;

  String token="";

  bool isInitialised =false;

  _MyHomePageState();

  @override
  void initState() {
    super.initState();

   // Sqflite.devSetDebugModeOn(true);
   _dbHelper = new DatabaseHelper();

    _firebaseMessaging.configure(
      onBackgroundMessage: NotificationHelper.backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message)async {
        if (mounted && isInitialised) {
          _showNotification(message);
        }
      },
      onLaunch: (Map<String, dynamic> message) {
        // @todo Navigate to proper window on click
        return;
      },
      onResume: (Map<String, dynamic> message) {
        // @todo Navigate to proper window on click
        //_showNotification(message);
       return;
      },
    );

    _firebaseMessaging.onTokenRefresh.listen((String fcmtoken){
        assert(fcmtoken != null);
        setState((){
            token = fcmtoken;
        });
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      // print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String fcmtoken){
      assert(fcmtoken != null);
     // print("Token "+fcmtoken);
     setState((){
      token = fcmtoken;
      });

    });

  }

  @override
  Widget build(BuildContext context) {

    return new Center(
      child: new TokenInheritedWidget(
    token: token,
    child: ServersManage() ),

    );
  }

   _showNotification(Map<String,dynamic> msg) async {
    if(msg['data'].isEmpty) return;
    var data = msg['data'];

    if (data.containsKey("info")) {
         NotificationHelper.showInfoNotification("Yay!", data["info"].toString());
    }

    if (data.containsKey("chat_type")) {
     // check if server exists on this device
     _dbHelper.fetchItem(Server.tableName, "installationid=? and isloggedin=?",[data['server_id'],1])
      .then((server){
        if (server != null) {
            Server srv = new Server.fromMap(server);
            Map<String,dynamic> chat =json.decode(data["chat"].toString());

            if (data['chat_type'].toString() == 'new_msg') {
              NotificationHelper.showNotification(
                  srv, 'new_msg', "New message from " + chat['nick'].toString(),
                  data['msg'].toString());
            }

            // pending chat
            if (data["chat_type"].toString() == "pending" )
            {
              NotificationHelper.showNotification(
                  srv,
                  'pending',
                  "New Chat from "+chat['nick'].toString(),
                  data['msg'].toString()
              );
            }

            if (data["chat_type"].toString() == "unread")
            {
              NotificationHelper.showNotification(
                  srv,'pending',
                  "Unread message from "+chat['nick'].toString(),
                  "");
            }
          }
      });
  }

  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState((){
      isInitialised = true;
    });

  }

}
