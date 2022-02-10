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
   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  String token = "";
  ServerRepository? serverRepository;

  FcmTokenBloc({@required this.serverRepository}) : super(FcmTokenInitial()) {
    assert(serverRepository != null);
    on<FcmTokenReceive>(_onFcmTokenReceive);
    on<FcmTokenRefresh>(_onFcmTokenRefresh);
    on<OperatorsChatClosedEvent>(_onOperatorsChatClosedEvent);
    on<OperatorsChatOpenedEvent>(_onOperatorsChatOpenedEvent);
    on<ChatOpenedEvent>(_onChatOpenedEvent);
    on<ChatPausedEvent>(_onChatPausedEvent);
    on<ChatClosedEvent>(_onChatClosedEvent);
    on<OnResumeEvent>(_onResumeEvent);
    on<NotificationClick>(_onNotificationClick);
    on<MessageReceivedEvent>(_onMessageReceivedEvent);
    _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging.onBackgroundMessage(LocalNotificationPlugin.backgroundMessageHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      add(MessageReceivedEvent(fcmToken: token, message: message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      add(MessageReceivedEvent(fcmToken: token, message: message));
    });

    _firebaseMessaging.onTokenRefresh.listen((String fcmtoken) {
      token = fcmtoken;
      add(FcmTokenRefresh(fcmToken: fcmtoken));
    });

    _firebaseMessaging.requestPermission(
        sound: true, badge: true, alert: true);

    _firebaseMessaging.getToken().then((String? fcmtoken) {
      assert(fcmtoken != null);
      token = fcmtoken!;
      add(FcmTokenReceive(fcmToken: fcmtoken));
    });

    // instantiated in LocalNotificationPlugin
    notificationPlugin
        .setListenerForLowerVersions(onNotificationInLowerVersions);
    notificationPlugin.setOnNotificationClick(onNotificationClick);
  }

  Future<void> _onFcmTokenReceive(FcmTokenReceive event, Emitter<FcmTokenState> emit) async {
    emit(FcmTokenReceived(token: event.fcmToken!));
  }

   Future<void> _onFcmTokenRefresh(FcmTokenRefresh event, Emitter<FcmTokenState> emit) async {
    emit(FcmTokenReceived(token: event.fcmToken!));
   }

   Future<void> _onOperatorsChatClosedEvent(OperatorsChatClosedEvent event, Emitter<FcmTokenState> emit) async {
     final currentState = state;
    if (currentState is ChatOperatorsOpenedState && currentState.chat?.chat_id == event.chat?.chat_id) {
      emit(ChatOperatorsClosedState(chat: event.chat!, token: token));
     }
   }

   Future<void> _onOperatorsChatOpenedEvent(OperatorsChatOpenedEvent event, Emitter<FcmTokenState> emit) async {
    emit(ChatOperatorsOpenedState(chat: event.chat, token: token));
   }

   Future<void> _onChatOpenedEvent(ChatOpenedEvent event, Emitter<FcmTokenState> emit) async {
    emit(ChatOpenedState(chat: event.chat, token: token));
   }

   Future<void> _onChatPausedEvent(ChatPausedEvent event, Emitter<FcmTokenState> emit) async {
    emit(ChatPausedState(chat: event.chat!, token: token));
   }

   Future<void> _onChatClosedEvent(ChatClosedEvent event, Emitter<FcmTokenState> emit) async {
     final currentState = state;
     if (currentState is ChatOpenedState && currentState.chat?.id == event.chat?.id) {
       emit(ChatClosedState(chat: event.chat!, token: token));
     }
     if (currentState is ChatPausedState && currentState.chat?.id == event.chat?.id) {
       emit(ChatClosedState(chat: event.chat!, token: token));
     }
   }

   Future<void> _onResumeEvent(OnResumeEvent event, Emitter<FcmTokenState> emit) async {
     if (event.message != null) {
       ReceivedNotification? notification =
       await _prepareNotification(event.message!);
       emit(NotificationClicked(notification: notification!));
     }
   }

   Future<void> _onNotificationClick(NotificationClick event, Emitter<FcmTokenState> emit) async {
     if (event.notification != null) {
       emit(NotificationClicked(notification: event.notification!));
     }
   }

   Future<void> _onMessageReceivedEvent(MessageReceivedEvent event, Emitter<FcmTokenState> emit) async {
     final currentState = state;
    if (currentState is ChatOpenedState) {
       emit(currentState.copyWith(
           chat: currentState.chat, token: currentState.token));
       _showNotification(event.message!, openedChat: currentState.chat);
     } else if (currentState is ChatOperatorsOpenedState) {
       emit(currentState.copyWith(
           chat: currentState.chat, token: currentState.token));
       _showNotification(event.message!, openedGroupChat: currentState.chat);
     } else {
       _showNotification(event.message!);
     }
   }


  Future<ReceivedNotification?> _prepareNotification(
      RemoteMessage msg) async {

    var data = msg.data;

    if (data.containsKey("chat_type")) {
      // check if server exists on this device
      var srv = await serverRepository!.fetchItemFromDB(Server.tableName,
          "installationid=? and isloggedin=?", [data['server_id'], 1]);

      if (srv != null) {
        Server server = Server.fromJson(srv);
        Map<String, dynamic> chat = jsonDecode(data["chat"].toString());

        if (data['chat_type'].toString() == 'new_msg') {
          return ReceivedNotification(
              server: server,
              chat: Chat.fromJson(chat),
              type: NotificationType.NEW_MESSAGE,
              title: "New message from " + chat['nick'].toString(),
              body: data['msg'].toString());
        }

        if (data['chat_type'].toString() == 'new_group_msg') {
          return ReceivedNotification(
              server: server,
              gchat: User.fromJson(chat),
              type: NotificationType.NEW_GROUP_MESSAGE,
              title: "New message from " + chat['name_official'].toString(),
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

        if (data["chat_type"].toString() == "subject") {
          return ReceivedNotification(
              server: server,
              chat: Chat.fromJson(chat),
              type: NotificationType.SUBJECT,
              title: "New subject",
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

  _showNotification(RemoteMessage msg, {Chat? openedChat, User? openedGroupChat}) async {

    ReceivedNotification? received = await _prepareNotification(msg);

    if (received != null) {

      if (received.type == NotificationType.NEW_MESSAGE && openedChat != null && openedChat.id == received.chat?.id) return;
      if (received.type == NotificationType.NEW_GROUP_MESSAGE && openedGroupChat != null && openedGroupChat.chat_id == received.gchat?.chat_id) return;

      notificationPlugin.showNotification(received);
    }
  }

  onNotificationInLowerVersions(ReceivedNotification receivedNotification) {
    add(NotificationClick(notification: receivedNotification));
  }

  onNotificationClick(String payload) async {
    if (payload.isNotEmpty) {

      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;

      ReceivedNotification receivedNotification = ReceivedNotification.fromJson(payloadMap);

      add(NotificationClick(notification: receivedNotification));

    }
  }
}
