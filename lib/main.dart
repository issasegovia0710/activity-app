import 'package:flutter/material.dart';

import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'screens/estadisticas.dart';
import 'screens/ajustes.dart';
import 'screens/misiones.dart';
import 'screens/activitis_dash.dart';
import 'screens/activitis_dash_day.dart';
import 'utils/notificaciones_tareas.dart';
import 'utils/auth_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacionesTareas.inicializarNotificaciones();
  runApp(const ActivityApp());
}

class ActivityApp extends StatelessWidget {
  const ActivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Day Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginGuard(
              child: LoginScreen(),
            ),

        '/dashboard': (context) => const AuthGuard(
              child: DashboardScreen(),
            ),

        '/home': (context) => const AuthGuard(
              child: DashboardScreen(),
            ),

        '/estadisticas': (context) => const AuthGuard(
              child: EstadisticasScreen(),
            ),

        '/ajustes': (context) => const AuthGuard(
              child: AjustesScreen(),
            ),

        '/misiones': (context) => const AuthGuard(
              child: MisionesScreen(),
            ),

        '/activitis-dash': (context) => const AuthGuard(
              child: ActivitisDashScreen(),
            ),

        '/activitis-dash-day': (context) => const AuthGuard(
              child: ActivitisDashDayScreen(),
            ),
      },
    );
  }
}