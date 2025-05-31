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
          emit(Authenticated(user: user));
        } else {
          emit(
            AuthFailure(
              message: 'Registrasi berhasil tetapi user tidak di temukan',
            ),
          );
        }
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
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
}
