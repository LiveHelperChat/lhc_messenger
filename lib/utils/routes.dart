import 'package:flutter/material.dart';

class MyRoutes{
  static final String login = "/login";
  static final String server = "/server";
  static final String chatPage = "/chats/chat";
  static final String main  = "/main";
  static final String serverDetails  = "/servers/server";
  static final String serversManage  = "/servers/manage";
  static final String twilio = "/main/twilio";
}

class FadeRoute<T> extends MaterialPageRoute<T> {
  FadeRoute({ WidgetBuilder builder, RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (settings.isInitialRoute)
      return child;
    // Fades between routes. (If you don't want any animation,
    // just return child.)
    return new FadeTransition(opacity: animation, child: child);
  }
}