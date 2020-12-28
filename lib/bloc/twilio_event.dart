part of 'twilio_bloc.dart';

abstract class TwilioEvent extends Equatable {
  const TwilioEvent();

  @override
  List<Object> get props => [];
}

class GetTwilioStatus extends TwilioEvent {
  @override
  List<Object> get props => [];
}
