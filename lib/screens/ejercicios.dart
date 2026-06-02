import 'package:flutter/material.dart';
import '../config/app_themes.dart';
import '../services/api_service.dart';

const List<String> diasOrdenEjercicio = [
  'L',
  'M',
  'MI',
  'J',
  'V',
  'S',
  'D',
];

const List<String> gruposMuscularesEjercicio = [
  'Full body',
  'Pecho',
  'Espalda',
  'Pierna',
  'Hombro',
  'Brazo',
  'Abdomen',
  'Cardio',
  'Movilidad',
];

class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;

  final TextEditingController ejercicioNombreController =
      TextEditingController();
  final TextEditingController ejercicioDescripcionController =
      TextEditingController();
  final TextEditingController ejercicioGrupoController =
      TextEditingController(text: 'Full body');
  final TextEditingController ejercicioTipoController =
      TextEditingController(text: 'Fuerza');
  final TextEditingController ejercicioDuracionController =
      TextEditingController(text: '8');
  final TextEditingController ejercicioExpController =
      TextEditingController(text: '10');

  final TextEditingController rutinaNombreController =
      TextEditingController();
  final TextEditingController rutinaDescripcionController =
      TextEditingController();
  final TextEditingController rutinaDuracionController =
      TextEditingController(text: '45');

  List<Map<String, dynamic>> ejercicios = [];
  List<Map<String, dynamic>> rutinas = [];
  List<Map<String, dynamic>> ejerciciosSeleccionados = [];

  Set<String> diasSeleccionados = {
    'L',
    'M',
    'MI',
    'J',
    'V',
  };

  TimeOfDay horaInicio = const TimeOfDay(hour: 7, minute: 0);
  bool rutinaActiva = true;
  bool argsCargados = false;

  bool cargandoEjercicios = false;
  bool cargandoRutinas = false;
  bool guardandoEjercicio = false;
  bool guardandoRutina = false;
  int? idRutinaAccionando;
  int? idEjercicioAccionando;

  bool mostrarPanelEjercicio = false;
  bool mostrarPanelRutina = false;

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
      duration: const Duration(milliseconds: 720),
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
      begin: 32,
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
    cargarTodo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argsCargados) return;
    argsCargados = true;

    final argsRaw = ModalRoute.of(context)?.settings.arguments;

    if (argsRaw is Map) {
      final args = Map<String, dynamic>.from(argsRaw);
      final temaDirecto = args['tema'];

      if (temaDirecto is ActivityTheme) {
        tema = temaDirecto;
      } else {
        tema = AppThemes.getById(args['temaId']?.toString());
      }
    }
  }

  @override
  void dispose() {
    introController.dispose();
    floatController.dispose();

    ejercicioNombreController.dispose();
    ejercicioDescripcionController.dispose();
    ejercicioGrupoController.dispose();
    ejercicioTipoController.dispose();
    ejercicioDuracionController.dispose();
    ejercicioExpController.dispose();

    rutinaNombreController.dispose();
    rutinaDescripcionController.dispose();
    rutinaDuracionController.dispose();

    super.dispose();
  }

  Future<void> cargarTodo() async {
    await cargarEjercicios();
    await cargarRutinas();
  }

  int toInt(dynamic value, int fallback) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.round();

    return int.tryParse(value.toString()) ?? fallback;
  }

  bool boolDesdeValor(dynamic value, bool fallback) {
    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is int) return value == 1;

    if (value is double) return value.round() == 1;

    final texto = value.toString().trim().toLowerCase();

    if (texto == '1' ||
        texto == 'true' ||
        texto == 'si' ||
        texto == 'sí' ||
        texto == 'activo' ||
        texto == 'activa') {
      return true;
    }

    if (texto == '0' ||
        texto == 'false' ||
        texto == 'no' ||
        texto == 'inactivo' ||
        texto == 'inactiva' ||
        texto == 'pausado' ||
        texto == 'pausada') {
      return false;
    }

    return fallback;
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

  String horaTexto(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  List<String> ordenarDiasSeleccionados(Set<String> dias) {
    return diasOrdenEjercicio.where((dia) => dias.contains(dia)).toList();
  }

  Set<String> obtenerDiasComoSet(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim().toUpperCase())
          .where((dia) => diasOrdenEjercicio.contains(dia))
          .toSet();
    }

    if (value is String) {
      return value
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((item) => item.trim().toUpperCase())
          .where((dia) => diasOrdenEjercicio.contains(dia))
          .toSet();
    }

    return {};
  }

  String etiquetaDias(Set<String> dias) {
    if (dias.length == 7) {
      return 'Todos los días';
    }

    if (dias.length == 5 &&
        dias.contains('L') &&
        dias.contains('M') &&
        dias.contains('MI') &&
        dias.contains('J') &&
        dias.contains('V')) {
      return 'Lunes a viernes';
    }

    if (dias.length == 2 && dias.contains('S') && dias.contains('D')) {
      return 'Sábado y domingo';
    }

    return diasOrdenEjercicio.where((dia) => dias.contains(dia)).join(', ');
  }

  Color mezclarConTema(
    Color color,
    double opacity, {
    Color? base,
  }) {
    return Color.alphaBlend(
      color.withOpacity(opacity),
      base ?? tema.tarjeta,
    );
  }

  Color colorPorGrupo(String? grupo) {
    final texto = (grupo ?? '').toLowerCase();

    if (texto.contains('pecho')) return const Color(0xFFEC4899);
    if (texto.contains('espalda')) return const Color(0xFF7C3AED);
    if (texto.contains('pierna')) return const Color(0xFF16A34A);
    if (texto.contains('cardio')) return const Color(0xFFEF4444);
    if (texto.contains('abdomen')) return const Color(0xFFF59E0B);
    if (texto.contains('movilidad')) return const Color(0xFF14B8A6);

    return const Color(0xFF0EA5E9);
  }

  Map<String, dynamic> normalizarEjercicio(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'nombre': item['nombre'] ?? item['name'] ?? 'Ejercicio',
      'descripcion': item['descripcion'] ?? item['description'],
      'grupo_muscular': item['grupo_muscular'] ?? item['grupoMuscular'],
      'tipo': item['tipo'] ?? item['type'],
      'duracion_minutos': toInt(item['duracion_minutos'], 5),
      'valor_exp': toInt(item['valor_exp'], 10),
      'activo': boolDesdeValor(item['activo'], true),
      'es_global': boolDesdeValor(item['es_global'], false),
    };
  }

  Map<String, dynamic> normalizarRutina(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'nombre': item['nombre'] ?? item['name'] ?? 'Rutina',
      'descripcion': item['descripcion'] ?? item['description'],
      'dias': item['dias'] ?? [],
      'hora_inicio': item['hora_inicio'] ?? item['horaInicio'] ?? '07:00',
      'duracion_minutos': toInt(item['duracion_minutos'], 45),
      'valor_exp_total': toInt(item['valor_exp_total'], 0),
      'activa': boolDesdeValor(item['activa'], true),
      'completada_hoy': boolDesdeValor(item['completada_hoy'], false),
      'ejercicios': item['ejercicios'] is List ? item['ejercicios'] : [],
    };
  }

  Future<void> cargarEjercicios() async {
    try {
      if (!mounted) return;

      setState(() {
        cargandoEjercicios = true;
      });

      final response = await ApiService.get('/actividades/ejercicios');

      List<dynamic> raw = [];

      if (response is Map<String, dynamic>) {
        raw = response['ejercicios'] is List ? response['ejercicios'] : [];
      }

      final lista = raw
          .whereType<Map>()
          .map((item) => normalizarEjercicio(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;

      setState(() {
        ejercicios = lista;
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudieron cargar los ejercicios.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargandoEjercicios = false;
      });
    }
  }

  Future<void> cargarRutinas() async {
    try {
      if (!mounted) return;

      setState(() {
        cargandoRutinas = true;
      });

      final response = await ApiService.get('/actividades/ejercicios/rutinas');

      List<dynamic> raw = [];

      if (response is Map<String, dynamic>) {
        raw = response['rutinas'] is List ? response['rutinas'] : [];
      }

      final lista = raw
          .whereType<Map>()
          .map((item) => normalizarRutina(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;

      setState(() {
        rutinas = lista;
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudieron cargar las rutinas.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargandoRutinas = false;
      });
    }
  }

  Future<void> seleccionarHora() async {
    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: horaInicio,
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

    if (nuevaHora == null) return;

    setState(() {
      horaInicio = nuevaHora;
    });
  }

  void alternarDia(String dia) {
    setState(() {
      if (diasSeleccionados.contains(dia)) {
        diasSeleccionados.remove(dia);
      } else {
        diasSeleccionados.add(dia);
      }
    });
  }

  void seleccionarLunesAViernes() {
    setState(() {
      diasSeleccionados = {'L', 'M', 'MI', 'J', 'V'};
    });
  }

  void seleccionarTodosLosDias() {
    setState(() {
      diasSeleccionados = {'L', 'M', 'MI', 'J', 'V', 'S', 'D'};
    });
  }

  void seleccionarFinSemana() {
    setState(() {
      diasSeleccionados = {'S', 'D'};
    });
  }

  void limpiarFormularioEjercicio() {
    ejercicioNombreController.clear();
    ejercicioDescripcionController.clear();
    ejercicioGrupoController.text = 'Full body';
    ejercicioTipoController.text = 'Fuerza';
    ejercicioDuracionController.text = '8';
    ejercicioExpController.text = '10';
  }

  void limpiarFormularioRutina() {
    rutinaNombreController.clear();
    rutinaDescripcionController.clear();
    rutinaDuracionController.text = '45';
    ejerciciosSeleccionados = [];

    setState(() {
      diasSeleccionados = {'L', 'M', 'MI', 'J', 'V'};
      horaInicio = const TimeOfDay(hour: 7, minute: 0);
      rutinaActiva = true;
    });
  }

  Future<void> guardarEjercicio() async {
    final nombre = ejercicioNombreController.text.trim();
    final descripcion = ejercicioDescripcionController.text.trim();
    final grupo = ejercicioGrupoController.text.trim();
    final tipo = ejercicioTipoController.text.trim();
    final duracion = toInt(ejercicioDuracionController.text, 5);
    final exp = toInt(ejercicioExpController.text, 10);

    if (nombre.isEmpty) {
      mostrarMensaje(
        titulo: 'Falta nombre',
        mensaje: 'Escribe el nombre del ejercicio.',
      );
      return;
    }

    if (duracion <= 0) {
      mostrarMensaje(
        titulo: 'Duración inválida',
        mensaje: 'La duración debe ser mayor a 0 minutos.',
      );
      return;
    }

    if (exp <= 0) {
      mostrarMensaje(
        titulo: 'XP inválida',
        mensaje: 'La experiencia debe ser mayor a 0.',
      );
      return;
    }

    try {
      setState(() {
        guardandoEjercicio = true;
      });

      final response = await ApiService.post(
        '/actividades/ejercicios',
        {
          'nombre': nombre,
          'descripcion': descripcion.isEmpty ? null : descripcion,
          'grupo_muscular': grupo.isEmpty ? null : grupo,
          'tipo': tipo.isEmpty ? null : tipo,
          'duracion_minutos': duracion,
          'valor_exp': exp,
          'activo': true,
        },
      );

      Map<String, dynamic>? ejercicioCreado;

      if (response is Map<String, dynamic> && response['ejercicio'] is Map) {
        ejercicioCreado = normalizarEjercicio(
          Map<String, dynamic>.from(response['ejercicio']),
        );
      }

      if (!mounted) return;

      setState(() {
        if (ejercicioCreado != null) {
          ejercicios.insert(0, ejercicioCreado);
        }

        mostrarPanelEjercicio = false;
      });

      limpiarFormularioEjercicio();
      await cargarEjercicios();

      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Ejercicio agregado',
        mensaje: 'El ejercicio se guardó correctamente.',
      );
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo guardar el ejercicio.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        guardandoEjercicio = false;
      });
    }
  }

  void agregarEjercicioARutina(Map<String, dynamic> ejercicio) {
    final id = ejercicio['id'];

    if (id == null) return;

    final yaExiste = ejerciciosSeleccionados.any(
      (item) => item['ejercicio_id'].toString() == id.toString(),
    );

    if (yaExiste) {
      mostrarMensaje(
        titulo: 'Ya agregado',
        mensaje: 'Ese ejercicio ya está en la rutina.',
      );
      return;
    }

    setState(() {
      ejerciciosSeleccionados.add({
        'ejercicio_id': id,
        'nombre': ejercicio['nombre'],
        'series': 3,
        'repeticiones': '12',
        'duracion_minutos': toInt(ejercicio['duracion_minutos'], 5),
        'descanso_segundos': 60,
        'valor_exp': toInt(ejercicio['valor_exp'], 10),
      });
    });
  }

  void quitarEjercicioDeRutina(Map<String, dynamic> ejercicio) {
    final id = ejercicio['ejercicio_id'];

    setState(() {
      ejerciciosSeleccionados.removeWhere(
        (item) => item['ejercicio_id'].toString() == id.toString(),
      );
    });
  }

  void actualizarDetalleRutina(
    Map<String, dynamic> ejercicio,
    String campo,
    dynamic valor,
  ) {
    final id = ejercicio['ejercicio_id'];

    setState(() {
      final index = ejerciciosSeleccionados.indexWhere(
        (item) => item['ejercicio_id'].toString() == id.toString(),
      );

      if (index == -1) return;

      ejerciciosSeleccionados[index] = {
        ...ejerciciosSeleccionados[index],
        campo: valor,
      };
    });
  }

  int get duracionCalculadaRutina {
    int total = 0;

    for (final item in ejerciciosSeleccionados) {
      total += toInt(item['duracion_minutos'], 0);
    }

    return total;
  }

  int get expCalculadaRutina {
    int total = 0;

    for (final item in ejerciciosSeleccionados) {
      total += toInt(item['valor_exp'], 0);
    }

    return total;
  }

  Future<void> guardarRutina() async {
    final nombre = rutinaNombreController.text.trim();
    final descripcion = rutinaDescripcionController.text.trim();
    final duracion = toInt(rutinaDuracionController.text, 45);

    if (nombre.isEmpty) {
      mostrarMensaje(
        titulo: 'Falta nombre',
        mensaje: 'Escribe el nombre de la rutina.',
      );
      return;
    }

    if (diasSeleccionados.isEmpty) {
      mostrarMensaje(
        titulo: 'Faltan días',
        mensaje: 'Selecciona al menos un día para la rutina.',
      );
      return;
    }

    if (ejerciciosSeleccionados.isEmpty) {
      mostrarMensaje(
        titulo: 'Sin ejercicios',
        mensaje: 'Agrega al menos un ejercicio a la rutina.',
      );
      return;
    }

    if (duracion < 40 || duracion > 60) {
      mostrarMensaje(
        titulo: 'Duración inválida',
        mensaje: 'La rutina debe durar entre 40 y 60 minutos.',
      );
      return;
    }

    try {
      setState(() {
        guardandoRutina = true;
      });

      final detalles = ejerciciosSeleccionados.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return {
          'ejercicio_id': item['ejercicio_id'],
          'orden': index + 1,
          'series': toInt(item['series'], 3),
          'repeticiones': item['repeticiones']?.toString() ?? '12',
          'duracion_minutos': toInt(item['duracion_minutos'], 5),
          'descanso_segundos': toInt(item['descanso_segundos'], 60),
          'valor_exp': toInt(item['valor_exp'], 10),
        };
      }).toList();

      final response = await ApiService.post(
        '/actividades/ejercicios/rutinas',
        {
          'nombre': nombre,
          'descripcion': descripcion.isEmpty ? null : descripcion,
          'dias': ordenarDiasSeleccionados(diasSeleccionados),
          'hora_inicio': horaTexto(horaInicio),
          'duracion_minutos': duracion,
          'activa': rutinaActiva,
          'ejercicios': detalles,
        },
      );

      Map<String, dynamic>? rutinaCreada;

      if (response is Map<String, dynamic> && response['rutina'] is Map) {
        rutinaCreada = normalizarRutina(
          Map<String, dynamic>.from(response['rutina']),
        );
      }

      if (!mounted) return;

      setState(() {
        if (rutinaCreada != null) {
          rutinas.insert(0, rutinaCreada);
        }

        mostrarPanelRutina = false;
      });

      limpiarFormularioRutina();
      await cargarRutinas();

      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Rutina agregada',
        mensaje: 'Tu rutina de ejercicio se guardó correctamente.',
      );
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo guardar la rutina.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        guardandoRutina = false;
      });
    }
  }

  Future<void> alternarRutinaActiva(Map<String, dynamic> rutina) async {
    final id = rutina['id'];

    if (id == null) return;

    final activaActual = rutina['activa'] == true;
    final activaNueva = !activaActual;

    try {
      setState(() {
        idRutinaAccionando = toInt(id, 0);
      });

      final response = await ApiService.put(
        '/actividades/ejercicios/rutinas/$id/estado',
        {
          'activa': activaNueva,
        },
      );

      Map<String, dynamic>? rutinaActualizada;

      if (response is Map<String, dynamic> && response['rutina'] is Map) {
        rutinaActualizada = normalizarRutina(
          Map<String, dynamic>.from(response['rutina']),
        );
      }

      if (!mounted) return;

      setState(() {
        final index = rutinas.indexWhere(
          (item) => item['id'].toString() == id.toString(),
        );

        if (index == -1) return;

        rutinas[index] = rutinaActualizada ??
            {
              ...rutinas[index],
              'activa': activaNueva,
            };
      });
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo cambiar el estado de la rutina.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        idRutinaAccionando = null;
      });
    }
  }

  Future<void> eliminarRutina(Map<String, dynamic> rutina) async {
    final id = rutina['id'];

    if (id == null) return;

    try {
      setState(() {
        idRutinaAccionando = toInt(id, 0);
      });

      await ApiService.delete('/actividades/ejercicios/rutinas/$id');

      if (!mounted) return;

      setState(() {
        rutinas.removeWhere((item) => item['id'].toString() == id.toString());
      });

      mostrarMensaje(
        titulo: 'Rutina eliminada',
        mensaje: 'La rutina se eliminó correctamente.',
      );
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo eliminar la rutina.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        idRutinaAccionando = null;
      });
    }
  }

  Future<void> eliminarEjercicio(Map<String, dynamic> ejercicio) async {
    final id = ejercicio['id'];

    if (id == null) return;

    try {
      setState(() {
        idEjercicioAccionando = toInt(id, 0);
      });

      await ApiService.delete('/actividades/ejercicios/$id');

      if (!mounted) return;

      setState(() {
        ejercicios.removeWhere((item) => item['id'].toString() == id.toString());
        ejerciciosSeleccionados.removeWhere(
          (item) => item['ejercicio_id'].toString() == id.toString(),
        );
      });

      mostrarMensaje(
        titulo: 'Ejercicio eliminado',
        mensaje: 'El ejercicio se eliminó correctamente.',
      );
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        titulo: 'Error',
        mensaje: limpiarError(
          error,
          'No se pudo eliminar el ejercicio.',
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        idEjercicioAccionando = null;
      });
    }
  }

  Future<void> confirmarEliminarRutina(Map<String, dynamic> rutina) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tema.tarjeta,
          title: Text(
            'Eliminar rutina',
            style: TextStyle(
              color: tema.texto,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${rutina['nombre'] ?? 'esta rutina'}"?',
            style: TextStyle(
              color: tema.textoSuave,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
                eliminarRutina(rutina);
              },
              style: FilledButton.styleFrom(
                backgroundColor: tema.peligro,
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarEliminarEjercicio(Map<String, dynamic> ejercicio) async {
    final esGlobal = ejercicio['es_global'] == true;

    if (esGlobal) {
      mostrarMensaje(
        titulo: 'Ejercicio global',
        mensaje: 'Este ejercicio es global y no se puede eliminar desde tu cuenta.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tema.tarjeta,
          title: Text(
            'Eliminar ejercicio',
            style: TextStyle(
              color: tema.texto,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${ejercicio['nombre'] ?? 'este ejercicio'}"?',
            style: TextStyle(
              color: tema.textoSuave,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
                eliminarEjercicio(ejercicio);
              },
              style: FilledButton.styleFrom(
                backgroundColor: tema.peligro,
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void mostrarMensaje({
    required String titulo,
    required String mensaje,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: tema.tarjeta,
          title: Text(
            titulo,
            style: TextStyle(
              color: tema.texto,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            mensaje,
            style: TextStyle(
              color: tema.textoSuave,
              fontWeight: FontWeight.w700,
              height: 1.35,
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
                color: const Color(0xFF0EA5E9).withOpacity(0.24),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -75,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: tema.secundario.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.11 + floatAnimation.value,
                left: 26,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: tema.barraXp.withOpacity(0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tema.borde.withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh: cargarTodo,
      color: const Color(0xFF0EA5E9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          buildHeader(),
          const SizedBox(height: 14),
          buildIntroCard(),
          const SizedBox(height: 14),
          buildActionsCard(),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: mostrarPanelEjercicio
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: buildExerciseFormCard(),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: mostrarPanelRutina
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: buildRoutineFormCard(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          buildRutinasList(),
          const SizedBox(height: 14),
          buildEjerciciosList(),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
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
              Text(
                'Ejercicio',
                style: TextStyle(
                  color: tema.texto,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Ejercicios, rutinas y XP por entrenar',
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
          onTap: cargarTodo,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tema.tarjeta,
              shape: BoxShape.circle,
              border: Border.all(
                color: tema.borde,
                width: 1.4,
              ),
            ),
            child: (cargandoEjercicios || cargandoRutinas)
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: const Color(0xFF0EA5E9),
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    color: Color(0xFF0EA5E9),
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.sports_gymnastics_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Crea ejercicios, arma rutinas de 40 a 60 minutos y márcalas como cumplidas desde el dashboard cuando toque entrenar.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tema.borde,
          width: 1.4,
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              'Administra tu catálogo y tus rutinas.',
              style: TextStyle(
                color: tema.textoSuave,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          buildActionPill(
            text: mostrarPanelEjercicio ? 'Cerrar ejercicio' : 'Agregar ejercicio',
            icon: mostrarPanelEjercicio ? Icons.close : Icons.add,
            color: mostrarPanelEjercicio ? tema.peligro : const Color(0xFF0EA5E9),
            onTap: guardandoEjercicio
                ? null
                : () {
                    setState(() {
                      mostrarPanelEjercicio = !mostrarPanelEjercicio;

                      if (mostrarPanelEjercicio) {
                        mostrarPanelRutina = false;
                      }
                    });
                  },
          ),
          buildActionPill(
            text: mostrarPanelRutina ? 'Cerrar rutina' : 'Crear rutina',
            icon: mostrarPanelRutina ? Icons.close : Icons.add_task_outlined,
            color: mostrarPanelRutina ? tema.peligro : tema.primario,
            onTap: guardandoRutina
                ? null
                : () {
                    setState(() {
                      mostrarPanelRutina = !mostrarPanelRutina;

                      if (mostrarPanelRutina) {
                        mostrarPanelEjercicio = false;
                      }
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget buildActionPill({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildExerciseFormCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.add_circle_outline,
            title: 'Nuevo ejercicio',
            subtitle: 'Crea un ejercicio para usarlo en rutinas.',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 14),
          buildLabel('Nombre'),
          buildTextInput(
            controller: ejercicioNombreController,
            icon: Icons.fitness_center_outlined,
            hint: 'Ej. Sentadilla',
          ),
          buildLabel('Descripción'),
          buildTextInput(
            controller: ejercicioDescripcionController,
            icon: Icons.description_outlined,
            hint: 'Detalles opcionales',
            multiline: true,
          ),
          buildLabel('Grupo muscular'),
          buildGrupoSelector(),
          buildTextInput(
            controller: ejercicioGrupoController,
            icon: Icons.category_outlined,
            hint: 'Ej. Pierna',
          ),
          buildLabel('Tipo'),
          buildTextInput(
            controller: ejercicioTipoController,
            icon: Icons.bolt_outlined,
            hint: 'Ej. Fuerza, cardio, movilidad',
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel('Duración min'),
                    buildTextInput(
                      controller: ejercicioDuracionController,
                      icon: Icons.timer_outlined,
                      hint: '8',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel('XP'),
                    buildTextInput(
                      controller: ejercicioExpController,
                      icon: Icons.flash_on,
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: guardandoEjercicio ? null : guardarEjercicio,
              icon: guardandoEjercicio
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                guardandoEjercicio ? 'Guardando...' : 'Guardar ejercicio',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                disabledBackgroundColor: tema.textoSuave,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRoutineFormCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.assignment_add,
            title: 'Nueva rutina',
            subtitle: 'Rutinas de 40 a 60 minutos.',
            color: tema.primario,
          ),
          const SizedBox(height: 14),
          buildLabel('Nombre'),
          buildTextInput(
            controller: rutinaNombreController,
            icon: Icons.edit_outlined,
            hint: 'Ej. Full body lunes a viernes',
          ),
          buildLabel('Descripción'),
          buildTextInput(
            controller: rutinaDescripcionController,
            icon: Icons.description_outlined,
            hint: 'Detalles opcionales',
            multiline: true,
          ),
          buildLabel('Días'),
          buildDiasRapidos(),
          const SizedBox(height: 10),
          buildDiasSelector(),
          buildLabel('Hora de inicio'),
          buildHoraSelector(),
          buildLabel('Duración total'),
          buildTextInput(
            controller: rutinaDuracionController,
            icon: Icons.timer_outlined,
            hint: '45',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          buildRoutineSummary(),
          const SizedBox(height: 14),
          buildActivaSwitch(),
          const SizedBox(height: 14),
          buildLabel('Elegir ejercicios'),
          buildExercisePicker(),
          const SizedBox(height: 14),
          buildSelectedExercises(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: guardandoRutina ? null : guardarRutina,
              icon: guardandoRutina
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                guardandoRutina ? 'Guardando...' : 'Guardar rutina',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: tema.primario,
                disabledBackgroundColor: tema.textoSuave,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: tema.borde,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tema.texto,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 13, bottom: 7),
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
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool multiline = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: multiline ? 88 : 54,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: mezclarConTema(
          const Color(0xFF0EA5E9),
          0.045,
          base: tema.tarjeta,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tema.borde,
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
              color: const Color(0xFF0EA5E9),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: multiline ? 3 : 1,
              maxLines: multiline ? 5 : 1,
              keyboardType: keyboardType,
              style: TextStyle(
                color: tema.texto,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: tema.textoSuave,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGrupoSelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gruposMuscularesEjercicio.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final grupo = gruposMuscularesEjercicio[index];
          final activo =
              ejercicioGrupoController.text.trim().toLowerCase() ==
                  grupo.toLowerCase();

          return GestureDetector(
            onTap: () {
              setState(() {
                ejercicioGrupoController.text = grupo;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo
                    ? colorPorGrupo(grupo)
                    : colorPorGrupo(grupo).withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorPorGrupo(grupo).withOpacity(0.24),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                grupo,
                style: TextStyle(
                  color: activo ? Colors.white : colorPorGrupo(grupo),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildDiasRapidos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildQuickDayButton(
          text: 'L a V',
          onTap: seleccionarLunesAViernes,
        ),
        buildQuickDayButton(
          text: 'Todos',
          onTap: seleccionarTodosLosDias,
        ),
        buildQuickDayButton(
          text: 'Fin de semana',
          onTap: seleccionarFinSemana,
        ),
      ],
    );
  }

  Widget buildQuickDayButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: guardandoRutina ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: tema.secundario.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: tema.secundario.withOpacity(0.25),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: tema.secundario,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget buildDiasSelector() {
    return Row(
      children: diasOrdenEjercicio.map((dia) {
        final activo = diasSeleccionados.contains(dia);

        return Expanded(
          child: GestureDetector(
            onTap: guardandoRutina
                ? null
                : () {
                    alternarDia(dia);
                  },
            child: Container(
              height: 42,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: activo ? tema.primario : tema.tarjeta,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: activo ? tema.primario : tema.borde,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                dia,
                style: TextStyle(
                  color: activo ? Colors.white : tema.textoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildHoraSelector() {
    return GestureDetector(
      onTap: guardandoRutina ? null : seleccionarHora,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tema.barraXp.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: tema.barraXp.withOpacity(0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tema.barraXp.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.schedule_outlined,
                color: tema.barraXp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                horaTexto(horaInicio),
                style: TextStyle(
                  color: tema.texto,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Cambiar',
              style: TextStyle(
                color: tema.barraXp,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRoutineSummary() {
    final duracionEscrita = toInt(rutinaDuracionController.text, 45);
    final duracionValida = duracionEscrita >= 40 && duracionEscrita <= 60;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: duracionValida
            ? tema.exito.withOpacity(0.08)
            : tema.peligro.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: duracionValida
              ? tema.exito.withOpacity(0.18)
              : tema.peligro.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            duracionValida
                ? Icons.check_circle_outline
                : Icons.warning_amber_outlined,
            color: duracionValida ? tema.exito : tema.peligro,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Seleccionados: $duracionCalculadaRutina min calculados • $expCalculadaRutina XP. La duración guardada debe estar entre 40 y 60 min.',
              style: TextStyle(
                color: tema.texto,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActivaSwitch() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tema.exito.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tema.exito.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            rutinaActiva ? Icons.toggle_on : Icons.toggle_off_outlined,
            color: rutinaActiva ? tema.exito : tema.textoSuave,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rutinaActiva ? 'Rutina activa' : 'Rutina pausada',
              style: TextStyle(
                color: tema.texto,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: rutinaActiva,
            activeColor: tema.exito,
            onChanged: guardandoRutina
                ? null
                : (value) {
                    setState(() {
                      rutinaActiva = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget buildExercisePicker() {
    if (cargandoEjercicios) {
      return Container(
        height: 86,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: const Color(0xFF0EA5E9),
        ),
      );
    }

    if (ejercicios.isEmpty) {
      return buildMiniEmpty(
        icon: Icons.fitness_center_outlined,
        title: 'Sin ejercicios',
        text: 'Primero agrega ejercicios al catálogo.',
      );
    }

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ejercicios.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (context, index) {
          final ejercicio = ejercicios[index];
          final color = colorPorGrupo(ejercicio['grupo_muscular']?.toString());

          return Container(
            width: 210,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.fitness_center_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ejercicio['nombre']?.toString() ?? 'Ejercicio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tema.texto,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${ejercicio['grupo_muscular'] ?? 'Sin grupo'} • ${ejercicio['duracion_minutos']} min • ${ejercicio['valor_exp']} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.textoSuave,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    agregarEjercicioARutina(ejercicio);
                  },
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Agregar a rutina',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSelectedExercises() {
    if (ejerciciosSeleccionados.isEmpty) {
      return buildMiniEmpty(
        icon: Icons.playlist_add_outlined,
        title: 'Rutina vacía',
        text: 'Selecciona ejercicios del catálogo para armarla.',
      );
    }

    return Column(
      children: ejerciciosSeleccionados.map((item) {
        return buildSelectedExerciseCard(item);
      }).toList(),
    );
  }

  Widget buildSelectedExerciseCard(Map<String, dynamic> item) {
    final TextEditingController seriesController = TextEditingController(
      text: toInt(item['series'], 3).toString(),
    );
    final TextEditingController repsController = TextEditingController(
      text: item['repeticiones']?.toString() ?? '12',
    );
    final TextEditingController duracionController = TextEditingController(
      text: toInt(item['duracion_minutos'], 5).toString(),
    );
    final TextEditingController descansoController = TextEditingController(
      text: toInt(item['descanso_segundos'], 60).toString(),
    );
    final TextEditingController expController = TextEditingController(
      text: toInt(item['valor_exp'], 10).toString(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.fondoSecundario.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tema.borde,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.drag_indicator,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item['nombre']?.toString() ?? 'Ejercicio',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  quitarEjercicioDeRutina(item);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tema.peligro.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: tema.peligro,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: buildSmallNumberInput(
                  label: 'Series',
                  controller: seriesController,
                  onChanged: (value) {
                    actualizarDetalleRutina(
                      item,
                      'series',
                      toInt(value, 3),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSmallTextInput(
                  label: 'Reps',
                  controller: repsController,
                  onChanged: (value) {
                    actualizarDetalleRutina(
                      item,
                      'repeticiones',
                      value.trim(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: buildSmallNumberInput(
                  label: 'Min',
                  controller: duracionController,
                  onChanged: (value) {
                    actualizarDetalleRutina(
                      item,
                      'duracion_minutos',
                      toInt(value, 5),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSmallNumberInput(
                  label: 'Descanso s',
                  controller: descansoController,
                  onChanged: (value) {
                    actualizarDetalleRutina(
                      item,
                      'descanso_segundos',
                      toInt(value, 60),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSmallNumberInput(
                  label: 'XP',
                  controller: expController,
                  onChanged: (value) {
                    actualizarDetalleRutina(
                      item,
                      'valor_exp',
                      toInt(value, 10),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSmallNumberInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return buildSmallTextInput(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget buildSmallTextInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        color: tema.texto,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: tema.textoSuave,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: tema.tarjeta,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: tema.borde,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: tema.borde,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(13)),
          borderSide: BorderSide(
            color: Color(0xFF0EA5E9),
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget buildRutinasList() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.calendar_month_outlined,
            title: 'Rutinas',
            subtitle: cargandoRutinas
                ? 'Consultando rutinas...'
                : '${rutinas.length} rutinas creadas',
            color: tema.primario,
          ),
          const SizedBox(height: 14),
          if (cargandoRutinas && rutinas.isEmpty)
            buildLoadingState('Cargando rutinas...')
          else if (rutinas.isEmpty)
            buildMiniEmpty(
              icon: Icons.inbox_outlined,
              title: 'Sin rutinas',
              text: 'Crea una rutina de ejercicio de 40 a 60 minutos.',
            )
          else
            Column(
              children: rutinas.map((rutina) {
                return buildRutinaCard(rutina);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildRutinaCard(Map<String, dynamic> rutina) {
    final id = toInt(rutina['id'], 0);
    final accionando = idRutinaAccionando == id;
    final activa = rutina['activa'] == true;
    final dias = obtenerDiasComoSet(rutina['dias']);
    final ejerciciosRutina = rutina['ejercicios'] is List
        ? rutina['ejercicios'] as List
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: activa
            ? mezclarConTema(tema.primario, 0.06)
            : mezclarConTema(tema.textoSuave, 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: activa ? tema.primario.withOpacity(0.25) : tema.borde,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: activa ? tema.primario : tema.textoSuave,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: accionando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        activa
                            ? Icons.fitness_center_outlined
                            : Icons.pause_circle_outline,
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
                      rutina['nombre']?.toString() ?? 'Rutina',
                      style: TextStyle(
                        color: tema.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rutina['descripcion']?.toString() ??
                          '${ejerciciosRutina.length} ejercicios en esta rutina',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              GestureDetector(
                onTap: accionando
                    ? null
                    : () {
                        confirmarEliminarRutina(rutina);
                      },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tema.peligro.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: tema.peligro,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildBadge(
                icon: Icons.calendar_month_outlined,
                text: etiquetaDias(dias),
                color: tema.primario,
              ),
              buildBadge(
                icon: Icons.schedule_outlined,
                text: rutina['hora_inicio']?.toString() ?? '07:00',
                color: tema.barraXp,
              ),
              buildBadge(
                icon: Icons.timer_outlined,
                text: '${rutina['duracion_minutos'] ?? 45} min',
                color: const Color(0xFF0EA5E9),
              ),
              buildBadge(
                icon: Icons.flash_on,
                text: '${rutina['valor_exp_total'] ?? 0} XP',
                color: tema.aviso,
              ),
              buildBadge(
                icon: activa
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                text: activa ? 'Activa' : 'Pausada',
                color: activa ? tema.exito : tema.textoSuave,
              ),
            ],
          ),
          if (ejerciciosRutina.isNotEmpty) ...[
            const SizedBox(height: 10),
            buildRoutineExercisesPreview(ejerciciosRutina),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: accionando
                      ? null
                      : () {
                          alternarRutinaActiva(rutina);
                        },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: activa ? tema.aviso : tema.exito,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      activa ? 'Pausar' : 'Activar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRoutineExercisesPreview(List ejerciciosRutina) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tema.fondoSecundario.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tema.borde,
        ),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: ejerciciosRutina.map((item) {
          String nombre = 'Ejercicio';

          if (item is Map) {
            nombre = item['nombre']?.toString() ??
                item['ejercicio_nombre']?.toString() ??
                'Ejercicio';
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              nombre,
              style: const TextStyle(
                color: Color(0xFF0369A1),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildEjerciciosList() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.fitness_center_outlined,
            title: 'Catálogo de ejercicios',
            subtitle: cargandoEjercicios
                ? 'Consultando ejercicios...'
                : '${ejercicios.length} ejercicios disponibles',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 14),
          if (cargandoEjercicios && ejercicios.isEmpty)
            buildLoadingState('Cargando ejercicios...')
          else if (ejercicios.isEmpty)
            buildMiniEmpty(
              icon: Icons.fitness_center_outlined,
              title: 'Sin ejercicios',
              text: 'Agrega ejercicios para construir tus rutinas.',
            )
          else
            Column(
              children: ejercicios.map((ejercicio) {
                return buildEjercicioCard(ejercicio);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildEjercicioCard(Map<String, dynamic> ejercicio) {
    final id = toInt(ejercicio['id'], 0);
    final accionando = idEjercicioAccionando == id;
    final color = colorPorGrupo(ejercicio['grupo_muscular']?.toString());
    final esGlobal = ejercicio['es_global'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: accionando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.fitness_center_outlined,
                    color: Colors.white,
                    size: 23,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ejercicio['nombre']?.toString() ?? 'Ejercicio',
                  style: TextStyle(
                    color: tema.texto,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ejercicio['grupo_muscular'] ?? 'Sin grupo'} • ${ejercicio['tipo'] ?? 'Sin tipo'}',
                  style: TextStyle(
                    color: tema.textoSuave,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    buildBadge(
                      icon: Icons.timer_outlined,
                      text: '${ejercicio['duracion_minutos'] ?? 0} min',
                      color: const Color(0xFF0EA5E9),
                    ),
                    buildBadge(
                      icon: Icons.flash_on,
                      text: '${ejercicio['valor_exp'] ?? 0} XP',
                      color: tema.aviso,
                    ),
                    if (esGlobal)
                      buildBadge(
                        icon: Icons.public_outlined,
                        text: 'Global',
                        color: tema.primario,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: accionando
                ? null
                : () {
                    confirmarEliminarEjercicio(ejercicio);
                  },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tema.peligro.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: tema.peligro,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tema.fondoSecundario.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tema.borde,
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: tema.texto,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMiniEmpty({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.fondoSecundario.withOpacity(0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tema.borde,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0EA5E9),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: tema.texto,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}