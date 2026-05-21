import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/dashboard.dart';
import 'screens/estadisticas.dart';
import 'screens/ajustes.dart';
import 'screens/misiones.dart';
import 'screens/activitis_dash.dart';
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DashboardScreen(),
        '/estadisticas': (context) => const EstadisticasScreen(),
        '/ajustes': (context) => const AjustesScreen(),
        '/misiones': (context) => const MisionesScreen(),
        '/activitis-dash': (context) => const ActivitisDashScreen(),
      },
    );
  }
}