import 'package:flutter/material.dart';
//plugin imports
import 'package:after_layout/after_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/pages/main_page.dart';
import 'package:livehelp/pages/servers_manage.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart';

import 'bloc/simple_bloc_observer.dart';

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
        theme: new ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: MyHomePage(
          title: "Login",
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  State<MyHomePage> createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AfterLayoutMixin<MyHomePage>, RouteAware {
  final GlobalKey<_MyHomePageState> homePageStateKey =
      GlobalKey<_MyHomePageState>();

  _MyHomePageState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocConsumer<ServerBloc, ServerState>(listener: (context, state) {
        if (state is ServerInitial || state is ServerListFromDBLoading) {}
      }, builder: (context, state) {
        if (state is ServerInitial || state is ServerListFromDBLoading) {
          //load servers that are logged in from DB.
          context
              .bloc<ServerBloc>()
              .add(GetServerListFromDB(onlyLoggedIn: true));
          return Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()));
        } else if (state is ServerListFromDBLoaded) {
          // If one or more servers is logged in
          if (state.serverList.length == 0) {
            return ServersManage();
          }
        } else if (state is ServerFromDBLoadError) {
          return Center(
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              child: Text("Error loading servers from database."),
            ),
          );
        }

        return MainPage();
      }),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {}
}
