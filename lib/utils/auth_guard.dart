import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool cargando = true;
  bool autorizado = false;

  @override
  void initState() {
    super.initState();
    verificarSesion();
  }

  Future<void> verificarSesion() async {
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

    setState(() {
      autorizado = true;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF312E81),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (!autorizado) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}

class LoginGuard extends StatefulWidget {
  final Widget child;

  const LoginGuard({
    super.key,
    required this.child,
  });

  @override
  State<LoginGuard> createState() => _LoginGuardState();
}

class _LoginGuardState extends State<LoginGuard> {
  bool cargando = true;
  bool puedeVerLogin = false;

  @override
  void initState() {
    super.initState();
    verificarSesion();
  }

  Future<void> verificarSesion() async {
    final tieneSesion = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (tieneSesion) {
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
      return;
    }

    setState(() {
      puedeVerLogin = true;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF312E81),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (!puedeVerLogin) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}