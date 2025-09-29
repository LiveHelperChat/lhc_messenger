import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/widget/widget.dart';
import 'package:livehelp/utils/utils.dart';

import 'package:livehelp/utils/routes.dart' as LHCRouter;

class ActiveListWidget extends StatefulWidget {
  final List<Server>? listOfServers;
  final VoidCallback? refreshList;
  final Function(Server, Chat) callbackCloseChat;
  final Function(Server, Chat) callBackDeleteChat;

  const ActiveListWidget(
      {Key? key,
      this.listOfServers,
      this.refreshList,
      required this.callbackCloseChat,
      required this.callBackDeleteChat})
      : super(key: key);

  @override
  _ActiveListWidgetState createState() => _ActiveListWidgetState();
}

class _ActiveListWidgetState extends State<ActiveListWidget> {
  ServerRepository? _serverRepository;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _serverRepository = context.watch<ServerRepository>();
    return BlocBuilder<ChatslistBloc, ChatListState>(
        builder: (context, state) {
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
              itemCount: state.activeChatList.length,
              itemBuilder: (BuildContext context, int index) {
                if (state.activeChatList.isNotEmpty) {
                  Chat chat = state.activeChatList[index];
                  Server server = widget.listOfServers!.firstWhere(
                      (srvr) => srvr.id == chat.serverid,
                      orElse: () => Server());

                  return server.id == null
                      ? const Text("No server found")
                      : GestureDetector(
                          child: ChatItemWidget(
                            server: server,
                            chat: chat,
                            menuBuilder: _itemMenuBuilder(),
                            onMenuSelected: (selectedOption) {
                              onItemSelected(
                                  context, server, chat, selectedOption);
                            },
                          ),
                          onTap: () {
                            /*  var route = new FadeRoute(
                            settings:
                                new RouteSettings(name: AppRoutes.chatPage),
                            builder: (BuildContext context) => ChatPage(
                              server: server,
                              chat: chat,
                              isNewChat: false,
                              refreshList: widget.refreshList,
                            ),
                          ); */
                            // RouteArguments is used to track chatpage widget
                            // foreground state
                            final routeArgs = RouteArguments(chatId: chat.id);
                            final routeSettings = RouteSettings(
                                name: AppRoutes.chatPage, arguments: routeArgs);
                            var route = LHCRouter.Router.generateRouteChatPage(
                                routeSettings,
                                chat,
                                server,
                                false,
                                widget.refreshList!);
                            Navigator.of(context).push(route);
                          },
                        );
                } else {
                  return Container();
                }
              });
        }
      }

      if (state is ChatListLoadError) {
        return ErrorReloadButton(
          child: Text("An error occurred: ${state.message}"),
          actionText: 'Refrescar',
          onButtonPress: () {
            print("Refrescar");
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
        value: ChatItemMenuOption.CLOSE,
        child: const Text('Cerrar'),
      ),
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.REJECT,
        child: const Text('Borrar'),
      ),
      const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.TRANSFER,
        child: const Text('Transferir'),
      ),
    ];
  }

  void onItemSelected(
      BuildContext ctx, Server srv, Chat chat, ChatItemMenuOption result) {
    switch (result) {
      case ChatItemMenuOption.CLOSE:
        widget.callbackCloseChat(srv, chat);
        break;
      case ChatItemMenuOption.REJECT:
        widget.callBackDeleteChat(srv, chat);
        break;
      case ChatItemMenuOption.TRANSFER:
        // widget.loadingState(true);
        _showOperatorList(ctx, srv, chat);
        //_getOperatorList(ctx,srv,chat);
        break;
      default:
        break;
    }
  }

  Future<List<dynamic>> _getOperatorList(
      BuildContext context, Server srvr, Chat chat) async {
    return await _serverRepository!.getOperatorsList(srvr);
  }

  void _showOperatorList(BuildContext context, Server srvr, Chat chat) {
    var futureBuilder = FutureBuilder(
      future: _getOperatorList(context, srvr, chat),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Text('cargando...');
          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return createListView(context, snapshot, srvr, chat);
            }
        }
      },
    );

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Container(
              child: new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Text(
                  "Seleccione operador conectado",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                new Divider(),
                Expanded(
                  child: futureBuilder,
                )
              ],
            ),
          ));
        });
  }

  Future<bool> _transferToUser(Server srvr, Chat chat, int userid) async {
    return _serverRepository!.transferChatUser(srvr, chat, userid);
  }

  Widget createListView(
      BuildContext context, AsyncSnapshot snapshot, Server srvr, Chat chat) {
    List<dynamic> listOP = snapshot.data;

    return listOP.isNotEmpty
        ? ListView.builder(
            reverse: false,
            padding: new EdgeInsets.all(6.0),
            itemCount: listOP.length,
            itemBuilder: (_, int index) {
              Map operator = listOP[index];
              return new ListTile(
                title: new Text(
                    'Nombre: ${operator["name"]} ${operator["surname"]}'),
                subtitle: new Text('Título: ${operator["job_title"]}'),
                onTap: () async {
                  await _transferToUser(srvr, chat, int.parse(operator['id']));
                  Navigator.of(context).pop();
                },
              );
            },
          )
        : const Text('No hay operadores conectados');
  }
}
