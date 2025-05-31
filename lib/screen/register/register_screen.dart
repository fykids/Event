import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/screen/register/register_view_model.dart';

class RegisterScreen extends StatelessWidget {
  final AppBloc appBloc;
  const RegisterScreen({super.key, required this.appBloc});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(appBloc: appBloc),
      child: RegisterScreenBody(),
    );
  }
}

class RegisterScreenBody extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreenBody>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GradientBackground.decoration,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 24,
              ), // tambah padding atas bawah
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: RegisterLogoSection(),
                  ),
                  SizedBox(height: 24),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RegisterForm(
                        formKey: _formKey,
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        isPasswordVisible: _isPasswordVisible,
                        isConfirmPasswordVisible: _isConfirmPasswordVisible,
                        isLoading: _isLoading,
                        acceptTerms: _acceptTerms,
                        onPasswordVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        onConfirmPasswordVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        onTermsToggle: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        onRegister: _handleRegister,
                        onBackToLogin: () {
                          context.read<NavigationBloc>()
                            ..add(NavigateToLogin());
                        },
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

  void _handleRegister() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      setState(() {
        _isLoading = true;
      });

      // Simulate register process
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Add your register logic here
      print(
        'Register with name: ${_nameController.text}, email: ${_emailController.text}',
      );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class RegisterLogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RegisterGlowingLogo(),
              SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) =>
                    YellowGradients.primary.createShader(bounds),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Join us today',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterGlowingLogo extends StatefulWidget {
  @override
  _RegisterGlowingLogoState createState() => _RegisterGlowingLogoState();
}

class _RegisterGlowingLogoState extends State<RegisterGlowingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: YellowGradients.primary,
            boxShadow: [
              BoxShadow(
                color: Color(
                  0xFFFFEB3B,
                ).withOpacity(0.6 * _glowAnimation.value),
                blurRadius: 25 * _glowAnimation.value,
                spreadRadius: 8 * _glowAnimation.value,
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: 40,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool isLoading;
  final bool acceptTerms;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onConfirmPasswordVisibilityToggle;
  final VoidCallback onTermsToggle;
  final VoidCallback onRegister;
  final VoidCallback onBackToLogin;

  const RegisterForm({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.isLoading,
    required this.acceptTerms,
    required this.onPasswordVisibilityToggle,
    required this.onConfirmPasswordVisibilityToggle,
    required this.onTermsToggle,
    required this.onRegister,
    required this.onBackToLogin,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Full Name',
              keyboardType: TextInputType.name,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(
                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                ).hasMatch(value)) {
                  return 'Password must contain uppercase, lowercase, and number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              isPassword: true,
              isPasswordVisible: isConfirmPasswordVisible,
              prefixIcon: Icons.lock_outline,
              onPasswordToggle: onConfirmPasswordVisibilityToggle,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  onChanged: (value) => onTermsToggle(),
                  activeColor: Color(0xFFFFEB3B),
                  checkColor: Colors.black87,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: Color(0xFFFFEB3B),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFFFFEB3B),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            GradientButton(
              onPressed: isLoading ? null : onRegister,
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                TextButton(
                  onPressed: onBackToLogin,
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFFFFEB3B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
