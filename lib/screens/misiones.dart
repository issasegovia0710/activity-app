import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../services/api_service.dart';
import '../utils/notificaciones_tareas.dart';

const List<Map<String, dynamic>> prioridades = [
  {
    'id': 1,
    'nombre': 'baja',
    'etiqueta': 'Baja',
    'color': Color(0xFF16A34A),
  },
  {
    'id': 2,
    'nombre': 'media',
    'etiqueta': 'Media',
    'color': Color(0xFFF59E0B),
  },
  {
    'id': 3,
    'nombre': 'alta',
    'etiqueta': 'Alta',
    'color': Color(0xFFEF4444),
  },
];

const List<Map<String, dynamic>> repeticiones = [
  {
    'id': 1,
    'valor': 'una vez',
    'etiqueta': 'Una vez',
  },
  {
    'id': 2,
    'valor': 'diario',
    'etiqueta': 'Diario',
  },
  {
    'id': 3,
    'valor': 'lunes a viernes',
    'etiqueta': 'L-V',
  },
  {
    'id': 4,
    'valor': 'sabado domingo',
    'etiqueta': 'S-D',
  },
  {
    'id': 5,
    'valor': 'personalizada',
    'etiqueta': 'Personalizada',
  },
];

const List<Map<String, dynamic>> dias = [
  {
    'codigo': 'L',
    'nombre': 'Lunes',
    'corto': 'L',
    'jsDay': 1,
  },
  {
    'codigo': 'M',
    'nombre': 'Martes',
    'corto': 'M',
    'jsDay': 2,
  },
  {
    'codigo': 'MI',
    'nombre': 'Miércoles',
    'corto': 'MI',
    'jsDay': 3,
  },
  {
    'codigo': 'J',
    'nombre': 'Jueves',
    'corto': 'J',
    'jsDay': 4,
  },
  {
    'codigo': 'V',
    'nombre': 'Viernes',
    'corto': 'V',
    'jsDay': 5,
  },
  {
    'codigo': 'S',
    'nombre': 'Sábado',
    'corto': 'S',
    'jsDay': 6,
  },
  {
    'codigo': 'D',
    'nombre': 'Domingo',
    'corto': 'D',
    'jsDay': 0,
  },
];

class MisionesScreen extends StatefulWidget {
  const MisionesScreen({super.key});

  @override
  State<MisionesScreen> createState() => _MisionesScreenState();
}

