import 'dart:async';
import 'dart:convert';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:meta/meta.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  void _initFCM() {
    _firebaseMessaging.configure(
      onBackgroundMessage: LocalNotificationPlugin.backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        this.add(MessageReceivedEvent(fcmToken: token, message: message));
      },
      onLaunch: (Map<String, dynamic> message) {
        // @todo Navigate to proper window on click
        return;
      },
      onResume: (Map<String, dynamic> message) {
        this.add(OnResumeEvent(message: message));
        return;
      },
    );

    _firebaseMessaging.onTokenRefresh.listen((String fcmtoken) {
      this.token = fcmtoken;
      this.add(FcmTokenRefresh(fcmToken: fcmtoken));
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {});

    _firebaseMessaging.getToken().then((String fcmtoken) {
      assert(fcmtoken != null);
      this.token = fcmtoken;
      add(FcmTokenReceive(fcmToken: fcmtoken));
    });

    // instantiated in LocalNotificationPlugin
    notificationPlugin
        .setListenerForLowerVersions(onNotificationInLowerVersions);
    notificationPlugin.setOnNotificationClick(onNotificationClick);
  }

  @override
  Stream<FcmTokenState> mapEventToState(
    FcmTokenEvent event,
  ) async* {
    final currentState = state;
    if (event is FcmTokenReceive) {
      yield FcmTokenReceived(token: event.fcmToken);
    } else if (event is FcmTokenRefresh) {
      yield FcmTokenReceived(token: event.fcmToken);
    } else if (event is ChatOpenedEvent) {
      yield ChatOpenedState(chat: event.chat, token: token);
    } else if (event is ChatPausedEvent) {
      yield ChatPausedState(chat: event.chat, token: token);
    } else if (event is ChatClosedEvent) {
      //Don't yield closedstate if previous chat and current chat are not the same.
      // Popping a chat page doesn't call dispose right away.
      // yielding a closed state later affects a newly opened chatstate
      if (currentState is ChatOpenedState && currentState.chat == event.chat) {
        yield ChatClosedState(chat: event.chat, token: token);
      }
      if (currentState is ChatPausedState && currentState.chat == event.chat) {
        yield ChatClosedState(chat: event.chat, token: token);
      }
    } else if (event is OnResumeEvent) {
      if (event.message != null) {
        ReceivedNotification notification =
            await _prepareNotification(event.message);
        yield NotificationClicked(notification: notification);
      }
    } else if (event is NotificationClick) {
      if (event.notification != null) {
        yield NotificationClicked(notification: event.notification);
      }
    } else if (event is MessageReceivedEvent) {
      if (currentState is ChatOpenedState) {
        yield currentState.copyWith(
            chat: currentState.chat, token: currentState.token);
        _showNotification(event.message, openedChat: currentState.chat);
      } else {
        _showNotification(event.message);
      }
    }
  }

  Future<ReceivedNotification> _prepareNotification(
      Map<String, dynamic> msg) async {
    if (msg['data'].isEmpty) return null;
    var data = msg['data'];

    if (data.containsKey("chat_type")) {
      // check if server exists on this device
      var srv = await serverRepository.fetchItemFromDB(Server.tableName,
          "installationid=? and isloggedin=?", [data['server_id'], 1]);

      if (srv != null) {
        Server server = new Server.fromJson(srv);
        Map<String, dynamic> chat = jsonDecode(data["chat"].toString());

        if (data['chat_type'].toString() == 'new_msg') {
          return ReceivedNotification(
              server: server,
              chat: Chat.fromJson(chat),
              type: NotificationType.NEW_MESSAGE,
              title: "New message from " + chat['nick'].toString(),
              body: data['msg'].toString());
        }

        // pending chat
        if (data["chat_type"].toString() == "pending") {
          return ReceivedNotification(
              server: server,
              chat: Chat.fromJson(chat),
              type: NotificationType.PENDING,
              title: "New Chat from " + chat['nick'].toString(),
              body: data['msg'].toString());
        }

        if (data["chat_type"].toString() == "unread") {
          return ReceivedNotification(
              server: server,
              chat: Chat.fromJson(chat),
              type: NotificationType.PENDING,
              title: "Unread message from " + chat['nick'].toString(),
              body: "");
        }
      }
    }
    return null;
  }

  _showNotification(Map<String, dynamic> msg, {Chat openedChat}) async {
    if (msg['data'].isEmpty) return null;

    ReceivedNotification received = await _prepareNotification(msg);

    if (received != null) {
      bool isChatOpened =
          openedChat != null && openedChat.id == received.chat?.id;

      if (received.type == NotificationType.NEW_MESSAGE && isChatOpened) return;

      notificationPlugin.showNotification(received);
    }
  }

  onNotificationInLowerVersions(ReceivedNotification receivedNotification) {
    if (receivedNotification != null) {
      add(NotificationClick(notification: receivedNotification));
    }
  }

  onNotificationClick(String payload) {
    if (payload.isNotEmpty) {
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;

      ReceivedNotification receivedNotification =
          ReceivedNotification.fromJson(payloadMap);
      add(NotificationClick(notification: receivedNotification));
    }
  }
}
