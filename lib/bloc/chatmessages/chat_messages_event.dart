part of 'chat_messages_bloc.dart';

abstract class ChatMessagesEvent extends Equatable {
  final Server server;
  final Chat chat;
  const ChatMessagesEvent({required this.server, required this.chat});

  @override
  List<Object> get props => [server, chat];
}

class FetchChatMessages extends ChatMessagesEvent {
  const FetchChatMessages({
    required Server server,
    required Chat chat,
  }) : super(server: server, chat: chat);
}

class PostMessage extends ChatMessagesEvent {
  final String? message;
  final String? sender;
  const PostMessage({
    required Server server,
    required Chat chat,
    this.message,
    this.sender,
  }) : super(server: server, chat: chat);

  @override
  List<Object> get props => [server, chat, message ?? ''];
}

class CloseChat extends ChatMessagesEvent {
  const CloseChat({required Server server, required Chat chat})
      : super(server: server, chat: chat);
}

class DeleteChat extends ChatMessagesEvent {
  const DeleteChat({required Server server, required Chat chat})
      : super(server: server, chat: chat);
}

class AcceptChat extends ChatMessagesEvent {
  const AcceptChat({required Server server, required Chat chat})
      : super(server: server, chat: chat);
}
