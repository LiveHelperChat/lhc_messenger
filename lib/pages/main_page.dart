import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:async_loader/async_loader.dart';
import 'package:after_layout/after_layout.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/pages/twilio_sms_chat.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/utils/server_requests.dart';
import 'package:livehelp/pages/loginForm.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/pages/servers_manage.dart';
import 'package:livehelp/pages/chat_list_active.dart';
import 'package:livehelp/pages/chat_list_pending.dart';
import 'package:livehelp/pages/chat_list_transferred.dart';
import 'package:livehelp/pages/server_details.dart';
import 'package:livehelp/widget/chat_number_indicator.dart';
import 'package:livehelp/widget/expansion_panel.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<MainPage> {
  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;

  final GlobalKey<AsyncLoaderState> _mainAsyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final int extensionVersion = 12; //(0.1.2)

  ServerRequest _serverRequest = new ServerRequest();
  DatabaseHelper dbHelper;

  List<Server> listServers = new List<Server>();
  List<Chat> _activeChatList = new List<Chat>();
  List<Chat> _pendingChatList = new List<Chat>();
  List<Chat> _transferedChatList = new List<Chat>();
  List<Chat> _twilioChatList = new List<Chat>();

  List<dynamic> activeChatStore = new List();
  List<dynamic> pendingChatStore = new List();
  List<dynamic> transferChatStore = new List();

  bool _actionLoading = false;

  Timer _timer;
  String _fcmToken;
  Server _selectedServer;
  bool _user_online;
  bool _userOnlineLoading = false;

  bool _showUpdateNotice = false;
  bool initialized = false;
  bool isTwilioActive = false;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    dbHelper = new DatabaseHelper();
    _user_online = false;
    Future.delayed(const Duration(milliseconds: 300), () async {_initLists();  });      
    _timer = myTimer(15);
  }

  void _initLists() async {
    await _getSavedServers();
    if(listServers.length > 0){
     await _getChatList();
    }  
    else {
      _loadManageServerPage();
    }
  }

  @override
  void dispose() {
    _timer.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _serverRequest.dispose();

    super.dispose();
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
        _initLists();
        _timer = myTimer(15);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_timer.isActive) _timer.cancel();
        break;
      default:
        break;
    }
  }

  //final String token;
  @override
  Widget build(BuildContext context) {

    final tokenInherited = TokenInheritedWidget.of(context);
    _fcmToken = tokenInherited.token;

    // get user online status
    // if (_selectedServer != null)_getOnlineStatus();

    Widget loadingIndicator =
        _actionLoading ? new CircularProgressIndicator() : new Container();

    var mainScaffold = DefaultTabController(
      length: 4,
      child:Scaffold(
          key: _scaffoldKey,
          appBar:  AppBar(
            title:  Text("Chat Lists"),
            bottom:  TabBar( tabs: <Tab>[
              Tab(
                child: new ChatNumberIndcator(
                  title: "Active",
                  offstage: _activeChatList.length == 0,
                  number: _activeChatList.length.toString(),
                ),
              ),
              Tab(
                child:  ChatNumberIndcator(
                  title: "New",
                  offstage: _pendingChatList.length == 0,
                  number: _pendingChatList.length.toString(),
                ),
              ),
              Tab(
                  child: new ChatNumberIndcator(
                    title: "Transfer",
                    offstage: _transferedChatList.length == 0,
                    number: _transferedChatList.length.toString(),
                  )),
              Tab(
                  child: new ChatNumberIndcator(
                    title: "SMS",
                    offstage: _twilioChatList?.length == 0,
                    number: _twilioChatList?.length.toString(),
                  ))
            ]),
          ),
          drawer: new Drawer(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    new UserAccountsDrawerHeader(
                      accountName: Text(""),
                      accountEmail:Container(

                        child:DropdownButton(
                            isExpanded: true,
                            value: _selectedServer,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white ,),
                            items: listServers.map((srvr) {
                              return new DropdownMenuItem(
                                value: srvr,
                                child: new Text('${srvr?.servername}', style: TextStyle(color: Colors.teal.shade900),),
                              );
                            }).toList(),
                            onChanged: (srv){
                              setState(() {
                                _selectedServer = srv;
                                /**Enable when extension version changes */
                                // showUpdateMsg();
                              });
                            }), ) ,
                      currentAccountPicture: GestureDetector(
                        child: new CircleAvatar(
                          child: new Text(
                            _selectedServer?.servername?.substring(0, 1) ?? "",
                            style: TextStyle(fontSize: 18.00, fontWeight: FontWeight.bold), ),
                        ),
                        onTap: () => {},
                      ),

                      decoration: new BoxDecoration(
                          image: new DecorationImage(
                              image: new AssetImage('graphics/header.jpg'),
                              fit: BoxFit.fill)),
                    ),
                    new Card(
                      child: new Container(
                        height: 150.0,
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            ListTile(
                              title:_selectedServer == null ? Text("") : Text("${_selectedServer?.url}",
                                style: TextStyle(fontSize: 11.0),
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.fade,
                                maxLines: 2,
                                softWrap: true,),
                              subtitle: _isServerLoggedIn() ? Text("Logged In", style:TextStyle(color: Colors.green))
                                  :  Text("Logged Out", style:TextStyle(color: Colors.redAccent)) ,
                            ),
                            ListTile(
                              title: new Text(
                                  "${_selectedServer?.firstname ?? ""} ${_selectedServer?.surname ?? ""}"),
                              subtitle: _selectedServer?.user_online == 1 ?? false
                                  ? new Text(
                                "Operator Online",
                                style: new TextStyle(fontSize: 10.0),
                              )
                                  : new Text("Operator Offline",
                                  style: new TextStyle(fontSize: 10.0)),
                              trailing: _userOnlineLoading
                                  ? new CircularProgressIndicator()
                                  : new IconButton(
                                icon:
                                _selectedServer?.user_online == 1 ?? false
                                    ? new Icon(Icons.flash_on,color: Colors.green,)
                                    : new Icon(Icons.flash_off,color: Colors.red,),
                                onPressed: () {
                                  if(_isServerLoggedIn()){
                                    setState(() {
                                      _userOnlineLoading = true;
                                    });
                                    _setOnlineStatus();
                                  }
                                  else {
                                    Navigator.of(context).pop();
                                    _showSnackBar("You are not logged in to the server");
                                  }

                                },
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    new Divider(),
                    new ListTile(
                        title: new Text("Server Details"),
                        leading: new Icon(Icons.web),
                        onTap: () {
                          if(_isServerLoggedIn()){
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              new FadeRoute(
                                builder: (BuildContext context) =>
                                new TokenInheritedWidget(
                                    token: _fcmToken,
                                    child: new ServerDetails(
                                      server: _selectedServer,
                                    )),
                                settings: new RouteSettings(
                                    name: MyRoutes.serverDetails, isInitialRoute: false),
                              ),
                            );
                          }
                          else {
                            Navigator.of(context).pop();
                            _showSnackBar("You are not logged in to the server");
                          }
                        }),
                    ListTile(
                      title: new Text("Manage Servers"),
                      leading: new Icon(Icons.settings),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          new FadeRoute(
                            builder: (BuildContext context) =>
                            new TokenInheritedWidget(
                                token: _fcmToken,
                                child: new ServersManage(manage: true,)
                            ),
                            settings: RouteSettings(name: MyRoutes.serversManage, isInitialRoute: false),
                          ),
                        );
                      },
                    ),

                    new Divider(),
                    _isServerLoggedIn() ?
                    ListTile(
                      title: new Text("Logout Server"),
                      leading: new Icon(Icons.exit_to_app),
                      onTap: () {
                        if(_isServerLoggedIn()){
                          Navigator.pop(context);
                          _showAlert();
                        }
                        else {
                          Navigator.of(context).pop();
                          _showSnackBar("You are not logged in to the server");
                        }
                      },
                    )
                        :  ListTile(
                      title: new Text("Login"),
                      leading: new Icon(Icons.exit_to_app),
                      onTap: () {
                        Navigator.pop(context);
                        _addServer(server: _selectedServer);
                      },
                    ) ,



                  ],
                ),
              )),
          body: new Stack(children: <Widget>[
            new TabBarView(
                children: <Widget>[
                  ActiveListWidget(
                    listOfServers: listServers,
                    listToAdd: _activeChatList,
                    loadingState: onActionLoading,
                    refreshList: _initLists,
                  ),
                  PendingListWidget(
                    listOfServers: listServers,
                    listToAdd: _pendingChatList,
                    loadingState: onActionLoading,
                    refreshList: _initLists,
                  ),
                  TransferredListWidget(
                    listOfServers: listServers,
                    listToAdd: _transferedChatList,
                    loadingState: onActionLoading,
                  ),
                  ActiveListWidget(
                    listOfServers: listServers,
                    listToAdd: _twilioChatList,
                    loadingState: onActionLoading,
                    refreshList: _initLists,
                  )
                ]),
            Center(child: loadingIndicator),
          ]),
          floatingActionButton: _speedDial(),

          bottomNavigationBar: Offstage(
            child: GestureDetector(
              onTap: () => _showBottomSheet(context),
              child: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Theme(
                  data: Theme.of(context).copyWith(accentColor: Colors.white),
                  child: Container(
                    color: Colors.red,
                    height: 48.0,
                    alignment: Alignment.center,
                    child: Text(
                      'Extension Update: Click me for more details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            offstage: !_showUpdateNotice,
          )) ,
    )
    ;

    var _asyncLoader = new AsyncLoader(
      key: _mainAsyncLoaderState,
      initState: () async {
        //TODO added return (might not be needed)
        // await _getSavedServers();
        return _initLists(); 
      },
      renderLoad: () => new Scaffold(
            body: new Center(child: new CircularProgressIndicator()),
          ),
      renderError: ([error]) =>
          new Scaffold(body: new Center(child: new Text('Something is wrong'))),
      renderSuccess: ({data}) {
        
        return mainScaffold;
      },
    );

    return _asyncLoader;
  }


  Timer myTimer(int seconds) {    //fetch list first
  
    return new Timer.periodic(
        new Duration(seconds: seconds), (Timer timer) => _getChatList(istimer: true));
  }

  void onActionLoading(bool val) {
    if(mounted){
       setState(() {
      _actionLoading = val;
    });
    }
   
  }

  bool _isServerLoggedIn(){
    return _selectedServer?.loggedIn() ?? false ? true : false;
  }

  // TODO Remove
  void onChatRemoved(Chat chat) {
    assert(chat != null);
    switch (chat.status.toString()) {
      case '1':
        setState(() {
          this._activeChatList.removeWhere((cht) => cht.id == chat.id);
        });
        break;
    }
  }

  Future<Null> _getChatList({istimer=false}) async {
  
    if (!_actionLoading && initialized) {
        // No logged in server
     if(listServers.length > 0 ){

     if(!istimer) onActionLoading(true);
      // TODO remove this line
     // await _getSavedServers();
     List<Chat> activeLists =[];
     List<Chat> pendingLists = [];
     List<Chat> transferLists = [];
     List<Chat> twilioLists = [];

     await Future.forEach(listServers, (Server server) async {

        if (server.loggedIn()) {
      
          var srvr = await   _serverRequest.getChatLists(server);
            if (srvr.activeChatList != null && srvr.activeChatList.length > 0) {
              activeLists.addAll(srvr.activeChatList);
              if(mounted){
                setState((){
                _activeChatList = cleanUpLists(_activeChatList, srvr.activeChatList);
                _activeChatList.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
              });
              }
               
            } else {
              if(mounted){
               setState(() {
                _activeChatList?.removeWhere((chat) => chat.serverid == server.id);
              }); 
              }
              
            }

            if (srvr.pendingChatList != null && srvr.pendingChatList.length > 0) {
              pendingLists.addAll(srvr.pendingChatList);
               if(mounted){
              setState(() {
                _pendingChatList = cleanUpLists(_pendingChatList, srvr.pendingChatList);
                _pendingChatList.sort((a, b) => a.id.compareTo(b.id));
              }); }
            } else {
               if(mounted){
              setState(() {
                _pendingChatList?.removeWhere((chat) => chat.serverid == server.id);
              });
               }
            }

            if (srvr.transferChatList != null && srvr.transferChatList.length > 0) {
              transferLists.addAll(srvr.transferChatList);
              setState(() {
                _transferedChatList = cleanUpLists(_transferedChatList, srvr.transferChatList);
                _transferedChatList.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
              });
            } else {              
                setState(() {                
              _transferedChatList?.removeWhere((chat) => chat.serverid == server.id);
                });
            }

            // check again in case there was network problem

           var hasTwilio =  await  _checkTwilio(server);
            if(hasTwilio){
                setState(() {
                  isTwilioActive = hasTwilio;
                });

                var svr2 = await _serverRequest.getTwilioChats(server);

                if (svr2.twilioChatList != null && svr2.twilioChatList.length > 0) {
                  twilioLists.addAll(svr2.twilioChatList);
                  setState(() {
                    _twilioChatList = cleanUpLists(_twilioChatList, srvr.twilioChatList);
                    _twilioChatList.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
                  });
                } else {
                  if (mounted) {
                    setState(() {
                      _twilioChatList?.removeWhere((chat) =>
                      chat.serverid == server.id);
                    });
                  }
                }
            }

        }
        else { 
          if(mounted){
              setState(() {
                _activeChatList?.removeWhere((chat) => chat.serverid == server.id);                
                _pendingChatList?.removeWhere((chat) => chat.serverid == server.id);           
              _transferedChatList?.removeWhere((chat) => chat.serverid == server.id);
              _twilioChatList?.removeWhere((chat) =>
                chat.serverid == server.id);
              });
               }

        }
      });
          if(mounted){            
         _activeChatList = _removeMissing(_activeChatList, activeLists);
         activeLists.clear();
        _pendingChatList = _removeMissing(_pendingChatList, pendingLists);
        pendingLists.clear();
        _transferedChatList =  _removeMissing(_transferedChatList, transferLists);
        transferLists.clear();
         _twilioChatList =  _removeMissing(_twilioChatList, twilioLists);
         twilioLists.clear();

          }
          
        
      }
    else {
      
     if(mounted){
         setState(() {        
      _activeChatList?.clear();
      _pendingChatList?.clear();
      _transferedChatList?.clear();
      _twilioChatList?.clear();
      });
      }     
    }

        onActionLoading(false);
    }
  }

  Future<bool> _checkTwilio(Server server) async{
   return await _serverRequest.isExtensionInstalled(server, "twilio");
  }

  List<Chat> cleanUpLists(List<Chat> chatToClean, List<dynamic> listFromServer) {
    listFromServer.map((map) => new Chat.fromMap(map));
    listFromServer.forEach((map) {

      // print("ListMessage: " + message.toMap().toString());
      if (chatToClean.any((chat) => chat.id == map.id && chat.serverid == map.serverid)) {
        int index = chatToClean.indexWhere(
            (chat) => chat.id == map.id && chat.serverid == map.serverid);
        chatToClean[index] = map;

      } else {
        chatToClean.add(map);
      }

    });
    return chatToClean;
  }
      /*Remove chats which have been closed from another device */
      List<Chat> _removeMissing(List<Chat> chatToClean, List<Chat> longList){

      if (chatToClean.length > 0 && longList.length > 0) {  
           
        List<int> removedIndices = new List();
        chatToClean.forEach((chat) {
          if (!longList.any((map) => map.id == chat.id && map.serverid == chat.serverid)) {
            int index = chatToClean.indexOf(chat);
            // print("index: " + index.toString());
            removedIndices.add(index);
          }
        });
        
        //remove the chats
        if (removedIndices != null && removedIndices.length > 0) {
          removedIndices.sort();
          removedIndices.reversed.toList().forEach(chatToClean.removeAt);
          removedIndices.clear();
        }
      }
      return chatToClean;  
  }

  Future<Null> _getSavedServers() async {

    // get logged in servers
    List<Map> savedRecs = await dbHelper.fetchAll(
        Server.tableName, "${Server.columns['db_id']}  ASC", "isloggedin=?",[1]);
        
    if (savedRecs != null && savedRecs.length > 0) {
      savedRecs.forEach((item) {
        if (!(listServers.any((serv) =>
            serv.servername == item['servername'] &&
            serv.url == item['url'] &&
            serv.username == item['username']))) {
          if(mounted){
          setState(() {
            listServers.add(new Server.fromMap(item));
          });
          }
        }
        if (_selectedServer == null) {
          setState(() {
            _selectedServer = listServers.elementAt(0);
          });
          _getOnlineStatus();

          //TODO Remove in future updates
          // check extension update
          //showUpdateMsg();
        }
      });
    } else {
      if(mounted){
         setState(() {
       listServers.clear(); 
      });
      }     

    }
  }

  Future<Server> _logout() async {
    await  _serverRequest.fetchInstallationId(_selectedServer, _fcmToken, "logout");
        _selectedServer.isloggedin = 0;
    return await dbHelper.upsertServer(_selectedServer, "id=?", [_selectedServer.id]);
  }

  void _loadManageServerPage(){
      Navigator.of(context).pushAndRemoveUntil(
                       FadeRoute(
                        builder: (BuildContext context) =>
                            new TokenInheritedWidget(
                                token: _fcmToken,
                                child: new ServersManage(manage: false,)),
                        settings: RouteSettings(
                            name: MyRoutes.server, isInitialRoute: false),
                      ), (Route<dynamic> route) => false);
  }

  void _showAlert() {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "Do you want to logout of the server? \n\nYou will not receive notifications for chats.",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Yes"),
            onPressed: () async {
             var sv = await _logout();
              Navigator.of(context).pop();
              _selectedServer = sv; 
              _initLists();
             
            }),
         MaterialButton(
            child: new Text("No"),
            onPressed: ()  {
              Navigator.of(context).pop();
            }),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void _showSnackBar(String text) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(text)));
  }

  Future<bool> _deleteServer() async {
      return dbHelper.deleteItem(Server.tableName, "id=?", [_selectedServer.id]);
  }

  Future<Null> _getOnlineStatus() async {
    _serverRequest.getUserOnlineStatus(_selectedServer).then((isOnline) {
      if (_user_online != isOnline) {
        setState(() {
          _user_online = isOnline;
          _selectedServer.user_online = isOnline ? 1 : 0;
        });

        dbHelper.upsertServer(_selectedServer, "id=?", [_selectedServer.id]);
      }
    });
  }

  Future<Null> _setOnlineStatus() async {
  var online =  await _serverRequest.setUserOnlineStatus(_selectedServer);
     
      setState(() {
        _selectedServer.user_online = online ? 1 : 0;
      });

        var srvr = await dbHelper.upsertServer(_selectedServer, "id=?", [_selectedServer.id]);
            setState(() {
                  _selectedServer = srvr;
                    _userOnlineLoading = false;
                });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      initialized = true;
    });

   // if (_selectedServer != null) showUpdateMsg();
  }

  void _addServer({Server server}) {
    Navigator.of(context).push(FadeRoute(
      builder: (BuildContext context) => new TokenInheritedWidget(
          token: _fcmToken, child:  LoginForm(isNew: true, server: server,)),
      settings: new RouteSettings(name: MyRoutes.login, isInitialRoute: false),
    ));
  }


  showUpdateMsg() async {
    // fetch extension version from Database
   Map<String,dynamic> configs = await  dbHelper.fetchItem(dbHelper.configTable, null, null);

   String storedVS = configs !=null ? configs[dbHelper.extVersionColumn] : null;

   _serverRequest.fetchVersionExt(_selectedServer).then((version) {
     if (version != null) {

       if(storedVS != null ){
     if(storedVS.isNotEmpty){
       // returned format is 0.1.2
       // remove the . and parse to int and compare
       num installVersion = num.tryParse(_parseVersion(version));
       num oldVersion  = num.tryParse(_parseVersion(storedVS));

       if (installVersion != null && installVersion >= oldVersion) {
         // print(vss.toString());
         _showUpdateNotice = false;
       } else {
         _showUpdateNotice = true;
         //_showBottomSheet(version);
       }
     }

       }
       else {
         var vsMap = {dbHelper.extVersionColumn:version};
         // Upsert config table
         dbHelper.upsertGeneral(dbHelper.configTable, vsMap); }

     } else {
       // _showUpdateNotice = true;
     }
   });

  }

  String _parseVersion(String vs){
   return vs.replaceAll(new RegExp(r'\.'), '');
  }

  _showBottomSheet(BuildContext ctx) {
    showModalBottomSheet<void>(
        context: ctx,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(10.0),
            height: 300.0,
            color: Colors.green,
            child: Center(
              child: new Text(
                "You can now receive notifications when the app is active.\n\nPlease update the Extension on your server to receive notifications. You can simply replace all the content in \'/extension/gcm\' with the new one from github. \n\n Visit: \n https://github.com/samapraku/lhc_gcm_extension \n\n\nDon't forget to clear your LHC cache for the update to reflect.",
                style: TextStyle(color: Colors.white),
                softWrap: true,
              ),
            ),
          );
        });
  }

  
  void _showAlertMsg(String title,String msg) {
    SimpleDialog
    dialog =

    new SimpleDialog(
      title: new Text(title,
        style: new TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        new Text(msg,
          style: new TextStyle(fontSize: 14.0),
        )
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog );
  }

  SpeedDial _speedDial(){
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
          onOpen: (){},
          onClose: (){},
          tooltip: 'Actions',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shape: CircleBorder(),
          children: [
            SpeedDialChild(
                child: Icon(Icons.refresh),
                backgroundColor: Theme.of(context).primaryColor,
                label: 'Reload list',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: () => _initLists()
            ),
            SpeedDialChild(
              child: Icon(Icons.sms),
              backgroundColor: Theme.of(context).primaryColor,
              label: 'Twilio SMS/Chat',
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () async {
    onActionLoading(true);
    // Check twilio extension before proceeding.
    var resp = await _serverRequest.isExtensionInstalled(_selectedServer, 'twilio');
    onActionLoading(false);
    if(resp){
      Navigator.of(context).push(FadeRoute(
        builder: (BuildContext context) =>  TwilioSMSChat(server:_selectedServer, refreshList: _initLists,),
        settings:
        new RouteSettings(name: MyRoutes.twilio, isInitialRoute: false),
      )
      );

    } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('Twilio Extension not installed or Network issues.')));
                }
              },
            ),

          ],
        );
  }



}
