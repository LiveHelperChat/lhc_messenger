part of 'chat_operators_messages_bloc.dart';

class ChatOperatorsMessagesState extends Equatable {
  const ChatOperatorsMessagesState();
  @override
  List<Object> get props => [];
}

class ChatOperatorsMessagesLoaded extends ChatOperatorsMessagesState {
  final Server server;
  final User chat;
  final List<Message> messages;
  final String chatStatus;
  final int chatStatusCode;
  final bool isLoading;
  final bool isChatClosed;
  final bool isChatAccepted;
  const ChatOperatorsMessagesLoaded(
      {required this.server,
        required this.chat,
        this.messages = const [],
        this.chatStatus = "",
        this.chatStatusCode = 0,
        this.isLoading = false,
        this.isChatClosed = false,
        this.isChatAccepted = true});

  ChatOperatorsMessagesLoaded copyWith(
      {Server? server,
        User? chat,
        List<Message>? messages,
        String? chatStatus,
        int? chatStatusCode,
        bool? isLoading,
        bool? isChatAccepted,
        bool? isChatClosed}) {
    return ChatOperatorsMessagesLoaded(
        server: server ?? this.server,
        chat: chat ?? this.chat,
        messages: messages ?? this.messages,
        chatStatus: chatStatus ?? this.chatStatus,
        chatStatusCode: chatStatusCode ?? this.chatStatusCode,
        isLoading: isLoading ?? this.isLoading,
        isChatAccepted: isChatAccepted ?? this.isChatAccepted,
        isChatClosed: isChatClosed ?? this.isChatClosed);
  }

  @override
  List<Object> get props =>
      [server, chat, messages, chatStatus, chatStatusCode, isLoading];
}

class ChatOperatorsMessagesInitial extends ChatOperatorsMessagesState {}

class ChatOperatorsMessagesLoadError extends ChatOperatorsMessagesState {
  final String? message;
  const ChatOperatorsMessagesLoadError({this.message});

  @override
  List<Object> get props => [];
}

