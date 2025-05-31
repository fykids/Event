import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_event.dart';
import 'package:tubes/bloc/app/app_state.dart';

class LoginViewModel extends ChangeNotifier {
  final AppBloc appBloc;

  late final StreamSubscription _subscription;

  LoginViewModel({required this.appBloc}) {
    _subscription = appBloc.stream.listen((state) {
      if (state is AuthLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      } else if (state is Authenticated) {
        _isLoading = false;
        _error = null;
        notifyListeners();
      } else if (state is AuthFailure) {
        _isLoading = false;
        _error = state.message;
        notifyListeners();
      } else if (state is Unauthenticated) {
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  Future<void> login() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      appBloc.add(LoggedIn(email: _email, password: _password));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
