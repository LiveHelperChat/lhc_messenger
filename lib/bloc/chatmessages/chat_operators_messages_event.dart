part of 'chat_operators_messages_bloc.dart';

abstract class ChatOperatorsMessagesEvent extends Equatable {
  final Server server;
  final User chat;
  const ChatOperatorsMessagesEvent({required this.server, required this.chat});

  @override
  List<Object> get props => [server, chat];
}

class FetchOperatorsChatMessages extends ChatOperatorsMessagesEvent {
  const FetchOperatorsChatMessages({required Server server, required User chat})
      : super(server: server, chat: chat);
}

class PostOperatorsMessage extends ChatOperatorsMessagesEvent {
  final String? message;
  const PostOperatorsMessage(
      {required Server server, required User chat, this.message})
      : super(server: server, chat: chat);

  @override
  List<Object> get props => [server, chat, message!];
}

class CloseOperatorsChat extends ChatOperatorsMessagesEvent {
  const CloseOperatorsChat({required Server server, required User chat})
      : super(server: server, chat: chat);
}

class DeleteOperatorsChat extends ChatOperatorsMessagesEvent {
  const DeleteOperatorsChat({required Server server, required User chat})
      : super(server: server, chat: chat);
}

class AcceptOperatorsChat extends ChatOperatorsMessagesEvent {
  const AcceptOperatorsChat({required Server server, required User chat})
      : super(server: server, chat: chat);
}
