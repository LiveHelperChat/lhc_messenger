import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/pages.dart';

class AppRoutes {
  static const String home = "/";
  static const String login = "/login";
  static const String server = "/server";
  static const String chatPage = "/chats/chat";
  static const String operatorsChatPage = "/chats/operatorschat";
  static const String main = "/main";
  static const String serverDetails = "/servers/server";
  static const String serversManage = "/servers/manage";
  static const String twilio = "/main/twilio";
}

///
/// Serves as a class to pass arguments to routes
class RouteArguments extends Equatable {
  final int? chatId;
  RouteArguments({this.chatId});

  @override
  List<Object> get props => [chatId!];
}

class FadeRoute<T> extends MaterialPageRoute<T> {
  bool isInitialRoute;
  FadeRoute(
      {WidgetBuilder? builder,
      RouteSettings? settings,
      this.isInitialRoute = false})
      : super(builder: builder!, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (isInitialRoute) return child;
    // Fades between routes. (If you don't want any animation,
    // just return child.)
    return FadeTransition(opacity: animation, child: child);
  }
}

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final RouteArguments args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.home:
        return FadeRoute(
          settings: settings,
          builder: (BuildContext context) => const MainPage(),
        );

      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
  }

  static Route<dynamic> generateRouteChatPage(RouteSettings settings,
      Chat? chat, Server? server, bool isNewChat, Function refreshList) {
    return FadeRoute(
      settings: settings,
      builder: (BuildContext context) => ChatPage(
        server: server,
        chat: chat,
        isNewChat: isNewChat,
        refreshList: () => refreshList,
      ),
    );
  }

  static Route<dynamic> generateRouteOperatorsChatPage(RouteSettings settings,
      User user, Server server, bool isNewChat, Function refreshList) {
    return FadeRoute(
      settings: settings,
      builder: (BuildContext context) => OperatorsChatPage(
        server: server,
        chat: user,
        isNewChat: isNewChat,
        refreshList: () => refreshList,
      ),
    );
  }
}

extension NavigatorStateExtension on NavigatorState {
  void pushRouteIfNotCurrent(Route route) async {
    if (!isCurrent(route)) {
      // popUntil(ModalRoute.withName(AppRoutes.home));
      push(route);
    }
  }

  bool isCurrent(Route newRoute) {
    bool isCurrent = false;
    popUntil((oldRoute) {
      final RouteArguments? oldArgs =
          oldRoute.settings.arguments as RouteArguments?;
      final RouteArguments? newArgs =
          newRoute.settings.arguments as RouteArguments?;
      if (oldRoute.settings.name == newRoute.settings.name &&
          oldArgs?.chatId == newArgs?.chatId) {
        isCurrent = true;
        return true;
      }
      if (oldRoute.settings.name == AppRoutes.home) {
        return true;
      }

      return false;
    });
    return isCurrent;
  }
}
