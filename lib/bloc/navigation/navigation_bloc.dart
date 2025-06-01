// navigation_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(SplashPageState()) {
    // Register all event handlers with proper syntax
    on<NavigateToLogin>((event, emit) {
      emit(LoginPageState());
    });

    on<NavigateToRegister>((event, emit) {
      emit(RegisterPageState());
    });

    on<NavigateToHome>((event, emit) {
      emit(HomePageState());
    });

    on<NavigateToCreate>((event, emit) {
      emit(CreateEventPageState());
    });

    on<NavigateToSplash>((event, emit) {
      emit(SplashPageState());
    });
  }
}
