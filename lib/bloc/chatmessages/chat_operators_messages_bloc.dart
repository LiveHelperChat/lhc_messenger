import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'chat_operators_messages_event.dart';
part 'chat_operators_messages_state.dart';

class ChatOperatorsMessagesBloc extends Bloc<ChatOperatorsMessagesEvent, ChatOperatorsMessagesState>{
  final ServerRepository serverRepository;
  ChatOperatorsMessagesBloc({@required this.serverRepository}) : assert(serverRepository != null), super(ChatOperatorsMessagesInitial());

  @override
  Stream<ChatOperatorsMessagesState> mapEventToState(ChatOperatorsMessagesEvent event) async* {
    final currentState = state;

    if (event is FetchOperatorsChatMessages) {
      yield* _mapChatMessagesLoadedToState(event, currentState);
    } else if (event is PostOperatorsMessage) {
      if (currentState is ChatOperatorsMessagesLoaded) {
        await serverRepository.postOperatorsMesssage(event.server, event.chat, event.message);
        this.add(FetchOperatorsChatMessages(server: event.server, chat: event.chat));
      }
    } else if (event is CloseOperatorsChat || event is DeleteOperatorsChat) {
      var closed = false;
      if (currentState is ChatOperatorsMessagesLoaded) {
        yield currentState.copyWith(isLoading: true);
        try{
          if(event is CloseOperatorsChat) {
            closed = await serverRepository.closeOperatorsChat(
                event.server, event.chat);
          }
          else if(event is DeleteOperatorsChat){
            closed = await serverRepository.deleteOperatorsChat(event.server, event.chat);
          }
          yield currentState.copyWith(isChatClosed: closed,  isLoading: false);
        } catch(ex){
          yield currentState.copyWith(isLoading: false);
          yield ChatOperatorsMessagesLoadError(message: "${ex?.message}");
        }
      }
    }
  }

  Stream<ChatOperatorsMessagesState> _mapChatMessagesLoadedToState(
      FetchOperatorsChatMessages event,
      ChatOperatorsMessagesState currentState,
      ) async* {
    /*try {*/

      if (event.chat.chat_id == null || event.chat.chat_id == 0) {
          return;
      }

      String chatStatus = "";
      int chatStatusCode = 0;
      int lastMsgId = 0;
      var chatData = {};
      List<Message> msgs = [];

      if (currentState is ChatOperatorsMessagesLoaded) {
        lastMsgId = currentState.messages.length > 0 ? currentState.messages.last.id : 0;
      }

      chatData = await serverRepository.syncOperatorsMessages(event.server, event.chat, lastMsgId);

      if (chatData.containsKey('chat_status')) {
        chatStatus = chatData['chat_status'] ?? "";
      }

      if (chatData.containsKey('chat_scode')) {
        chatStatusCode = chatData['chat_scode'] ?? 0;
      }

      if (chatData.containsKey('messages')) {
        msgs.addAll(chatData['messages']);
      }

      if( state is ChatOperatorsMessagesInitial){
        yield ChatOperatorsMessagesLoaded(server:
        event.server,
            chat: event.chat,
            messages: msgs,
            chatStatus: chatStatus,
            chatStatusCode: chatStatusCode);
      }

      if(currentState is ChatOperatorsMessagesLoaded) {
        yield currentState.copyWith(server:
        event.server,
            chat: event.chat,
            messages: List.from(currentState.messages)..addAll(msgs),
            chatStatus: chatStatus,
            chatStatusCode: chatStatusCode);
      }

    /*} on Exception {
      yield ChatOperatorsMessagesLoadError(message: "Chat list could not be loaded");
    }*/
  }
}