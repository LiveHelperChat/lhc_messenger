part of 'fcmtoken_bloc.dart';

abstract class FcmTokenState extends Equatable {
  final String token;
  const FcmTokenState({this.token});

  @override
  List<Object> get props => [];
}

class FcmTokenInitial extends FcmTokenState {}

class FcmTokenReceived extends FcmTokenState {
  final String token;
  const FcmTokenReceived({@required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}

class FcmTokenRefreshed extends FcmTokenState {
  final String token;
  const FcmTokenRefreshed({@required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}
