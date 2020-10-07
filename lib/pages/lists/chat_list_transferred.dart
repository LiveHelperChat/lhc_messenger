import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/widget/chat_item_widget.dart';
import 'package:livehelp/pages/chat/chat_page.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/services/server_api_client.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class TransferredListWidget extends StatefulWidget {
  TransferredListWidget({
    Key key,
    this.listOfServers,
    this.refreshList,
  }) : super(key: key);

  final List<Server> listOfServers;
  final VoidCallback refreshList;

  @override
  _TransferredListWidgetState createState() =>
      new _TransferredListWidgetState();
}

class _TransferredListWidgetState extends State<TransferredListWidget> {
  ServerApiClient _serverRequest;

  @override
  void initState() {
    super.initState();
    _serverRequest = ServerApiClient(httpClient: http.Client());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatslistBloc, ChatListState>(builder: (context, state) {
      if (state is ChatslistInitial) {
        return Center(child: CircularProgressIndicator());
      }

      if (state is ChatListLoaded) {
        return ListView.builder(
            itemCount: state.transferChatList.length,
            itemBuilder: (BuildContext context, int index) {
              Chat chat = state.transferChatList[index];
              Server server = widget.listOfServers.firstWhere(
                  (srvr) => srvr.id == chat.serverid,
                  orElse: () => null);

              return GestureDetector(
                child: new ChatItemWidget(
                  server: server,
                  chat: chat,
                  menuBuilder: _itemMenuBuilder(),
                  onMenuSelected: (selectedOption) {
                    onItemSelected(server, chat, selectedOption);
                  },
                ),
                onTap: () {},
              );
            });
      }
      if (state is ChatListLoadError) {
        return Text("An error occurred: ${state.message}");
      }
      return ListView.builder(
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) {
            return Text("No list available");
          });
    });
  }

  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ChatItemMenuOption>>[
      /*  const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.ACCEPT,
      child: const Text('Accept Chat'),
    ),  */
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.ACCEPT,
        child: const Text('Accept Chat'),
      ),
    ];
  }

  void onItemSelected(Server srvr, Chat chat, ChatItemMenuOption selectedMenu) {
    switch (selectedMenu) {
      case ChatItemMenuOption.ACCEPT:
        _acceptChat(srvr, chat);
        break;
      default:
        break;
    }
  }

  void _acceptChat(Server srv, Chat chat) async {
    await _serverRequest.acceptChatTransfer(srv, chat);
    widget.refreshList();
    var route = new FadeRoute(
      settings: new RouteSettings(name: AppRoutes.chatPage),
      builder: (BuildContext context) => new ChatPage(
        server: srv,
        chat: chat,
        isNewChat: false,
      ),
    );

    Navigator.of(context).push(route);
  }
}
