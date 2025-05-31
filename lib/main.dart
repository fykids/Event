import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_event.dart';
import 'package:tubes/bloc/app/app_state.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/bloc/navigation/navigation_state.dart';
import 'package:tubes/data/repositories/auth_repository.dart';
import 'package:tubes/firebase_options.dart';
import 'package:tubes/screen/home/home_screen.dart';
import 'package:tubes/screen/login/login_screen.dart';
import 'package:tubes/screen/login/login_view_model.dart';
import 'package:tubes/screen/register/register_screen.dart';
import 'package:tubes/screen/register/register_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        BlocProvider<AppBloc>(
          create: (context) {
            final bloc = AppBloc(
              authRepository: context.read<AuthRepository>(),
            );
            bloc.add(AppStarted());
            return bloc;
          },
        ),
        BlocProvider<NavigationBloc>(
          create: (_) => NavigationBloc()..add(NavigateToLogin()),
        ),
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(appBloc: context.read<AppBloc>()),
        ),
        ChangeNotifierProvider<RegisterViewModel>(
          create: (context) =>
              RegisterViewModel(appBloc: context.read<AppBloc>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocListener(
        listeners: [
          BlocListener<AppBloc, AppState>(
            listener: (context, state) {
              final navBloc = context.read<NavigationBloc>();

              if (state is Authenticated) {
                navBloc.add(NavigateToHome());
              } else if (state is Unauthenticated) {
                navBloc.add(NavigateToLogin());
              }
            },
          ),
        ],
        child: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            if (state is LoginPageState) {
              return LoginScreen(appBloc: context.read<AppBloc>());
            } else if (state is RegisterPageState) {
              return RegisterScreen(appBloc: context.read<AppBloc>());
            } else if (state is HomePageState) {
              return HomeScreen();
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
