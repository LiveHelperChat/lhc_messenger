import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'chatslist_event.dart';
part 'chatslist_state.dart';

class ChatslistBloc extends Bloc<ChatslistEvent, ChatListState> {
  final ServerRepository? serverRepository;

  ChatslistBloc({this.serverRepository}) : super(ChatslistInitial()) {
    on<ChatListInitialise>(_onChatListInitialise);
    on<FetchChatsList>(_onFetchChatsList);
    on<CloseChatMainPage>(_onCloseChatMainPage);
    on<DeleteChatMainPage>(_onDeleteChatMainPage);
  }

  Future<void> _onChatListInitialise(
      ChatListInitialise event, Emitter<ChatListState> emit) async {
    emit(ChatslistInitial());
  }

  Future<void> _onFetchChatsList(
      FetchChatsList event, Emitter<ChatListState> emit) async {
    final currentState = state;
    try {
      if (currentState is ChatslistInitial) {
        try {
          var server = await serverRepository!.fetchChatList(event.server);

          emit(ChatListLoaded(
              activeChatList: server.activeChatList,
              pendingChatList: server.pendingChatList,
              transferChatList: server.transferChatList,
              twilioChatList: server.twilioChatList,
              closedChatList: server.closedChatList,
              botChatList: server.botChatList,
              subjectChatList: server.subjectChatList,
              operatorsChatList: server.operatorsChatList,
              userOnline: server.userOnline));
        } catch (ex) {
          print("error here");
          print(ex.toString());
          emit(ChatListLoadError(message: ex.toString()));
        }
      }

      if (currentState is ChatListLoaded) {
        var server = await serverRepository!.fetchChatList(event.server);
        // without List.from, the listview will not rebuild
        List<Chat> activeChats = List.from(currentState.activeChatList);
        List<Chat> pendingChats = List.from(currentState.pendingChatList);
        List<Chat> transferChats = List.from(currentState.transferChatList);
        List<Chat> twilioChats = List.from(currentState.twilioChatList);
        List<Chat> closedChats = List.from(currentState.closedChatList);
        List<Chat> botChats = List.from(currentState.botChatList);
        List<Chat> subjectChats = List.from(currentState.subjectChatList);
        List<User> operatorsChatChats =
            List.from(currentState.operatorsChatList);

        List<Chat> activeList =
            await _cleanList(ChatListName.active, server, activeChats);

        List<Chat> closedList =
            await _cleanList(ChatListName.closed, server, closedChats);

        List<Chat> botList =
            await _cleanList(ChatListName.bot, server, botChats);

        List<Chat> subjectList =
            await _cleanList(ChatListName.subject, server, subjectChats);

        List<User> operatorsList = await _cleanListOperator(
            ChatListName.operators, server, operatorsChatChats);

        List<Chat> pendingList =
            await _cleanList(ChatListName.pending, server, pendingChats);

        List<Chat> transferList =
            await _cleanList(ChatListName.transfer, server, transferChats);

        List<Chat> twilioList =
            await _cleanList(ChatListName.twilio, server, twilioChats);
        emit(ChatListLoaded(
            activeChatList: _sortByLastMessageTime(activeList),
            pendingChatList: pendingList,
            transferChatList: transferList,
            twilioChatList: _sortByLastMessageTime(twilioList),
            closedChatList: _sortById(closedList),
            botChatList: _sortByLastMessageTime(botList),
            subjectChatList: _sortByLastMessageTime(subjectList),
            operatorsChatList: _sortByLastOperatorMessageTime(operatorsList),
            userOnline: server.userOnline));
      }
    } on Exception {
      emit(ChatListLoadError(message: "Chat list could not be loaded"));
    }
  }

  Future<void> _onCloseChatMainPage(
      CloseChatMainPage event, Emitter<ChatListState> emit) async {
    final currentState = state;
    if (currentState is ChatListLoaded) {
      emit(currentState.copyWith(isLoading: true));
      try {
        await serverRepository!.closeChat(event.server, event.chat);
        add(FetchChatsList(server: event.server));
        emit(currentState.copyWith(isLoading: false));
      } catch (ex) {
        emit(currentState.copyWith(isLoading: false));
        emit(ChatListLoadError(message: ex.toString()));
      }
    }
  }

