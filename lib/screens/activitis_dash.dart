import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../services/api_service.dart';

const List<Map<String, dynamic>> prioridadesActivitis = [
  {'id': 1, 'nombre': 'baja', 'etiqueta': 'Baja'},
  {'id': 2, 'nombre': 'media', 'etiqueta': 'Media'},
  {'id': 3, 'nombre': 'alta', 'etiqueta': 'Alta'},
];

class ActivitisDashScreen extends StatefulWidget {
  const ActivitisDashScreen({super.key});

  @override
  State<ActivitisDashScreen> createState() => _ActivitisDashScreenState();
}

class _ActivitisDashScreenState extends State<ActivitisDashScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;

  String tipo = '';
  Map<String, dynamic>? categoria;

  List<Map<String, dynamic>> actividades = [];
  bool cargando = false;
  bool guardando = false;

  String filtroEstado = 'en_proceso';
  String busquedaActividades = '';

  final TextEditingController buscadorController = TextEditingController();

  Map<String, dynamic>? actividadEditando;
  bool mostrarEditor = false;

  String nombre = '';
  String descripcion = '';
  String prioridad = 'media';
  String duracionHoras = '';
  String estatus = 'pendiente';
  DateTime? fechaCierreEditando;
  bool fechaCierreManualEditada = false;

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
    ).animate(CurvedAnimation(parent: introController, curve: Curves.easeOut));

    slideAnimation = Tween<double>(begin: 35, end: 0).animate(
      CurvedAnimation(parent: introController, curve: Curves.easeOutBack),
    );

    floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );

    overlayOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: modalController, curve: Curves.easeOut));

    modalScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: modalController, curve: Curves.easeOutBack),
    );

    modalTranslateY = Tween<double>(begin: 45, end: 0).animate(
      CurvedAnimation(parent: modalController, curve: Curves.easeOutBack),
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

      tipo = args['tipo']?.toString() ?? '';

      categoria = args['categoria'] is Map
          ? Map<String, dynamic>.from(args['categoria'])
          : null;

      final temaDirecto = args['tema'];

      if (temaDirecto is ActivityTheme) {
        tema = temaDirecto;
      } else {
        tema = AppThemes.getById(args['temaId']?.toString());
      }
    }

    cargarActividades();
  }

  @override
  void dispose() {
    introController.dispose();
    floatController.dispose();
    modalController.dispose();
    buscadorController.dispose();
    super.dispose();
  }

  int toInt(dynamic value, int fallback) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.round();

    return int.tryParse(value.toString()) ?? fallback;
  }

  double? toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    return double.tryParse(value.toString());
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

  DateTime? obtenerFechaInicio(Map<String, dynamic> actividad) {
    return convertirFecha(
      actividad['fecha_inicio'] ??
          actividad['fechaInicio'] ??
          actividad['fecha_inicial'] ??
          actividad['inicio'],
    );
  }

  DateTime? obtenerFechaCierre(Map<String, dynamic> actividad) {
    final fechaDirecta = convertirFecha(
      actividad['fecha_fin'] ??
          actividad['fechaFin'] ??
          actividad['fecha_cierre'] ??
          actividad['fechaCierre'] ??
          actividad['cierre'] ??
          actividad['fin'],
    );

    if (fechaDirecta != null) {
      return fechaDirecta;
    }

    final inicio = obtenerFechaInicio(actividad);
    final duracion = toDouble(actividad['duracion_horas']);

    if (inicio == null || duracion == null || duracion <= 0) {
      return null;
    }

    return inicio.add(Duration(minutes: (duracion * 60).round()));
  }

  String formatearFechaHora(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString().padLeft(4, '0');
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String? formatearFechaApi(DateTime? fecha) {
    if (fecha == null) return null;

    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');
    final second = fecha.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
  }

  String normalizarEstatus(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  bool esTerminada(dynamic value) {
    final texto = normalizarEstatus(value);

    return texto == 'completada' ||
        texto == 'completado' ||
        texto == 'terminada' ||
        texto == 'terminado' ||
        texto == 'finalizada' ||
        texto == 'finalizado';
  }

  bool esNoCumplida(dynamic value) {
    final texto = normalizarEstatus(value);

    return texto == 'no_cumplida' ||
        texto == 'no cumplida' ||
        texto == 'no_cumplido' ||
        texto == 'no cumplido' ||
        texto == 'fallida';
  }

  String obtenerEstadoActividad(Map<String, dynamic> actividad) {
    final estatusRaw = actividad['estatus'];

    if (esTerminada(estatusRaw)) {
      return 'terminada';
    }

    if (esNoCumplida(estatusRaw)) {
      return 'no_cumplida';
    }

    final ahora = DateTime.now();
    final inicio = obtenerFechaInicio(actividad);
    final cierre = obtenerFechaCierre(actividad);

    if (inicio != null && inicio.isAfter(ahora)) {
      return 'abre_pronto';
    }

    if (cierre != null && cierre.isBefore(ahora)) {
      return 'vencida';
    }

    return 'en_proceso';
  }

  int ordenEstado(String estado) {
    if (estado == 'en_proceso') return 1;
    if (estado == 'abre_pronto') return 2;
    if (estado == 'vencida') return 3;
    if (estado == 'no_cumplida') return 4;
    if (estado == 'terminada') return 5;

    return 6;
  }

  DateTime? fechaParaOrdenar(Map<String, dynamic> actividad, String estado) {
    if (estado == 'en_proceso') {
      return obtenerFechaCierre(actividad);
    }

    if (estado == 'abre_pronto') {
      return obtenerFechaInicio(actividad);
    }

    if (estado == 'vencida') {
      return obtenerFechaCierre(actividad);
    }

    if (estado == 'no_cumplida') {
      return obtenerFechaCierre(actividad) ?? obtenerFechaInicio(actividad);
    }

    if (estado == 'terminada') {
      return obtenerFechaCierre(actividad) ?? obtenerFechaInicio(actividad);
    }

    return obtenerFechaInicio(actividad);
  }

  String etiquetaEstado(String estado) {
    if (estado == 'terminada') return 'Terminada';
    if (estado == 'en_proceso') return 'En proceso';
    if (estado == 'abre_pronto') return 'Abre pronto';
    if (estado == 'vencida') return 'Vencida';
    if (estado == 'no_cumplida') return 'No cumplida';

    return 'Todas';
  }

  Color colorEstado(String estado) {
    if (estado == 'terminada') return tema.exito;
    if (estado == 'en_proceso') return tema.primario;
    if (estado == 'abre_pronto') return tema.secundario;
    if (estado == 'vencida') return tema.peligro;
    if (estado == 'no_cumplida') return tema.peligro;

    return tema.primario;
  }

  IconData iconoEstado(String estado) {
    if (estado == 'terminada') return Icons.check_circle_outline;
    if (estado == 'en_proceso') return Icons.play_circle_outline;
    if (estado == 'abre_pronto') return Icons.schedule_outlined;
    if (estado == 'vencida') return Icons.warning_amber_outlined;
    if (estado == 'no_cumplida') return Icons.cancel_outlined;

    return Icons.list_alt_outlined;
  }

  int contarPorEstado(String estado) {
    if (estado == 'todas') {
      return actividades.length;
    }

    return actividades.where((actividad) {
      return obtenerEstadoActividad(actividad) == estado;
    }).length;
  }

  bool coincideBusqueda(Map<String, dynamic> actividad) {
    final texto = busquedaActividades.trim().toLowerCase();

    if (texto.isEmpty) return true;

    final inicio = formatearFechaHora(obtenerFechaInicio(actividad));
    final cierre = formatearFechaHora(obtenerFechaCierre(actividad));
    final estado = etiquetaEstado(obtenerEstadoActividad(actividad));

    final campos = [
      actividad['nombre'],
      actividad['descripcion'],
      actividad['prioridad'],
      actividad['estatus'],
      actividad['repetecion'],
      actividad['valor_exp'],
      actividad['duracion_horas'],
      inicio,
      cierre,
      estado,
    ].map((item) => item?.toString().toLowerCase() ?? '').join(' ');

    return campos.contains(texto);
  }

  List<Map<String, dynamic>> get actividadesFiltradas {
    final lista = actividades.where((actividad) {
      final estado = obtenerEstadoActividad(actividad);

      final coincideFiltro = filtroEstado == 'todas'
          ? true
          : estado == filtroEstado;

      return coincideFiltro && coincideBusqueda(actividad);
    }).toList();

    lista.sort((a, b) {
      final estadoA = obtenerEstadoActividad(a);
      final estadoB = obtenerEstadoActividad(b);

      if (filtroEstado == 'todas') {
        final ordenA = ordenEstado(estadoA);
        final ordenB = ordenEstado(estadoB);

        if (ordenA != ordenB) {
          return ordenA.compareTo(ordenB);
        }
      }

      final fechaA = fechaParaOrdenar(a, estadoA);
      final fechaB = fechaParaOrdenar(b, estadoB);

      final tiempoA = fechaA?.millisecondsSinceEpoch ?? 9999999999999;
      final tiempoB = fechaB?.millisecondsSinceEpoch ?? 9999999999999;

      final comparacionFecha = tiempoA.compareTo(tiempoB);

      if (comparacionFecha != 0) {
        return comparacionFecha;
      }

      final nombreA = a['nombre']?.toString().toLowerCase() ?? '';
      final nombreB = b['nombre']?.toString().toLowerCase() ?? '';

      return nombreA.compareTo(nombreB);
    });

    return lista;
  }

  Color mezclarConTema(Color color, double opacity, {Color? base}) {
    return Color.alphaBlend(color.withOpacity(opacity), base ?? tema.tarjeta);
  }

  Future<void> cargarActividades() async {
    try {
      setState(() {
        cargando = true;
      });

      final response = await ApiService.get('/actividades');

      List<dynamic> listaRaw = [];

      if (response is Map<String, dynamic> && response['actividades'] is List) {
        listaRaw = response['actividades'];
      }

      final lista = listaRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final filtradas = lista.where((actividad) {
        return actividad['tipo']?.toString().trim().toLowerCase() ==
            tipo.trim().toLowerCase();
      }).toList();

      if (!mounted) return;

      setState(() {
        actividades = filtradas;
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(error, 'No se pudieron cargar las actividades.'),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
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

  void abrirEditor(Map<String, dynamic> actividad) {
    setState(() {
      actividadEditando = actividad;
      mostrarEditor = true;

      nombre = actividad['nombre']?.toString() ?? '';
      descripcion = actividad['descripcion']?.toString() ?? '';
      prioridad = actividad['prioridad']?.toString() ?? 'media';

      duracionHoras = actividad['duracion_horas'] == null
          ? ''
          : '${actividad['duracion_horas']}';

      estatus = actividad['estatus']?.toString() ?? 'pendiente';

      fechaCierreEditando = obtenerFechaCierre(actividad);
      fechaCierreManualEditada = false;
    });

    modalController.forward(from: 0);
  }

  Future<void> cerrarEditor() async {
    if (guardando) return;

    await modalController.reverse();

    if (!mounted) return;

    setState(() {
      mostrarEditor = false;
      actividadEditando = null;
      fechaCierreEditando = null;
      fechaCierreManualEditada = false;
    });
  }

  Future<void> seleccionarFechaCierre() async {
    final base =
        fechaCierreEditando ??
        (actividadEditando == null
            ? null
            : obtenerFechaCierre(actividadEditando!)) ??
        DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      barrierDismissible: false,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: tema.primario,
              onPrimary: Colors.white,
              surface: tema.tarjeta,
              onSurface: tema.texto,
            ),
            dialogBackgroundColor: tema.tarjeta,
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      barrierDismissible: false,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: tema.primario,
              onPrimary: Colors.white,
              surface: tema.tarjeta,
              onSurface: tema.texto,
            ),
            dialogBackgroundColor: tema.tarjeta,
          ),
          child: child!,
        );
      },
    );

    if (hora == null) return;

    setState(() {
      fechaCierreEditando = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );

      fechaCierreManualEditada = true;
    });
  }

