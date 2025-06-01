import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_state.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/screen/login/login_screen.dart';
import 'package:tubes/screen/register/register_view_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatelessWidget {
  final AppBloc appBloc;
  const RegisterScreen({super.key, required this.appBloc});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(appBloc: appBloc),
      child: const RegisterScreenBody(),
    );
  }
}

class RegisterScreenBody extends StatefulWidget {
  const RegisterScreenBody({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreenBody>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
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
      body: BlocListener<AppBloc, AppState>(
        bloc: context.read<RegisterViewModel>().appBloc,
        listener: (context, state) {
          final viewModel = context.read<RegisterViewModel>();

          if (state is AuthLoading) {
            // Registration in progress
            viewModel.setLoading(true);
          } else if (state is AuthSuccess) {
            // Registration successful - show success message
            viewModel.setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Don't navigate immediately, wait for Authenticated state
          } else if (state is Authenticated) {
            // User is now authenticated, navigate to login or home
            viewModel.setLoading(false);

            // Navigate to home or dashboard instead of login
            // Since user is already authenticated after registration
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) =>
                    LoginScreen(appBloc: context.read<AppBloc>()),
              ),
              (route) => false,
            );
          } else if (state is AuthFailure) {
            // Registration failed
            viewModel.setLoading(false);
            viewModel.setError(state.message);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is Unauthenticated) {
            // Handle unauthenticated state
            viewModel.setLoading(false);
          }
        },
        child: Container(
          decoration: GradientBackground.decoration,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const RegisterLogoSection(),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Consumer<RegisterViewModel>(
                          builder: (context, viewModel, child) {
                            return RegisterForm(
                              formKey: _formKey,
                              nameController: _nameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              isPasswordVisible: _isPasswordVisible,
                              isConfirmPasswordVisible:
                                  _isConfirmPasswordVisible,
                              isLoading: viewModel.isLoading,
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
                                context.read<NavigationBloc>().add(
                                  NavigateToLogin(),
                                );
                              },
                            );
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
      ),
    );
  }

  void _handleRegister() async {
    final viewModel = context.read<RegisterViewModel>();

    // Clear any previous errors
    viewModel.clearError();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update view model dengan nilai dari controller
    viewModel.updateName(_nameController.text.trim());
    viewModel.updateEmail(_emailController.text.trim());
    viewModel.updatePassword(_passwordController.text);
    viewModel.updateConfirmPassword(_confirmPasswordController.text);

    // Call register - the BlocListener will handle the response
    await viewModel.register();
  }
}

class RegisterLogoSection extends StatelessWidget {
  const RegisterLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RegisterGlowingLogo(),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) =>
                    YellowGradients.primary.createShader(bounds),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
  const RegisterGlowingLogo({super.key});

  @override
  RegisterGlowingLogoState createState() => RegisterGlowingLogoState();
}

class RegisterGlowingLogoState extends State<RegisterGlowingLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _glowController;
  Animation<double>? _glowAnimation;

  @override
  void initState() {
    super.initState();
    try {
      _glowController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowController!, curve: Curves.easeInOut),
      );

      // Start the animation after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _glowController != null) {
          _glowController!.repeat(reverse: true);
        }
      });
    } catch (e) {
      debugPrint('Error initializing glow animation: $e');
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback if animation is not initialized
    if (_glowAnimation == null || _glowController == null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: YellowGradients.primary,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFEB3B).withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.person_add_outlined,
          size: 40,
          color: Colors.black87,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glowAnimation!,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: YellowGradients.primary,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFFEB3B,
                ).withOpacity(0.6 * _glowAnimation!.value),
                blurRadius: 25 * _glowAnimation!.value,
                spreadRadius: 8 * _glowAnimation!.value,
              ),
            ],
          ),
          child: const Icon(
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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFEB3B).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  onChanged: (value) => onTermsToggle(),
                  activeColor: const Color(0xFFFFEB3B),
                  checkColor: Colors.black87,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      children: const [
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
            const SizedBox(height: 24),
            GradientButton(
              onPressed: isLoading ? null : onRegister,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black87,
                        ),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                TextButton(
                  onPressed: onBackToLogin,
                  child: const Text(
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
