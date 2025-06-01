import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tubes/data/repositories/auth_repository.dart';

import 'app_event.dart';
import 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final AuthRepository authRepository;

  AppBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = authRepository.currentUser;
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      } catch (_) {
        emit(Unauthenticated());
      }
    });

    on<LoggedIn>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signInWithEmail(event.email, event.password);
        final user = authRepository.currentUser;
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    });

    on<SignUp>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signUpWithEmail(
          event.email,
          event.password,
          name: event.name,
        );

        final user = authRepository.currentUser;

        if (user != null) {
          // Emit success first, then authenticated
          emit(AuthSuccess());
          // Small delay to ensure success state is processed
          await Future.delayed(Duration(milliseconds: 100));
          emit(Authenticated(user: user));
        } else {
          emit(
            AuthFailure(message: 'Registration successful but user not found'),
          );
        }
      } catch (e) {
        // Better error handling for Firebase Auth errors
        String errorMessage = _getFirebaseErrorMessage(e.toString());
        emit(AuthFailure(message: errorMessage));
      }
    });

    on<LoggedOut>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signOut();
        emit(Unauthenticated());
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    });
  }

  String _getFirebaseErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address. Please enter a valid email.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Registration failed. Please try again.';
    }
  }
}
