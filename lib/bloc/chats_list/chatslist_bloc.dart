import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'chatslist_event.dart';
part 'chatslist_state.dart';

class ChatslistBloc extends Bloc<ChatslistEvent, ChatListState> {
  final ServerRepository serverRepository;

  ChatslistBloc({this.serverRepository}) : super(ChatslistInitial());

  @override
  Stream<ChatListState> mapEventToState(
    ChatslistEvent event,
  ) async* {
    final currentState = state;
    if (event is ChatListInitialise) {
      yield ChatslistInitial();
    } else if (event is FetchChatsList) {
      yield* _mapChatListLoadedToState(event, state);
    } else if (event is CloseChatMainPage || event is DeleteChatMainPage) {
      if (currentState is ChatListLoaded) {
        yield currentState.copyWith(isLoading: true);
        try {
          if (event is CloseChatMainPage) {
            await serverRepository.closeChat(event.server, event.chat);
            add(FetchChatsList(server: event.server));
          } else if (event is DeleteChatMainPage) {
            await serverRepository.deleteChat(event.server, event.chat);
            add(FetchChatsList(server: event.server));
          }
          yield currentState.copyWith(isLoading: false);
        } catch (ex) {
          yield currentState.copyWith(isLoading: false);
          yield ChatListLoadError(message: "${ex?.message}");
        }
      }
    }
  }

  Stream<ChatListState> _mapChatListLoadedToState(
    FetchChatsList event,
    ChatListState currentState,
  ) async* {
    try {
      if (currentState is ChatslistInitial) {
        try {
          var server = await serverRepository.fetchChatList(event.server);

          yield ChatListLoaded(
              activeChatList: server.activeChatList,
              pendingChatList: server.pendingChatList,
              transferChatList: server.transferChatList,
              twilioChatList: server.twilioChatList);
        } catch (ex) {
          yield ChatListLoadError(message: "${ex?.message}");
        }
      }

      if (currentState is ChatListLoaded) {
        var server = await serverRepository.fetchChatList(event.server);
        // without List.from, the listview will not rebuild
        List<Chat> activeChats = List.from(currentState.activeChatList);
        List<Chat> pendingChats = List.from(currentState.pendingChatList);
        List<Chat> transferChats = List.from(currentState.transferChatList);
        List<Chat> twilioChats = List.from(currentState.twilioChatList);

        List<Chat> activeList =
            await _cleanList(ChatListName.active, server, activeChats);
        List<Chat> pendingList =
            await _cleanList(ChatListName.pending, server, pendingChats);

        List<Chat> transferList =
            await _cleanList(ChatListName.transfer, server, transferChats);
        List<Chat> twilioList =
            await _cleanList(ChatListName.twilio, server, twilioChats);

        yield ChatListLoaded(
            activeChatList: _sortByLastMessageTime(activeList),
            pendingChatList: pendingList,
            transferChatList: transferList,
            twilioChatList: twilioList);
      }
    } on Exception {
      yield ChatListLoadError(message: "Chat list could not be loaded");
    }
  }

  Future<List<Server>> getChatList() async {
    // No logged in server
    var listServers =
        await serverRepository.getServersFromDB(onlyLoggedIn: true);

    List<Server> serverList = <Server>[];

    if (listServers.length > 0) {
      await Future.forEach(listServers, (Server server) async {
        if (server.loggedIn) {
          var srvr = await serverRepository.fetchChatList(server);

          if (server.twilioInstalled == true) {
            //srvr = await serverRepository.getTwilioChats(srvr);
          }
          serverList.add(srvr);
        }
      });
    }
    return serverList;
  }

  Future<List<Chat>> _cleanList(
      ChatListName listName, Server server, List<Chat> listToClean) async {
    switch (listName) {
      case ChatListName.active:
        if (server.activeChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.activeChatList);
        }
        return listToClean;

      case ChatListName.pending:
        if (server.pendingChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.pendingChatList);
        }
        return listToClean;
      case ChatListName.transfer:
        if (server.transferChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.transferChatList);
        }
        return listToClean;
      case ChatListName.twilio:
        if (server.twilioChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.twilioChatList);
        }
        return listToClean;
    }
    return listToClean;
  }

/*
  List<Chat> _cleanList(Server server, List<Chat> listToClean) {
    print("Updating from server");
    // remove chats from state if no list returned
    if (server.activeChatList.length == 0) {
      if(listToClean.length > 0)
        listToClean.removeWhere((chat) => chat.serverid == server.id);
    }

    if (server.pendingChatList.length > 0) {
      _updateList(pendingChatList, server.pendingChatList);
    } else {
      this.pendingChatList.removeWhere((chat) => chat.serverid == server.id);
    }
    if (server.transferChatList.length > 0) {
      this.transferChatList.removeWhere((chat) => chat.serverid == server.id);
    }
    if (server.transferChatList.length > 0) {
      _updateList(transferChatList, server.transferChatList);
    } else {
      this.transferChatList.removeWhere((chat) => chat.serverid == server.id);
    }
    if (server.twilioChatList.length > 0) {
      _updateList(twilioChatList, server.twilioChatList);
    } else {
      this.twilioChatList.removeWhere((chat) => chat.serverid == server.id);
    }
  }

  */

  Future<List<Chat>> _updateChatList(
      List<Chat> chatToUpdate, List<Chat> listFromServer) async {
    List<Chat> resultList = chatToUpdate;
    await Future.forEach(listFromServer, (Chat map) async {
      if (resultList
          .any((chat) => chat.id == map.id && chat.serverid == map.serverid)) {
        int index = resultList.indexWhere(
            (chat) => chat.id == map.id && chat.serverid == map.serverid);
        resultList[index] = map;
      } else {
        resultList.add(map);
      }
    });
    //return chatToUpdate;
    //return resultList;
    return await _removeMissingChatFromList(resultList, listFromServer);
  }

  List<Chat> _sortByLastMessageTime(List<Chat> listToSort) {
    listToSort.sort((a, b) => b.last_msg_time.compareTo(a.last_msg_time));
    return listToSort;
  }

  /*Remove chats which have been closed from another device */
  Future<List<Chat>> _removeMissingChatFromList(
      List<Chat> chatToClean, List<Chat> listToCompare) async {
    List<Chat> resultList = chatToClean;
    if (resultList.length > 0 && resultList.length > 0) {
      List<int> removedIndices = new List();

      int serverIdIncoming = listToCompare.first.serverid;
      resultList.asMap().forEach((index, chat) {
        if (!listToCompare.any(
            (map) => map.id == chat.id && chat.serverid == chat.serverid)) {
          //assume listToCompare belongs to a single server
          if (chat.serverid == serverIdIncoming) {
            // int index = resultList.indexOf(chat);
            // print("index: " + index.toString());
            removedIndices.add(index);
          }
        }
      });

      //remove the chats
      if (removedIndices != null && removedIndices.length > 0) {
        removedIndices.sort();
        removedIndices.reversed.toList().forEach(resultList.removeAt);
        removedIndices.clear();
      }
    }
    return resultList;
  }
}
