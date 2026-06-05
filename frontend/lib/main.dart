import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/environment.dart';
import 'constants/colors.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/activation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: FmpPrepApp()));
}

class FmpPrepApp extends ConsumerWidget {
  const FmpPrepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'FMP Prep AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _buildHome(auth),
    );
  }

  Widget _buildHome(AuthState auth) {
    if (auth.status == AuthStatus.unknown) {
      return const _SplashGate();
    }
    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }
    if (!auth.isActivated) {
      return const ActivationScreen();
    }
    return const DashboardScreen();
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
