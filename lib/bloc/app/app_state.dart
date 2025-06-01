import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AppState extends Equatable {
  const AppState();
}

class AuthInitial extends AppState {
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AppState {
  @override
  List<Object?> get props => [];
}

class Authenticated extends AppState {
  final User user;
  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

class Unauthenticated extends AppState {
  @override
  List<Object?> get props => [];
}

class AuthFailure extends AppState {
  final String message;
  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSuccess extends AppState {
  @override
  List<Object?> get props => [];
}