  Future<void> _onDeleteChatMainPage(
      DeleteChatMainPage event, Emitter<ChatListState> emit) async {
    final currentState = state;
    if (currentState is ChatListLoaded) {
      emit(currentState.copyWith(isLoading: true));
      try {
        await serverRepository!.deleteChat(event.server, event.chat);
        add(FetchChatsList(server: event.server));
        emit(currentState.copyWith(isLoading: false));
      } catch (ex) {
        emit(currentState.copyWith(isLoading: false));
        emit(ChatListLoadError(message: ex.toString()));
      }
    }
  }

  Future<List<Server>> getChatList() async {
    // No logged in server
    var listServers =
        await serverRepository!.getServersFromDB(onlyLoggedIn: true);

    List<Server> serverList = <Server>[];

    if (listServers.isNotEmpty) {
      await Future.forEach(listServers, (Server server) async {
        if (server.isLoggedIn) {
          var srvr = await serverRepository!.fetchChatList(server);
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
        if (server.activeChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.activeChatList);
        }
        return listToClean;

      case ChatListName.pending:
        if (server.pendingChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.pendingChatList);
        }
        return listToClean;

      case ChatListName.bot:
        if (server.botChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean = await _updateChatList(listToClean, server.botChatList);
        }
        return listToClean;

      case ChatListName.subject:
        if (server.subjectChatList.length == 0) {
          if (listToClean.length > 0) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.subjectChatList);
        }
        return listToClean;

      case ChatListName.closed:
        if (server.closedChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.closedChatList);
        }
        return listToClean;

      case ChatListName.transfer:
        if (server.transferChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.transferChatList);
        }
        return listToClean;

      case ChatListName.twilio:
        if (server.twilioChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateChatList(listToClean, server.twilioChatList);
        }
        return listToClean;
      default:
        return listToClean;
    }
  }

  Future<List<User>> _cleanListOperator(
      ChatListName listName, Server server, List<User> listToClean) async {
    switch (listName) {
      case ChatListName.operators:
        if (server.operatorsChatList.isEmpty) {
          if (listToClean.isNotEmpty) {
            listToClean.removeWhere((chat) => chat.serverid == server.id);
          }
        } else {
          listToClean =
              await _updateOperatorList(listToClean, server.operatorsChatList);
        }
        return listToClean;
      default:
        return listToClean;
    }
  }

  Future<List<User>> _updateOperatorList(
      List<User> chatToUpdate, List<User> listFromServer) async {
    List<User> resultList = chatToUpdate;

    await Future.forEach(listFromServer, (User map) async {
      if (resultList.any((chat) =>
          chat.user_id == map.user_id && chat.serverid == map.serverid)) {
        int index = resultList.indexWhere((chat) =>
            chat.user_id == map.user_id && chat.serverid == map.serverid);
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
    listToSort.sort((a, b) => a.last_msg_time!.compareTo(b.last_msg_time!));
    return listToSort;
  }

  List<Chat> _sortById(List<Chat> listToSort) {
    listToSort.sort((a, b) => a.id!.compareTo(b.id!));
    return listToSort;
  }

  /*Remove chats which have been closed from another device */
  Future<List<Chat>> _removeMissingChatFromList(
      List<Chat> chatToClean, List<Chat> listToCompare) async {
    List<Chat> resultList = chatToClean;
    if (resultList.isNotEmpty && resultList.isNotEmpty) {
      List<int> removedIndices = [];

      int? serverIdIncoming = listToCompare.first.serverid;
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
      if (removedIndices.isNotEmpty) {
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
    if (resultList.isNotEmpty && resultList.isNotEmpty) {
      List<int> removedIndices = List.empty();

      int? serverIdIncoming = listToCompare.first.serverid;
      resultList.asMap().forEach((index, chat) {
        if (!listToCompare.any((map) =>
            map.user_id == chat.user_id && chat.serverid == chat.serverid)) {
          //assume listToCompare belongs to a single server
          if (chat.serverid == serverIdIncoming) {
            removedIndices.add(index);
          }
        }
      });

      //remove the chats
      if (removedIndices.isNotEmpty) {
        removedIndices.sort();
        removedIndices.reversed.toList().forEach(resultList.removeAt);
        removedIndices.clear();
      }
    }
    return resultList;
  }
}
