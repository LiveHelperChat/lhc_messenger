import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/widget/widget.dart';
import 'package:livehelp/pages/chat/chat_page.dart';
import 'package:livehelp/utils/routes.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class PendingListWidget extends StatefulWidget {
  PendingListWidget(
      {Key key,
      this.listOfServers,
      @required this.callBackDeleteChat,
      this.refreshList})
      : super(key: key);

  final List<Server> listOfServers;
  final Function(Server, Chat) callBackDeleteChat;

  final VoidCallback refreshList;

  @override
  _PendingListWidgetState createState() => new _PendingListWidgetState();
}

class _PendingListWidgetState extends State<PendingListWidget> {
  ServerRepository _serverRepository;

  List<Chat> _listToAdd;

  @override
  void initState() {
    super.initState();
    _serverRepository = context.repository<ServerRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatslistBloc, ChatListState>(builder: (context, state) {
      if (state is ChatslistInitial) {
        return Center(child: CircularProgressIndicator());
      }

      if (state is ChatListLoaded) {
        return ListView.builder(
            itemCount: state.pendingChatList.length,
            itemBuilder: (BuildContext context, int index) {
              Chat chat = state.pendingChatList.reversed.toList()[index];
              Server server = widget.listOfServers.firstWhere(
                  (srvr) => srvr.id == chat.serverid,
                  orElse: () => null);

              return GestureDetector(
                child: ChatItemWidget(
                  server: server,
                  chat: chat,
                  menuBuilder: _itemMenuBuilder(),
                  onMenuSelected: (selectedOption) {
                    onItemSelected(context, server, chat, selectedOption);
                  },
                ),
                onTap: () {
                  var route = FadeRoute(
                    settings: RouteSettings(name: AppRoutes.chatPage),
                    builder: (BuildContext context) =>
                        BlocProvider<ChatMessagesBloc>(
                            create: (context) => ChatMessagesBloc(
                                serverRepository: _serverRepository),
                            child: ChatPage(
                              server: server,
                              chat: chat,
                              isNewChat: true,
                              refreshList: widget.refreshList,
                            )),
                  );
                  Navigator.of(context).push(route);
                },
              );
            });
      }

      if (state is ChatListLoadError) {
        return ErrorReloadButton(
          message: "An error occurred: ${state.message}",
          actionText: 'Reload',
          onButtonPress: () {
            context.bloc<ChatslistBloc>().add(ChatListInitialise());
          },
        );
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

  void onItemSelected(BuildContext ctxt, Server srvr, Chat chat,
      ChatItemMenuOption selectedMenu) {
    switch (selectedMenu) {
      case ChatItemMenuOption.PREVIEW:
        var route = new FadeRoute(
          settings: new RouteSettings(name: AppRoutes.chatPage),
          builder: (ctxt) => ChatPage(
            server: srvr,
            chat: chat,
            isNewChat: true,
            refreshList: widget.refreshList,
          ),
        );
        Navigator.of(ctxt).push(route);
        break;
      case ChatItemMenuOption.REJECT:
        widget.callBackDeleteChat(srvr, chat);
        break;
      default:
        break;
    }
  }

  void _updateList(chat) {
    setState(() {
      _listToAdd.removeWhere((cht) => chat.id == cht.id);
    });
  }
}