class _MisionesScreenState extends State<MisionesScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;
  Map<String, dynamic>? usuario;

  List<Map<String, dynamic>> tipos = [];
  bool cargandoTipos = false;
  String busquedaCategorias = '';

  Map<String, dynamic>? tipoSeleccionado;
  bool mostrarFormulario = false;
  bool guardando = false;

  String nombre = '';
  String descripcion = '';
  String tipoTexto = '';
  String prioridad = 'media';
  String duracionHoras = '';
  String repetecion = 'una vez';

  String fechaUnica = '';
  String horaInicio = '';

  Map<String, bool> diasPersonalizados = {};
  Map<String, String> horasPersonalizadas = {};

  bool actividadAutoacompletable = false;
  bool argsCargados = false;

  late AnimationController introController;
  late AnimationController floatController;
  late AnimationController modalController;

  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> floatAnimation;
  late Animation<double> overlayOpacity;
  late Animation<double> modalScale;
  late Animation<double> modalTranslateY;

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
      duration: const Duration(milliseconds: 320),
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

    overlayOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOut,
      ),
    );

    modalScale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOutBack,
      ),
    );

    modalTranslateY = Tween<double>(
      begin: 45,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: modalController,
        curve: Curves.easeOutBack,
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

      tema = AppThemes.getById(args['temaId']?.toString());
    }

    cargarTipos();
  }

  @override
  void dispose() {
    introController.dispose();
    floatController.dispose();
    modalController.dispose();
    super.dispose();
  }

  List<Color> get coloresTipos {
    return [
      tema.primario,
      tema.barraXp,
      tema.secundario,
      const Color(0xFF14B8A6),
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      tema.peligro,
      tema.exito,
    ];
  }

  List<Map<String, dynamic>> get tiposFiltrados {
    final texto = busquedaCategorias.trim().toLowerCase();

    if (texto.isEmpty) {
      return tipos;
    }

    return tipos.where((tipo) {
      final nombreTipo = tipo['nombre']?.toString().toLowerCase() ?? '';
      final descripcionTipo =
          tipo['descripcion']?.toString().toLowerCase() ?? '';

      return nombreTipo.contains(texto) || descripcionTipo.contains(texto);
    }).toList();
  }

  Future<void> cargarTipos() async {
    try {
      setState(() {
        cargandoTipos = true;
      });

      final response = await ApiService.get('/actividades/tipos');

      List<dynamic> tiposRaw = [];

      if (response is Map<String, dynamic> && response['tipos'] is List) {
        tiposRaw = response['tipos'];
      }

      final tiposFiltradosRaw = tiposRaw.whereType<Map>().toList();

      final tiposFormateados = tiposFiltradosRaw.asMap().entries.map((entry) {
        final index = entry.key;
        final tipo = Map<String, dynamic>.from(entry.value);

        return {
          'id': tipo['id'] ?? index + 1,
          'nombre': tipo['nombre'] ?? 'Sin nombre',
          'descripcion':
              'Ver, editar y administrar actividades de esta categoría.',
          'icono': obtenerIconoTipo(tipo['nombre']),
          'color': coloresTipos[index % coloresTipos.length],
          'fondo': tema.suavePrimario,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        tipos = tiposFormateados;
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudieron cargar las categorías desde la base de datos.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargandoTipos = false;
      });
    }
  }

  IconData obtenerIconoTipo(dynamic tipo) {
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

    return Icons.album_outlined;
  }

  String obtenerFechaHoy() {
    final fecha = DateTime.now();

    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String obtenerHoraActual() {
    final fecha = DateTime.now();

    final hours = fecha.hour.toString().padLeft(2, '0');
    final minutes = fecha.minute.toString().padLeft(2, '0');

    return '$hours:$minutes';
  }

  void abrirFormulario([Map<String, dynamic>? tipo]) {
    setState(() {
      tipoSeleccionado = tipo;
      mostrarFormulario = true;

      nombre = '';
      descripcion = '';
      tipoTexto = tipo?['nombre']?.toString() ?? '';
      prioridad = 'media';
      duracionHoras = '';
      repetecion = 'una vez';

      fechaUnica = obtenerFechaHoy();
      horaInicio = obtenerHoraActual();

      diasPersonalizados = {};
      horasPersonalizadas = {};

      actividadAutoacompletable = false;
    });

    modalController.forward(from: 0);
  }

  Future<void> cerrarFormulario() async {
    if (guardando) return;

    await modalController.reverse();

    if (!mounted) return;

    setState(() {
      mostrarFormulario = false;
      tipoSeleccionado = null;
    });
  }

  void irAClasificacion(Map<String, dynamic> categoria) {
    Navigator.pushNamed(
      context,
      '/activitis-dash',
      arguments: {
        'tipo': categoria['nombre'],
        'categoria': categoria,
        'usuario': usuario,
        'temaId': tema.id,
      },
    );
  }

  int calcularExpPorPrioridad() {
    if (prioridad == 'baja') return 5;
    if (prioridad == 'media') return 15;
    if (prioridad == 'alta') return 25;

    return 15;
  }

  int calcularBonusPorHoras() {
    final horas = double.tryParse(duracionHoras.trim());

    if (duracionHoras.trim().isEmpty || horas == null || horas <= 0) {
      return 0;
    }

    return (horas * 5).ceil();
  }

  int get valorExpCalculado {
    return calcularExpPorPrioridad() + calcularBonusPorHoras();
  }

  void seleccionarRepeticion(String repeticionSeleccionada) {
    setState(() {
      repetecion = repeticionSeleccionada;

      if (repeticionSeleccionada != 'personalizada') {
        diasPersonalizados = {};
        horasPersonalizadas = {};
      }
    });
  }

  void cambiarDiaPersonalizado(String codigo) {
    final valorActual = diasPersonalizados[codigo] ?? false;
    final nuevoValor = !valorActual;

    setState(() {
      diasPersonalizados[codigo] = nuevoValor;

      if (nuevoValor) {
        horasPersonalizadas[codigo] =
            horasPersonalizadas[codigo] ?? obtenerHoraActual();
      } else {
        horasPersonalizadas.remove(codigo);
      }
    });
  }

  void cambiarHoraPersonalizada(String codigo, String valor) {
    setState(() {
      horasPersonalizadas[codigo] = valor;
    });
  }

  bool fechaValida(String fecha) {
    final fechaTexto = fecha.trim();

    if (fechaTexto.isEmpty) return false;

    final regex = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');
    final match = regex.firstMatch(fechaTexto);

    if (match == null) return false;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);

    if (year == null || month == null || day == null) return false;

    final fechaObj = DateTime.tryParse(fechaTexto);

    if (fechaObj == null) return false;

    return fechaObj.year == year &&
        fechaObj.month == month &&
        fechaObj.day == day;
  }

  bool horaValida(String hora) {
    final horaTexto = hora.trim();

    if (horaTexto.isEmpty) return false;

    final regex = RegExp(r'^([0-9]{1,2}):([0-9]{2})$');
    final match = regex.firstMatch(horaTexto);

    if (match == null) return false;

    final horas = int.tryParse(match.group(1)!);
    final minutos = int.tryParse(match.group(2)!);

    if (horas == null || minutos == null) return false;

    return horas >= 0 && horas <= 23 && minutos >= 0 && minutos <= 59;
  }

  String normalizarHora(String hora) {
    final horaTexto = hora.trim();

    if (horaTexto.isEmpty) return '';

    final partes = horaTexto.split(':');

    if (partes.length != 2) return horaTexto;

    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);

    if (h == null || m == null) return horaTexto;

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String formatearFechaMysql(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final hours = fecha.hour.toString().padLeft(2, '0');
    final minutes = fecha.minute.toString().padLeft(2, '0');
    final seconds = fecha.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hours:$minutes:$seconds';
  }

  String? construirFechaInicioMysql(String fecha, String hora) {
    if (!fechaValida(fecha) || !horaValida(hora)) {
      return null;
    }

    return '${fecha.trim()} ${normalizarHora(hora)}:00';
  }

  DateTime? construirFechaConHora(DateTime fechaBase, String hora) {
    if (!horaValida(hora)) return null;

    final partes = normalizarHora(hora).split(':');
    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);

    return DateTime(
      fechaBase.year,
      fechaBase.month,
      fechaBase.day,
      horas,
      minutos,
    );
  }

  int obtenerJsDay(DateTime fecha) {
    if (fecha.weekday == DateTime.sunday) return 0;
    return fecha.weekday;
  }

  String? buscarProximaFechaPorDias(List<String> diasPermitidos, String hora) {
    if (!horaValida(hora)) return null;

    final ahora = DateTime.now();

    for (int i = 0; i <= 14; i++) {
      final candidataBase = DateTime(
        ahora.year,
        ahora.month,
        ahora.day + i,
      );

      final jsDay = obtenerJsDay(candidataBase);

      final diaEncontrado = dias.firstWhere(
        (dia) => dia['jsDay'] == jsDay,
        orElse: () => {},
      );

      final codigoDia = diaEncontrado['codigo']?.toString();

      if (codigoDia == null || !diasPermitidos.contains(codigoDia)) {
        continue;
      }

      final candidata = construirFechaConHora(candidataBase, hora);

      if (candidata == null) continue;

      if (candidata.isAfter(ahora)) {
        return formatearFechaMysql(candidata);
      }
    }

    return null;
  }

  String? construirRepeticion({bool modoPreview = false}) {
    if (repetecion == 'una vez') return 'una vez';

    if (repetecion == 'diario') return 'diario';

    if (repetecion == 'lunes a viernes') return 'lunes a viernes';

    if (repetecion == 'sabado domingo') return 'sabado domingo';

    if (repetecion == 'personalizada') {
      final diasSeleccionados = dias.where((dia) {
        final codigo = dia['codigo'].toString();
        return diasPersonalizados[codigo] == true;
      }).toList();

      if (diasSeleccionados.isEmpty) {
        return modoPreview ? 'Selecciona días y horas' : null;
      }

      final partes = <String>[];

      for (final dia in diasSeleccionados) {
        final codigo = dia['codigo'].toString();
        final horaDia = horasPersonalizadas[codigo] ?? '';

        if (!horaValida(horaDia)) {
          if (modoPreview) partes.add('$codigo-pendiente');
          continue;
        }

        partes.add('$codigo-${normalizarHora(horaDia)}');
      }

      if (partes.isEmpty) {
        return modoPreview ? 'Completa las horas seleccionadas' : null;
      }

      return partes.join(', ');
    }

    return null;
  }

  String? obtenerFechaInicioParaGuardar() {
    if (repetecion == 'una vez') {
      return construirFechaInicioMysql(fechaUnica, horaInicio);
    }

    if (repetecion == 'diario') {
      return buscarProximaFechaPorDias(
        ['L', 'M', 'MI', 'J', 'V', 'S', 'D'],
        horaInicio,
      );
    }

    if (repetecion == 'lunes a viernes') {
      return buscarProximaFechaPorDias(
        ['L', 'M', 'MI', 'J', 'V'],
        horaInicio,
      );
    }

    if (repetecion == 'sabado domingo') {
      return buscarProximaFechaPorDias(
        ['S', 'D'],
        horaInicio,
      );
    }

    if (repetecion == 'personalizada') {
      final candidatas = <Map<String, dynamic>>[];

      for (final dia in dias) {
        final codigo = dia['codigo'].toString();

        if (diasPersonalizados[codigo] != true) continue;

        final horaDia = horasPersonalizadas[codigo] ?? '';

        if (!horaValida(horaDia)) continue;

        final fechaProxima = buscarProximaFechaPorDias([codigo], horaDia);

        if (fechaProxima == null) continue;

        final fechaParse = DateTime.tryParse(fechaProxima.replaceAll(' ', 'T'));

        if (fechaParse == null) continue;

        candidatas.add({
          'fecha': fechaProxima,
          'timestamp': fechaParse.millisecondsSinceEpoch,
        });
      }

      if (candidatas.isEmpty) return null;

      candidatas.sort((a, b) {
        return (a['timestamp'] as int).compareTo(b['timestamp'] as int);
      });

      return candidatas.first['fecha']?.toString();
    }

    return null;
  }

  bool validarRepeticion() {
    if (repetecion == 'una vez') {
      if (!fechaValida(fechaUnica)) {
        mostrarMensaje(
          titulo: 'Fecha inválida',
          mensaje:
              'Escribe la fecha en formato YYYY-MM-DD. Ejemplo: 2026-04-27',
        );
        return false;
      }

      if (!horaValida(horaInicio)) {
        mostrarMensaje(
          titulo: 'Hora inválida',
          mensaje: 'Escribe una hora válida. Ejemplo: 6:00',
        );
        return false;
      }

      return true;
    }

    if (repetecion == 'diario' ||
        repetecion == 'lunes a viernes' ||
        repetecion == 'sabado domingo') {
      if (!horaValida(horaInicio)) {
        mostrarMensaje(
          titulo: 'Hora inválida',
          mensaje: 'Escribe una hora válida. Ejemplo: 6:00',
        );
        return false;
      }

      return true;
    }

    if (repetecion == 'personalizada') {
      final diasSeleccionados = dias.where((dia) {
        final codigo = dia['codigo'].toString();
        return diasPersonalizados[codigo] == true;
      }).toList();

      if (diasSeleccionados.isEmpty) {
        mostrarMensaje(
          titulo: 'Faltan días',
          mensaje: 'Selecciona al menos un día.',
        );
        return false;
      }

      for (final dia in diasSeleccionados) {
        final codigo = dia['codigo'].toString();
        final horaDia = horasPersonalizadas[codigo] ?? '';

        if (!horaValida(horaDia)) {
          mostrarMensaje(
            titulo: 'Hora inválida',
            mensaje:
                'Escribe una hora válida para ${dia['nombre']}. Ejemplo: 6:00',
          );
          return false;
        }
      }

      return true;
    }

    return true;
  }

  dynamic obtenerIdActividadRespuesta(
    dynamic response,
    Map<String, dynamic> nuevaActividad,
  ) {
    if (response is Map<String, dynamic>) {
      final actividad = response['actividad'];

      if (actividad is Map<String, dynamic>) {
        return actividad['id'] ??
            actividad['id_actividad'] ??
            actividad['idActividad'];
      }

      return response['id'] ??
          response['id_actividad'] ??
          response['idActividad'] ??
          response['actividadId'] ??
          '${nuevaActividad['nombre']}-${nuevaActividad['fecha_inicio']}';
    }

    return '${nuevaActividad['nombre']}-${nuevaActividad['fecha_inicio']}';
  }

  Future<void> guardarMision() async {
    if (tipoTexto.trim().isEmpty) {
      mostrarMensaje(
        titulo: 'Falta tipo',
        mensaje: 'Escribe o elige un tipo/categoría para la misión.',
      );
      return;
    }

    if (nombre.trim().isEmpty) {
      mostrarMensaje(
        titulo: 'Falta nombre',
        mensaje: 'Escribe el nombre de la misión.',
      );
      return;
    }

    final horas = double.tryParse(duracionHoras.trim());

    if (duracionHoras.trim().isNotEmpty && (horas == null || horas <= 0)) {
      mostrarMensaje(
        titulo: 'Duración inválida',
        mensaje: 'La duración debe ser un número mayor a 0.',
      );
      return;
    }

    if (!validarRepeticion()) return;

    final double? duracionFinal =
        duracionHoras.trim().isNotEmpty && horas != null ? horas : null;

    final fechaInicioFinal = obtenerFechaInicioParaGuardar();

    if (fechaInicioFinal == null) {
      mostrarMensaje(
        titulo: 'Falta fecha de inicio',
        mensaje: 'No se pudo calcular la próxima fecha de inicio.',
      );
      return;
    }

    final nuevaActividad = {
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
      'tipo': tipoTexto.trim(),
      'prioridad': prioridad,
      'valor_exp': valorExpCalculado,
      'duracion_horas': duracionFinal,
      'fecha_inicio': fechaInicioFinal,
      'actividad_autoacompletable': actividadAutoacompletable ? 1 : 0,
      'repetecion': construirRepeticion(modoPreview: false),
      'estatus': 'pendiente',
      'auxiliar': null,
    };

    try {
      setState(() {
        guardando = true;
      });

      final response = await ApiService.post('/actividades', nuevaActividad);

      final idActividad = obtenerIdActividadRespuesta(
        response,
        nuevaActividad,
      );

      DateTime? fechaExpiracionCalculada;

      if (duracionFinal != null) {
        final fechaInicioDate = DateTime.tryParse(
          fechaInicioFinal.replaceAll(' ', 'T'),
        );

        if (fechaInicioDate != null) {
          fechaExpiracionCalculada = fechaInicioDate.add(
            Duration(
              minutes: (duracionFinal * 60).round(),
            ),
          );
        }
      }

      final actividadParaNotificaciones = {
        'id': idActividad,
        'id_tarea': idActividad,
        'titulo': nuevaActividad['nombre'],
        'nombre': nuevaActividad['nombre'],
        'descripcion': nuevaActividad['descripcion'],
        'tipo': nuevaActividad['tipo'],
        'prioridad': nuevaActividad['prioridad'],
        'estatus': nuevaActividad['estatus'],
        'fechaInicio': fechaInicioFinal,
        'fecha_inicio': fechaInicioFinal,
        'fechaExpiracion': fechaExpiracionCalculada == null
            ? null
            : formatearFechaMysql(fechaExpiracionCalculada),
        'fecha_expiracion': fechaExpiracionCalculada == null
            ? null
            : formatearFechaMysql(fechaExpiracionCalculada),
        'duracion_horas': duracionFinal,
        'actividad_autoacompletable':
            nuevaActividad['actividad_autoacompletable'],
      };

      final resultadoNotificaciones =
          await NotificacionesTareas.programarNotificacionesTarea(
        actividadParaNotificaciones,
      );

      if (resultadoNotificaciones['ok'] != true) {
        debugPrint(
          'La misión se guardó, pero no se pudieron programar notificaciones: ${resultadoNotificaciones['mensaje']}',
        );
      }

      String mensaje = 'La misión se dio de alta correctamente.';

      if (response is Map<String, dynamic> && response['mensaje'] != null) {
        mensaje = response['mensaje'].toString();
      }

      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Misión creada',
        mensaje: mensaje,
      );

      setState(() {
        guardando = false;
      });

      await cerrarFormulario();
      await cargarTipos();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo guardar la misión. Revisa el backend o la sesión.',
        ),
      );
    }
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
              child: buildContent(size),
            ),
            if (mostrarFormulario) buildFormularioOverlay(size),
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
            icon: Icons.flag,
          ),
          animatedBubble(
            top: size.height * 0.15,
            right: size.width * 0.1,
            color: tema.barraXp.withOpacity(0.2),
            icon: Icons.rocket_launch,
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

  Widget buildContent(Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        children: [
          buildHeader(),
          buildInfoCard(),
          buildSearchBox(),
          buildNewMissionButton(),
          Expanded(
            child: buildCategoriasArea(),
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
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
                  'Misiones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${usuario?['nombre_usuario'] ?? 'Jugador'}, crea o revisa tus categorías',
                  style: TextStyle(
                    color: tema.borde,
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

  Widget buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tema.primario,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: tema.borde,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.album_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorías de misiones',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Busca, abre o crea misiones dentro de cada categoría.',
                  style: TextStyle(
                    color: tema.textoSuave,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBox() {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.55),
          width: 1.2,
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
        children: [
          Icon(
            Icons.search,
            color: tema.primario,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  busquedaCategorias = value;
                });
              },
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar categoría...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (busquedaCategorias.trim().isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  busquedaCategorias = '';
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildNewMissionButton() {
    return Container(
      width: double.infinity,
      height: 42,
      margin: const EdgeInsets.only(bottom: 12),
      child: FilledButton.icon(
        onPressed: () => abrirFormulario(null),
        icon: const Icon(
          Icons.add_circle_outline,
          size: 20,
        ),
        label: const Text(
          'Crear nueva misión',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: tema.primario,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget buildCategoriasArea() {
    if (cargandoTipos) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'Cargando tipos...',
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

    if (tipos.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.folder_open_outlined,
                  size: 42,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Aún no hay tipos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crea una misión para que aparezca su categoría.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

    final lista = tiposFiltrados;

    if (lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
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
                  Icons.search_off,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sin resultados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'No encontré categorías con "$busquedaCategorias".',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho >= 820 ? 2 : 1;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 138,
          ),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final tipo = lista[index];

            return AnimatedCategoryCard(
              categoria: tipo,
              index: index,
              tema: tema,
              onPress: () => irAClasificacion(tipo),
              onCreate: () => abrirFormulario(tipo),
            );
          },
        );
      },
    );
  }

  Widget buildFormularioOverlay(Size size) {
    return AnimatedBuilder(
      animation: modalController,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: overlayOpacity.value,
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.78),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, modalTranslateY.value),
                child: Transform.scale(
                  scale: modalScale.value,
                  child: buildFormularioCard(size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFormularioCard(Size size) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: size.height * 0.88,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: tema.borde,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          buildFormularioHeader(),
          Flexible(
            child: SingleChildScrollView(
              child: buildFormularioBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormularioHeader() {
    final Color colorCategoria = tipoSeleccionado?['color'] is Color
        ? tipoSeleccionado!['color'] as Color
        : tema.primario;

    final IconData iconoCategoria = tipoSeleccionado?['icono'] is IconData
        ? tipoSeleccionado!['icono'] as IconData
        : Icons.album_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorCategoria,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF8FAFC),
                width: 3,
              ),
            ),
            child: Icon(
              iconoCategoria,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva misión',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipoSeleccionado != null
                      ? tipoSeleccionado!['nombre'].toString()
                      : 'Nuevo tipo/categoría',
                  style: TextStyle(
                    color: tema.textoSuave,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: cerrarFormulario,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tema.peligro,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormularioBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('Tipo / categoría'),
        buildTextInput(
          value: tipoTexto,
          icon: Icons.album_outlined,
          hint: 'Ej. Vida diaria, Escuela, Trabajo',
          onChanged: (value) {
            setState(() {
              tipoTexto = value;
            });
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Puedes usar un tipo existente o escribir uno nuevo.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        buildLabel('Nombre de la misión'),
        buildTextInput(
          value: nombre,
          icon: Icons.edit_outlined,
          hint: 'Ej. Hacer tarea',
          onChanged: (value) {
            setState(() {
              nombre = value;
            });
          },
        ),
        buildLabel('Descripción'),
        buildTextInput(
          value: descripcion,
          icon: Icons.description_outlined,
          hint: 'Describe brevemente la misión',
          multiline: true,
          onChanged: (value) {
            setState(() {
              descripcion = value;
            });
          },
        ),
        buildLabel('Prioridad'),
        buildPrioridadRow(),
        buildLabel('Duración estimada en horas'),
        buildTextInput(
          value: duracionHoras,
          icon: Icons.access_time,
          hint: 'Ej. 1.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {
              duracionHoras = value;
            });
          },
        ),
        buildLabel('Repetición'),
        buildRepetitionGrid(),
        buildCamposRepeticion(),
        buildLabel('Actividad autoacompletable'),
        buildAutoBox(),
        buildLabel('Experiencia asignada automáticamente'),
        buildExpAutoBox(),
        buildExpBreakdownBox(),
        const SizedBox(height: 18),
        buildSaveButton(),
      ],
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildTextInput({
    required String value,
    required IconData icon,
    required String hint,
    required ValueChanged<String> onChanged,
    bool multiline = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: multiline ? 88 : 54,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: multiline ? 14 : 0),
            child: Icon(
              icon,
              color: tema.primario,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              enabled: !guardando,
              keyboardType: keyboardType,
              minLines: multiline ? 3 : 1,
              maxLines: multiline ? 5 : 1,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget buildPrioridadRow() {
    return Row(
      children: prioridades.map((item) {
        final activo = prioridad == item['nombre'];
        final color = item['color'] as Color;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: guardando
                  ? null
                  : () {
                      setState(() {
                        prioridad = item['nombre'].toString();
                      });
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: activo ? color : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activo ? color : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item['etiqueta'].toString(),
                  style: TextStyle(
                    color: activo ? Colors.white : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildRepetitionGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: repeticiones.map((item) {
        final activo = repetecion == item['valor'];

        return GestureDetector(
          onTap: guardando
              ? null
              : () {
                  seleccionarRepeticion(item['valor'].toString());
                },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: activo ? tema.primario : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: activo ? tema.primario : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Text(
              item['etiqueta'].toString(),
              style: TextStyle(
                color: activo ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildCamposRepeticion() {
    if (repetecion == 'una vez') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLabel('Fecha y hora de inicio'),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: buildTextInput(
                  value: fechaUnica,
                  icon: Icons.calendar_today_outlined,
                  hint: 'YYYY-MM-DD',
                  onChanged: (value) {
                    setState(() {
                      fechaUnica = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: buildTextInput(
                  value: horaInicio,
                  icon: Icons.access_time,
                  hint: '6:00',
                  onChanged: (value) {
                    setState(() {
                      horaInicio = value;
                    });
                  },
                ),
              ),
            ],
          ),
          buildPreviewBox(
            primera: 'Inicio: ${obtenerFechaInicioParaGuardar() ?? 'pendiente'}',
            segunda: 'Repetición: una vez',
          ),
        ],
      );
    }

    if (repetecion == 'diario' ||
        repetecion == 'lunes a viernes' ||
        repetecion == 'sabado domingo') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLabel('Hora de inicio'),
          buildTextInput(
            value: horaInicio,
            icon: Icons.access_time,
            hint: '6:00',
            onChanged: (value) {
              setState(() {
                horaInicio = value;
              });
            },
          ),
          buildPreviewBox(
            primera:
                'Próxima fecha: ${obtenerFechaInicioParaGuardar() ?? 'pendiente'}',
            segunda: 'Repetición: ${construirRepeticion(modoPreview: true)}',
          ),
        ],
      );
    }

    if (repetecion == 'personalizada') {
      final diasSeleccionados = dias.where((dia) {
        final codigo = dia['codigo'].toString();
        return diasPersonalizados[codigo] == true;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLabel('Selecciona días y hora'),
          Row(
            children: dias.map((dia) {
              final codigo = dia['codigo'].toString();
              final activo = diasPersonalizados[codigo] == true;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: guardando
                        ? null
                        : () {
                            cambiarDiaPersonalizado(codigo);
                          },
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: activo ? tema.primario : Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color:
                              activo ? tema.primario : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dia['corto'].toString(),
                        style: TextStyle(
                          color:
                              activo ? Colors.white : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          ...diasSeleccionados.map((dia) {
            final codigo = dia['codigo'].toString();

            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dia['nombre'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildTextInput(
                    value: horasPersonalizadas[codigo] ?? '',
                    icon: Icons.access_time,
                    hint: '6:00',
                    onChanged: (value) {
                      cambiarHoraPersonalizada(codigo, value);
                    },
                  ),
                ],
              ),
            );
          }),
          buildPreviewBox(
            primera:
                'Próxima fecha: ${obtenerFechaInicioParaGuardar() ?? 'pendiente'}',
            segunda: 'Repetición: ${construirRepeticion(modoPreview: true)}',
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget buildPreviewBox({
    required String primera,
    required String segunda,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se guardará como:',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            primera,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            segunda,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAutoBox() {
    return GestureDetector(
      onTap: guardando
          ? null
          : () {
              setState(() {
                actividadAutoacompletable = !actividadAutoacompletable;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: actividadAutoacompletable
              ? tema.suavePrimario
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: actividadAutoacompletable
                ? tema.primario
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: actividadAutoacompletable
                    ? tema.primario
                    : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                actividadAutoacompletable ? Icons.check : Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actividadAutoacompletable ? 'Activada' : 'Desactivada',
                    style: TextStyle(
                      color: actividadAutoacompletable
                          ? tema.primario
                          : const Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Si expira, se marcará como no cumplida y restará la mitad de XP.',
                    style: TextStyle(
                      color: actividadAutoacompletable
                          ? tema.primario
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExpAutoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tema.barraXp,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.flash_on,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valorExpCalculado XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Se calcula por prioridad y duración',
                  style: TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 12,
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

  Widget buildExpBreakdownBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          buildExpBreakdownRow(
            label: 'Prioridad',
            value: '+${calcularExpPorPrioridad()} XP',
          ),
          const SizedBox(height: 6),
          buildExpBreakdownRow(
            label: 'Horas',
            value: '+${calcularBonusPorHoras()} XP',
          ),
        ],
      ),
    );
  }

  Widget buildExpBreakdownRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: guardando ? null : guardarMision,
        icon: guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          guardando ? 'Guardando...' : 'Guardar misión',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: tema.primario,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class AnimatedCategoryCard extends StatefulWidget {
  final Map<String, dynamic> categoria;
  final int index;
  final ActivityTheme tema;
  final VoidCallback onPress;
  final VoidCallback onCreate;

  const AnimatedCategoryCard({
    super.key,
    required this.categoria,
    required this.index,
    required this.tema,
    required this.onPress,
    required this.onCreate,
  });

  @override
  State<AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<AnimatedCategoryCard>
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
      duration: const Duration(milliseconds: 430),
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
      begin: 20,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: Curves.easeOutBack,
      ),
    );

    scaleAnimation = pressController;

    Future.delayed(Duration(milliseconds: widget.index * 65), () {
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

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;
    final tema = widget.tema;

    final Color color = categoria['color'] is Color
        ? categoria['color'] as Color
        : tema.primario;

    final IconData icono = categoria['icono'] is IconData
        ? categoria['icono'] as IconData
        : Icons.album_outlined;

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tema.tarjeta,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF8FAFC),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        icono,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria['nombre']?.toString() ?? 'Sin nombre',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tema.texto,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            categoria['descripcion']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tema.textoSuave,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    GestureDetector(
                      onTap: widget.onCreate,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              GestureDetector(
                onTap: widget.onPress,
                child: Container(
                  height: 34,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: color.withOpacity(0.18),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver actividades',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.chevron_right,
                        color: color,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}