import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jlfxkatjtuqhxlwegmly.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsZnhrYXRqdHVxaHhsd2VnbWx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMjM0MTMsImV4cCI6MjEwMjY5OTQxM30.rHM25Ujt0biun7F3iSZtgJtWqBvICDhLyyUcCWn6yhE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Smart Mist Fan',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D13),
        useMaterial3: true,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => LoginScreen(),

        '/register': (context) => RegisterScreen(),

        '/dashboard': (context) => DashboardScreen(
              username: '',
            ),

        '/settings': (context) => SettingsScreen(
              username: '',
            ),
      },
    );
  }
}