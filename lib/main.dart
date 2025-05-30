import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/auth/pages/login_page.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/chats/chat_provider.dart';
import 'modules/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
      title: 'ERP Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const LoginPage(), // Always start at login
    );
  }
}
