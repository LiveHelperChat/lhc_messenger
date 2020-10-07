import 'package:flutter/material.dart';

import 'package:livehelp/pages/main_page.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
class AppRoutes{
  static const String login = "/login";
  static const String server = "/server";
  static const String chatPage = "/chats/chat";
  static const String main  = "/main";
  static const String serverDetails  = "/servers/server";
  static const String serversManage  = "/servers/manage";
  static const String twilio = "/main/twilio";
}

class RouteArguments{
  String fcmToken;
  RouteArguments(this.fcmToken);
}

class FadeRoute<T> extends MaterialPageRoute<T> {
  bool isInitialRoute;
  FadeRoute({ WidgetBuilder builder, RouteSettings settings, this.isInitialRoute = false})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,Widget child) {
    if (this.isInitialRoute)
      return child;
    // Fades between routes. (If you don't want any animation,
    // just return child.)
    return FadeTransition(opacity: animation, child: child);
  }
}

class Router {
 static Route<dynamic> generateRoute(RouteSettings settings) {

      final RouteArguments args = settings.arguments;
      switch (settings.name) {
        
        case AppRoutes.main:
        return   FadeRoute(
                        settings: settings,
                        builder: (BuildContext context) =>
                            new TokenInheritedWidget(
                                token: args?.fcmToken,
                                child: MainPage(
                                )),
                      );
      
      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
  }
  }