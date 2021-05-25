import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'chat_messages_event.dart';
part 'chat_messages_state.dart';

class ChatMessagesBloc extends Bloc<ChatMessagesEvent, ChatMessagesState>{
  final ServerRepository serverRepository;
  ChatMessagesBloc({@required this.serverRepository}) : assert(serverRepository != null), super(ChatMessagesInitial());

  @override
  Stream<ChatMessagesState> mapEventToState(ChatMessagesEvent event) async* {
    final currentState = state;

   if (event is FetchChatMessages) {
      yield* _mapChatMessagesLoadedToState(event, currentState);
   } else if (event is PostMessage) {
     if (currentState is ChatMessagesLoaded) {
       await serverRepository.postMesssage(event.server, event.chat, event.message);
       this.add(FetchChatMessages(server: event.server, chat: event.chat));
      }
    } else if (event is CloseChat || event is DeleteChat){
     var closed = false;
     if (currentState is ChatMessagesLoaded) {
       yield currentState.copyWith(isLoading: true);
       try{
         if(event is CloseChat) {
           closed = await serverRepository.closeChat(
               event.server, event.chat);
         }
         else if(event is DeleteChat){
           closed = await serverRepository.deleteChat(event.server, event.chat);
         }
         yield currentState.copyWith(isChatClosed: closed,  isLoading: false);
       } catch(ex){
         yield currentState.copyWith(isLoading: false);
         yield ChatMessagesLoadError(message: "${ex?.message}");
       }
      }
     }
  }

  Stream<ChatMessagesState> _mapChatMessagesLoadedToState(
      FetchChatMessages event,
      ChatMessagesState currentState,
      ) async* {
    try {
      String chatStatus = "";
      int chatStatusCode = 0;
      int lastMsgId = 0;
      var chatData = {};
      List<Message> msgs = [];

      if(currentState is ChatMessagesLoaded) {
        lastMsgId = currentState.messages.length > 0 ? currentState.messages.last.id : 0;
      }
      
      chatData = await serverRepository.syncMessages(event.server, event.chat, lastMsgId);

      if (chatData.containsKey('chat_status')) {
         chatStatus = chatData['chat_status'] ?? "";
      }

      if (chatData.containsKey('chat_scode')) {
        chatStatusCode = chatData['chat_scode'] ?? 0;
      }

      if (chatData.containsKey('messages')) {
           msgs.addAll(chatData['messages']);
      }

      if( state is ChatMessagesInitial){
        yield ChatMessagesLoaded(server:
        event.server,
            chat: event.chat,
            messages: msgs,
            chatStatus: chatStatus,
            chatStatusCode: chatStatusCode);
      }

      if(currentState is ChatMessagesLoaded) {
        yield currentState.copyWith(server:
        event.server,
            chat: event.chat,
            messages: List.from(currentState.messages)..addAll(msgs),
            chatStatus: chatStatus,
            chatStatusCode: chatStatusCode);
      }

    } on Exception {
      yield ChatMessagesLoadError(message: "Chat list could not be loaded");
    }
  }
}