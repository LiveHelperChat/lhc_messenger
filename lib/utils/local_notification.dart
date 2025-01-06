import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

import 'package:livehelp/model/model.dart';

class LocalNotificationPlugin {
  //
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  final BehaviorSubject<ReceivedNotification>
      didReceivedLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  var initializationSettings;

  LocalNotificationPlugin._() {
    init();
  }

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isIOS) {
      _requestIOSPermission();
    } else {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'com.livehelperchat.chat.channel.NEWCHAT', // id
        'New chat (background)', // title
        description: 'New chat notifications while app is in the background',
        // description
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      const AndroidNotificationChannel channelMessage =
          AndroidNotificationChannel(
        'com.livehelperchat.chat.channel.NEWMESSAGE', // id
        'New messages (background)', // title
        description:
            'New chat messages notifications while app is in the background',
        // description
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      const AndroidNotificationChannel channelGroupMessage =
          AndroidNotificationChannel(
        'com.livehelperchat.chat.channel.NEWGROUPMESSAGE', // id
        'New group messages (background)', // title
        description:
            'New group messages notifications while app is in the background',
        // description
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      const AndroidNotificationChannel subjectMessage =
          AndroidNotificationChannel(
        'com.livehelperchat.chat.channel.SUBJECT', // id
        'New subject', // title
        description: 'New subject notifications while app is in the background',
        // description
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      flutterLocalNotificationsPlugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      flutterLocalNotificationsPlugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channelMessage);

      flutterLocalNotificationsPlugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channelGroupMessage);

      flutterLocalNotificationsPlugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(subjectMessage);
    }

    initializePlatformSpecifics();
  }

  // default channel id - same as in AndroidManifest.xml file
  static final NotificationChannel channelDefault = NotificationChannel(
      id: "com.livehelperchat.chat.channel.lhcmessenger_notification",
      name: "Default",
      description: "Default notifications while app is open",
      number: 1001);

  static final NotificationChannel silentChannel = NotificationChannel(
      id: "com.livehelperchat.chat.channel.lhc_silent_channel",
      name: "Default",
      description: "Default notifications while app is open",
      number: 1001);

  static final NotificationChannel channelNewChat = NotificationChannel(
      id: "com.livehelperchat.chat.channel.NEWCHAT",
      name: "New chat (open app)",
      description: "New chat notifications while app is open",
      number: 1111);

  static final NotificationChannel channelNewMsg = NotificationChannel(
      id: "com.livehelperchat.chat.channel.NEWMESSAGE",
      name: "New messages (open app)",
      description: "New messages notifications while app is open",
      number: 2222);

  static final NotificationChannel channelUnreadMsg = NotificationChannel(
      id: "com.livehelperchat.chat.channel.UNREADMSG",
      name: "Unread messages (open app)",
      description: "Unread messages notifications while app is open",
      number: 3333);

  static final NotificationChannel channelNewGroupMsg = NotificationChannel(
      id: "com.livehelperchat.chat.channel.NEWGROUPMESSAGE",
      name: "New group messages (open app)",
      description: "New group messages notifications while app is open",
      number: 4444);

  static final NotificationChannel channelSubject = NotificationChannel(
      id: "com.livehelperchat.chat.channel.SUBJECT",
      name: "New subject (open app)",
      description: "New subject while app is open",
      number: 5555);

  initializePlatformSpecifics() {
    var initializationSettingsAndroid = AndroidInitializationSettings('icon');
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        ReceivedNotification receivedNotification = ReceivedNotification(
            id: id, title: title!, body: body!, payload: payload);
        didReceivedLocalNotificationSubject.add(receivedNotification);
      },
    );
    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  _requestIOSPermission() {
    flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: false,
          badge: true,
          sound: true,
        );
  }

  void _createDefaultNotificationChannel() async {
    //Create Default Android channel
    var defaultAndroidNotificationChannel = AndroidNotificationChannel(
      channelDefault.id,
      channelDefault.name,
      description: channelDefault.description,
    );
    await flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultAndroidNotificationChannel);
  }

  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceivedLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin?.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      onNotificationClick(notificationResponse.payload);
    });

    _createDefaultNotificationChannel();
  }

  showNotification(ReceivedNotification notification) async {
    NotificationChannel? channel;
    //String title="";
    switch (notification.type) {
      case NotificationType.NEW_MESSAGE:
        channel = channelNewMsg;
        break;
      case NotificationType.NEW_GROUP_MESSAGE:
        channel = channelNewGroupMsg;
        break;
      case NotificationType.PENDING:
        channel = channelNewChat;
        break;
      case NotificationType.UNREAD:
        channel = channelUnreadMsg;
        break;
      case NotificationType.SUBJECT:
        channel = channelSubject;
        break;
      default:
        break;
    }

    if (notification.server?.isLoggedIn ?? false) {
      displayNotification(channel!, notification,
          playSound: notification.server?.soundnotify == 0);
    }
  }

  void displayNotification(
      NotificationChannel channel, ReceivedNotification notification,
      {bool playSound = true}) async {
    String channelId, channelName, channelDescription;
    if (playSound) {
      channelId = channel.id;
      channelName = channel.name;
      channelDescription = channel.description;
    } else {
      channelId = LocalNotificationPlugin.silentChannel.id;
      channelName = channel.name;
      channelDescription = channel.description;
    }

    var vibrationPattern = new Int64List(3);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 100;
    vibrationPattern[2] = 1000;
    // vibrationPattern[3] = 1000;
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId, channelName,
        channelDescription: channelDescription,
        icon: 'icon',
        importance: Importance.high,
        priority: Priority.high,
        playSound: playSound,
        sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
        styleInformation: const DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin?.show(channel.number,
        notification.title, notification.body, platformChannelSpecifics,
        payload: jsonEncode(notification.toJson()));
  }

  static Future<dynamic> backgroundMessageHandler(RemoteMessage message) {
    // Handle data message
    final dynamic data = message.data;

    // Handle notification message
    final dynamic notification = message.notification;

    return Future<void>.value();
  }

  Future<int> getPendingNotificationCount() async {
    List<PendingNotificationRequest> p =
        await flutterLocalNotificationsPlugin!.pendingNotificationRequests();
    return p.length;
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin?.cancel(0);
  }

  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin?.cancelAll();
  }
}

