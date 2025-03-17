import 'package:flutter/material.dart';
import 'package:frontend/ui/screens/home/home_screen.dart';
import 'package:frontend/ui/screens/login/login_screen.dart';
import 'package:frontend/ui/screens/signup/signup_screen.dart';
import 'package:frontend/ui/screens/add_task/add_task_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => MyHomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/add_task':
        return MaterialPageRoute(builder: (_) => const AddNewTask());
      default:
        return MaterialPageRoute(builder: (_) => MyHomePage());
    }
  }
}