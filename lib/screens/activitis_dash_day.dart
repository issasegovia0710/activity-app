import 'package:flutter/material.dart';
import '../config/app_themes.dart';

const List<Map<String, dynamic>> prioridadesDay = [
  {
    'id': 1,
    'nombre': 'baja',
    'etiqueta': 'Baja',
  },
  {
    'id': 2,
    'nombre': 'media',
    'etiqueta': 'Media',
  },
  {
    'id': 3,
    'nombre': 'alta',
    'etiqueta': 'Alta',
  },
];

const List<Map<String, dynamic>> sugerenciasMisionesDay = [
  {
    'nombre': 'Tender cama',
    'descripcion': 'Dejar la cama ordenada al iniciar el día.',
    'icono': Icons.bed_outlined,
  },
  {
    'nombre': 'Lavarte los dientes',
    'descripcion': 'Rutina de higiene personal.',
    'icono': Icons.clean_hands_outlined,
  },
  {
    'nombre': 'Lavar trastes',
    'descripcion': 'Limpiar los trastes pendientes.',
    'icono': Icons.local_dining_outlined,
  },
  {
    'nombre': 'Trapear',
    'descripcion': 'Limpiar el piso con trapeador.',
    'icono': Icons.cleaning_services_outlined,
  },
  {
    'nombre': 'Barrer',
    'descripcion': 'Barrer el área asignada.',
    'icono': Icons.house_outlined,
  },
  {
    'nombre': 'Sacar basura',
    'descripcion': 'Retirar la basura del lugar.',
    'icono': Icons.delete_outline,
  },
];

const List<String> diasOrdenDay = [
  'L',
  'M',
  'MI',
  'J',
  'V',
  'S',
  'D',
];

class ActivitisDashDayScreen extends StatefulWidget {
  const ActivitisDashDayScreen({super.key});

  @override
  State<ActivitisDashDayScreen> createState() => _ActivitisDashDayScreenState();
}

