import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../services/api_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;

  Map<String, dynamic>? usuario;
  Map<String, dynamic>? nivelInfo;
  List<Map<String, dynamic>> misiones = [];

  bool cargando = true;
  bool argsCargados = false;

  late AnimationController introController;
  late AnimationController floatController;

  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> floatAnimation;

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

    introController.forward();
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

      nivelInfo = args['nivelInfo'] is Map
          ? Map<String, dynamic>.from(args['nivelInfo'])
          : null;

      if (args['misiones'] is List) {
        misiones = (args['misiones'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      tema = AppThemes.getById(args['temaId']?.toString());
    }

    cargarDatos();
  }

  @override
  void dispose() {
    introController.dispose();
    floatController.dispose();
    super.dispose();
  }

  int toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  double toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Future<void> cargarDatos() async {
    try {
      if (!mounted) return;

      setState(() {
        cargando = true;
      });

      final responses = await Future.wait([
        ApiService.get('/auth/nivel'),
        ApiService.get('/actividades'),
      ]);

      final nivelResponse = responses[0];
      final actividadesResponse = responses[1];

      if (nivelResponse is Map<String, dynamic>) {
        if (nivelResponse['usuario'] is Map) {
          usuario = Map<String, dynamic>.from(nivelResponse['usuario']);
        }

        if (nivelResponse['nivel_info'] is Map) {
          nivelInfo = Map<String, dynamic>.from(nivelResponse['nivel_info']);
        }
      }

      if (actividadesResponse is Map<String, dynamic> &&
          actividadesResponse['actividades'] is List) {
        misiones = (actividadesResponse['actividades'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (error) {
      debugPrint('Error al cargar estadísticas: $error');
    } finally {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  void regresar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final xpTotal = toInt(usuario?['exp'], 0);
    final nivelActual = toInt(usuario?['nivel'] ?? nivelInfo?['nivel'], 1);

    final expNivelActual = toInt(nivelInfo?['exp_nivel_actual'], 0);
    final expSiguienteNivel = toInt(nivelInfo?['exp_siguiente_nivel'], 0);
    final expParaSubir = toInt(nivelInfo?['exp_para_subir'], 0);
    final porcentajeNivel = toDouble(nivelInfo?['porcentaje'], 0);

    final xpDentroDelNivel = expSiguienteNivel > expNivelActual
        ? xpTotal - expNivelActual
        : xpTotal;

    final xpNecesariaDelNivel = expSiguienteNivel > expNivelActual
        ? expSiguienteNivel - expNivelActual
        : 0;

    final progresoNivel = (porcentajeNivel.clamp(0, 100)) / 100;

    final misionesTotales = misiones.length;

    final misionesCompletadas = misiones.where((mision) {
      return mision['estatus'] == 'completada' || mision['completada'] == true;
    }).length;

    final misionesNoCumplidas = misiones.where((mision) {
      return mision['estatus'] == 'no_cumplida';
    }).length;

    final misionesPendientes = misiones.where((mision) {
      return mision['estatus'] == 'pendiente';
    }).length;

    final misionesEnProceso = misiones.where((mision) {
      return mision['estadoTiempo'] == 'en_proceso';
    }).length;

    final misionesPorAbrir = misiones.where((mision) {
      return mision['estadoTiempo'] == 'por_abrir';
    }).length;

    final porcentajeCompletado = misionesTotales > 0
        ? ((misionesCompletadas / misionesTotales) * 100).round()
        : 0;

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
                      child: cargando
                          ? buildLoading()
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 28),
                              children: [
                                buildBigStatCard(
                                  xpTotal: xpTotal,
                                  nivelActual: nivelActual,
                                  xpNecesariaDelNivel: xpNecesariaDelNivel,
                                  xpDentroDelNivel: xpDentroDelNivel,
                                  progresoNivel: progresoNivel,
                                  expParaSubir: expParaSubir,
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    InfoCard(
                                      icon: Icons.emoji_events_outlined,
                                      label: 'Nivel actual',
                                      value: nivelActual.toString(),
                                      color: tema.primario,
                                      bg: tema.suavePrimario,
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.hourglass_empty,
                                      label: 'XP del nivel',
                                      value: xpNecesariaDelNivel > 0
                                          ? '$xpDentroDelNivel/$xpNecesariaDelNivel'
                                          : '$xpTotal',
                                      color: tema.barraXp,
                                      bg: const Color(0xFFFFFBEB),
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.flag_outlined,
                                      label: 'Pendientes',
                                      value: misionesPendientes.toString(),
                                      color: tema.secundario,
                                      bg: tema.suaveSecundario,
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.play_circle_outline,
                                      label: 'En proceso',
                                      value: misionesEnProceso.toString(),
                                      color: const Color(0xFF14B8A6),
                                      bg: const Color(0xFFCCFBF1),
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.hourglass_empty,
                                      label: 'Próximas',
                                      value: misionesPorAbrir.toString(),
                                      color: const Color(0xFF0EA5E9),
                                      bg: const Color(0xFFE0F2FE),
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.done_all_outlined,
                                      label: 'Completadas',
                                      value: misionesCompletadas.toString(),
                                      color: tema.exito,
                                      bg: const Color(0xFFDCFCE7),
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.cancel_outlined,
                                      label: 'No cumplidas',
                                      value: misionesNoCumplidas.toString(),
                                      color: tema.peligro,
                                      bg: const Color(0xFFFEE2E2),
                                      tema: tema,
                                    ),
                                    InfoCard(
                                      icon: Icons.list_alt_outlined,
                                      label: 'Total',
                                      value: misionesTotales.toString(),
                                      color: const Color(0xFF7C3AED),
                                      bg: const Color(0xFFF3E8FF),
                                      tema: tema,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                buildProgressSummary(
                                  porcentajeCompletado: porcentajeCompletado,
                                  misionesCompletadas: misionesCompletadas,
                                  misionesTotales: misionesTotales,
                                ),
                                const SizedBox(height: 14),
                                buildResumenRapido(
                                  xpTotal: xpTotal,
                                  porcentajeNivel: porcentajeNivel,
                                ),
                                const SizedBox(height: 10),
                              ],
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
            color: tema.primario.withOpacity(0.2),
            icon: Icons.bar_chart,
          ),
          animatedBubble(
            top: size.height * 0.15,
            right: size.width * 0.1,
            color: tema.barraXp.withOpacity(0.2),
            icon: Icons.emoji_events,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Resumen de progreso del jugador',
                  style: TextStyle(
                    color: tema.borde,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: cargarDatos,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tema.borde,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.refresh,
                color: tema.primario,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBigStatCard({
    required int xpTotal,
    required int nivelActual,
    required int xpNecesariaDelNivel,
    required int xpDentroDelNivel,
    required double progresoNivel,
    required int expParaSubir,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tema.tarjeta,
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tema.primario,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            xpTotal.toString(),
            style: TextStyle(
              color: tema.texto,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Experiencia total',
            style: TextStyle(
              color: tema.textoSuave,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel $nivelActual',
                style: TextStyle(
                  color: tema.textoSuave,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                xpNecesariaDelNivel > 0
                    ? '$xpDentroDelNivel / $xpNecesariaDelNivel XP'
                    : 'Nivel máximo',
                style: TextStyle(
                  color: tema.textoSuave,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresoNivel,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(tema.barraXp),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            expParaSubir > 0
                ? 'Faltan $expParaSubir XP para el siguiente nivel'
                : 'Nivel máximo alcanzado',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProgressSummary({
    required int porcentajeCompletado,
    required int misionesCompletadas,
    required int misionesTotales,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avance de misiones',
                      style: TextStyle(
                        color: tema.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$misionesCompletadas de $misionesTotales misiones completadas',
                      style: TextStyle(
                        color: tema.textoSuave,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$porcentajeCompletado%',
                style: TextStyle(
                  color: tema.primario,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: porcentajeCompletado / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(tema.primario),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResumenRapido({
    required int xpTotal,
    required double porcentajeNivel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen rápido',
            style: TextStyle(
              color: tema.texto,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SummaryLine(
            icon: Icons.person_outline,
            color: tema.primario,
            text: 'Jugador: ${usuario?['nombre_usuario'] ?? 'Sin usuario'}',
          ),
          SummaryLine(
            icon: Icons.auto_awesome,
            color: tema.barraXp,
            text: 'EXP total acumulada: $xpTotal',
          ),
          SummaryLine(
            icon: Icons.trending_up,
            color: tema.exito,
            text: 'Progreso del nivel: ${porcentajeNivel.round()}%',
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final ActivityTheme tema;

  const InfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.tema,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 46) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(24),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.texto,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const SummaryLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}