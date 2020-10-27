import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:after_layout/after_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/lists/chat_list_twilio.dart';
import 'package:livehelp/pages/pages.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/widget/widget.dart';

import 'package:livehelp/globals.dart' as globals;

class MainPage extends StatefulWidget {
  const MainPage();

  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<MainPage>,
        RouteAware {
  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<Server> listServers = new List<Server>();

  List<dynamic> activeChatStore = new List();
  List<dynamic> pendingChatStore = new List();
  List<dynamic> transferChatStore = new List();

  Timer _timerChatList;
  Server _selectedServer;

  bool initialized = false;
  bool isTwilioActive = false;
  DatabaseHelper dbHelper = DatabaseHelper();

  ChatslistBloc _chatListBloc;
  ServerBloc _serverBloc;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _serverBloc = context.bloc<ServerBloc>();
    _chatListBloc = context.bloc<ChatslistBloc>()..add(ChatListInitialise());
    _init();

    _timerChatList = _chatListTimer(5);
  }

  @override
  void dispose() {
    _timerChatList.cancel();

    WidgetsBinding.instance.removeObserver(this);
    globals.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    globals.routeObserver.subscribe(this, ModalRoute.of(context));
  }

// Called when the current route has been pushed.
  @override
  void didPush() {
    _init();
  }

