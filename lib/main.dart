import 'package:flutter/material.dart';
//plugin imports
import 'bloc/simple_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/pages/servers_manage.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart';

import 'package:livehelp/globals.dart' as globals;

void main() async {
  Bloc.observer = SimpleBlocObserver();
  DatabaseHelper dbHelper = DatabaseHelper();
  ServerRepository serverRepository = new ServerRepository(
      dBHelper: dbHelper,
      serverApiClient: ServerApiClient(httpClient: http.Client()));
  runApp(RepositoryProvider<ServerRepository>(
      create: (context) {
        return serverRepository;
      },
      child: MultiBlocProvider(providers: [
        BlocProvider<ServerBloc>(
          create: (context) => ServerBloc(serverRepository: serverRepository),
        ),
        BlocProvider<FcmTokenBloc>(
          lazy: false,
          create: (context) => FcmTokenBloc(serverRepository: serverRepository),
        ),
        BlocProvider<LoginformBloc>(
          create: (context) =>
              LoginformBloc(serverRepository: serverRepository),
        ),
        BlocProvider<ChatslistBloc>(
          create: (context) =>
              ChatslistBloc(serverRepository: serverRepository),
        ),
      ], child: App())));
}

class App extends StatelessWidget {
  App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Live Helper Chat',
        navigatorObservers: [globals.routeObserver],
        theme: new ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ServersManage();
  }
}
