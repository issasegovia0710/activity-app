import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../config/storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ActivityTheme tema = AppThemes.clasico;

  static const List<Color> coloresTipos = [
    Color(0xFF4F46E5),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
    Color(0xFF16A34A),
  ];

  static const int veinticuatroHorasMs = 24 * 60 * 60 * 1000;
  static const Duration tiempoExtraParaCumplir = Duration(hours: 1);

  Map<String, dynamic>? usuario;
  int xpTotal = 0;
  int nivelActual = 0;
  Map<String, dynamic>? nivelInfo;

  List<Map<String, dynamic>> misiones = [];
  bool cargandoMisiones = false;
  DateTime ahoraTick = DateTime.now();

  String filtroMisiones = 'pendientes';

  bool mostrarLevelUp = false;
  bool mostrarConfirmLogout = false;
  bool cerrandoSesion = false;

  Timer? timer;

  late AnimationController introController;
  late AnimationController floatController;
  late AnimationController glowController;
  late AnimationController runnerController;
  late AnimationController levelUpController;
  late AnimationController logoutController;
  late AnimationController logoutSpinController;

  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> headerScaleAnimation;
  late Animation<double> floatAnimation;
  late Animation<double> glowAnimation;
  late Animation<double> runnerAnimation;
  late Animation<double> levelOpacityAnimation;
  late Animation<double> levelScaleAnimation;
  late Animation<double> logoutOpacityAnimation;
  late Animation<double> logoutScaleAnimation;
  late Animation<double> logoutTranslateAnimation;

  @override
  void initState() {
    super.initState();

    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    runnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    logoutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    logoutSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

    headerScaleAnimation = Tween<double>(
      begin: 0.94,
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

    glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: glowController,
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

    levelOpacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: levelUpController,
        curve: Curves.easeOut,
      ),
    );

    levelScaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: levelUpController,
        curve: Curves.elasticOut,
      ),
    );

    logoutOpacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOut,
      ),
    );

    logoutScaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOutBack,
      ),
    );

    logoutTranslateAnimation = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: logoutController,
        curve: Curves.easeOutBack,
      ),
    );

    introController.forward();

    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;

      setState(() {
        ahoraTick = DateTime.now();
        misiones = recalcularCuentasRegresivas(misiones);
      });
    });

    cargarDatosIniciales();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (usuario == null && args is Map<String, dynamic>) {
      usuario = args['usuario'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(args['usuario'])
          : args;

      xpTotal = toInt(usuario?['exp'], 0);
      nivelActual = toInt(usuario?['nivel'], 1);

      if (args['nivelInfo'] is Map<String, dynamic>) {
        nivelInfo = Map<String, dynamic>.from(args['nivelInfo']);
      } else if (args['nivel_info'] is Map<String, dynamic>) {
        nivelInfo = Map<String, dynamic>.from(args['nivel_info']);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();

    introController.dispose();
    floatController.dispose();
    glowController.dispose();
    runnerController.dispose();
    levelUpController.dispose();
    logoutController.dispose();
    logoutSpinController.dispose();

    super.dispose();
  }

  Future<void> cargarDatosIniciales() async {
    final usuarioGuardado = await AuthService.getUsuario();

    if (!mounted) return;

    if (usuario == null && usuarioGuardado != null) {
      setState(() {
        usuario = usuarioGuardado;
        xpTotal = toInt(usuarioGuardado['exp'], 0);
        nivelActual = toInt(usuarioGuardado['nivel'], 0);
      });
    }

    await cargarNivelUsuario();
    await cargarMisionesDelDia();
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

  int? intDesdeMapa(Map<String, dynamic>? mapa, List<String> llaves) {
    if (mapa == null) return null;

    for (final llave in llaves) {
      if (!mapa.containsKey(llave)) continue;

      final valor = mapa[llave];

      if (valor == null) continue;

      if (valor is int) return valor;

      if (valor is double) return valor.round();

      final convertido = int.tryParse(valor.toString());

      if (convertido != null) return convertido;
    }

    return null;
  }

  double? doubleDesdeMapa(Map<String, dynamic>? mapa, List<String> llaves) {
    if (mapa == null) return null;

    for (final llave in llaves) {
      if (!mapa.containsKey(llave)) continue;

      final valor = mapa[llave];

      if (valor == null) continue;

      if (valor is double) return valor;

      if (valor is int) return valor.toDouble();

      final convertido = double.tryParse(valor.toString());

      if (convertido != null) return convertido;
    }

    return null;
  }

  bool boolDesdeMapa(Map<String, dynamic>? mapa, List<String> llaves) {
    if (mapa == null) return false;

    for (final llave in llaves) {
      if (!mapa.containsKey(llave)) continue;

      final valor = mapa[llave];

      if (valor is bool) return valor;

      final texto = valor.toString().trim().toLowerCase();

      if (texto == '1' ||
          texto == 'true' ||
          texto == 'si' ||
          texto == 'sí' ||
          texto == 'maximo' ||
          texto == 'máximo') {
        return true;
      }
    }

    return false;
  }

  DateTime? convertirFecha(dynamic valor) {
    if (valor == null) return null;

    if (valor is DateTime) {
      return valor;
    }

    final textoOriginal = valor.toString().trim();

    if (textoOriginal.isEmpty) return null;

    final textoLimpio = textoOriginal
        .replaceAll('T', ' ')
        .replaceAll(RegExp(r'\.\d+'), '')
        .replaceAll(RegExp(r'Z$', caseSensitive: false), '')
        .replaceAll(RegExp(r'([+-]\d{2}:?\d{2})$'), '')
        .trim();

    final regex = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    );

    final match = regex.firstMatch(textoLimpio);

    if (match == null) {
      return DateTime.tryParse(textoOriginal);
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;

    return DateTime(year, month, day, hour, minute, second);
  }

  DateTime? obtenerFechaReferencia(
    Map<String, dynamic> item,
    List<String> llaves,
  ) {
    for (final llave in llaves) {
      final fecha = convertirFecha(item[llave]);

      if (fecha != null) {
        return fecha;
      }
    }

    return null;
  }

  bool fechaDentroDeHoras(DateTime? fecha, int horas) {
    if (fecha == null) return false;

    final diferencia = ahoraTick.difference(fecha);

    return diferencia.inMilliseconds >= 0 &&
        diferencia.inHours < horas;
  }

  String obtenerFechaKey(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  bool esMismaFecha(DateTime? fechaA, DateTime? fechaB) {
    if (fechaA == null || fechaB == null) return false;

    return obtenerFechaKey(fechaA) == obtenerFechaKey(fechaB);
  }

  String? formatearHora(DateTime? fecha) {
    if (fecha == null) return null;

    final horas = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');

    return '$horas:$minutos';
  }

  String formatearFechaCorta(DateTime? fecha) {
    if (fecha == null) return '';

    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  String formatearFechaHora(DateTime? fecha) {
    if (fecha == null) return '--/-- --:--';

    final fechaTexto = formatearFechaCorta(fecha);
    final horaTexto = formatearHora(fecha) ?? '--:--';

    return '$fechaTexto $horaTexto';
  }

  String formatearCuentaRegresiva(
    DateTime? fechaObjetivo, [
    DateTime? fechaActual,
  ]) {
    if (fechaObjetivo == null) return '';

    final actual = fechaActual ?? DateTime.now();
    final diferencia = fechaObjetivo.difference(actual);

    if (diferencia.inMilliseconds <= 0) {
      return 'Ya abrió';
    }

    final horas = diferencia.inHours;
    final minutos = diferencia.inMinutes.remainder(60);

    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')} h';
  }

  Color obtenerColorPorTipo(dynamic tipo) {
    final texto = (tipo ?? '').toString().toLowerCase();
    int total = 0;

    for (int i = 0; i < texto.length; i++) {
      total += texto.codeUnitAt(i);
    }

    return coloresTipos[total % coloresTipos.length];
  }

  IconData obtenerIconoPorTipo(dynamic tipo) {
    final texto = (tipo ?? '').toString().toLowerCase();

    if (texto.contains('vida') || texto.contains('diaria')) {
      return Icons.home_outlined;
    }

    if (texto.contains('escuela') || texto.contains('estudio')) {
      return Icons.school_outlined;
    }

    if (texto.contains('trabajo')) {
      return Icons.work_outline;
    }

    if (texto.contains('salud')) {
      return Icons.favorite_border;
    }

    if (texto.contains('casa')) {
      return Icons.construction_outlined;
    }

    return Icons.flag_outlined;
  }

  String normalizarEstatus(dynamic valor) {
    return (valor ?? '').toString().trim().toLowerCase();
  }

  bool estatusEsTerminado(dynamic valor) {
    final estatus = normalizarEstatus(valor);

    return estatus == 'completada' ||
        estatus == 'completado' ||
        estatus == 'terminada' ||
        estatus == 'terminado' ||
        estatus == 'finalizada' ||
        estatus == 'finalizado';
  }

  bool estatusEsNoCumplido(dynamic valor) {
    final estatus = normalizarEstatus(valor);

    return estatus == 'no_cumplida' ||
        estatus == 'no cumplida' ||
        estatus == 'no_cumplido' ||
        estatus == 'no cumplido' ||
        estatus == 'fallida' ||
        estatus == 'vencida';
  }

  bool estatusEsPendiente(dynamic valor) {
    final estatus = normalizarEstatus(valor);

    return estatus.isEmpty ||
        estatus == 'pendiente' ||
        estatus == 'activa' ||
        estatus == 'activo';
  }

  String obtenerEstadoTiempo(
    Map<String, dynamic> actividad,
    DateTime? fechaInicio,
    DateTime? fechaFin, [
    DateTime? ahora,
  ]) {
    final actual = ahora ?? DateTime.now();
    final estatus = actividad['estatus'];

    if (estatusEsTerminado(estatus)) return 'completada';
    if (estatusEsNoCumplido(estatus)) return 'no_cumplida';

    if (fechaInicio == null) return 'sin_fecha';

    if (fechaInicio.isAfter(actual)) {
      final diferencia = fechaInicio.difference(actual).inMilliseconds;

      if (diferencia <= veinticuatroHorasMs) {
        return 'por_abrir';
      }

      return 'futura';
    }

    if (fechaFin == null) {
      return 'atrasada';
    }

    DateTime fechaFinNormalizada = fechaFin;

    if (fechaFinNormalizada.isBefore(fechaInicio) ||
        fechaFinNormalizada.isAtSameMomentAs(fechaInicio)) {
      fechaFinNormalizada = fechaFinNormalizada.add(const Duration(days: 1));
    }

    final limiteParaCumplir = fechaFinNormalizada.add(tiempoExtraParaCumplir);

    if (actual.isBefore(limiteParaCumplir)) {
      return 'en_proceso';
    }

    return 'vencida';
  }

  DateTime? obtenerLimiteParaCumplir(
    DateTime? fechaInicio,
    DateTime? fechaFin,
  ) {
    if (fechaInicio == null || fechaFin == null) return null;

    DateTime fechaFinNormalizada = fechaFin;

    if (fechaFinNormalizada.isBefore(fechaInicio) ||
        fechaFinNormalizada.isAtSameMomentAs(fechaInicio)) {
      fechaFinNormalizada = fechaFinNormalizada.add(const Duration(days: 1));
    }

    return fechaFinNormalizada.add(tiempoExtraParaCumplir);
  }

  Map<String, dynamic> mapearActividadAMision(Map<String, dynamic> actividad) {
    final fechaInicio = convertirFecha(actividad['fecha_inicio']);
    final fechaFin = convertirFecha(actividad['fecha_fin']);
    final estadoTiempo = obtenerEstadoTiempo(
      actividad,
      fechaInicio,
      fechaFin,
      ahoraTick,
    );
    final fechaLimiteCumplimiento = obtenerLimiteParaCumplir(
      fechaInicio,
      fechaFin,
    );

    final valorExp = toInt(actividad['valor_exp'], 0);
    final estatus = actividad['estatus'];

    return {
      ...actividad,
      'titulo': actividad['nombre'],
      'categoria': actividad['tipo'] ?? 'Sin categoría',
      'xp': valorExp,
      'color': obtenerColorPorTipo(actividad['tipo']),
      'icono': obtenerIconoPorTipo(actividad['tipo']),
      'completada': estatusEsTerminado(estatus),
      'noCumplida': estatusEsNoCumplido(estatus),
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'fechaLimiteCumplimiento': fechaLimiteCumplimiento,
      'fechaInicioTexto': formatearFechaHora(fechaInicio),
      'fechaFinTexto': formatearFechaHora(fechaFin),
      'fechaLimiteTexto': formatearFechaHora(fechaLimiteCumplimiento),
      'fechaCorta': formatearFechaCorta(fechaInicio),
      'horaInicio': formatearHora(fechaInicio),
      'horaFinal': formatearHora(fechaFin),
      'vencida': estadoTiempo == 'vencida',
      'atrasada': estadoTiempo == 'atrasada',
      'enProceso': estadoTiempo == 'en_proceso',
      'porAbrir': estadoTiempo == 'por_abrir',
      'futura': estadoTiempo == 'futura',
      'estadoTiempo': estadoTiempo,
      'cuentaRegresiva': estadoTiempo == 'por_abrir' || estadoTiempo == 'futura'
          ? formatearCuentaRegresiva(fechaInicio, ahoraTick)
          : '',
      'penalizacion': (valorExp / 2).ceil(),
    };
  }

  List<Map<String, dynamic>> ordenarMisiones(List<Map<String, dynamic>> lista) {
    final pesoEstado = {
      'vencida': 1,
      'no_cumplida': 2,
      'atrasada': 3,
      'en_proceso': 4,
      'activa': 5,
      'por_abrir': 6,
      'futura': 7,
      'completada': 8,
      'sin_fecha': 9,
    };

    final copia = [...lista];

    copia.sort((a, b) {
      final pesoA = pesoEstado[a['estadoTiempo']] ?? 99;
      final pesoB = pesoEstado[b['estadoTiempo']] ?? 99;

      if (pesoA != pesoB) {
        return pesoA.compareTo(pesoB);
      }

      final fechaA = a['fechaInicio'];
      final fechaB = b['fechaInicio'];

      final tiempoA = fechaA is DateTime ? fechaA.millisecondsSinceEpoch : 0;
      final tiempoB = fechaB is DateTime ? fechaB.millisecondsSinceEpoch : 0;

      return tiempoA.compareTo(tiempoB);
    });

    return copia;
  }

  List<Map<String, dynamic>> obtenerMisionesParaDashboard(
    List<Map<String, dynamic>> actividades,
  ) {
    final mapeadas = actividades.map(mapearActividadAMision).toList();

    return ordenarMisiones(mapeadas);
  }

  List<Map<String, dynamic>> recalcularCuentasRegresivas(
    List<Map<String, dynamic>> misionesActuales,
  ) {
    final actualizadas = misionesActuales.map((mision) {
      final fechaInicio = convertirFecha(mision['fecha_inicio']);
      final fechaFin = convertirFecha(mision['fecha_fin']);

      final estadoTiempo = obtenerEstadoTiempo(
        mision,
        fechaInicio,
        fechaFin,
        ahoraTick,
      );
      final fechaLimiteCumplimiento = obtenerLimiteParaCumplir(
        fechaInicio,
        fechaFin,
      );

      return {
        ...mision,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'fechaLimiteCumplimiento': fechaLimiteCumplimiento,
        'fechaInicioTexto': formatearFechaHora(fechaInicio),
        'fechaFinTexto': formatearFechaHora(fechaFin),
        'fechaLimiteTexto': formatearFechaHora(fechaLimiteCumplimiento),
        'estadoTiempo': estadoTiempo,
        'vencida': estadoTiempo == 'vencida',
        'atrasada': estadoTiempo == 'atrasada',
        'enProceso': estadoTiempo == 'en_proceso',
        'porAbrir': estadoTiempo == 'por_abrir',
        'futura': estadoTiempo == 'futura',
        'cuentaRegresiva': estadoTiempo == 'por_abrir' || estadoTiempo == 'futura'
            ? formatearCuentaRegresiva(fechaInicio, ahoraTick)
            : '',
      };
    }).toList();

    return ordenarMisiones(actualizadas);
  }

  bool esPendienteFiltro(Map<String, dynamic> mision) {
    final estado = mision['estadoTiempo']?.toString();

    if (!estatusEsPendiente(mision['estatus'])) return false;

    return estado == 'activa' ||
        estado == 'atrasada' ||
        estado == 'en_proceso' ||
        estado == 'sin_fecha';
  }

  bool esProximaFiltro(Map<String, dynamic> mision) {
    final estado = mision['estadoTiempo']?.toString();

    if (!estatusEsPendiente(mision['estatus'])) return false;

    return estado == 'por_abrir' || estado == 'futura';
  }

  bool esVencidaFiltro(Map<String, dynamic> mision) {
    final estado = mision['estadoTiempo']?.toString();

    if (estado == 'vencida') {
      return true;
    }

    if (estado == 'no_cumplida' || mision['noCumplida'] == true) {
      final fechaReferencia = obtenerFechaReferencia(
        mision,
        [
          'fecha_no_cumplida',
          'fechaLimiteCumplimiento',
          'fecha_cierre',
          'fecha_actualizacion',
          'updated_at',
          'fecha_fin',
          'fecha_inicio',
        ],
      );

      return fechaDentroDeHoras(fechaReferencia, 24);
    }

    return false;
  }

  bool esTerminadaFiltro(Map<String, dynamic> mision) {
    if (mision['completada'] != true && !estatusEsTerminado(mision['estatus'])) {
      return false;
    }

    final fechaReferencia = obtenerFechaReferencia(
      mision,
      [
        'fecha_completada',
        'fecha_completado',
        'completada_en',
        'terminada_en',
        'fecha_actualizacion',
        'updated_at',
        'fecha_fin',
        'fecha_inicio',
      ],
    );

    return fechaDentroDeHoras(fechaReferencia, 48);
  }

  List<Map<String, dynamic>> get misionesFiltradas {
    List<Map<String, dynamic>> filtradas;

    if (filtroMisiones == 'proximas') {
      filtradas = misiones.where(esProximaFiltro).toList();
    } else if (filtroMisiones == 'vencidas') {
      filtradas = misiones.where(esVencidaFiltro).toList();
    } else if (filtroMisiones == 'terminadas') {
      filtradas = misiones.where(esTerminadaFiltro).toList();
    } else {
      filtradas = misiones.where(esPendienteFiltro).toList();
    }

    return ordenarMisiones(filtradas);
  }

  int get totalPendientes {
    return misiones.where(esPendienteFiltro).length;
  }

  int get totalProximas {
    return misiones.where(esProximaFiltro).length;
  }

  int get totalVencidas {
    return misiones.where(esVencidaFiltro).length;
  }

  int get totalTerminadas {
    return misiones.where(esTerminadaFiltro).length;
  }

  String get tituloFiltroActual {
    if (filtroMisiones == 'proximas') return 'Misiones próximas';
    if (filtroMisiones == 'vencidas') return 'Misiones vencidas';
    if (filtroMisiones == 'terminadas') return 'Misiones terminadas';

    return 'Misiones pendientes';
  }

  String get subtituloFiltroActual {
    if (filtroMisiones == 'proximas') {
      return 'Actividades que todavía no inician';
    }

    if (filtroMisiones == 'vencidas') {
      return 'Vencidas y no cumplidas recientes';
    }

    if (filtroMisiones == 'terminadas') {
      return 'Completadas durante las últimas 48 horas';
    }

    return 'Actividades activas o listas para completar';
  }

  String get textoVacioFiltro {
    if (filtroMisiones == 'proximas') {
      return 'No tienes misiones próximas.';
    }

    if (filtroMisiones == 'vencidas') {
      return 'No tienes misiones vencidas recientes.';
    }

    if (filtroMisiones == 'terminadas') {
      return 'No tienes misiones terminadas recientes.';
    }

    return 'No tienes misiones pendientes.';
  }

  String get descripcionVacioFiltro {
    if (filtroMisiones == 'proximas') {
      return 'Cuando una misión tenga fecha futura, aparecerá aquí.';
    }

    if (filtroMisiones == 'vencidas') {
      return 'Las no cumplidas se ocultan después de 24 horas.';
    }

    if (filtroMisiones == 'terminadas') {
      return 'Solo se muestran las terminadas durante las últimas 48 horas.';
    }

    return 'Las misiones activas, atrasadas o en proceso aparecerán aquí.';
  }

  Future<void> actualizarUsuarioEnStorage(
    Map<String, dynamic>? usuarioActualizado,
  ) async {
    if (usuarioActualizado == null) return;

    await StorageService.setItem(
      'usuario',
      usuarioActualizado.toString(),
    );
  }

  Future<void> cargarNivelUsuario() async {
    try {
      final response = await ApiService.get('/auth/nivel');

      if (response is! Map<String, dynamic>) {
        return;
      }

      final usuarioRaw = response['usuario'];
      final nivelInfoRaw = response['nivel_info'] ??
          response['nivelInfo'] ??
          response['info_nivel'] ??
          response['nivel_actual_info'];

      if (!mounted) return;

      setState(() {
        if (usuarioRaw is Map<String, dynamic>) {
          usuario = Map<String, dynamic>.from(usuarioRaw);
          xpTotal = toInt(usuario?['exp'], xpTotal);
          nivelActual = toInt(usuario?['nivel'], nivelActual);
        }

        if (nivelInfoRaw is Map<String, dynamic>) {
          nivelInfo = Map<String, dynamic>.from(nivelInfoRaw);
        }
      });

      if (usuarioRaw is Map<String, dynamic>) {
        await StorageService.setItem(
          'usuario',
          Map<String, dynamic>.from(usuarioRaw).toString(),
        );
      }
    } catch (error) {
      debugPrint('Error al cargar nivel: $error');
    }
  }

  Future<dynamic> guardarExpEnBackend(int nuevoExp) async {
    final response = await ApiService.put('/auth/exp', {
      'exp': nuevoExp,
    });

    if (response is Map<String, dynamic> && response['usuario'] != null) {
      final usuarioActualizado = Map<String, dynamic>.from(response['usuario']);

      if (!mounted) return response;

      setState(() {
        usuario = usuarioActualizado;
        xpTotal = toInt(usuarioActualizado['exp'], 0);
        nivelActual = toInt(usuarioActualizado['nivel'], 1);

        final nivelInfoRaw = response['nivel_info'] ??
            response['nivelInfo'] ??
            response['info_nivel'] ??
            response['nivel_actual_info'];

        nivelInfo = nivelInfoRaw is Map<String, dynamic>
            ? Map<String, dynamic>.from(nivelInfoRaw)
            : nivelInfo;
      });

      if (response['subio_nivel'] == true) {
        mostrarAnimacionLevelUp();
      }
    }

    return response;
  }

  Future<void> procesarVencidasEnBackend() async {
    try {
      await ApiService.post('/actividades/procesar-vencidas');
      await cargarNivelUsuario();
    } catch (error) {
      debugPrint('Error al procesar vencidas: $error');
    }
  }

  Future<void> cargarMisionesDelDia() async {
    try {
      if (!mounted) return;

      setState(() {
        cargandoMisiones = true;
      });

      await procesarVencidasEnBackend();

      final response = await ApiService.get('/actividades');

      List<dynamic> actividadesRaw = [];

      if (response is Map<String, dynamic>) {
        actividadesRaw = response['actividades'] is List
            ? response['actividades'] as List
            : [];
      }

      final actividades = actividadesRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final misionesDashboard = obtenerMisionesParaDashboard(actividades);

      if (!mounted) return;

      setState(() {
        misiones = misionesDashboard;
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudieron cargar las misiones del dashboard.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargandoMisiones = false;
      });
    }
  }

  Future<void> completarMision(Map<String, dynamic> misionSeleccionada) async {
    if (!estatusEsPendiente(misionSeleccionada['estatus'])) {
      return;
    }

    try {
      final valorExp = toInt(misionSeleccionada['valor_exp'], 0);
      final nuevoXp = xpTotal + valorExp;

      await ApiService.put('/actividades/${misionSeleccionada['id']}/completar');
      await guardarExpEnBackend(nuevoXp);

      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Misión completada',
        mensaje: 'Ganaste $valorExp puntos de experiencia.',
      );

      await cargarMisionesDelDia();
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo completar la misión.',
        ),
      );
    }
  }

  void mostrarAnimacionLevelUp() {
    setState(() {
      mostrarLevelUp = true;
    });

    levelUpController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1700), () async {
      if (!mounted) return;

      await levelUpController.reverse();

      if (!mounted) return;

      setState(() {
        mostrarLevelUp = false;
      });
    });
  }

  String limpiarError(Object error, String fallback) {
    String mensaje = error.toString();

    if (mensaje.startsWith('Exception: ')) {
      mensaje = mensaje.replaceFirst('Exception: ', '');
    }

    if (mensaje.trim().isEmpty) {
      return fallback;
    }

    return mensaje;
  }

  void mostrarMensaje({
    required String titulo,
    required String mensaje,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
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

  void iniciarAnimacionConfirmLogout() {
    setState(() {
      mostrarConfirmLogout = true;
      cerrandoSesion = false;
    });

    logoutController.forward(from: 0);
  }

  Future<void> cancelarCerrarSesion() async {
    await logoutController.reverse();

    if (!mounted) return;

    setState(() {
      mostrarConfirmLogout = false;
      cerrandoSesion = false;
    });
  }

  Future<void> cerrarSesion() async {
    try {
      setState(() {
        cerrandoSesion = true;
      });

      logoutSpinController.repeat();

      await Future.delayed(const Duration(milliseconds: 950));

      await AuthService.logout();

      logoutSpinController.stop();

      if (!mounted) return;

      setState(() {
        misiones = [];
        nivelInfo = null;
        xpTotal = 0;
        nivelActual = 1;
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (error) {
      logoutSpinController.stop();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void navegarAScreen(String screenName) {
    final args = {
      'usuario': usuario,
      'xpTotal': xpTotal,
      'nivelActual': nivelActual,
      'nivelInfo': nivelInfo,
      'misiones': misiones,
      'temaId': tema.id,
    };

    if (screenName == 'Misiones') {
      Navigator.pushNamed(
        context,
        '/misiones',
        arguments: args,
      );
      return;
    }

    if (screenName == 'Estadisticas' || screenName == 'Estadísticas') {
      Navigator.pushNamed(
        context,
        '/estadisticas',
        arguments: args,
      );
      return;
    }

    if (screenName == 'Ajustes') {
      Navigator.pushNamed(
        context,
        '/ajustes',
        arguments: args,
      );
      return;
    }

    mostrarMensaje(
      titulo: screenName,
      mensaje: 'Esta pantalla todavía falta convertirla de React Native a Flutter.',
    );
  }

  int? get expInicioNivel {
    return intDesdeMapa(nivelInfo, [
      'exp_inicio',
      'exp_min',
      'exp_minima',
      'xp_inicio',
      'xp_min',
      'xp_minima',
      'experiencia_inicio',
      'experiencia_minima',
    ]);
  }

  int? get expSiguienteNivel {
    return intDesdeMapa(nivelInfo, [
      'exp_siguiente',
      'exp_requerida_siguiente',
      'exp_necesaria_siguiente',
      'exp_para_siguiente_nivel',
      'exp_max',
      'exp_fin',
      'xp_siguiente',
      'xp_requerido_siguiente',
      'xp_necesario_siguiente',
      'experiencia_siguiente',
      'experiencia_requerida_siguiente',
    ]);
  }

  int? get siguienteNivel {
    return intDesdeMapa(nivelInfo, [
      'siguiente_nivel',
      'nivel_siguiente',
      'proximo_nivel',
      'próximo_nivel',
    ]);
  }

  bool get esNivelMaximo {
    return boolDesdeMapa(nivelInfo, [
      'es_maximo',
      'es_máximo',
      'nivel_maximo',
      'nivel_máximo',
      'maximo',
      'máximo',
    ]);
  }

  double get progresoNivel {
    final porcentaje = doubleDesdeMapa(nivelInfo, [
      'porcentaje',
      'porcentaje_nivel',
      'progreso',
      'progreso_nivel',
    ]);

    if (porcentaje != null) {
      if (porcentaje <= 1 && porcentaje >= 0) return porcentaje;
      if (porcentaje < 0) return 0;
      if (porcentaje > 100) return 1;

      return porcentaje / 100;
    }

    final inicio = expInicioNivel ?? 0;
    final siguiente = expSiguienteNivel;

    if (siguiente == null || siguiente <= inicio) return 0;

    final avance = xpTotal - inicio;
    final total = siguiente - inicio;

    final valor = avance / total;

    if (valor < 0) return 0;
    if (valor > 1) return 1;

    return valor;
  }

  int get expParaSubir {
    final directo = intDesdeMapa(nivelInfo, [
      'exp_para_subir',
      'xp_para_subir',
      'faltante',
      'exp_faltante',
      'xp_faltante',
      'experiencia_faltante',
    ]);

    if (directo != null && directo > 0) return directo;

    final siguiente = expSiguienteNivel;

    if (siguiente != null && siguiente > xpTotal) {
      return siguiente - xpTotal;
    }

    return 0;
  }

  String get textoNivelProgreso {
    if (nivelInfo == null) {
      return 'Consultando tabla de niveles...';
    }

    if (expParaSubir > 0) {
      final nivelDestino = siguienteNivel ?? (nivelActual + 1);

      return 'Faltan $expParaSubir XP para nivel $nivelDestino';
    }

    final siguiente = expSiguienteNivel;

    if (siguiente != null && xpTotal >= siguiente && !esNivelMaximo) {
      final nivelDestino = siguienteNivel ?? (nivelActual + 1);

      return 'Ya tienes XP para nivel $nivelDestino';
    }

    if (esNivelMaximo) {
      return 'Último nivel registrado en la tabla';
    }

    return 'Nivel calculado desde la tabla de niveles';
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
              child: buildMainContent(size),
            ),
            if (mostrarLevelUp) buildLevelUpOverlay(size),
            if (mostrarConfirmLogout) buildLogoutOverlay(size),
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
            icon: Icons.star,
          ),
          animatedBubble(
            top: size.height * 0.15,
            right: size.width * 0.10,
            color: tema.barraXp.withOpacity(0.2),
            icon: Icons.flash_on,
          ),
          animatedBubble(
            bottom: size.height * 0.10,
            left: size.width * 0.12,
            color: tema.secundario.withOpacity(0.2),
            icon: Icons.diamond,
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

  Widget buildMainContent(Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        children: [
          buildHeaderCard(),
          const SizedBox(height: 8),
          buildTabsRow(),
          const SizedBox(height: 8),
          buildPanelHeader(),
          const SizedBox(height: 8),
          buildMissionFilters(),
          Expanded(
            child: buildMissionsArea(),
          ),
        ],
      ),
    );
  }

  Widget buildHeaderCard() {
    final nombreUsuario = usuario?['nombre_usuario'] ?? 'Jugador';

    return AnimatedBuilder(
      animation: Listenable.merge([
        glowAnimation,
        runnerAnimation,
        headerScaleAnimation,
      ]),
      builder: (context, child) {
        final borderColor = Color.lerp(
          tema.borde,
          tema.primario,
          glowAnimation.value,
        )!;

        final runnerY = -4 * runnerAnimation.value;
        final runnerRotation = -0.052 + (runnerAnimation.value * 0.104);

        return Transform.scale(
          scale: headerScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: tema.tarjeta,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: tema.primario.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tema.primario,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tema.borde,
                          width: 3,
                        ),
                      ),
                      child: Transform.translate(
                        offset: Offset(0, runnerY),
                        child: Transform.rotate(
                          angle: runnerRotation,
                          child: const Icon(
                            Icons.directions_run,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreUsuario.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tema.texto,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.flash_on,
                                size: 13,
                                color: tema.barraXp,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  'Nivel $nivelActual • $xpTotal XP total',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tema.textoSuave,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            textoNivelProgreso,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: iniciarAnimacionConfirmLogout,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progresoNivel,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(tema.barraXp),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTabsRow() {
    return Row(
      children: [
        Expanded(
          child: ScreenButton(
            title: 'Misiones',
            icon: Icons.flag_outlined,
            color: tema.primario,
            onPress: () => navegarAScreen('Misiones'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ScreenButton(
            title: 'Estadísticas',
            icon: Icons.bar_chart_outlined,
            color: tema.barraXp,
            onPress: () => navegarAScreen('Estadísticas'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ScreenButton(
            title: 'Ajustes',
            icon: Icons.settings_outlined,
            color: tema.secundario,
            onPress: () => navegarAScreen('Ajustes'),
          ),
        ),
      ],
    );
  }

  Widget buildPanelHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tituloFiltroActual,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtituloFiltroActual,
                style: const TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: cargarMisionesDelDia,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh,
              color: tema.primario,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMissionFilters() {
    final filtros = [
      {
        'id': 'pendientes',
        'label': 'Pendientes',
        'count': totalPendientes,
        'icon': Icons.pending_actions_outlined,
      },
      {
        'id': 'proximas',
        'label': 'Próximas',
        'count': totalProximas,
        'icon': Icons.schedule_outlined,
      },
      {
        'id': 'vencidas',
        'label': 'Vencidas',
        'count': totalVencidas,
        'icon': Icons.warning_amber_outlined,
      },
      {
        'id': 'terminadas',
        'label': 'Terminadas',
        'count': totalTerminadas,
        'icon': Icons.check_circle_outline,
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final id = filtro['id'].toString();
          final activo = filtroMisiones == id;
          final icono = filtro['icon'] as IconData;
          final count = filtro['count'] as int;

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroMisiones = id;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo ? Colors.white : Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: activo ? Colors.white : Colors.white.withOpacity(0.22),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icono,
                    size: 17,
                    color: activo ? tema.primario : Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    filtro['label'].toString(),
                    style: TextStyle(
                      color: activo ? tema.texto : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: activo
                          ? tema.primario.withOpacity(0.12)
                          : Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: activo ? tema.primario : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildMissionsArea() {
    final lista = misionesFiltradas;

    if (cargandoMisiones) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'Cargando misiones...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.dark_mode_outlined,
                  size: 38,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  textoVacioFiltro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  descripcionVacioFiltro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 28),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final mision = lista[index];

        return AnimatedMissionCard(
          mision: mision,
          index: index,
          onComplete: () => completarMision(mision),
        );
      },
    );
  }

  Widget buildLevelUpOverlay(Size size) {
    return AnimatedBuilder(
      animation: levelUpController,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: levelOpacityAnimation.value,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.78),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: levelScaleAnimation.value,
                child: Container(
                  width: size.width * 0.82,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFFACC15),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFACC15).withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: tema.barraXp,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFEF3C7),
                            width: 5,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Subiste de nivel!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tema.texto,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ahora eres nivel $nivelActual',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tema.textoSuave,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.star,
                            color: Color(0xFFFACC15),
                            size: 20,
                          ),
                          SizedBox(width: 14),
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFACC15),
                            size: 24,
                          ),
                          SizedBox(width: 14),
                          Icon(
                            Icons.star,
                            color: Color(0xFFFACC15),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildLogoutOverlay(Size size) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        logoutController,
        logoutSpinController,
      ]),
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: logoutOpacityAnimation.value,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.82),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, logoutTranslateAnimation.value),
                child: Transform.scale(
                  scale: logoutScaleAnimation.value,
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.28),
                          blurRadius: 26,
                          offset: const Offset(0, 15),
                        ),
                      ],
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
                              color: const Color(0xFFEF4444),
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
                          cerrandoSesion ? 'Cerrando sesión...' : '¿Cerrar sesión?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tema.texto,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          cerrandoSesion
                              ? 'Guardando salida y limpiando tu sesión.'
                              : 'Tu avance queda guardado. Para volver tendrás que iniciar sesión de nuevo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tema.textoSuave,
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
                                    backgroundColor: const Color(0xFFEF4444),
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

class ScreenButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPress;

  const ScreenButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPress,
  });

  @override
  State<ScreenButton> createState() => _ScreenButtonState();
}

class _ScreenButtonState extends State<ScreenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1,
      value: 1,
    );

    scaleAnimation = controller;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void pressIn() {
    controller.reverse();
  }

  void pressOut() {
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPress,
      onTapDown: (_) => pressIn(),
      onTapUp: (_) => pressOut(),
      onTapCancel: pressOut,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedMissionCard extends StatefulWidget {
  final Map<String, dynamic> mision;
  final int index;
  final VoidCallback onComplete;

  const AnimatedMissionCard({
    super.key,
    required this.mision,
    required this.index,
    required this.onComplete,
  });

  @override
  State<AnimatedMissionCard> createState() => _AnimatedMissionCardState();
}

class _AnimatedMissionCardState extends State<AnimatedMissionCard>
    with TickerProviderStateMixin {
  late AnimationController introController;
  late AnimationController pressController;

  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1,
      value: 1,
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

    scaleAnimation = pressController;

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (!mounted) return;
      introController.forward();
    });
  }

  @override
  void dispose() {
    introController.dispose();
    pressController.dispose();
    super.dispose();
  }

  void pressIn() {
    pressController.reverse();
  }

  void pressOut() {
    pressController.forward();
  }

  bool estatusEsTerminado(dynamic valor) {
    final estatus = (valor ?? '').toString().trim().toLowerCase();

    return estatus == 'completada' ||
        estatus == 'completado' ||
        estatus == 'terminada' ||
        estatus == 'terminado' ||
        estatus == 'finalizada' ||
        estatus == 'finalizado';
  }

  bool estatusEsNoCumplido(dynamic valor) {
    final estatus = (valor ?? '').toString().trim().toLowerCase();

    return estatus == 'no_cumplida' ||
        estatus == 'no cumplida' ||
        estatus == 'no_cumplido' ||
        estatus == 'no cumplido' ||
        estatus == 'fallida' ||
        estatus == 'vencida';
  }

  bool estatusEsPendiente(dynamic valor) {
    final estatus = (valor ?? '').toString().trim().toLowerCase();

    return estatus.isEmpty ||
        estatus == 'pendiente' ||
        estatus == 'activa' ||
        estatus == 'activo';
  }

  @override
  Widget build(BuildContext context) {
    final mision = widget.mision;

    final completada =
        mision['completada'] == true || estatusEsTerminado(mision['estatus']);
    final noCumplida =
        mision['noCumplida'] == true || estatusEsNoCumplido(mision['estatus']);
    final porAbrir = mision['estadoTiempo'] == 'por_abrir';
    final futura = mision['estadoTiempo'] == 'futura';
    final atrasada = mision['estadoTiempo'] == 'atrasada';
    final vencida = mision['estadoTiempo'] == 'vencida';
    final enProceso = mision['estadoTiempo'] == 'en_proceso';

    String textoEstado() {
      if (completada) return 'Terminada';
      if (noCumplida) return 'No cumplida';
      if (vencida) return 'Vencida';
      if (atrasada) return 'Atrasada';
      if (enProceso) return 'En proceso';
      if (porAbrir) return 'Abre pronto';
      if (futura) return 'Próxima';
      return 'Activa';
    }

    Color background = Colors.white;
    Color border = Colors.transparent;
    Color badgeBg = const Color(0xFFEEF2FF);
    Color badgeText = const Color(0xFF4F46E5);

    if (noCumplida || vencida) {
      background = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECACA);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFB91C1C);
    } else if (atrasada) {
      background = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
    } else if (enProceso) {
      background = const Color(0xFFECFDF5);
      border = const Color(0xFFBBF7D0);
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF047857);
    } else if (porAbrir || futura) {
      background = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      badgeBg = const Color(0xFFDBEAFE);
      badgeText = const Color(0xFF0369A1);
    } else if (completada) {
      background = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF16A34A);
    }

    final Color missionColor = mision['color'] is Color
        ? mision['color']
        : const Color(0xFF4F46E5);

    final IconData icon = mision['icono'] is IconData
        ? mision['icono']
        : Icons.flag_outlined;

    final int xp = mision['xp'] is int
        ? mision['xp']
        : int.tryParse('${mision['xp'] ?? 0}') ?? 0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        introController,
        pressController,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => pressIn(),
        onTapUp: (_) => pressOut(),
        onTapCancel: pressOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: border,
              width: border == Colors.transparent ? 0 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: missionColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF8FAFC),
                    width: 3,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${mision['categoria'] ?? 'Sin categoría'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            textoEstado(),
                            style: TextStyle(
                              fontSize: 10,
                              color: badgeText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${mision['titulo'] ?? 'Sin título'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${mision['descripcion'] ?? 'Sin descripción'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        height: 1.34,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        buildScheduleBox(
                          icon: Icons.calendar_today_outlined,
                          text:
                              'Inicio ${mision['fechaInicioTexto'] ?? '--/-- --:--'}',
                        ),
                        buildScheduleBox(
                          icon: Icons.flag_outlined,
                          text:
                              'Final ${mision['fechaFinTexto'] ?? '--/-- --:--'}',
                        ),
                      ],
                    ),
                    if (enProceso)
                      buildInfoBox(
                        icon: Icons.play_circle_outline,
                        text:
                            'Puedes cumplirla hasta ${mision['fechaLimiteTexto'] ?? '--/-- --:--'}.',
                        bg: const Color(0xFFD1FAE5),
                        color: const Color(0xFF047857),
                      ),
                    if (porAbrir || futura)
                      buildInfoBox(
                        icon: Icons.hourglass_empty,
                        text: porAbrir
                            ? 'Abre en ${mision['cuentaRegresiva'] ?? ''}'
                            : 'Programada para más adelante.',
                        bg: const Color(0xFFDBEAFE),
                        color: const Color(0xFF0369A1),
                      ),
                    if (atrasada)
                      buildInfoBox(
                        icon: Icons.error_outline,
                        text: 'Ya inició, todavía puedes cumplirla.',
                        bg: const Color(0xFFFEF3C7),
                        color: const Color(0xFF92400E),
                      ),
                    if (noCumplida)
                      buildInfoBox(
                        icon: Icons.warning_amber_outlined,
                        text:
                            'No cumplida. Penalización: -${mision['penalizacion'] ?? 0} XP',
                        bg: const Color(0xFFFEE2E2),
                        color: const Color(0xFFB91C1C),
                      ),
                    if (vencida && !noCumplida)
                      buildInfoBox(
                        icon: Icons.warning_amber_outlined,
                        text:
                            'Tiempo agotado. Debe cerrarse como no cumplida y aplicar penalización.',
                        bg: const Color(0xFFFEE2E2),
                        color: const Color(0xFFB91C1C),
                      ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flash_on,
                                size: 15,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+$xp XP',
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        buildCompleteButton(
                          completada: completada,
                          noCumplida: noCumplida,
                          porAbrir: porAbrir || futura,
                          vencida: vencida,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildScheduleBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoBox({
    required IconData icon,
    required String text,
    required Color bg,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompleteButton({
    required bool completada,
    required bool noCumplida,
    required bool porAbrir,
    required bool vencida,
  }) {
    Color bg = const Color(0xFF4F46E5);
    IconData icon = Icons.check;
    String text = 'Completar';
    bool bloqueada = false;

    if (completada) {
      bg = const Color(0xFF16A34A);
      icon = Icons.done_all;
      text = 'Lista';
      bloqueada = true;
    } else if (noCumplida) {
      bg = const Color(0xFF94A3B8);
      icon = Icons.close;
      text = 'Cerrada';
      bloqueada = true;
    } else if (porAbrir) {
      bg = const Color(0xFF64748B);
      icon = Icons.lock_outline;
      text = 'Bloqueada';
      bloqueada = true;
    } else if (vencida) {
      bg = const Color(0xFFEF4444);
      icon = Icons.warning_amber_outlined;
      text = 'Vencida';
      bloqueada = true;
    }

    return GestureDetector(
      onTap: bloqueada ? null : widget.onComplete,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}