LocalNotificationPlugin notificationPlugin = LocalNotificationPlugin._();

class ReceivedNotification {
  int? id;
  Chat? chat;
  User? gchat;
  Server? server;
  NotificationType? type;
  final String title;
  final String body;
  String? payload;

  ReceivedNotification({
    required this.title,
    required this.body,
    this.server,
    this.id,
    this.type,
    this.chat,
    this.gchat,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'server': server?.toJson(),
        'title': title,
        'body': body,
        'payload': payload,
        'type': type.toString(),
        'chat': chat?.toJson(),
        'gchat': gchat?.toJson()
      };

  ReceivedNotification.fromJson(Map<String, dynamic> map)
      : id = map['id'] ?? 0,
        body = map['body'] ?? '',
        title = map['title'] ?? 'Title not specified',
        payload = map['payload'] ?? '' {
    type = getNotificationTypeFromString(map['type'].toString());
    server = Server.fromJson(map['server']);
    chat = map.containsKey('chat') && map['chat'] != null
        ? Chat.fromJson(map['chat'])
        : null;
    gchat = map.containsKey('gchat') && map['gchat'] != null
        ? User.fromJson(map['gchat'])
        : null;
  }

  NotificationType getNotificationTypeFromString(String typeStr) {
    return NotificationType.values.firstWhere((nt) => nt.toString() == typeStr,
        orElse: () => NotificationType.UNREAD);
  }
}

enum NotificationType {
  INFO,
  NEW_MESSAGE,
  PENDING,
  UNREAD,
  NEW_GROUP_MESSAGE,
  SUBJECT
}
