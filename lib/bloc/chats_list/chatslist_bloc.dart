import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

import 'dart:convert';
import 'dart:developer' as developer;

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
              twilioChatList: server.twilioChatList,
              closedChatList: server.closedChatList,
              operatorsChatList: server.operatorsChatList
          );
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
        List<Chat> closedChats = List.from(currentState.closedChatList);
        List<User> operatorsChatChats = List.from(currentState.operatorsChatList);

        List<Chat> activeList =
            await _cleanList(ChatListName.active, server, activeChats);

        List<Chat> closedList =
            await _cleanList(ChatListName.closed, server, closedChats);

        List<User> operatorsList =
            await _cleanListOperator(ChatListName.operators, server, operatorsChatChats);

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
            twilioChatList: _sortByLastMessageTime(twilioList),
            closedChatList: _sortById(closedList),
            operatorsChatList: _sortByLastOperatorMessageTime(operatorsList)
        );
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
        if (server.isLoggedIn) {
          var srvr = await serverRepository.fetchChatList(server);
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

      case ChatListName.closed:
        if (server.closedChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.closedChatList);
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

  Future<List<User>> _cleanListOperator(
      ChatListName listName, Server server, List<User> listToClean) async {
    switch (listName) {
      case ChatListName.operators:
        if (server.operatorsChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateOperatorList(listToClean, server.operatorsChatList);
        }
        return listToClean;
    }
    return listToClean;
  }

  Future<List<User>> _updateOperatorList(
      List<User> chatToUpdate, List<User> listFromServer) async {
    List<User> resultList = chatToUpdate;

    await Future.forEach(listFromServer, (User map) async {
      if (resultList
          .any((chat) => chat.user_id == map.user_id && chat.serverid == map.serverid)) {
        int index = resultList.indexWhere(
            (chat) => chat.user_id == map.user_id && chat.serverid == map.serverid);
        resultList[index] = map;
      } else {
        resultList.add(map);
      }
    });

    return await _removeMissingOperatorFromList(resultList, listFromServer);
  }

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

    return await _removeMissingChatFromList(resultList, listFromServer);
  }

  List<Chat> _sortByLastMessageTime(List<Chat> listToSort) {
    listToSort.sort((a, b) => b.last_msg_time.compareTo(a.last_msg_time));
    return listToSort;
  }

  List<User> _sortByLastOperatorMessageTime(List<User> listToSort) {
    listToSort.sort((a, b) => a.last_msg_time.compareTo(b.last_msg_time));
    return listToSort;
  }

  List<Chat> _sortById(List<Chat> listToSort) {
    listToSort.sort((a, b) => a.id.compareTo(b.id));
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

  Future<List<User>> _removeMissingOperatorFromList(
      List<User> chatToClean, List<User> listToCompare) async {
    List<User> resultList = chatToClean;
    if (resultList.length > 0 && resultList.length > 0) {
      List<int> removedIndices = new List();

      int serverIdIncoming = listToCompare.first.serverid;
      resultList.asMap().forEach((index, chat) {
        if (!listToCompare.any(
            (map) => map.user_id == chat.user_id && chat.serverid == chat.serverid)) {
          //assume listToCompare belongs to a single server
          if (chat.serverid == serverIdIncoming) {
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
