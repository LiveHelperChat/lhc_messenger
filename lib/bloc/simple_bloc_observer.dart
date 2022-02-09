import 'package:bloc/bloc.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    if (event.toString() == 'MessageReceivedEvent') print('onEvent $event');
    super.onEvent(bloc, event);
  }


  @override
  void onError(BlocBase  cubit, Object error, StackTrace stackTrace) {
    print('onError $error');
    super.onError(cubit, error, stackTrace);
  }
}
