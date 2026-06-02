import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color fondo = const Color(0xFF312E81);
  final Color fondoSecundario = const Color(0xFF4C1D95);
  final Color primario = const Color(0xFF4F46E5);
  final Color secundario = const Color(0xFFEC4899);
  final Color barraXp = const Color(0xFFF59E0B);
  final Color borde = const Color(0xFFC7D2FE);

  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;

  bool revisandoSesion = true;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    opacityAnimation = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      verificarSesion();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> verificarSesion() async {
    try {
      final tieneSesion = await AuthService.isLoggedIn();

      if (!mounted) return;

      if (!tieneSesion) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        return;
      }

      final usuario = await AuthService.getUsuario();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
        arguments: {
          'usuario': usuario,
        },
      );
    } catch (_) {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Stack(
          children: [
            buildBackground(size),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: opacityAnimation.value,
                          child: Transform.scale(
                            scale: scaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: primario,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primario.withOpacity(0.42),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 10,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: barraXp,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sentiment_satisfied_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 34),
                              child: Icon(
                                Icons.directions_run,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Activity Day Life',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisando tu sesión...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: borde,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBackground(Size size) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -85,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: primario.withOpacity(0.33),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: fondoSecundario.withOpacity(0.58),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 35,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: secundario.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.16,
            left: 28,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: barraXp.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}