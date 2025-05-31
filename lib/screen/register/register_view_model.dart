import 'package:flutter/material.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_event.dart';

class RegisterViewModel extends ChangeNotifier {
  final AppBloc appBloc;

  RegisterViewModel({required this.appBloc});

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  bool _isLoading = false;
  String? _error;

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get name => _name;
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

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  Future<void> register() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Validasi password dan konfirmasi
    if (_password != _confirmPassword) {
      _error = 'Password dan Konfirmasi Password tidak cocok';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      appBloc.add(SignUp(
        email: _email,
        password: _password,
        name: _name,
      ));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
