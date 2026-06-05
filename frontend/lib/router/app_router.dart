import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
    }
  }
}