  @override
  // Called when the top route has been popped off, and the current route shows up.
  void didPopNext() {
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecyleState = state;
    });

    _checkState();
  }

  void _checkState() {
    switch (_lastLifecyleState) {
      case AppLifecycleState.resumed:
        if (!(_timerChatList?.isActive ?? false)) {
          _timerChatList = _chatListTimer(5);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_timerChatList.isActive) _timerChatList.cancel();
        break;
      default:
        break;
    }
  }

  void _init() {
    _serverBloc.add(GetServerListFromDB(onlyLoggedIn: true));
    _serverBloc.add(GetUserOnlineStatus());
    _loadChatList();
  }

  @override
  Widget build(BuildContext context) {
    /*
    if (_timerChatList == null) {
      _timerChatList = new Timer.periodic(
          new Duration(seconds: 10), (Timer timer) => _loadChatList()); //
    } */

    var mainScaffold = BlocListener<FcmTokenBloc, FcmTokenState>(
        listener: (context, state) {
          if (state is NotificationClicked) {
            _navigateToPage(state.notification);
          }
        },
        child:
            BlocConsumer<ServerBloc, ServerState>(listener: (context, state) {
          if (state is ServerInitial) {
            _serverBloc.add(GetServerListFromDB(onlyLoggedIn: true));
            _chatListBloc.add(ChatListInitialise());
          }

          if (state is ServerListFromDBLoaded) {
            listServers = state.serverList;
            if (state.serverList?.isNotEmpty ?? false) {
              if (_selectedServer == null ||
                  state.serverList.any((sv) => sv.id != _selectedServer.id)) {
                _selectedServer = state.serverList.elementAt(0);
              }
            } else {
              _loadServerManage(context);
            }
          }

          if (state is ServerLoggedOut) {
            _serverBloc.add(InitServers());
          }
        }, builder: (context, state) {
          var tabs = <Tab>[
            Tab(
              child: BlocBuilder<ChatslistBloc, ChatListState>(
                  builder: (context, state) {
                if (state is ChatListLoaded) {
                  return ChatNumberIndcator(
                    title: "Active",
                    offstage: state.activeChatList.length == 0,
                    number: state.activeChatList.length.toString(),
                  );
                }
                return ChatNumberIndcator(
                  title: "Active",
                  offstage: true,
                  number: "0",
                );
              }),
            ),
            Tab(
              child: BlocBuilder<ChatslistBloc, ChatListState>(
                  builder: (context, state) {
                if (state is ChatListLoaded) {
                  return ChatNumberIndcator(
                    title: "Pending",
                    offstage: state.pendingChatList.length == 0,
                    number: state.pendingChatList.length.toString(),
                  );
                }
                return ChatNumberIndcator(
                  title: "Pending",
                  offstage: true,
                  number: "0",
                );
              }),
            ),
            Tab(
              child: BlocBuilder<ChatslistBloc, ChatListState>(
                  builder: (context, state) {
                if (state is ChatListLoaded) {
                  return ChatNumberIndcator(
                    title: "Transfer",
                    offstage: state.transferChatList.length == 0,
                    number: state.transferChatList.length.toString(),
                  );
                }
                return ChatNumberIndcator(
                  title: "Transfer",
                  offstage: true,
                  number: "0",
                );
              }),
            )
          ];

          var bodyWidgets = <Widget>[
            ActiveListWidget(
              listOfServers: listServers,
              refreshList: _loadChatList,
              callbackCloseChat: (server, chat) {
                _chatListBloc
                    .add(CloseChatMainPage(server: server, chat: chat));
              },
              callBackDeleteChat: (server, chat) {
                _chatListBloc
                    .add(DeleteChatMainPage(server: server, chat: chat));
              },
            ),
            PendingListWidget(
              listOfServers: listServers,
              refreshList: _loadChatList,
              callBackDeleteChat: (server, chat) {
                _chatListBloc
                    .add(DeleteChatMainPage(server: server, chat: chat));
              },
            ),
            TransferredListWidget(
              listOfServers: listServers,
              refreshList: _loadChatList,
            ),
          ];

          if (state is ServerListFromDBLoaded) {
            //Add twilio Tabs
            if (state.selectedServer != null &&
                state.selectedServer.twilioInstalled == true) {
              tabs.add(Tab(child: new BlocBuilder<ChatslistBloc, ChatListState>(
                  builder: (context, state) {
                if (state is ChatListLoaded) {
                  return ChatNumberIndcator(
                    title: "SMS",
                    offstage: state.twilioChatList.length == 0,
                    number: state.twilioChatList.length.toString(),
                  );
                }

                return ChatNumberIndcator(
                  title: "Twilio",
                  offstage: true,
                  number: "0",
                );
              })));

              bodyWidgets.add(TwilioListWidget(
                listOfServers: listServers,
                refreshList: _loadChatList,
                callbackCloseChat: (server, chat) {
                  _chatListBloc
                      .add(CloseChatMainPage(server: server, chat: chat));
                },
                callBackDeleteChat: (server, chat) {
                  _chatListBloc
                      .add(DeleteChatMainPage(server: server, chat: chat));
                },
              ));
            }
          }

          return DefaultTabController(
              length: tabs.length,
              child: BlocBuilder<ServerBloc, ServerState>(
                  builder: (context, state) {
                /*
              if (state is ServerInitial) {
      _loadChatList();
      return Center(child: CircularProgressIndicator());
    }

    if (state is ServerListFromDBLoaded) {
      if (state.serverList?.isNotEmpty ?? false) {
        listServers = state.serverList;

        _loadChatList();
      }
    }
    if (state is ServerListLoadError) {
      return ErrorReloadButton(
          child: Text(state.message),
          onButtonPress: () {
            _loadChatList();
          },
          actionText: 'Reload');
    }  
              */

                if (state is ServerListFromDBLoaded) {
                  if (state.serverList?.isNotEmpty ?? false) {
                    listServers = state.serverList;
                    _loadChatList();
                  }

                  return Scaffold(
                    backgroundColor: Colors.white,
                    key: _scaffoldKey,
                    appBar: AppBar(
                      title: Text("Chats List"),
                      bottom: TabBar(tabs: tabs),
                    ),
                    drawer: Drawer(
                        child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          UserAccountsDrawerHeader(
                            accountName: Text(""),
                            accountEmail: Container(
                              child: DropdownButton(
                                  isExpanded: true,
                                  value: state.serverList.isNotEmpty
                                      ? state.selectedServer
                                      : null,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  items: listServers.map((srvr) {
                                    return DropdownMenuItem(
                                      value: srvr,
                                      child: Text(
                                        '${srvr?.servername}',
                                        style: TextStyle(
                                            color: Colors.teal.shade900),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (srvr) {
                                    _selectedServer = srvr;
                                    _serverBloc.add(SelectServer(server: srvr));
                                    _serverBloc.add(GetUserOnlineStatus(
                                        server: srvr, isActionLoading: true));
                                  }),
                            ),
                            currentAccountPicture: GestureDetector(
                              child: new CircleAvatar(
                                child: new Text(
                                  state.selectedServer?.servername
                                          ?.substring(0, 1) ??
                                      "",
                                  style: TextStyle(
                                      fontSize: 18.00,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () => {},
                            ),
                            decoration: BoxDecoration(
                                image: new DecorationImage(
                                    image:
                                        new AssetImage('graphics/header.jpg'),
                                    fit: BoxFit.fill)),
                          ),
                          Column(
                            children: [
                              Card(
                                child: new Container(
                                  child: new Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      ListTile(
                                        title: state.selectedServer?.url == null
                                            ? Text("")
                                            : Text(
                                                "${state.selectedServer?.url}",
                                                style:
                                                    TextStyle(fontSize: 11.0),
                                                textAlign: TextAlign.left,
                                                overflow: TextOverflow.fade,
                                                maxLines: 2,
                                                softWrap: true,
                                              ),
                                        subtitle: state.selectedServer
                                                    ?.isLoggedIn ??
                                                false
                                            ? Text("Logged In",
                                                style: TextStyle(
                                                    color: Colors.green))
                                            : Text("Logged Out",
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                      ),
                                      ListTile(
                                        title: Text(
                                            "${state.selectedServer?.firstname ?? ""} ${state.selectedServer?.surname ?? ""}"),
                                        subtitle:
                                            state.selectedServer?.userOnline ??
                                                    false
                                                ? Text(
                                                    "Operator Online",
                                                    style: new TextStyle(
                                                        fontSize: 10.0),
                                                  )
                                                : Text("Operator Offline",
                                                    style: new TextStyle(
                                                        fontSize: 10.0)),
                                        trailing: state.isActionLoading
                                            ? CircularProgressIndicator()
                                            : IconButton(
                                                icon: state.selectedServer
                                                            ?.userOnline ??
                                                        false
                                                    ? Icon(
                                                        Icons.flash_on,
                                                        color: Colors.green,
                                                      )
                                                    : Icon(
                                                        Icons.flash_off,
                                                        color: Colors.red,
                                                      ),
                                                onPressed: () {
                                                  if ((state.selectedServer
                                                          ?.isLoggedIn ??
                                                      false)) {
                                                    _serverBloc.add(
                                                        SetUserOnlineStatus(
                                                            server: state
                                                                .selectedServer));
                                                  } else {
                                                    Navigator.of(context).pop();
                                                    _showSnackBar(
                                                        "You are not logged in to the server");
                                                  }
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ListTile(
                                  title: Text("Server Settings"),
                                  leading: Icon(Icons.settings),
                                  onTap: () {
                                    if (state.selectedServer.isLoggedIn) {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        FadeRoute(
                                          builder: (BuildContext context) =>
                                              ServerSettings(
                                            server: state.selectedServer,
                                          ),
                                          settings: new RouteSettings(
                                            name: AppRoutes.serverDetails,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).pop();
                                      _showSnackBar(
                                          "You are not logged in to the server");
                                    }
                                  }),
                              state.selectedServer?.isLoggedIn ?? false
                                  ? ListTile(
                                      title: Text("Logout Server"),
                                      leading: Icon(Icons.exit_to_app),
                                      onTap: () {
                                        if (state.selectedServer.isLoggedIn) {
                                          Navigator.pop(context);
                                          _showAlert(
                                              context, state.selectedServer);
                                        } else {
                                          Navigator.of(context).pop();
                                          _showSnackBar(
                                              "You are not logged in to the server");
                                        }
                                      },
                                    )
                                  : ListTile(
                                      title: Text("Login"),
                                      leading: Icon(Icons.exit_to_app),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _addServer(
                                            server: state.selectedServer);
                                      },
                                    ),
                            ],
                          ),
                          Divider(),
                          ListTile(
                            title: Text("Manage Servers"),
                            leading: Icon(Icons.add),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                FadeRoute(
                                  builder: (BuildContext context) =>
                                      ServersManage(
                                    returnToList: true,
                                  ),
                                  settings: RouteSettings(
                                    name: AppRoutes.serversManage,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )),
                    body: Stack(children: <Widget>[
                      new TabBarView(children: bodyWidgets)
                    ]),
                    floatingActionButton: _speedDial(context),
                  );
                }
                if (state is ServerListLoadError) {
                  return ErrorReloadButton(
                      child: Text(state.message),
                      onButtonPress: () {
                        _serverBloc.add(InitServers());
                      },
                      actionText: 'Reload');
                }
                return Scaffold(
                    body: ErrorReloadButton(
                        child: Text("No Active Server"),
                        onButtonPress: () {
                          _serverBloc.add(InitServers());
                        },
                        actionText: 'Reload'));
              }));
        }));
    return mainScaffold;
  }

  void _navigateToPage(ReceivedNotification notification) {
    if (!(notification.server?.isLoggedIn ?? true)) return;

    final routeArgs = RouteArguments(chatId: notification.chat?.id);
    final routeSettings =
        RouteSettings(name: AppRoutes.chatPage, arguments: routeArgs);
    bool isNewChat = notification.type == NotificationType.PENDING;

    var routeChat = LHCRouter.Router.generateRouteChatPage(routeSettings,
        notification.chat, notification.server, isNewChat, _loadChatList);

    if (notification.type == NotificationType.NEW_MESSAGE ||
        notification.type == NotificationType.UNREAD) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        Navigator.of(context).pushRouteIfNotCurrent(routeChat);
      });
    } else if (notification.type == NotificationType.PENDING) {
      Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.home));
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        Navigator.of(context).push(routeChat);
      });
    }
  }

  void _loadChatList() {
    listServers.forEach((server) {
      if (server.isLoggedIn) {
        _chatListBloc.add(FetchChatsList(server: server));
      }
    });
  }

  void _loadServerManage(BuildContext context) {
    // navigate to server management page if no server exists
    Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(
          builder: (BuildContext context) => ServersManage(
            returnToList: false,
          ),
          settings: RouteSettings(
            name: AppRoutes.server,
          ),
        ),
        (Route<dynamic> route) => false);
  }

  Timer _chatListTimer(int seconds) {
    //fetch list first

    return new Timer.periodic(
        new Duration(seconds: seconds), (Timer timer) => _loadChatList());
  }

  void _showAlert(BuildContext context, Server server) {
    AlertDialog dialog = new AlertDialog(
      content: Text(
        "Do you want to logout of the server? \n\nYou will not receive notifications for chats.",
        style: TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Yes"),
            onPressed: () {
              _serverBloc.add(LogoutServer(
                  server: server,
                  deleteServer: false,
                  fcmToken: context.bloc<FcmTokenBloc>().token));
              Navigator.of(context).pop();
            }),
        MaterialButton(
            child: new Text("No"),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void _showSnackBar(String text) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      initialized = true;
    });
  }

  void _addServer({Server server}) {
    Navigator.of(context).push(FadeRoute(
      builder: (BuildContext context) => LoginForm(
        server: server,
      ),
      settings: new RouteSettings(
        name: AppRoutes.login,
      ),
    ));
  }

  void _showAlertMsg(String title, String msg) {
    SimpleDialog dialog = new SimpleDialog(
      title: new Text(
        title,
        style: new TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        new Text(
          msg,
          style: new TextStyle(fontSize: 14.0),
        )
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  SpeedDial _speedDial(BuildContext context) {
    var serverRepository = context.repository<ServerRepository>();
    var children = [
      SpeedDialChild(
          child: Icon(Icons.refresh),
          backgroundColor: Theme.of(context).primaryColor,
          label: 'Reload list',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => _loadChatList())
    ];

    if (_serverBloc.state is ServerListFromDBLoaded) {
      final currentState = _serverBloc.state as ServerListFromDBLoaded;
      if (currentState.selectedServer != null &&
          currentState.selectedServer.twilioInstalled == true) {
        children.add(SpeedDialChild(
          child: Icon(Icons.sms),
          backgroundColor: Theme.of(context).primaryColor,
          label: 'Twilio SMS/Chat',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () async {
            Navigator.of(context).push(FadeRoute(
              builder: (BuildContext context) =>
                  RepositoryProvider<ServerRepository>(
                      create: (context) => serverRepository,
                      child: TwilioSMSChat(
                        server: _selectedServer,
                        refreshList: () {},
                      )),
              settings: new RouteSettings(
                name: AppRoutes.twilio,
              ),
            ));
          },
        ));
      }
    }

    return SpeedDial(
        // both default to 16
        marginRight: 18,
        marginBottom: 20,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child: Icon(Icons.add),
        visible: true,
        // If true user is forced to close dial manually
        // by tapping main button and overlay is not rendered.
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () {},
        onClose: () {},
        tooltip: 'Actions',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: CircleBorder(),
        children: children);
  }
}
