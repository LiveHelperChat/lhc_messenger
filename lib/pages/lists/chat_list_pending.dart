import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/widget.dart';

class PendingListWidget extends StatefulWidget {
  const PendingListWidget(
      {Key? key,
      this.listOfServers,
      required this.callBackDeleteChat,
      this.refreshList})
      : super(key: key);

  final List<Server>? listOfServers;
  final Function(Server, Chat) callBackDeleteChat;

  final VoidCallback? refreshList;

  @override
  _PendingListWidgetState createState() => _PendingListWidgetState();
}

class _PendingListWidgetState extends State<PendingListWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatslistBloc, ChatListState>(builder: (context, state) {
      if (state is ChatslistInitial) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state is ChatListLoaded) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return ListView.builder(
              itemCount: state.pendingChatList.length,
              itemBuilder: (BuildContext context, int index) {
                Chat chat = state.pendingChatList.reversed.toList()[index];
                Server server = widget.listOfServers!.firstWhere(
                    (srvr) => srvr.id == chat.serverid,
                    orElse: () => Server());

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
                    /* var route = FadeRoute(
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
                  ); */
                    final routeArgs = RouteArguments(chatId: chat.id);
                    final routeSettings = RouteSettings(
                        name: AppRoutes.chatPage, arguments: routeArgs);
                    var route = LHCRouter.Router.generateRouteChatPage(
                        routeSettings, chat, server, true, widget.refreshList!);
                    Navigator.of(context).push(route);
                  },
                );
              });
        }
      }

      if (state is ChatListLoadError) {
        return ErrorReloadButton(
          child: Text("An error occurred: ${state.message}"),
          actionText: 'Reload',
          onButtonPress: () {
            context.read<ChatslistBloc>().add(ChatListInitialise());
          },
        );
      }

      return ListView.builder(
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) {
            return const Text("No list available");
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
        final routeArgs = RouteArguments(chatId: chat.id);
        final routeSettings =
            RouteSettings(name: AppRoutes.chatPage, arguments: routeArgs);
        var route = LHCRouter.Router.generateRouteChatPage(
            routeSettings, chat, srvr, true, widget.refreshList!);
        Navigator.of(ctxt).push(route);
        break;
      case ChatItemMenuOption.REJECT:
        widget.callBackDeleteChat(srvr, chat);
        break;
      default:
        break;
    }
  }
}
