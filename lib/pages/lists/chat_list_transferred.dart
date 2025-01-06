import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/widget.dart';

class TransferredListWidget extends StatefulWidget {
  const TransferredListWidget({
    Key? key,
    this.listOfServers,
    this.refreshList,
  }) : super(key: key);

  final List<Server>? listOfServers;
  final VoidCallback? refreshList;

  @override
  _TransferredListWidgetState createState() => _TransferredListWidgetState();
}

class _TransferredListWidgetState extends State<TransferredListWidget> {
  ServerApiClient? _serverRequest;
  @override
  void initState() {
    super.initState();
    _serverRequest = ServerApiClient(httpClient: http.Client());
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
              itemCount: state.transferChatList.length,
              itemBuilder: (BuildContext context, int index) {
                Chat chat = state.transferChatList[index];
                Server server = widget.listOfServers!.firstWhere(
                    (srvr) => srvr.id == chat.serverid,
                    orElse: () => Server());

                return GestureDetector(
                  child: ChatItemWidget(
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
    await _serverRequest!.acceptChatTransfer(srv, chat);
    widget.refreshList!();

    final routeArgs = RouteArguments(chatId: chat.id);
    final routeSettings =
        RouteSettings(name: AppRoutes.chatPage, arguments: routeArgs);
    var route = LHCRouter.Router.generateRouteChatPage(
        routeSettings, chat, srv, false, widget.refreshList!);

    Navigator.of(context).push(route);
  }
}
