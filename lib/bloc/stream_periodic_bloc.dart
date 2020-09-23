import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:livehelp/bloc/bloc.dart';

class StreamPeriodicBloc extends Bloc {
  final BehaviorSubject<bool> _onTerminate = BehaviorSubject<bool>();

  Stream<dynamic> _scheduler;

  StreamSubscription _streamSub;

  void executeStreamPeriodic(Duration duration, Function func) {
    _scheduler = Stream.periodic(duration).takeUntil(_onTerminate.stream);

    _streamSub = _scheduler.listen((_) {
      func();
    });
  }

  void pause() {
    if(!_streamSub.isPaused)
    _streamSub.pause();
  }

  void resume(){
    if(_streamSub.isPaused)
    _streamSub.resume();
  }

  @override
  void dispose() async {
    _onTerminate.close();
    await _streamSub?.cancel();
  }
}
