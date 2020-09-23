import 'dart:async';

import 'package:livehelp/bloc/stream_periodic_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/model/server.dart';

class ChatPageBloc extends StreamPeriodicBloc {
  final chatMessagesService;
  final Server server;
  final Chat chat;

  final PublishSubject<int> _syncMsgsSubject = PublishSubject<int>();
  final PublishSubject<Map<String, dynamic>> _chatDataSubject =
      PublishSubject();
  final PublishSubject<List<Message>> _msgsCollectionSubject = PublishSubject();

  Sink<void> get inSyncMsgs => _syncMsgsSubject.sink;

  Stream<List<Message>> get chatMessages$ => _msgsCollectionSubject.stream;
  Stream<Map<String, dynamic>> get chatData$ => _chatDataSubject.stream;
  Stream<dynamic> _sheduler;

  final BehaviorSubject<int> _lastMsgIdSubject =
      new BehaviorSubject<int>.seeded(0);
  int get _currentLastMsgId => _lastMsgIdSubject.value;
  Stream<int> get lastMsgId$ => _lastMsgIdSubject.stream;

  final BehaviorSubject<String> _chatStatusSubject =
      BehaviorSubject<String>.seeded("");
  Stream<String> get chatStatus$ => _chatStatusSubject.stream;
  Sink<String> get inChatStatus => _chatStatusSubject.sink;

  final BehaviorSubject<int> _chatStatusCodeSubject = BehaviorSubject<int>();
  Stream<int> get chatStatusCode => _chatStatusCodeSubject.stream;
  Sink<int> get inChatStatusCode => _chatStatusCodeSubject.sink;
/*
  final BehaviorSubject<bool> _onTerminate = BehaviorSubject<bool>();

  StreamSubscription _streamSub;

  Stream<Map<String, dynamic>> chatDataRepeat$() async* {
    yield* Stream.periodic(Duration(seconds: 5), (_) {
      return chatMessagesService.syncMessages(server, chat, _currentLastMsgId);
    }).asyncMap(
      (value) async => await value,
    );
  } */

  Stream<Map<String, dynamic>> fetchChatData$() async* {
    yield* Stream.fromFuture(
        chatMessagesService.syncMessages(server, chat, _currentLastMsgId));
  }

  ChatPageBloc(this.chatMessagesService, this.server, this.chat) {
    syncMessages();
    _syncMessagesPeriodic();

    _chatDataSubject.stream.listen((chatMsgs) {
      print(chatMsgs.toString());
      if (chatMsgs.containsKey('messages')) {
        if (!_msgsCollectionSubject.isClosed) {
          _msgsCollectionSubject.add(chatMsgs['messages']);
        }
        if (!_lastMsgIdSubject.isClosed) {
          _lastMsgIdSubject.add(chatMsgs['messages'].last.id);
        }
      }

      if (!_chatStatusSubject.isClosed) {
        _chatStatusSubject.add(chatMsgs['chat_status'] ?? "");
      }

      if (!_chatStatusCodeSubject.isClosed) {
        _chatStatusCodeSubject.add(chatMsgs['chat_scode'] ?? 0);
      }
    });
  }

  void _syncMessagesPeriodic() {
    /*_sheduler =
        Stream.periodic(Duration(seconds: 3)).takeUntil(_onTerminate.stream);

    _streamSub = _sheduler.listen((_) {
      syncMessages();
    });*/
    executeStreamPeriodic(Duration(seconds: 5), syncMessages);
  }

  void syncMessages() {
    chatMessagesService
        .syncMessages(server, chat, _currentLastMsgId)
        .then((chatData) {
      if (!_chatDataSubject.isClosed) {
        _chatDataSubject.add(chatData);
      }
    });
  }

  @override
  void pause() {
    super.pause();
  }

  @override
  void resume() {
    super.resume();
  }

  @override
  void dispose() {
    _syncMsgsSubject.close();
    _chatDataSubject.close();
    _msgsCollectionSubject.close();
    _lastMsgIdSubject.close();
    _chatStatusSubject.close();
    _chatStatusCodeSubject.close();
    super.dispose();
  }
}
