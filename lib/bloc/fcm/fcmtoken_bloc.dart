import 'dart:async';
import 'dart:convert';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:meta/meta.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:livehelp/utils/notification_helper.dart';

part 'fcmtoken_event.dart';
part 'fcmtoken_state.dart';

class FcmTokenBloc extends Bloc<FcmTokenEvent, FcmTokenState> {
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String token = "";
  ServerRepository serverRepository;

  FcmTokenBloc({@required this.serverRepository}) : super(FcmTokenInitial()) {
    assert(serverRepository != null);

    _initFCM();
  }
  void _initFCM(){

    _firebaseMessaging.configure(
      onBackgroundMessage: NotificationHelper.backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        _showNotification(message);
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

    _firebaseMessaging.onTokenRefresh.listen((String fcmtoken) {
      this.token = fcmtoken;
      add(FcmTokenRefresh(fcmToken: fcmtoken));
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      // print("Settings registered: $settings");
    });

    _firebaseMessaging.getToken().then((String fcmtoken) {
      assert(fcmtoken != null);
      this.token = fcmtoken;
      add(FcmTokenReceive(fcmToken: fcmtoken));
    });
  }

  @override
  Stream<FcmTokenState> mapEventToState(
    FcmTokenEvent event,
  ) async* {
    if (event is FcmTokenReceive) {
      yield FcmTokenReceived(token: event.fcmToken);
    }
    if (event is FcmTokenRefresh) {
      yield FcmTokenReceived(token: event.fcmToken);
    }
  }

  _showNotification(Map<String, dynamic> msg) async {
    if (msg['data'].isEmpty) return;
    var data = msg['data'];

    if (data.containsKey("info")) {
      NotificationHelper.showInfoNotification("Yay!", data["info"].toString());
    }

    if (data.containsKey("chat_type")) {
      // check if server exists on this device
      serverRepository.fetchItemFromDB(
          Server.tableName,
          "installationid=? and isloggedin=?",
          [data['server_id'], 1]).then((server) {
        if (server != null) {
          Server srv = new Server.fromMap(server);
          Map<String, dynamic> chat = json.decode(data["chat"].toString());

          if (data['chat_type'].toString() == 'new_msg') {
            NotificationHelper.showNotification(
                srv,
                'new_msg',
                "New message from " + chat['nick'].toString(),
                data['msg'].toString());
          }

          // pending chat
          if (data["chat_type"].toString() == "pending") {
            NotificationHelper.showNotification(
                srv,
                'pending',
                "New Chat from " + chat['nick'].toString(),
                data['msg'].toString());
          }

          if (data["chat_type"].toString() == "unread") {
            NotificationHelper.showNotification(srv, 'pending',
                "Unread message from " + chat['nick'].toString(), "");
          }
        }
      });
    }
  }
}
