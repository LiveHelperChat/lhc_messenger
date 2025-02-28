import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/globals.dart' as globals;
import 'package:livehelp/model/server.dart';
import 'package:livehelp/pages/main_page.dart';
import 'package:livehelp/pages/servers_manage.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart'; //plugin imports
import 'package:livehelp/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'bloc/simple_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
      await Firebase.initializeApp();
    } catch (e) {
      print("Error initializing Firebase: $e");
    }

  try {
        await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  } catch (e) {
        print("Error initializing FlutterDownloader: $e");
  }

  // Setting up the Bloc observer
  Bloc.observer = SimpleBlocObserver();
  // Initialize your database helper and server repository
  DatabaseHelper dbHelper = DatabaseHelper();
  ServerRepository serverRepository = ServerRepository(
    dBHelper: dbHelper,
    serverApiClient: ServerApiClient(
      httpClient: http.Client(),
    ),
  );
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(
    RepositoryProvider<ServerRepository>(
      create: (context) {
        return serverRepository;
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ServerBloc>(
            create: (context) => ServerBloc(serverRepository: serverRepository),
          ),
          BlocProvider<FcmTokenBloc>(
            lazy: false,
            create: (context) =>
                FcmTokenBloc(serverRepository: serverRepository),
          ),
          BlocProvider<LoginformBloc>(
            create: (context) =>
                LoginformBloc(serverRepository: serverRepository),
          ),
          BlocProvider<ChatslistBloc>(
            create: (context) =>
                ChatslistBloc(serverRepository: serverRepository),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // DialogShower.init(context);

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Live Helper Chat',
        navigatorObservers: [globals.routeObserver],
        theme: ThemeData(
          primaryColor: Colors.indigo,
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.indigo, // Set AppBar background color to green
            foregroundColor: Colors.white, // Set text/icon color in AppBar
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}

// class MyHomePage extends StatelessWidget {
//   const MyHomePage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ServersManage();
//   }
// }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ServerBloc? _serverBloc;
  @override
  void initState() {
    super.initState();
    if ((sharedPreferences?.getBool("isLoggedIn") ?? false)) {
      _serverBloc = context.read<ServerBloc>();
      _serverBloc?.add(const GetServerListFromDB(onlyLoggedIn: true));
      _serverBloc?.add(GetUserOnlineStatus(server: Server()));
    }
    Future.delayed(
      Duration(seconds: 2),
      () {
        Navigator.of(context).pop();
        if ((sharedPreferences?.getBool("isLoggedIn") ?? false)) {
          Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(
                builder: (BuildContext context) => const MainPage(),
                settings: const RouteSettings(
                  name: AppRoutes.home,
                ),
              ),
              (Route<dynamic> route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(
                builder: (BuildContext context) => ServersManage(),
                settings: const RouteSettings(
                  name: AppRoutes.serversManage,
                ),
              ),
              (Route<dynamic> route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Image.asset(
                'assets/images/icon.png',
                height: 200,
              ),
              SizedBox(height: 10),
              // App Name
              Text(
                'Live Helper Chat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SharedPreferences? sharedPreferences;
