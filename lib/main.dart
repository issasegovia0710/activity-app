import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'screens/estadisticas.dart';
import 'screens/ajustes.dart';
import 'screens/misiones.dart';
import 'screens/activitis_dash.dart';
import 'screens/activitis_dash_day.dart';
import 'utils/notificaciones_tareas.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/home': (context) => const HomeScreen(),
        '/estadisticas': (context) => const EstadisticasScreen(),
        '/ajustes': (context) => const AjustesScreen(),
        '/misiones': (context) => const MisionesScreen(),
        '/activitis-dash': (context) => const ActivitisDashScreen(),
        '/activitis-dash-day': (context) => const ActivitisDashDayScreen(),
      },
    );
  }
}