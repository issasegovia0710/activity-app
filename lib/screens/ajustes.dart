import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../config/storage_service.dart';
import '../services/auth_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;
  String temaActual = 'clasico';

  static const String appNombre = 'Activity';
  static const String appVersion = '1.2.0';

  Map<String, dynamic>? usuario;

  bool notificacionesActivas = true;
  bool recordatorioMisiones = true;
  bool alertaAntesDeVencer = true;
  bool bloqueoSesion = false;
  bool confirmarAntesDeCompletar = true;

  String nombreVisible = 'Jugador';

  String? modalActivo;
  bool mostrarConfirmLogout = false;
  bool cerrandoSesion = false;
  bool argsCargados = false;

  late AnimationController introController;
  late AnimationController floatController;
  late AnimationController modalController;
  late AnimationController logoutController;
  late AnimationController logoutSpinController;

  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> floatAnimation;
  late Animation<double> modalOpacity;
  late Animation<double> modalScale;
  late Animation<double> modalTranslateY;
  late Animation<double> logoutOpacity;
  late Animation<double> logoutScale;
  late Animation<double> logoutTranslateY;

  @override
  void initState() {
    super.initState();

    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    modalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    logoutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    logoutSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
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

    slideAnimation = Tween<double>(
      begin: 35,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: Curves.easeOutBack,
      ),
    );
    

    floatAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(
      CurvedAnimation(
        parent: floatController,
        curve: Curves.easeInOut,
      ),
    );

    modalOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOut,
      ),
    );

    modalScale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOutBack,
      ),
    );

    modalTranslateY = Tween<double>(
      begin: 26,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOutBack,
      ),
    );

    logoutOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOut,
      ),
    );

    logoutScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOutBack,
      ),
    );

    logoutTranslateY = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOutBack,
      ),
    );

    introController.forward();
    cargarPreferencias();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argsCargados) return;

    argsCargados = true;

    final argsRaw = ModalRoute.of(context)?.settings.arguments;

    if (argsRaw is Map) {
      final args = Map<String, dynamic>.from(argsRaw);

      usuario = args['usuario'] is Map
          ? Map<String, dynamic>.from(args['usuario'])
          : null;

      temaActual = args['temaId']?.toString() ?? 'clasico';
      tema = AppThemes.getById(temaActual);
      nombreVisible = usuario?['nombre_usuario']?.toString() ?? 'Jugador';
    }
  }

  @override
  void dispose() {
    introController.dispose();
    floatController.dispose();
    modalController.dispose();
    logoutController.dispose();
    logoutSpinController.dispose();
    super.dispose();
  }

  Future<void> cargarPreferencias() async {
    final notificacionesGuardadas =
        await StorageService.getItem('notificaciones_activas');
    final recordatorioGuardado =
        await StorageService.getItem('recordatorio_misiones');
    final alertaGuardada = await StorageService.getItem('alerta_antes_vencer');
    final bloqueoGuardado = await StorageService.getItem('bloqueo_sesion');
    final confirmarGuardado = await StorageService.getItem('confirmar_completar');
    final nombreGuardado = await StorageService.getItem('nombre_visible');
    final temaGuardado = await StorageService.getItem('tema_app');

    if (!mounted) return;

    setState(() {
      if (notificacionesGuardadas != null) {
        notificacionesActivas = notificacionesGuardadas == 'true';
      }

      if (recordatorioGuardado != null) {
        recordatorioMisiones = recordatorioGuardado == 'true';
      }

      if (alertaGuardada != null) {
        alertaAntesDeVencer = alertaGuardada == 'true';
      }

      if (bloqueoGuardado != null) {
        bloqueoSesion = bloqueoGuardado == 'true';
      }

      if (confirmarGuardado != null) {
        confirmarAntesDeCompletar = confirmarGuardado == 'true';
      }

      if (nombreGuardado != null && nombreGuardado.trim().isNotEmpty) {
        nombreVisible = nombreGuardado;
      }

      if (temaGuardado != null && temaGuardado.trim().isNotEmpty) {
        temaActual = temaGuardado;
        tema = AppThemes.getById(temaActual);
      }
    });
  }

  Future<void> guardarPreferencia(String key, Object value) async {
    await StorageService.setItem(key, value.toString());
  }

  void regresar() {
    Navigator.pop(context);
  }

  void abrirModal(String tipo) {
    setState(() {
      modalActivo = tipo;
    });

    modalController.forward(from: 0);
  }

  Future<void> cerrarModal() async {
    await modalController.reverse();

    if (!mounted) return;

    setState(() {
      modalActivo = null;
    });
  }

  Future<void> cambiarTema(String idTema) async {
    final nuevoTema = AppThemes.getById(idTema);

    await StorageService.setItem('tema_app', idTema);

    if (!mounted) return;

    setState(() {
      temaActual = idTema;
      tema = nuevoTema;
    });
  }

  Future<void> guardarNombreVisible() async {
    final nombreLimpio = nombreVisible.trim();

    if (nombreLimpio.isEmpty) {
      setState(() {
        nombreVisible = usuario?['nombre_usuario']?.toString() ?? 'Jugador';
      });

      return;
    }

    await guardarPreferencia('nombre_visible', nombreLimpio);
    await cerrarModal();
  }

  Future<void> cambiarNotificaciones(bool valor) async {
    setState(() {
      notificacionesActivas = valor;

      if (!valor) {
        recordatorioMisiones = false;
        alertaAntesDeVencer = false;
      }
    });

    await guardarPreferencia('notificaciones_activas', valor);

    if (!valor) {
      await guardarPreferencia('recordatorio_misiones', false);
      await guardarPreferencia('alerta_antes_vencer', false);
    }
  }

  Future<void> cambiarRecordatorioMisiones(bool valor) async {
    setState(() {
      recordatorioMisiones = valor;
    });

    await guardarPreferencia('recordatorio_misiones', valor);
  }

  Future<void> cambiarAlertaAntesDeVencer(bool valor) async {
    setState(() {
      alertaAntesDeVencer = valor;
    });

    await guardarPreferencia('alerta_antes_vencer', valor);
  }

  Future<void> cambiarBloqueoSesion(bool valor) async {
    setState(() {
      bloqueoSesion = valor;
    });

    await guardarPreferencia('bloqueo_sesion', valor);
  }

  Future<void> cambiarConfirmarCompletar(bool valor) async {
    setState(() {
      confirmarAntesDeCompletar = valor;
    });

    await guardarPreferencia('confirmar_completar', valor);
  }

  void abrirConfirmacionCerrarSesion() {
    setState(() {
      mostrarConfirmLogout = true;
      cerrandoSesion = false;
    });

    logoutController.forward(from: 0);
  }

  Future<void> cancelarCerrarSesion() async {
    if (cerrandoSesion) return;

    await logoutController.reverse();

    if (!mounted) return;

    setState(() {
      mostrarConfirmLogout = false;
      cerrandoSesion = false;
    });
  }

  Future<void> cerrarSesion() async {
    setState(() {
      cerrandoSesion = true;
    });

    logoutSpinController.repeat();

    await Future.delayed(const Duration(milliseconds: 900));

    await AuthService.logout();

    logoutSpinController.stop();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  IconData iconoModal() {
    if (modalActivo == 'perfil') return Icons.person_outline;
    if (modalActivo == 'notificaciones') return Icons.notifications_outlined;
    if (modalActivo == 'tema') return Icons.color_lens_outlined;
    if (modalActivo == 'seguridad') return Icons.shield_outlined;
    return Icons.sports_esports_outlined;
  }

  String tituloModal() {
    if (modalActivo == 'perfil') return 'Información del perfil';
    if (modalActivo == 'notificaciones') return 'Notificaciones';
    if (modalActivo == 'tema') return 'Tema visual';
    if (modalActivo == 'seguridad') return 'Seguridad';
    return 'Información de la app';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: tema.fondo,
      body: SafeArea(
        child: Stack(
          children: [
            buildBackground(size),
            AnimatedBuilder(
              animation: introController,
              builder: (context, child) {
                return Opacity(
                  opacity: fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  children: [
                    buildHeader(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 28),
                        children: [
                          buildProfileCard(),
                          buildOptionCard(
                            icon: Icons.notifications_outlined,
                            title: 'Notificaciones',
                            subtitle: notificacionesActivas
                                ? 'Activas'
                                : 'Desactivadas',
                            iconColor: tema.primario,
                            iconBg: tema.suavePrimario,
                            onTap: () => abrirModal('notificaciones'),
                            trailing: buildStatusPill(),
                          ),
                          buildOptionCard(
                            icon: Icons.color_lens_outlined,
                            title: 'Tema visual',
                            subtitle: '${tema.nombre} • ${tema.descripcion}',
                            iconColor: tema.secundario,
                            iconBg: tema.suaveSecundario,
                            onTap: () => abrirModal('tema'),
                          ),
                          buildOptionCard(
                            icon: Icons.shield_outlined,
                            title: 'Seguridad',
                            subtitle: 'Sesión, confirmaciones y protección',
                            iconColor: tema.aviso,
                            iconBg: const Color(0xFFFFFBEB),
                            onTap: () => abrirModal('seguridad'),
                          ),
                          buildOptionCard(
                            icon: Icons.sports_esports_outlined,
                            title: 'Información de la app',
                            subtitle: '$appNombre v$appVersion • Misiones y progreso',
                            iconColor: Colors.white,
                            iconBg: tema.primario,
                            onTap: () => abrirModal('app'),
                          ),
                          const SizedBox(height: 4),
                          FilledButton.icon(
                            onPressed: abrirConfirmacionCerrarSesion,
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: tema.peligro,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (modalActivo != null) buildModal(size),
            if (mostrarConfirmLogout) buildLogoutOverlay(),
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
            top: -95,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: tema.primario.withOpacity(0.33),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -45,
            right: 15,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: tema.secundario.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          animatedBubble(
            top: size.height * 0.08,
            left: size.width * 0.08,
            color: Colors.white.withOpacity(0.14),
            icon: Icons.settings,
          ),
          animatedBubble(
            top: size.height * 0.15,
            right: size.width * 0.1,
            color: tema.secundario.withOpacity(0.2),
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  Widget animatedBubble({
    double? top,
    double? left,
    double? right,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Positioned(
          top: top == null ? null : top + floatAnimation.value,
          left: left,
          right: right,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: regresar,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tema.primario,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tema.borde,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajustes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Cuenta, preferencias y sesión',
                  style: TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileCard() {
    return GestureDetector(
      onTap: () => abrirModal('perfil'),
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: tema.primario,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tema.suavePrimario,
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombreVisible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca para ver información del perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            MiniProfileRow(
              icon: Icons.mail_outline,
              color: const Color(0xFF64748B),
              text: usuario?['correo']?.toString() ?? 'Sin correo registrado',
            ),
            MiniProfileRow(
              icon: Icons.flash_on_outlined,
              color: tema.barraXp,
              text:
                  'Nivel ${usuario?['nivel'] ?? 0} • ${usuario?['exp'] ?? 0} XP',
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
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusPill() {
    final activo = notificacionesActivas;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        activo ? 'ON' : 'OFF',
        style: TextStyle(
          color: activo ? const Color(0xFF16A34A) : const Color(0xFFB91C1C),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildModal(Size size) {
    return AnimatedBuilder(
      animation: modalController,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: modalOpacity.value,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.82),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, modalTranslateY.value),
                child: Transform.scale(
                  scale: modalScale.value,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 410,
                      maxHeight: size.height * 0.84,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildModalHeader(),
                        Flexible(
                          child: SingleChildScrollView(
                            child: buildModalContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildModalHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tema.primario,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconoModal(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tituloModal(),
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: cerrarModal,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF475569),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildModalContent() {
    if (modalActivo == 'perfil') return buildPerfilModal();
    if (modalActivo == 'notificaciones') return buildNotificacionesModal();
    if (modalActivo == 'tema') return buildTemaModal();
    if (modalActivo == 'seguridad') return buildSeguridadModal();
    return buildAppModal();
  }

  Widget buildPerfilModal() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: tema.primario,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tema.suavePrimario,
                    width: 5,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                usuario?['nombre_usuario']?.toString() ?? 'Jugador',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Perfil local de la sesión actual',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        InfoRow(
          icon: Icons.person_outline,
          label: 'Usuario',
          value: usuario?['nombre_usuario']?.toString() ?? 'No disponible',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.mail_outline,
          label: 'Correo',
          value: usuario?['correo']?.toString() ?? 'No disponible',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.flash_on_outlined,
          label: 'Experiencia',
          value: '${usuario?['exp'] ?? 0} XP',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.emoji_events_outlined,
          label: 'Nivel',
          value: '${usuario?['nivel'] ?? 0}',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Fecha de alta',
          value: usuario?['alta'] != null
              ? usuario!['alta'].toString().substring(0, 10)
              : 'No disponible',
          color: tema.primario,
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Nombre visible en ajustes',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: TextEditingController(text: nombreVisible)
            ..selection = TextSelection.collapsed(offset: nombreVisible.length),
          onChanged: (value) {
            nombreVisible = value;
          },
          decoration: InputDecoration(
            hintText: 'Nombre visible',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: guardarNombreVisible,
          icon: const Icon(Icons.save_outlined),
          label: const Text(
            'Guardar nombre visible',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: tema.primario,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNotificacionesModal() {
    return Column(
      children: [
        SettingSwitch(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones generales',
          subtitle: 'Permite avisos dentro de la app',
          value: notificacionesActivas,
          onValueChange: cambiarNotificaciones,
          color: tema.primario,
        ),
        SettingSwitch(
          icon: Icons.flag_outlined,
          title: 'Recordatorio de misiones',
          subtitle: 'Avisos sobre misiones pendientes',
          value: recordatorioMisiones,
          onValueChange: cambiarRecordatorioMisiones,
          disabled: !notificacionesActivas,
          color: tema.primario,
        ),
        SettingSwitch(
          icon: Icons.alarm_outlined,
          title: 'Alerta antes de vencer',
          subtitle: 'Aviso cuando una misión esté por terminar',
          value: alertaAntesDeVencer,
          onValueChange: cambiarAlertaAntesDeVencer,
          disabled: !notificacionesActivas,
          color: tema.primario,
        ),
        const NoticeBox(
          icon: Icons.info_outline,
          text:
              'Estas opciones quedan guardadas localmente. Para notificaciones reales después se conecta con notificaciones nativas.',
        ),
      ],
    );
  }

  Widget buildTemaModal() {
    return Column(
      children: [
        ...AppThemes.todos.map((item) {
          final seleccionado = temaActual == item.id;

          return GestureDetector(
            onTap: () => cambiarTema(item.id),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: seleccionado ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: seleccionado ? item.primario : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      themeDot(item.fondo),
                      Transform.translate(
                        offset: const Offset(-4, 0),
                        child: themeDot(item.primario),
                      ),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: themeDot(item.secundario),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.descripcion,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    seleccionado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        seleccionado ? item.primario : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        }),
        const NoticeBox(
          icon: Icons.color_lens_outlined,
          text:
              'El tema queda guardado localmente. Al volver a abrir ajustes se mantiene tu selección.',
        ),
      ],
    );
  }

  Widget buildSeguridadModal() {
    return Column(
      children: [
        SettingSwitch(
          icon: Icons.lock_outline,
          title: 'Bloqueo de sesión',
          subtitle: 'Preparado para pedir acceso al volver',
          value: bloqueoSesion,
          onValueChange: cambiarBloqueoSesion,
          color: tema.primario,
        ),
        SettingSwitch(
          icon: Icons.done_all_outlined,
          title: 'Confirmar antes de completar',
          subtitle: 'Evita completar misiones por accidente',
          value: confirmarAntesDeCompletar,
          onValueChange: cambiarConfirmarCompletar,
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.shield_outlined,
          label: 'Estado de sesión',
          value: 'Sesión activa',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.key_outlined,
          label: 'Token',
          value: 'Guardado localmente',
          color: tema.primario,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await cerrarModal();
            abrirConfirmacionCerrarSesion();
          },
          icon: const Icon(Icons.logout),
          label: const Text(
            'Cerrar sesión segura',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: tema.peligro,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAppModal() {
    return Column(
      children: [
        InfoRow(
          icon: Icons.sports_esports_outlined,
          label: 'Aplicación',
          value: appNombre,
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.new_releases_outlined,
          label: 'Versión',
          value: '$appNombre $appVersion',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.layers_outlined,
          label: 'Módulos',
          value: 'Misiones, estadísticas y ajustes',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.phone_iphone_outlined,
          label: 'Uso',
          value: 'Compatible con web y móvil',
          color: tema.primario,
        ),
        InfoRow(
          icon: Icons.storage_outlined,
          label: 'Conexión',
          value: 'API local / servidor',
          color: tema.primario,
        ),
        const NoticeBox(
          icon: Icons.auto_awesome,
          text:
              'Versión Activity 1.2.0. Esta sección puede crecer para mostrar soporte, políticas y exportación de progreso.',
        ),
      ],
    );
  }

  Widget themeDot(Color color) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }

  Widget buildLogoutOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        logoutController,
        logoutSpinController,
      ]),
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: logoutOpacity.value,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.82),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, logoutTranslateY.value),
                child: Transform.scale(
                  scale: logoutScale.value,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 370),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: cerrandoSesion
                              ? logoutSpinController.value * 6.28318530718
                              : 0,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: tema.peligro,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFEE2E2),
                                width: 6,
                              ),
                            ),
                            child: Icon(
                              cerrandoSesion ? Icons.sync : Icons.logout,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cerrandoSesion
                              ? 'Cerrando sesión...'
                              : '¿Cerrar sesión?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          cerrandoSesion
                              ? 'Limpiando tu sesión y regresando al inicio.'
                              : 'Tu avance queda guardado. Para volver tendrás que iniciar sesión de nuevo.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (cerrandoSesion)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Saliendo del tablero',
                                style: TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: cancelarCerrarSesion,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: cerrarSesion,
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text(
                                    'Salir',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: tema.peligro,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MiniProfileRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const MiniProfileRow({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onValueChange;
  final bool disabled;
  final Color color;

  const SettingSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onValueChange,
    required this.color,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: disabled ? const Color(0xFF94A3B8) : color,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: disabled ? null : onValueChange,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const NoticeBox({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0369A1),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0369A1),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}