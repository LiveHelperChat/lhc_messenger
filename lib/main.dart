import 'package:firebase_core/firebase_core.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  BlocOverrides.runZoned((){
    DatabaseHelper dbHelper = DatabaseHelper();
    ServerRepository serverRepository = ServerRepository(
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
        ], child: const App())));
  },
  blocObserver: SimpleBlocObserver()
  );

}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Live Helper Chat',
        navigatorObservers: [globals.routeObserver],
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ServersManage();
  }
}
