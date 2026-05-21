import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? usuario;

  final Color fondo = const Color(0xFFF8FAFC);
  final Color primario = const Color(0xFF4F46E5);
  final Color texto = const Color(0xFF1E293B);
  final Color textoSuave = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  Future<void> cargarUsuario() async {
    final usuarioGuardado = await AuthService.getUsuario();

    if (!mounted) return;

    setState(() {
      usuario = usuarioGuardado;
    });
  }

  Future<void> cerrarSesion() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (usuario == null && args is Map<String, dynamic>) {
      usuario = args;
    }

    final nombreUsuario = usuario?['nombre_usuario'] ??
        usuario?['nombre'] ??
        usuario?['usuario'] ??
        'Usuario';

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        title: const Text(
          'Activity',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primario,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: primario.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          nombreUsuario.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Panel principal',
              style: TextStyle(
                color: texto,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí vamos a conectar tus actividades, tareas, horarios y notificaciones.',
              style: TextStyle(
                color: textoSuave,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            buildOptionCard(
              icon: Icons.task_alt,
              title: 'Mis actividades',
              subtitle: 'Ver y administrar actividades registradas.',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            buildOptionCard(
              icon: Icons.add_circle_outline,
              title: 'Crear actividad',
              subtitle: 'Agregar una nueva actividad al sistema.',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            buildOptionCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notificaciones',
              subtitle: 'Recordatorios antes de vencer o expirar.',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primario.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: primario,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: texto,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textoSuave,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}