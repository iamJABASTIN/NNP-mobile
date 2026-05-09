import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Service for handling authentication logic.
class AuthService {
  /// Get current session
  static Session? get currentSession => SupabaseConfig.client.auth.currentSession;

  /// Get current user
  static User? get currentUser => SupabaseConfig.client.auth.currentUser;

  /// Check if logged in
  static bool get isLoggedIn => currentSession != null;

  /// Login with email and password
  static Future<AuthResponse> login(String email, String password) async {
    return await SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  static Future<void> logout() async {
    await SupabaseConfig.client.auth.signOut();
  }

  /// Listen to auth changes
  static Stream<AuthState> get authStateChanges =>
      SupabaseConfig.client.auth.onAuthStateChange;
}
