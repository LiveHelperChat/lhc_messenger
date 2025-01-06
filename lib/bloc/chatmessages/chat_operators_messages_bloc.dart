// ignore_for_file: unused_local_variable

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'chat_operators_messages_event.dart';
part 'chat_operators_messages_state.dart';

class ChatOperatorsMessagesBloc
    extends Bloc<ChatOperatorsMessagesEvent, ChatOperatorsMessagesState> {
  final ServerRepository? serverRepository;
  ChatOperatorsMessagesBloc({this.serverRepository})
      : super(ChatOperatorsMessagesInitial()) {
    on<FetchOperatorsChatMessages>(_onFetchOperatorsChatMessages);
    on<PostOperatorsMessage>(_onPostOperatorsMessage);
    on<CloseOperatorsChat>(_onCloseOperatorsChat);
    on<DeleteOperatorsChat>(_onDeleteOperatorsChat);
  }

  Future<void> _onFetchOperatorsChatMessages(FetchOperatorsChatMessages event,
      Emitter<ChatOperatorsMessagesState> emit) async {
    final currentState = state;

    if (event.chat.chat_id == null || event.chat.chat_id == 0) {
      return;
    }

    String chatStatus = "";
    int chatStatusCode = 0;
    int? lastMsgId = 0;
    Map chatData = {};
    List<Message> msgs = [];

    if (currentState is ChatOperatorsMessagesLoaded) {
      lastMsgId =
          currentState.messages.isNotEmpty ? currentState.messages.last.id : 0;
    }

    chatData = await serverRepository?.syncOperatorsMessages(
            event.server, event.chat, lastMsgId!) ??
        {};

    if (chatData.containsKey('chat_status')) {
      chatStatus = chatData['chat_status'] ?? "";
    }

    if (chatData.containsKey('chat_scode')) {
      chatStatusCode = chatData['chat_scode'] ?? 0;
    }

    if (chatData.containsKey('messages')) {
      msgs.addAll(chatData['messages']);
    }

    if (state is ChatOperatorsMessagesInitial) {
      emit(ChatOperatorsMessagesLoaded(
          server: event.server,
          chat: event.chat,
          messages: msgs,
          chatStatus: chatStatus,
          chatStatusCode: chatStatusCode));
    }

    if (currentState is ChatOperatorsMessagesLoaded) {
      emit(currentState.copyWith(
          server: event.server,
          chat: event.chat,
          messages: List.from(currentState.messages)..addAll(msgs),
          chatStatus: chatStatus,
          chatStatusCode: chatStatusCode));
    }
  }

  Future<void> _onPostOperatorsMessage(PostOperatorsMessage event,
      Emitter<ChatOperatorsMessagesState> emit) async {
    final currentState = state;
    if (currentState is ChatOperatorsMessagesLoaded) {
      var id = await serverRepository?.postOperatorsMesssage(
          event.server, event.chat, event.message!);
      add(FetchOperatorsChatMessages(server: event.server, chat: event.chat));
    }
  }

  Future<void> _onCloseOperatorsChat(CloseOperatorsChat event,
      Emitter<ChatOperatorsMessagesState> emit) async {
    bool? closed = false;
    final currentState = state;
    if (currentState is ChatOperatorsMessagesLoaded) {
      emit(currentState.copyWith(isLoading: true));
      try {
        closed = await serverRepository?.closeOperatorsChat(
            event.server, event.chat);
        emit(currentState.copyWith(isChatClosed: closed, isLoading: false));
      } catch (ex) {
        emit(currentState.copyWith(isLoading: false));
        emit(ChatOperatorsMessagesLoadError(message: ex.toString()));
      }
    }
  }

  Future<void> _onDeleteOperatorsChat(DeleteOperatorsChat event,
      Emitter<ChatOperatorsMessagesState> emit) async {
    bool? closed = false;
    final currentState = state;
    if (currentState is ChatOperatorsMessagesLoaded) {
      emit(currentState.copyWith(isLoading: true));
      try {
        closed = await serverRepository?.deleteOperatorsChat(
            event.server, event.chat);
        emit(currentState.copyWith(isChatClosed: closed, isLoading: false));
      } catch (ex) {
        emit(currentState.copyWith(isLoading: false));
        emit(ChatOperatorsMessagesLoadError(message: ex.toString()));
      }
    }
  }
}