Future<void> guardarEdicion() async {
  if (actividadEditando?['id'] == null) {
    mostrarMensaje(
      titulo: 'Error',
      mensaje: 'No se encontró el id de la actividad.',
    );
    return;
  }

  if (nombre.trim().isEmpty) {
    mostrarMensaje(
      titulo: 'Falta nombre',
      mensaje: 'Escribe el nombre de la actividad.',
    );
    return;
  }

  final horas = double.tryParse(duracionHoras.trim());

  if (duracionHoras.trim().isNotEmpty && horas == null) {
    mostrarMensaje(
      titulo: 'Duración inválida',
      mensaje: 'La duración debe ser un número válido.',
    );
    return;
  }

  final inicio = obtenerFechaInicio(actividadEditando!);

  if (inicio != null &&
      fechaCierreEditando != null &&
      fechaCierreEditando!.isBefore(inicio)) {
    mostrarMensaje(
      titulo: 'Fecha inválida',
      mensaje: 'La fecha de cierre no puede quedar antes de la fecha de inicio.',
    );
    return;
  }

  final duracionFinal =
      duracionHoras.trim().isNotEmpty && horas != null ? horas : null;

  final actividadActualizada = {
    'nombre': nombre.trim(),
    'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
    'tipo': tipo,
    'prioridad': prioridad,
    'valor_exp': valorExpCalculado,
    'duracion_horas': duracionFinal,
    'repetecion': actividadEditando?['repetecion'],
    'estatus': estatus,
    'auxiliar': actividadEditando?['auxiliar'],
  };

  try {
    setState(() {
      guardando = true;
    });

    await ApiService.put(
      '/actividades/${actividadEditando!['id']}',
      actividadActualizada,
    );

    if (fechaCierreManualEditada && fechaCierreEditando != null) {
      await ApiService.put(
        '/actividades/${actividadEditando!['id']}/cierre',
        {
          'fecha_fin': formatearFechaApi(fechaCierreEditando),
        },
      );
    }

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    mostrarMensaje(
      titulo: 'Actividad actualizada',
      mensaje: 'La actividad se editó correctamente.',
    );

    await cerrarEditor();
    await cargarActividades();
  } catch (error) {
    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    mostrarMensaje(
      titulo: 'Error',
      mensaje: limpiarError(
        error,
        'No se pudo editar la actividad.',
      ),
    );
  }
}


  Future<void> eliminarActividad(Map<String, dynamic> actividad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tema.tarjeta,
          title: Text(
            'Eliminar actividad',
            style: TextStyle(color: tema.texto, fontWeight: FontWeight.w900),
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${actividad['nombre'] ?? 'esta actividad'}"?',
            style: TextStyle(
              color: tema.textoSuave,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: tema.textoSuave,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: tema.peligro),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await ApiService.delete('/actividades/${actividad['id']}');

      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Eliminada',
        mensaje: 'La actividad fue eliminada.',
      );

      await cargarActividades();
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(error, 'No se pudo eliminar la actividad.'),
      );
    }
  }

  Future<void> cambiarEstatusRapido(Map<String, dynamic> actividad) async {
    final nuevoEstatus = esTerminada(actividad['estatus'])
        ? 'pendiente'
        : 'completada';

    final actividadActualizada = {
      'nombre': actividad['nombre'],
      'descripcion': actividad['descripcion'],
      'tipo': actividad['tipo'],
      'prioridad': actividad['prioridad'] ?? 'media',
      'valor_exp': actividad['valor_exp'],
      'duracion_horas': actividad['duracion_horas'],
      'fecha_fin': formatearFechaApi(obtenerFechaCierre(actividad)),
      'repetecion': actividad['repetecion'],
      'estatus': nuevoEstatus,
      'auxiliar': actividad['auxiliar'],
    };

    try {
      await ApiService.put(
        '/actividades/${actividad['id']}',
        actividadActualizada,
      );

      await cargarActividades();
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(error, 'No se pudo cambiar el estatus.'),
      );
    }
  }

  void abrirDescripcion(Map<String, dynamic> actividad) {
    final descripcionTexto =
        actividad['descripcion']?.toString().trim().isNotEmpty == true
        ? actividad['descripcion'].toString()
        : 'Esta actividad no tiene descripción registrada.';

    final inicio = formatearFechaHora(obtenerFechaInicio(actividad));
    final cierre = formatearFechaHora(obtenerFechaCierre(actividad));
    final estado = obtenerEstadoActividad(actividad);
    final color = colorEstado(estado);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tema.tarjeta,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: tema.borde, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        iconoEstado(estado),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        actividad['nombre']?.toString() ?? 'Actividad',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tema.texto,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: mezclarConTema(
                            tema.primario,
                            0.10,
                            base: tema.tarjeta,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: tema.texto, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: mezclarConTema(
                      tema.primario,
                      0.06,
                      base: tema.tarjeta,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    descripcionTexto,
                    style: TextStyle(
                      color: tema.texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                buildDialogDateRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de inicio',
                  value: inicio,
                  color: tema.primario,
                ),
                buildDialogDateRow(
                  icon: Icons.flag_outlined,
                  label: 'Fecha de cierre',
                  value: cierre,
                  color: tema.peligro,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDialogDateRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 13,
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

  Color obtenerColorPrioridad(dynamic valor) {
    if (valor == 'baja') return tema.exito;
    if (valor == 'media') return tema.aviso;
    if (valor == 'alta') return tema.peligro;

    return tema.textoSuave;
  }

  Color obtenerColorCategoria() {
    if (categoria?['color'] is Color) {
      return categoria!['color'] as Color;
    }

    return tema.primario;
  }

  IconData obtenerIconoCategoria() {
    if (categoria?['icono'] is IconData) {
      return categoria!['icono'] as IconData;
    }

    return Icons.album_outlined;
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

  void mostrarMensaje({required String titulo, required String mensaje}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tema.tarjeta,
          title: Text(
            titulo,
            style: TextStyle(color: tema.texto, fontWeight: FontWeight.w900),
          ),
          content: Text(
            mensaje,
            style: TextStyle(
              color: tema.textoSuave,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Aceptar',
                style: TextStyle(
                  color: tema.primario,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
              child: buildContent(),
            ),
            if (mostrarEditor) buildEditorOverlay(size),
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
            icon: Icons.list,
          ),
          animatedBubble(
            top: size.height * 0.15,
            right: size.width * 0.1,
            color: tema.barraXp.withOpacity(0.2),
            icon: Icons.edit,
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
              border: Border.all(color: tema.borde.withOpacity(0.35)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        children: [
          buildHeader(),
          buildInfoCard(),
          buildSearchBox(),
          buildFiltrosEstado(),
          Expanded(child: buildActividadesArea()),
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
                border: Border.all(color: tema.borde, width: 2),
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
                Text(
                  tipo.isEmpty ? 'Actividades' : tipo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Busca, filtra y administra actividades',
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
            onTap: cargarActividades,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tema.tarjeta,
                shape: BoxShape.circle,
                border: Border.all(color: tema.borde, width: 1.5),
              ),
              child: Icon(Icons.refresh, color: tema.primario, size: 23),
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
        border: Border.all(color: tema.borde.withOpacity(0.75), width: 1.2),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: obtenerColorCategoria(),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: tema.borde, width: 3),
            ),
            child: Icon(obtenerIconoCategoria(), color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de actividades',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ordenado por proceso, cierre próximo, apertura y estado.',
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
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.borde.withOpacity(0.75), width: 1.2),
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
          Icon(Icons.search, color: tema.primario, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: buscadorController,
              onChanged: (value) {
                setState(() {
                  busquedaActividades = value;
                });
              },
              style: TextStyle(
                color: tema.texto,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar actividad...',
                hintStyle: TextStyle(
                  color: tema.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (busquedaActividades.trim().isNotEmpty)
            GestureDetector(
              onTap: () {
                buscadorController.clear();
                setState(() {
                  busquedaActividades = '';
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: mezclarConTema(
                    tema.primario,
                    0.10,
                    base: tema.tarjeta,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: tema.textoSuave, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildFiltrosEstado() {
    final filtros = [
      {
        'id': 'en_proceso',
        'label': 'En proceso',
        'icon': Icons.play_circle_outline,
      },
      {
        'id': 'abre_pronto',
        'label': 'Abre pronto',
        'icon': Icons.schedule_outlined,
      },
      {
        'id': 'vencida',
        'label': 'Vencidas',
        'icon': Icons.warning_amber_outlined,
      },
      {
        'id': 'no_cumplida',
        'label': 'No cumplidas',
        'icon': Icons.cancel_outlined,
      },
      {
        'id': 'terminada',
        'label': 'Terminadas',
        'icon': Icons.check_circle_outline,
      },
      {'id': 'todas', 'label': 'Todas', 'icon': Icons.list_alt_outlined},
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
          final activo = filtroEstado == id;
          final color = id == 'todas' ? tema.primario : colorEstado(id);
          final icon = filtro['icon'] as IconData;
          final count = contarPorEstado(id);

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroEstado = id;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo
                    ? tema.tarjeta
                    : mezclarConTema(tema.primario, 0.08, base: tema.fondo),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: activo ? tema.borde : tema.borde.withOpacity(0.45),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 17, color: activo ? color : tema.textoSuave),
                  const SizedBox(width: 5),
                  Text(
                    filtro['label'].toString(),
                    style: TextStyle(
                      color: activo ? tema.texto : tema.textoSuave,
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
                          ? color.withOpacity(0.12)
                          : tema.tarjeta.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: activo ? color : tema.textoSuave,
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

  Widget buildActividadesArea() {
    if (cargando) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tema.primario),
            const SizedBox(height: 10),
            Text(
              'Cargando actividades...',
              style: TextStyle(
                color: tema.texto,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (actividades.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tema.tarjeta.withOpacity(0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tema.borde.withOpacity(0.75)),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 44, color: tema.primario),
                const SizedBox(height: 12),
                Text(
                  'Sin actividades',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Todavía no hay actividades guardadas en esta clasificación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tema.textoSuave,
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

    final lista = actividadesFiltradas;

    if (lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: tema.tarjeta.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tema.borde.withOpacity(0.75)),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 42, color: tema.primario),
                const SizedBox(height: 10),
                Text(
                  'Sin resultados',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'No encontré actividades con los filtros actuales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tema.textoSuave,
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
        final actividad = lista[index];
        final estado = obtenerEstadoActividad(actividad);

        return ActivityCard(
          actividad: actividad,
          index: index,
          tema: tema,
          estado: estado,
          estadoLabel: etiquetaEstado(estado),
          estadoColor: colorEstado(estado),
          estadoIcon: iconoEstado(estado),
          fechaInicioTexto: formatearFechaHora(obtenerFechaInicio(actividad)),
          fechaCierreTexto: formatearFechaHora(obtenerFechaCierre(actividad)),
          obtenerColorPrioridad: obtenerColorPrioridad,
          onEdit: () => abrirEditor(actividad),
          onDelete: () => eliminarActividad(actividad),
          onToggleStatus: () => cambiarEstatusRapido(actividad),
          onDescription: () => abrirDescripcion(actividad),
        );
      },
    );
  }

  Widget buildEditorOverlay(Size size) {
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
                  child: buildEditorCard(size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildEditorCard(Size size) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 520, maxHeight: size.height * 0.88),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: tema.borde, width: 2),
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
          buildEditorHeader(),
          Flexible(child: SingleChildScrollView(child: buildEditorBody())),
        ],
      ),
    );
  }

  Widget buildEditorHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: tema.primario,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tema.borde, width: 3),
            ),
            child: const Icon(
              Icons.edit_outlined,
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
                  'Editar actividad',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tipo,
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
            onTap: cerrarEditor,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tema.peligro,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditorBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('Nombre'),
        buildTextInput(
          value: nombre,
          icon: Icons.edit_outlined,
          hint: 'Nombre de la actividad',
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
          hint: 'Descripción',
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
        buildLabel('Fecha de cierre'),
        buildFechaCierreEditor(),
        buildLabel('Estatus'),
        buildStatusRow(),
        buildLabel('Experiencia recalculada'),
        buildExpAutoBox(),
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
        style: TextStyle(
          color: tema.texto,
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
      constraints: BoxConstraints(minHeight: multiline ? 88 : 54),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: mezclarConTema(tema.primario, 0.05, base: tema.tarjeta),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tema.borde, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: multiline ? 14 : 0),
            child: Icon(icon, color: tema.primario, size: 20),
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
              style: TextStyle(
                color: tema.texto,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: tema.textoSuave),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFechaCierreEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mezclarConTema(tema.peligro, 0.05, base: tema.tarjeta),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.borde, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tema.peligro.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.flag_outlined, color: tema.peligro, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatearFechaHora(fechaCierreEditando),
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Solo cambia el cierre, no modifica la duración.',
                  style: TextStyle(
                    color: tema.textoSuave,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: guardando ? null : seleccionarFechaCierre,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: tema.primario,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Cambiar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
      children: prioridadesActivitis.map((item) {
        final activo = prioridad == item['nombre'];
        final color = obtenerColorPrioridad(item['nombre']);

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
                  color: activo ? color : tema.tarjeta,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activo ? color : tema.borde,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item['etiqueta'].toString(),
                  style: TextStyle(
                    color: activo ? Colors.white : tema.textoSuave,
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

  Widget buildStatusRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildStatusOption(
          value: 'pendiente',
          label: 'Pendiente',
          color: tema.aviso,
        ),
        buildStatusOption(
          value: 'completada',
          label: 'Completada',
          color: tema.exito,
        ),
        buildStatusOption(
          value: 'no_cumplida',
          label: 'No cumplida',
          color: tema.peligro,
        ),
      ],
    );
  }

  Widget buildStatusOption({
    required String value,
    required String label,
    required Color color,
  }) {
    final activo = estatus == value;

    return GestureDetector(
      onTap: guardando
          ? null
          : () {
              setState(() {
                estatus = value;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: activo ? color.withOpacity(0.16) : tema.tarjeta,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: activo ? color : tema.borde, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? color : tema.textoSuave,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
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
        border: Border.all(color: tema.borde.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tema.barraXp,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tema.borde, width: 3),
            ),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valorExpCalculado XP',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Se recalcula por prioridad y duración',
                  style: TextStyle(
                    color: tema.textoSuave,
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

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: guardando ? null : guardarEdicion,
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
          guardando ? 'Guardando...' : 'Guardar cambios',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: tema.primario,
          disabledBackgroundColor: tema.textoSuave,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatefulWidget {
  final Map<String, dynamic> actividad;
  final int index;
  final ActivityTheme tema;
  final String estado;
  final String estadoLabel;
  final Color estadoColor;
  final IconData estadoIcon;
  final String fechaInicioTexto;
  final String fechaCierreTexto;
  final Color Function(dynamic) obtenerColorPrioridad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onDescription;

  const ActivityCard({
    super.key,
    required this.actividad,
    required this.index,
    required this.tema,
    required this.estado,
    required this.estadoLabel,
    required this.estadoColor,
    required this.estadoIcon,
    required this.fechaInicioTexto,
    required this.fechaCierreTexto,
    required this.obtenerColorPrioridad,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onDescription,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard>
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
      lowerBound: 0.98,
      upperBound: 1,
      value: 1,
    );

    fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: introController, curve: Curves.easeOut));

    slideAnimation = Tween<double>(begin: 35, end: 0).animate(
      CurvedAnimation(parent: introController, curve: Curves.easeOutBack),
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

  Color mezclarConTarjeta(Color color, double opacity) {
    return Color.alphaBlend(color.withOpacity(opacity), widget.tema.tarjeta);
  }

  @override
  Widget build(BuildContext context) {
    final actividad = widget.actividad;
    final tema = widget.tema;

    final prioridadColor = widget.obtenerColorPrioridad(actividad['prioridad']);

    final bool completada = widget.estado == 'terminada';

    Color background = tema.tarjeta;
    Color border = tema.borde;

    if (widget.estado == 'terminada') {
      background = mezclarConTarjeta(tema.exito, 0.08);
      border = tema.exito.withOpacity(0.30);
    } else if (widget.estado == 'vencida' || widget.estado == 'no_cumplida') {
      background = mezclarConTarjeta(tema.peligro, 0.08);
      border = tema.peligro.withOpacity(0.30);
    } else if (widget.estado == 'abre_pronto') {
      background = mezclarConTarjeta(tema.secundario, 0.08);
      border = tema.secundario.withOpacity(0.30);
    } else if (widget.estado == 'en_proceso') {
      background = mezclarConTarjeta(tema.primario, 0.08);
      border = tema.primario.withOpacity(0.30);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([introController, pressController]),
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Transform.scale(scale: scaleAnimation.value, child: child),
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
            border: Border.all(color: border, width: 1.4),
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
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.estadoColor,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: tema.borde, width: 3),
                    ),
                    child: Icon(
                      widget.estadoIcon,
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
                          actividad['nombre']?.toString() ?? 'Sin nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tema.texto,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            buildStatusBadge(),
                            buildMetaBadge(
                              icon: Icons.priority_high,
                              text:
                                  actividad['prioridad']?.toString() ??
                                  'sin prioridad',
                              color: prioridadColor,
                              bg: prioridadColor.withOpacity(0.12),
                            ),
                            buildMetaBadge(
                              icon: Icons.flash_on,
                              text: '${actividad['valor_exp'] ?? 0} XP',
                              color: tema.barraXp,
                              bg: tema.barraXp.withOpacity(0.12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildDateBadge(
                    icon: Icons.calendar_today_outlined,
                    label: 'Inicio',
                    text: widget.fechaInicioTexto,
                    color: tema.primario,
                  ),
                  buildDateBadge(
                    icon: Icons.flag_outlined,
                    label: 'Cierre',
                    text: widget.fechaCierreTexto,
                    color: tema.peligro,
                  ),
                  buildMetaBadge(
                    icon: Icons.access_time,
                    text: actividad['duracion_horas'] != null
                        ? '${actividad['duracion_horas']} h'
                        : 'sin horas',
                    color: tema.texto,
                    bg: tema.tarjeta.withOpacity(0.62),
                  ),
                  buildMetaBadge(
                    icon: Icons.repeat,
                    text: actividad['repetecion']?.toString() ?? 'Una vez',
                    color: tema.primario,
                    bg: tema.primario.withOpacity(0.10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: buildActionButton(
                      text: 'Descripción',
                      icon: Icons.description_outlined,
                      bg: tema.texto,
                      onTap: widget.onDescription,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildActionButton(
                      text: completada ? 'Pendiente' : 'Completar',
                      icon: completada
                          ? Icons.keyboard_return
                          : Icons.check_circle_outline,
                      bg: completada ? tema.aviso : tema.exito,
                      onTap: widget.onToggleStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: buildActionButton(
                      text: 'Editar',
                      icon: Icons.edit_outlined,
                      bg: tema.primario,
                      onTap: widget.onEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 54,
                    child: buildActionButton(
                      text: '',
                      icon: Icons.delete_outline,
                      bg: tema.peligro,
                      onTap: widget.onDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: widget.estadoColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.estadoColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.estadoIcon, size: 14, color: widget.estadoColor),
          const SizedBox(width: 4),
          Text(
            widget.estadoLabel,
            style: TextStyle(
              color: widget.estadoColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateBadge({
    required IconData icon,
    required String label,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            '$label $text',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMetaBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.tema.borde.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required String text,
    required IconData icon,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
