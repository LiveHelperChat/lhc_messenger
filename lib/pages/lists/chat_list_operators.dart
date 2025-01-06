import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/widget.dart';

class OperatorsListWidget extends StatefulWidget {
  const OperatorsListWidget(
      {Key? key,
      this.listOfServers,
      required this.callBackDeleteChat,
      this.refreshList})
      : super(key: key);

  final List<Server>? listOfServers;
  final Function(Server, Chat) callBackDeleteChat;

  final VoidCallback? refreshList;

  @override
  _OperatorsListWidgetState createState() => _OperatorsListWidgetState();
}

class _OperatorsListWidgetState extends State<OperatorsListWidget> {
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
              itemCount: state.operatorsChatList.length,
              itemBuilder: (BuildContext context, int index) {
                User chat = state.operatorsChatList.reversed.toList()[index];
                Server server = widget.listOfServers!.firstWhere(
                    (srvr) => srvr.id == chat.serverid,
                    orElse: () => new Server());

                return GestureDetector(
                  child: OperatorItemWidget(
                    server: server,
                    chat: chat,
                    menuBuilder: _itemMenuBuilder(),
                    onMenuSelected: (selectedOption) {
                      onItemSelected(context, server, chat, selectedOption);
                    },
                  ),
                  onTap: () {
                    final routeArgs = RouteArguments(chatId: chat.user_id);
                    final routeSettings = RouteSettings(
                        name: AppRoutes.operatorsChatPage,
                        arguments: routeArgs);
                    var route = LHCRouter.Router.generateRouteOperatorsChatPage(
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
            return Text("No list available");
          });
    });
  }

  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ChatItemMenuOption>>[
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.PREVIEW,
        child: const Text('Start chat'),
      )
    ];
  }

  void onItemSelected(BuildContext ctxt, Server srvr, User chat,
      ChatItemMenuOption selectedMenu) {
    switch (selectedMenu) {
      case ChatItemMenuOption.PREVIEW:
        final routeArgs = RouteArguments(chatId: chat.user_id);
        final routeSettings = RouteSettings(
            name: AppRoutes.operatorsChatPage, arguments: routeArgs);
        var route = LHCRouter.Router.generateRouteOperatorsChatPage(
            routeSettings, chat, srvr, true, widget.refreshList!);
        Navigator.of(ctxt).push(route);
        break;
      default:
        break;
    }
  }
}
