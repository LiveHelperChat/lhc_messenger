import 'dart:typed_data';
import 'dart:async';

import 'package:livehelp/model/server.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationHelper {
  //[ChannelID, Channel Description]
  static final Map<String, String> channelIDNewChat = {
    "id": "gh.com.tbsapps.lhcmessenger.channel.NEWCHAT",
    "name": "New Chat",
    "description": "New Chat",
    "number":"1111"
  };

  // static final String channelNameNewChat = ;
  static final Map<String, String> channelIDNewMsg = {
    "id": "gh.com.tbsapps.lhcmessenger.channel.NEWMESSAGE",
    "name": "New Messages",
    "description": "New Messages",
    "number":"2222"
  };

  //static final String channelNameNewMSG = ;
  static final Map<String, String> channelIDUnreadMsg = {
    "id": "gh.com.tbsapps.lhcmessenger.channel.UNREADMSG",
    "name": "Unread Messages",
    "description": "Unread Messages",
    "number":"3333"
  };

  //static final String channelNameUnreadMsg =;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

  static void showNotification(Server server, String type, String title,
      String msg) async {
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(
        initializationSettings, selectNotification: onSelectNotification);

    Map<String, String> channel;
    //String title="";
    switch (type) {
      case 'new_msg':
        channel = channelIDNewMsg;
        // title = "New Message";
        break;
      case 'pending':
        channel = channelIDNewChat;
        // title = 'New Chat';
        break;
      case 'unread':
        channel = channelIDUnreadMsg;
        // title = 'Unread Message';
        break;
      default:
        break;
    }
    if (server.isloggedin == 1) {
      if (server.soundnotify == 0) {
        notifyWithNoSound(server.servername + ": " + title, msg, int.tryParse(channel['number']));
      }
      else {
        notifyWithSound(channel, server.servername + ": " + title, msg,int.tryParse(channel['number']));
      }
    }
  }


  /// Schedules a notification that specifies a different icon, sound and vibration pattern
  static notifyWithSound(Map<String, String> channel, String title,String msg,int notificationID) async {

  //  print(msg);
    var vibrationPattern = new Int64List(3);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 100;
    vibrationPattern[2] = 1000;
    // vibrationPattern[3] = 1000;
    var androidPlatformChannelSpecifics =
    new AndroidNotificationDetails(channel['id'],
      channel['name'], channel['description'],
      icon: 'icon',
      sound: 'slow_spring_board',
    ); // vibrationPattern: vibrationPattern
    var iOSPlatformChannelSpecifics =
    new IOSNotificationDetails(sound: "slow_spring_board.aiff");
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        notificationID,
        title,
        msg,
        platformChannelSpecifics);
  }

  static void notifyWithNoSound(String title, String message,int notificationID) async {
    var androidPlatformChannelSpecifics =
    new AndroidNotificationDetails('silent channel id',
        'silent channel name', 'silent channel description',
        playSound: false,
        styleInformation: new DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
    new IOSNotificationDetails(presentSound: false);
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.show(notificationID, '<b>$title</b>',
        message, platformChannelSpecifics);
  }

  static Future onSelectNotification(String payload) async {
    if (payload != null) {
      //  debugPrint('notification payload: ' + payload);
    }
  }
}

