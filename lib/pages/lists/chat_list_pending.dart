import 'dart:async';
import 'package:flutter/material.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/widget/chat_item_widget.dart';
import 'package:livehelp/pages/chat/chat_page.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/services/server_requests.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class PendingListWidget extends StatefulWidget {
  PendingListWidget(
      {Key key,
      this.listOfServers,
      this.listToAdd,
      this.loadingState,
      this.refreshList})
      : super(key: key);

  final List<Chat> listToAdd;
  final List<Server> listOfServers;

  final ValueChanged<bool> loadingState;
  final VoidCallback refreshList;

  @override
  _PendingListWidgetState createState() => new _PendingListWidgetState();
}

class _PendingListWidgetState extends State<PendingListWidget> {
  ServerRequest _serverRequest;

  List<Chat> _listToAdd;

  @override
  void initState() {
    super.initState();
    _serverRequest = new ServerRequest();
    _listToAdd = widget.listToAdd;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new RefreshIndicator(
      onRefresh: _onRefresh,
      child: new ListView.builder(
          itemCount: _listToAdd.length, itemBuilder: _itemBuilder),
    ));
  }

  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ChatItemMenuOption>>[
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.PREVIEW,
        child: const Text('Preview'),
      ),
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.REJECT,
        child: const Text('Reject Chat'),
      ),
    ];
  }

  Widget _itemBuilder(BuildContext context, int index) {
    List<Chat> reversedList = _listToAdd.reversed.toList();

    Chat chat = reversedList[index];
    Server server = widget.listOfServers
        .firstWhere((srvr) => srvr.id == chat.serverid, orElse: () => null);
    return server == null
        ? Text("Server not found")
        : GestureDetector(
            child: ChatItemWidget(
              server: server,
              chat: chat,
              menuBuilder: _itemMenuBuilder(),
              onMenuSelected: (selectedOption) {
                onItemSelected(server, chat, selectedOption);
              },
            ),
            onTap: () {
              var route = FadeRoute(
                settings: RouteSettings(name: AppRoutes.chatPage),
                builder: (BuildContext context) => new ChatPage(
                  server: server,
                  chat: chat,
                  isNewChat: true,
                  refreshList: widget.refreshList,
                ),
              );
              Navigator.of(context).push(route);
            },
          );
  }

  void onItemSelected(Server srvr, Chat chat, ChatItemMenuOption selectedMenu) {
    switch (selectedMenu) {
      case ChatItemMenuOption.PREVIEW:
        var route = new FadeRoute(
          settings: new RouteSettings(name: AppRoutes.chatPage),
          builder: (BuildContext context) => new ChatPage(
            server: srvr,
            chat: chat,
            isNewChat: true,
            refreshList: widget.refreshList,
          ),
        );
        Navigator.of(context).push(route);
        break;
      case ChatItemMenuOption.REJECT:
        widget.loadingState(true);
        _deleteChat(srvr, chat);
        break;
      default:
        break;
    }
    // print(selectedMenu.value.toString());
  }

  void _deleteChat(Server srv, Chat chat) async {
    await _serverRequest.deleteChat(srv, chat, list : 'pending').then((deleted) {
      widget.loadingState(!deleted);
//TODO
      if (deleted) _updateList(chat);
    });
  }

  void _updateList(chat) {
    setState(() {
      _listToAdd.removeWhere((cht) => chat.id == cht.id);
    });
  }

  Future<Null> _onRefresh() {
    Completer<Null> completer = new Completer<Null>();
    Timer timer = new Timer(new Duration(seconds: 3), () {
      completer.complete();
    });
    return completer.future;
  }
}
