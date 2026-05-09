import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const WaiterApp());
}

class WaiterApp extends StatefulWidget {
  const WaiterApp({super.key});

  @override
  State<WaiterApp> createState() => _WaiterAppState();
}

class _WaiterAppState extends State<WaiterApp> {
  bool _showSplash = true;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NNP Waiter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _showSplash 
        ? SplashScreen(onComplete: () {
            setState(() {
              _showSplash = false;
              _isInitialized = true;
            });
          })
        : StreamBuilder<AuthState>(
            stream: AuthService.authStateChanges,
            builder: (context, snapshot) {
              final session = snapshot.data?.session ?? AuthService.currentSession;
              
              if (session != null) {
                // If we just logged in and haven't shown splash yet, 
                // but the user wants Login -> Splash -> Home flow.
                // We'll handle the "re-splash" inside the LoginScreen success.
                return const AppShell();
              }
              
              return LoginScreen(
                onLoginSuccess: () {
                  // This callback allows us to trigger the splash again
                  setState(() => _showSplash = true);
                },
              );
            },
          ),
    );
  }
}
