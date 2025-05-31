import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_state.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/screen/login/login_view_model.dart';

class LoginScreen extends StatelessWidget {
  final AppBloc appBloc;
  const LoginScreen({super.key, required this.appBloc});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(appBloc: appBloc),
      child: LoginScreenBody(),
    );
  }
}

class LoginScreenBody extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenBody>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GradientBackground.decoration,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: LogoSection(),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: BlocListener<AppBloc, AppState>(
                          listener: (context, state) {
                            if (state is Authenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Login berhasil! Selamat datang ${state.user.displayName ?? state.user.email}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );

                              context.read<NavigationBloc>().add(
                                NavigateToHome(),
                              );
                            } else if (state is AuthFailure) {
                              // Login gagal - tampilkan error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Login gagal: ${state.message}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                          child: Consumer<LoginViewModel>(
                            builder: (context, loginVM, child) {
                              return LoginForm(
                                formKey: _formKey,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                isPasswordVisible: _isPasswordVisible,
                                isLoading: loginVM.isLoading,
                                onPasswordVisibilityToggle: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                onLogin: () async {
                                  if (_formKey.currentState!.validate()) {
                                    loginVM.updateEmail(
                                      _emailController.text.trim(),
                                    );
                                    loginVM.updatePassword(
                                      _passwordController.text,
                                    );
                                    await loginVM.login();
                                  }
                                },
                                onGoogleLogin: () {
                                  // Implement Google login
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Google login akan segera tersedia',
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;

  const LoginForm({
    Key? key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onPasswordVisibilityToggle,
    required this.onLogin,
    required this.onGoogleLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFFFEB3B).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: passwordController,
                label: 'Password',
                isPassword: true,
                isPasswordVisible: isPasswordVisible,
                prefixIcon: Icons.lock_outline,
                onPasswordToggle: onPasswordVisibilityToggle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 14),
                  ),
                ),
              ),
              SizedBox(height: 24),
              GradientButton(
                onPressed: onLogin,
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black87,
                          ),
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  context.read<NavigationBloc>().add(NavigateToRegister());
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFFFFEB3B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[600])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 20),
              GoogleSignInButton(
                onPressed: isLoading ? null : onGoogleLogin,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
