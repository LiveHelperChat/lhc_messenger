part of 'chat_messages_bloc.dart';

enum MessagesListStatus { isSuccess, isloading }

class ChatMessagesState extends Equatable {
  const ChatMessagesState();
  @override
  List<Object> get props => [];
}

class ChatMessagesLoaded extends ChatMessagesState {
  final Server server;
  final Chat chat;
  final List<Message> messages;
  final String chatStatus;
  final int chatStatusCode;
  final bool isLoading;
  final bool isChatClosed;
  final bool isChatAccepted;
  const ChatMessagesLoaded(
      {required this.server,
        required this.chat,
        this.messages = const [],
        this.chatStatus = "",
        this.chatStatusCode = 0,
        this.isLoading = false,
        this.isChatClosed = false,
        this.isChatAccepted = true});

  ChatMessagesLoaded copyWith(
      {Server? server,
        Chat? chat,
        List<Message>? messages,
        String? chatStatus,
        int? chatStatusCode,
        bool? isLoading,
        bool? isChatAccepted,
        bool? isChatClosed})  {
    return ChatMessagesLoaded(
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

class ChatMessagesInitial extends ChatMessagesState {}

class ChatMessagesLoadError extends ChatMessagesState {
  final String? message;
  const ChatMessagesLoadError({this.message});

  @override
  List<Object> get props => [];
}

