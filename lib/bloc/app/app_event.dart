import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();
}

class AppStarted extends AppEvent {
  @override
  List<Object?> get props => [];
}

class LoggedIn extends AppEvent {
  final String email;
  final String password;

  const LoggedIn({required this.email, required this.password});

  @override
  // TODO: implement props
  List<Object?> get props => [email, password];
}

class SignUp extends AppEvent {
  final String email;
  final String password;
  final String? name;

  const SignUp({required this.email, required this.password, required this.name});

  @override
  // TODO: implement props
  List<Object?> get props => [email, password];
}

class LoggedOut extends AppEvent {
  @override
  List<Object?> get props => [];
}
