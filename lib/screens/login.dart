import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool transitioning = false;
  bool obscurePassword = true;

  late AnimationController introController;
  late AnimationController floatController;
  late AnimationController runnerController;
  late AnimationController glowController;
  late AnimationController transitionController;

  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> floatAnimation;
  late Animation<double> runnerAnimation;
  late Animation<double> glowAnimation;
  late Animation<double> transitionOpacity;
  late Animation<double> transitionScale;
  late Animation<double> transitionRunnerX;
  late Animation<double> portalScale;

  final Color fondo = const Color(0xFF312E81);
  final Color fondoSecundario = const Color(0xFF4C1D95);
  final Color primario = const Color(0xFF4F46E5);
  final Color secundario = const Color(0xFFEC4899);
  final Color tarjeta = Colors.white;
  final Color texto = const Color(0xFF1E293B);
  final Color textoSuave = const Color(0xFF64748B);
  final Color borde = const Color(0xFFC7D2FE);
  final Color barraXp = const Color(0xFFF59E0B);
  final Color peligro = const Color(0xFFEF4444);
  final Color exito = const Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();

    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    runnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: Curves.easeOut,
      ),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: Curves.easeOutBack,
      ),
    );

    scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: Curves.easeOutBack,
      ),
    );

    floatAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(
      CurvedAnimation(
        parent: floatController,
        curve: Curves.easeInOut,
      ),
    );

    runnerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: runnerController,
        curve: Curves.easeInOut,
      ),
    );

    glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: glowController,
        curve: Curves.easeInOut,
      ),
    );

    transitionOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: transitionController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    transitionScale = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: transitionController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    transitionRunnerX = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: transitionController,
        curve: const Interval(0.25, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    portalScale = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(
      CurvedAnimation(
        parent: transitionController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInCubic),
      ),
    );

    introController.forward();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    introController.dispose();
    floatController.dispose();
    runnerController.dispose();
    glowController.dispose();
    transitionController.dispose();

    super.dispose();
  }

  Future<void> handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage(
        title: 'Atención',
        message: 'Ingresa tu usuario y contraseña, por favor.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
      );

      debugPrint('Login exitoso: ${result['usuario']}');

      if (!mounted) return;

      setState(() {
        loading = false;
        transitioning = true;
      });

      await transitionController.forward();

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: result['usuario'],
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      String message = error.toString();

      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }

      showMessage(
        title: 'Fallo al entrar',
        message: message,
      );
    }
  }

  void showMessage({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 34,
                ),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: buildLoginCard(size),
                    ),
                  ),
                ),
              ),
            ),
            if (transitioning) buildTransitionOverlay(size),
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
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: primario.withOpacity(0.33),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: 20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: secundario.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          animatedBubble(
            top: size.height * 0.12,
            left: size.width * 0.12,
            color: primario.withOpacity(0.2),
            icon: Icons.star,
            size: 58,
          ),
          animatedBubble(
            top: size.height * 0.2,
            right: size.width * 0.1,
            color: barraXp.withOpacity(0.2),
            icon: Icons.diamond,
            size: 72,
          ),
          animatedBubble(
            bottom: size.height * 0.13,
            left: size.width * 0.14,
            color: exito.withOpacity(0.2),
            icon: Icons.flash_on,
            size: 58,
          ),
          animatedBubble(
            bottom: size.height * 0.22,
            right: size.width * 0.16,
            color: secundario.withOpacity(0.2),
            icon: Icons.public,
            size: 62,
          ),
        ],
      ),
    );
  }

  Widget animatedBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required IconData icon,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Positioned(
          top: top == null ? null : top + floatAnimation.value,
          bottom: bottom == null ? null : bottom - floatAnimation.value,
          left: left,
          right: right,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  Widget buildLoginCard(Size size) {
    final cardWidth = size.width > 500 ? 460.0 : size.width * 0.88;

    return AnimatedBuilder(
      animation: Listenable.merge([
        glowAnimation,
        runnerAnimation,
      ]),
      builder: (context, child) {
        final borderColor = Color.lerp(
          borde,
          primario,
          glowAnimation.value,
        )!;

        final shadowOpacity = 0.15 + (glowAnimation.value * 0.20);

        final runnerX = -8 + (runnerAnimation.value * 16);
        final runnerY = 0 - (runnerAnimation.value * 6);
        final runnerRotation = -0.07 + (runnerAnimation.value * 0.14);
        final shadowScale = 1 - (runnerAnimation.value * 0.18);

        return Container(
          width: cardWidth,
          padding: const EdgeInsets.fromLTRB(30, 34, 30, 24),
          decoration: BoxDecoration(
            color: tarjeta,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primario.withOpacity(shadowOpacity),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -86),
                child: SizedBox(
                  width: 145,
                  height: 125,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 7,
                        child: Transform.scale(
                          scaleX: shadowScale,
                          child: Container(
                            width: 78,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(runnerX, runnerY),
                        child: Transform.rotate(
                          angle: runnerRotation,
                          child: buildRunner(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -75),
                child: Column(
                  children: [
                    Text(
                      'Activity Day Life',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: texto,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Corre hacia tus metas diarias',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textoSuave,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildMessageBox(),
                    const SizedBox(height: 20),
                    buildInput(
                      controller: usernameController,
                      hint: 'Nombre de usuario',
                      icon: Icons.person_outline,
                      obscure: false,
                    ),
                    const SizedBox(height: 16),
                    buildInput(
                      controller: passwordController,
                      hint: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscure: obscurePassword,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    buildLoginButton(),
                    const SizedBox(height: 18),
                    buildBottomIcons(),
                    const SizedBox(height: 18),
                    const Text(
                      'v1.2.0 - Activity',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRunner() {
    return SizedBox(
      width: 120,
      height: 115,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -8,
            top: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                speedLine(26, barraXp),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: speedLine(18, primario),
                ),
                const SizedBox(height: 7),
                speedLine(30, secundario),
              ],
            ),
          ),
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: primario,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primario.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 8,
                  child: Container(
                    width: 42,
                    height: 42,
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
                      size: 26,
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
        ],
      ),
    );
  }

  Widget speedLine(double width, Color color) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget buildMessageBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: barraXp.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: barraXp.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 20,
            color: barraXp,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Prepara tu aventura del día',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    bool isPassword = false,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borde,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primario,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              enabled: !loading && !transitioning,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              style: TextStyle(
                color: texto,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: loading || transitioning
                  ? null
                  : () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textoSuave,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading || transitioning ? null : handleLogin,
        style: FilledButton.styleFrom(
          backgroundColor: primario,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const Row(
                  key: ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Abriendo camino...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : transitioning
                  ? const Row(
                      key: ValueKey('success'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'ACCESO CONCEDIDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      key: ValueKey('normal'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'ENTRAR AL SISTEMA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget buildBottomIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        miniBadge(Icons.directions_walk, primario),
        const SizedBox(width: 10),
        miniBadge(Icons.flag, secundario),
        const SizedBox(width: 10),
        miniBadge(Icons.auto_awesome, barraXp),
      ],
    );
  }

  Widget miniBadge(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget buildTransitionOverlay(Size size) {
    return AnimatedBuilder(
      animation: transitionController,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: transitionOpacity.value,
            child: Transform.scale(
              scale: transitionScale.value,
              child: Container(
                color: fondo,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: portalScale.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: primario,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 10,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        transitionRunnerX.value * size.width,
                        0,
                      ),
                      child: SizedBox(
                        width: 180,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  transitionLine(70, barraXp),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 18),
                                    child: transitionLine(52, primario),
                                  ),
                                  const SizedBox(height: 12),
                                  transitionLine(82, secundario),
                                ],
                              ),
                            ),
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: primario,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.55),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 8,
                                    child: Container(
                                      width: 38,
                                      height: 38,
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
                                    padding: EdgeInsets.only(top: 30),
                                    child: Icon(
                                      Icons.directions_run,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: size.height * 0.18,
                      child: Column(
                        children: [
                          const Text(
                            'Entrando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Preparando tu tablero',
                            style: TextStyle(
                              color: borde,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget transitionLine(double width, Color color) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}