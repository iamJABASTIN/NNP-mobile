import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration — same project as the web admin dashboard.
class SupabaseConfig {
  static const String url = 'https://zfweuakxeakppgvjmpxs.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpmd2V1YWt4ZWFrcHBndmptcHhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MDc1NjksImV4cCI6MjA5MDE4MzU2OX0.zt24NZZJ5qfi_qcodEEPTz15Jqe4UiREU2eYhsJx6gU';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