class _ActivitisDashDayScreenState extends State<ActivitisDashDayScreen>
    with TickerProviderStateMixin {
  ActivityTheme tema = AppThemes.clasico;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  List<Map<String, dynamic>> misiones = [];

  Set<String> diasSeleccionados = {
    'L',
    'M',
    'MI',
    'J',
    'V',
  };

  String prioridad = 'media';
  TimeOfDay horaSeleccionada = const TimeOfDay(hour: 8, minute: 0);
  bool activa = true;
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
      duration: const Duration(milliseconds: 720),
    );

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
      begin: 34,
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
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
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

  Color colorPrioridad(String valor) {
    if (valor == 'baja') return tema.exito;
    if (valor == 'media') return tema.aviso;
    if (valor == 'alta') return tema.peligro;

    return tema.textoSuave;
  }

  int expPorPrioridad(String valor) {
    if (valor == 'baja') return 5;
    if (valor == 'media') return 15;
    if (valor == 'alta') return 25;

    return 15;
  }

  String etiquetaDias(Set<String> dias) {
    if (dias.length == 7) {
      return 'Todos los días';
    }

    if (
      dias.contains('L') &&
      dias.contains('M') &&
      dias.contains('MI') &&
      dias.contains('J') &&
      dias.contains('V') &&
      dias.length == 5
    ) {
      return 'Lunes a viernes';
    }

    if (dias.contains('S') && dias.contains('D') && dias.length == 2) {
      return 'Sábado y domingo';
    }

    return diasOrdenDay.where((dia) => dias.contains(dia)).join(', ');
  }

  String horaTexto(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  void aplicarSugerencia(Map<String, dynamic> sugerencia) {
    nombreController.text = sugerencia['nombre']?.toString() ?? '';
    descripcionController.text = sugerencia['descripcion']?.toString() ?? '';

    setState(() {});
  }

  Future<void> seleccionarHora() async {
    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: horaSeleccionada,
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
      horaSeleccionada = nuevaHora;
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

  void seleccionarTodosLosDias() {
    setState(() {
      diasSeleccionados = {
        'L',
        'M',
        'MI',
        'J',
        'V',
        'S',
        'D',
      };
    });
  }

  void seleccionarLunesAViernes() {
    setState(() {
      diasSeleccionados = {
        'L',
        'M',
        'MI',
        'J',
        'V',
      };
    });
  }

  void seleccionarFinSemana() {
    setState(() {
      diasSeleccionados = {
        'S',
        'D',
      };
    });
  }

  void limpiarFormulario() {
    nombreController.clear();
    descripcionController.clear();

    setState(() {
      diasSeleccionados = {
        'L',
        'M',
        'MI',
        'J',
        'V',
      };
      prioridad = 'media';
      horaSeleccionada = const TimeOfDay(hour: 8, minute: 0);
      activa = true;
    });
  }

  void guardarMisionLocal() {
    final nombre = nombreController.text.trim();
    final descripcion = descripcionController.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        titulo: 'Falta nombre',
        mensaje: 'Escribe el nombre de la misión diaria.',
      );
      return;
    }

    if (diasSeleccionados.isEmpty) {
      mostrarMensaje(
        titulo: 'Faltan días',
        mensaje: 'Selecciona al menos un día para repetir la misión.',
      );
      return;
    }

    final nuevaMision = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'nombre': nombre,
      'descripcion': descripcion.isEmpty ? null : descripcion,
      'dias': diasSeleccionados.toList(),
      'hora': horaTexto(horaSeleccionada),
      'prioridad': prioridad,
      'valor_exp': expPorPrioridad(prioridad),
      'activa': activa,
    };

    setState(() {
      misiones.insert(0, nuevaMision);
    });

    limpiarFormulario();

    mostrarMensaje(
      titulo: 'Misión agregada',
      mensaje: 'La misión se agregó al frente. Después la conectamos al backend.',
    );
  }

  void eliminarMision(Map<String, dynamic> mision) {
    setState(() {
      misiones.removeWhere((item) => item['id'] == mision['id']);
    });
  }

  void alternarActiva(Map<String, dynamic> mision) {
    setState(() {
      final index = misiones.indexWhere((item) => item['id'] == mision['id']);

      if (index == -1) return;

      misiones[index] = {
        ...misiones[index],
        'activa': !(misiones[index]['activa'] == true),
      };
    });
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
                color: tema.primario.withOpacity(0.28),
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
                top: size.height * 0.10 + floatAnimation.value,
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
                    Icons.auto_awesome_outlined,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        buildHeader(),
        const SizedBox(height: 14),
        buildIntroCard(),
        const SizedBox(height: 14),
        buildFormCard(),
        const SizedBox(height: 14),
        buildMissionsList(),
      ],
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
              Text(
                'Misiones diarias',
                style: TextStyle(
                  color: tema.texto,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Rutinas repetibles de vida diaria',
                style: TextStyle(
                  color: tema.textoSuave,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.primario,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: tema.primario.withOpacity(0.22),
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
              Icons.repeat_on_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Carga tareas como tender cama, lavarte los dientes, lavar trastes, trapear o barrer. Aquí solo armamos el frente.',
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

  Widget buildFormCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.add_task_outlined,
            title: 'Nueva misión',
            subtitle: 'Configura una tarea repetible.',
          ),
          const SizedBox(height: 14),
          buildSugerencias(),
          const SizedBox(height: 14),
          buildLabel('Nombre'),
          buildTextInput(
            controller: nombreController,
            icon: Icons.edit_outlined,
            hint: 'Ej. Tender cama',
          ),
          buildLabel('Descripción'),
          buildTextInput(
            controller: descripcionController,
            icon: Icons.description_outlined,
            hint: 'Detalles opcionales',
            multiline: true,
          ),
          buildLabel('Días de repetición'),
          buildDiasRapidos(),
          const SizedBox(height: 10),
          buildDiasSelector(),
          buildLabel('Hora sugerida'),
          buildHoraSelector(),
          buildLabel('Prioridad'),
          buildPrioridadRow(),
          const SizedBox(height: 14),
          buildActivaSwitch(),
          const SizedBox(height: 18),
          buildSaveButton(),
        ],
      ),
    );
  }

  Widget buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: tema.primario.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: tema.primario,
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

  Widget buildSugerencias() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sugerenciasMisionesDay.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final sugerencia = sugerenciasMisionesDay[index];

          return GestureDetector(
            onTap: () {
              aplicarSugerencia(sugerencia);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: tema.primario.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: tema.primario.withOpacity(0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sugerencia['icono'] as IconData,
                    color: tema.primario,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sugerencia['nombre'].toString(),
                    style: TextStyle(
                      color: tema.primario,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: multiline ? 88 : 54,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: mezclarConTema(
          tema.primario,
          0.05,
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
              color: tema.primario,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
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

  Widget buildDiasRapidos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildQuickDayButton(
          text: 'Todos',
          onTap: seleccionarTodosLosDias,
        ),
        buildQuickDayButton(
          text: 'L a V',
          onTap: seleccionarLunesAViernes,
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
      onTap: onTap,
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
      children: diasOrdenDay.map((dia) {
        final activo = diasSeleccionados.contains(dia);

        return Expanded(
          child: GestureDetector(
            onTap: () {
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
      onTap: seleccionarHora,
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
                horaTexto(horaSeleccionada),
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

  Widget buildPrioridadRow() {
    return Row(
      children: prioridadesDay.map((item) {
        final nombre = item['nombre'].toString();
        final activo = prioridad == nombre;
        final color = colorPrioridad(nombre);

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                prioridad = nombre;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
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
        );
      }).toList(),
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
            activa ? Icons.toggle_on : Icons.toggle_off_outlined,
            color: activa ? tema.exito : tema.textoSuave,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activa ? 'Misión activa' : 'Misión pausada',
              style: TextStyle(
                color: tema.texto,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: activa,
            activeColor: tema.exito,
            onChanged: (value) {
              setState(() {
                activa = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: guardarMisionLocal,
        icon: const Icon(Icons.save_outlined),
        label: const Text(
          'Agregar misión diaria',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: tema.primario,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget buildMissionsList() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: tema.borde,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            icon: Icons.list_alt_outlined,
            title: 'Misiones cargadas',
            subtitle: '${misiones.length} en esta pantalla',
          ),
          const SizedBox(height: 14),
          if (misiones.isEmpty)
            buildEmptyState()
          else
            Column(
              children: misiones.map((mision) {
                return buildMissionCard(mision);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
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
          Icon(
            Icons.inbox_outlined,
            color: tema.primario,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'Sin misiones todavía',
            style: TextStyle(
              color: tema.texto,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Carga una misión diaria desde el formulario de arriba.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.textoSuave,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMissionCard(Map<String, dynamic> mision) {
    final dias = (mision['dias'] as List)
        .map((item) => item.toString())
        .toSet();

    final prioridadTexto = mision['prioridad']?.toString() ?? 'media';
    final color = colorPrioridad(prioridadTexto);
    final estaActiva = mision['activa'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estaActiva
            ? mezclarConTema(tema.primario, 0.06)
            : mezclarConTema(tema.textoSuave, 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: estaActiva ? tema.primario.withOpacity(0.25) : tema.borde,
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
                  color: estaActiva ? tema.primario : tema.textoSuave,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  estaActiva
                      ? Icons.auto_awesome_motion_outlined
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
                      mision['nombre']?.toString() ?? 'Misión',
                      style: TextStyle(
                        color: tema.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mision['descripcion']?.toString() ?? 'Sin descripción',
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
                onTap: () {
                  eliminarMision(mision);
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
              buildMissionBadge(
                icon: Icons.calendar_month_outlined,
                text: etiquetaDias(dias),
                color: tema.primario,
              ),
              buildMissionBadge(
                icon: Icons.schedule_outlined,
                text: mision['hora']?.toString() ?? '08:00',
                color: tema.barraXp,
              ),
              buildMissionBadge(
                icon: Icons.priority_high,
                text: prioridadTexto,
                color: color,
              ),
              buildMissionBadge(
                icon: Icons.flash_on,
                text: '${mision['valor_exp'] ?? 0} XP',
                color: tema.aviso,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    alternarActiva(mision);
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: estaActiva ? tema.aviso : tema.exito,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      estaActiva ? 'Pausar' : 'Activar',
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

  Widget buildMissionBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
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
}