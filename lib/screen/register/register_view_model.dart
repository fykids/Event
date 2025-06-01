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
    _error = null; // Clear error when user changes input
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    _error = null;
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    _error = null;
    notifyListeners();
  }

  void updateName(String value) {
    _name = value;
    _error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> register() async {
    // Basic validation (form validation should handle most of this)
    if (_name.trim().isEmpty ||
        _email.trim().isEmpty ||
        _password.isEmpty ||
        _confirmPassword.isEmpty) {
      setError("Please fill all fields");
      return;
    }

    if (_password != _confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    // Clear any previous errors
    _error = null;
    notifyListeners();

    try {
      // Send event to AppBloc for registration
      // The BlocListener in the UI will handle the loading state
      appBloc.add(
        SignUp(
          name: _name.trim(),
          email: _email.trim().toLowerCase(),
          password: _password,
        ),
      );
    } catch (e) {
      setError("Registration failed: ${e.toString()}");
    }
  }

  void reset() {
    _email = '';
    _password = '';
    _confirmPassword = '';
    _name = '';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
