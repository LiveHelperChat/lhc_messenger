import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/services/server_repository.dart';

part 'twilio_event.dart';
part 'twilio_state.dart';

class TwilioBloc extends Bloc<TwilioEvent, TwilioState> {
  final ServerRepository? serverRepository;
  final DatabaseHelper? databaseHelper;
  TwilioBloc({this.serverRepository, this.databaseHelper})
      : super(TwilioInitial()) {
    on(mapEventToState);
  }

  Future<void> mapEventToState(
      TwilioEvent event, Emitter<TwilioState> emit) async {}
}
