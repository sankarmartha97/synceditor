import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/services/page_service.dart';
import 'features/page/bloc/page_bloc.dart';
import 'features/page/views/page_dashboard.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/views/login_screen.dart';

void main() {
  runApp(const SyncEditorApp());
}

class SyncEditorApp extends StatelessWidget {
  const SyncEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final apiClient = ApiClient.instance;
    final pageService = PageService(apiClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()..add(const AppStarted())),
        BlocProvider(create: (context) => PageBloc(pageService)),
      ],
      child: MaterialApp(
        title: 'Sync Editor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(elevation: 2),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Show loading while checking auth status
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If authenticated, show page dashboard
            if (state is AuthAuthenticated) {
              return const PageDashboard();
            }

            // Otherwise show login screen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
