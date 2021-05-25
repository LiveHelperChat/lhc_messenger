part of 'twilio_bloc.dart';

abstract class TwilioState extends Equatable {
  const TwilioState();

  @override
  List<Object> get props => [];
}

class TwilioInitial extends TwilioState {}

class TwilioStatus extends TwilioState {
  final bool isInstalled;

  const TwilioStatus({this.isInstalled = false});

  @override
  List<Object> get props => [isInstalled];
}
