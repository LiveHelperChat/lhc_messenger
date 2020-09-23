import 'dart:async';

import 'package:livehelp/bloc/stream_periodic_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/services/chat_list_service.dart';
import 'package:livehelp/services/twilio_service.dart';

class ChatsListBloc extends StreamPeriodicBloc {
  DatabaseHelper _dBHelper;
  ChatListService _chatListService;
  TwilioService _twilioService;

  List<Server> serversList = <Server>[];

  final PublishSubject<List<Server>> _serversListSubject =
      PublishSubject<List<Server>>();

  final BehaviorSubject<Server> _selectedServerSubject =
      BehaviorSubject<Server>();
  Server get selectedServer => _selectedServerSubject.value;

  final PublishSubject<List<Server>> _chatsListSubject =
      PublishSubject<List<Server>>();
  final PublishSubject<List<Chat>> _activeChatListSubject =
      PublishSubject<List<Chat>>();
  final PublishSubject<List<Chat>> _pendingChatListSubject =
      PublishSubject<List<Chat>>();
  final PublishSubject<List<Chat>> _transferChatListSubject =
      PublishSubject<List<Chat>>();
  final PublishSubject<List<Chat>> _twilioChatListSubject =
      PublishSubject<List<Chat>>();

  Stream<dynamic> _scheduler;
  Stream<List<Server>> get serversList$ => _serversListSubject.stream;
  Stream<List<Chat>> get activeChatList$ => _activeChatListSubject.stream;
  Stream<List<Chat>> get pendingChatList$ => _pendingChatListSubject.stream;
  Stream<List<Chat>> get transferChatList$ => _transferChatListSubject.stream;
  Stream<List<Chat>> get twilioChatList$ => _twilioChatListSubject.stream;
  /**/

  StreamSubscription _streamSub;

  final BehaviorSubject<bool> _onTerminate = BehaviorSubject<bool>();

  final List<Chat> _activeChatList = <Chat>[];
  final List<Chat> _pendingChatList = <Chat>[];
  final List<Chat> _transferChatList = <Chat>[];

  ChatsListBloc(ChatListService chatListService, TwilioService twilioService) {
    _dBHelper = new DatabaseHelper();
    _chatListService = chatListService;
    _twilioService = twilioService;

    loadServers();
    _serversListSubject.stream.listen((listOfServers) async {
      //getChatList();
      print("out loop");
      // getChatListPeriodic();
    });
  }

  @override
  void pause() {
    super.pause();
  }

  @override
  void resume() {
    super.resume();
  }

  @override
  void dispose() {
    _selectedServerSubject.close();
    _serversListSubject.close();
    _chatsListSubject.close();
    print("Disposed");
    super.dispose();
  }

  void _addServers(List<Server> servers) {
    servers.forEach((element) {});
  }

  void loadServers() async {
    //await  Future.delayed(const Duration(seconds: 1), () async {  });
    await _getSavedServers();
    //Load list first
    getChatList();
    //Initiate periodic loading
    getChatListPeriodic();
  }

  Future<Null> _getSavedServers() async {
    // get logged in servers
    List<Map> savedRecs = await _dBHelper.fetchAll(Server.tableName,
        "${Server.columns['db_id']}  ASC", "isloggedin=?", [1]);

    if (savedRecs != null && savedRecs.length > 0) {
      savedRecs.forEach((item) {
        Server newServer = new Server.fromMap(item);
        if (!(serversList.any((srvr) => srvr == newServer))) {
          print(item.toString());
          serversList.add(newServer);
          _activeChatListSubject.add(newServer.activeChatList);
        } else {
          int index = serversList.indexWhere((srvr) => srvr == newServer);
          serversList[index] = newServer;
        }

        if (selectedServer == null) {
          //  _selectedServerSubject.add(_serversList.elementAt(0));
          //    _getOnlineStatus();
          //    _getTwilioStatus();
        }
      });
    } else {
      serversList.clear();
      _serversListSubject.add(serversList);
    }
  }

  void getChatListPeriodic() {
    executeStreamPeriodic(Duration(seconds: 5), getChatList);
  }

  void getChatList() async {
    // No logged in server
    if (serversList.length > 0) {
      // TODO remove this line
      // await _getSavedServers();
      List<Chat> activeLists = [];
      List<Chat> pendingLists = [];
      List<Chat> transferLists = [];
      List<Chat> twilioLists = [];
      List<Server> serverList = <Server>[];
      print("HERE 1");
      await Future.forEach(serversList, (Server server) async {
        if (server.loggedIn) {
          var srvr = await _chatListService.getChatLists(server);
          if (srvr.activeChatList != null && srvr.activeChatList.length > 0) {
            _activeChatListSubject.add(srvr.activeChatList);

            _serversListSubject.add(serversList);
          } else {
            _activeChatList.removeWhere((chat) => chat.serverid == srvr.id);
          }

          if (srvr.pendingChatList != null && srvr.pendingChatList.length > 0) {
            _pendingChatListSubject.add(srvr.pendingChatList);
          }

          if (srvr.transferChatList != null &&
              srvr.transferChatList.length > 0) {
            _transferChatListSubject.add(srvr.transferChatList);
          }

          if (server.twilioInstalled == true) {
            var svr2 = await _twilioService.getTwilioChats(server);

            if (svr2.twilioChatList != null && svr2.twilioChatList.length > 0) {
              _twilioChatListSubject.add(svr2.twilioChatList);
            }
          }

          serverList.add(server);
        }
      });

      if (serverList.length > 0) {
        _serversListSubject.add(serverList);
      }
    }
  }

  List<Chat> cleanUpLists(
      List<Chat> chatToClean, List<dynamic> listFromServer) {
    listFromServer.map((map) => new Chat.fromMap(map));
    listFromServer.forEach((map) {
      if (chatToClean
          .any((chat) => chat.id == map.id && chat.serverid == map.serverid)) {
        int index = chatToClean.indexWhere(
            (chat) => chat.id == map.id && chat.serverid == map.serverid);
        chatToClean[index] = map;
      } else {
        chatToClean.add(map);
      }
    });

    chatToClean.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
    return chatToClean;
  }
}
