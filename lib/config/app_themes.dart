import 'package:flutter/material.dart';

class ActivityTheme {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;

  final Color fondo;
  final Color fondoSecundario;
  final Color tarjeta;

  final Color primario;
  final Color secundario;
  final Color barraXp;

  final Color texto;
  final Color textoSuave;
  final Color borde;

  final Color exito;
  final Color aviso;
  final Color peligro;

  const ActivityTheme({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.fondo,
    required this.fondoSecundario,
    required this.tarjeta,
    required this.primario,
    required this.secundario,
    required this.barraXp,
    required this.texto,
    required this.textoSuave,
    required this.borde,
    required this.exito,
    required this.aviso,
    required this.peligro,
  });

  Color get suavePrimario {
    return primario.withOpacity(0.14);
  }

  Color get suaveSecundario {
    return secundario.withOpacity(0.14);
  }

  Color get suaveBarraXp {
    return barraXp.withOpacity(0.14);
  }

  Color get suaveExito {
    return exito.withOpacity(0.14);
  }

  Color get suaveAviso {
    return aviso.withOpacity(0.16);
  }

  Color get suavePeligro {
    return peligro.withOpacity(0.14);
  }
}

class AppThemes {
  static const ActivityTheme clasico = ActivityTheme(
    id: 'clasico',
    nombre: 'Morado limpio',
    descripcion: 'Morado vivo con tarjetas blancas y contraste fuerte.',
    icono: Icons.auto_awesome_outlined,
    fondo: Color(0xFF312E81),
    fondoSecundario: Color(0xFF4338CA),
    tarjeta: Color(0xFFFFFFFF),
    primario: Color(0xFF4F46E5),
    secundario: Color(0xFF8B5CF6),
    barraXp: Color(0xFFF59E0B),
    texto: Color(0xFF111827),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFC7D2FE),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
  );

  static const ActivityTheme bosque = ActivityTheme(
    id: 'bosque',
    nombre: 'Verde limpio',
    descripcion: 'Verde elegante con blancos, negro suave y acentos frescos.',
    icono: Icons.eco_outlined,
    fondo: Color(0xFF064E3B),
    fondoSecundario: Color(0xFF0F766E),
    tarjeta: Color(0xFFFFFFFF),
    primario: Color(0xFF10B981),
    secundario: Color(0xFF14B8A6),
    barraXp: Color(0xFF111827),
    texto: Color(0xFF111827),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFA7F3D0),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
  );

  static const ActivityTheme noche = ActivityTheme(
    id: 'noche',
    nombre: 'Blanco y negro',
    descripcion: 'Negro premium con tarjetas blancas y acentos fríos.',
    icono: Icons.dark_mode_outlined,
    fondo: Color(0xFF020617),
    fondoSecundario: Color(0xFF111827),
    tarjeta: Color(0xFFFFFFFF),
    primario: Color(0xFF111827),
    secundario: Color(0xFF475569),
    barraXp: Color(0xFF06B6D4),
    texto: Color(0xFF020617),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFE2E8F0),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
  );

  static const ActivityTheme rosa = ActivityTheme(
    id: 'rosa',
    nombre: 'Rosa limpio',
    descripcion: 'Rosa intenso con tarjetas blancas y detalles suaves.',
    icono: Icons.favorite_outline,
    fondo: Color(0xFF831843),
    fondoSecundario: Color(0xFFBE185D),
    tarjeta: Color(0xFFFFFFFF),
    primario: Color(0xFFEC4899),
    secundario: Color(0xFFF472B6),
    barraXp: Color(0xFFF59E0B),
    texto: Color(0xFF111827),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFFBCFE8),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
  );

  static const ActivityTheme fuego = ActivityTheme(
    id: 'fuego',
    nombre: 'Fuego limpio',
    descripcion: 'Naranja cálido con blancos y contraste alto.',
    icono: Icons.local_fire_department_outlined,
    fondo: Color(0xFF7C2D12),
    fondoSecundario: Color(0xFFEA580C),
    tarjeta: Color(0xFFFFFFFF),
    primario: Color(0xFFF97316),
    secundario: Color(0xFFEF4444),
    barraXp: Color(0xFFFBBF24),
    texto: Color(0xFF111827),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFFED7AA),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
  );

  static const List<ActivityTheme> todos = [
    clasico,
    bosque,
    noche,
    rosa,
    fuego,
  ];

  static final ValueNotifier<ActivityTheme> temaActual =
      ValueNotifier<ActivityTheme>(clasico);

  static ActivityTheme getById(String? id) {
    if (id == null || id.trim().isEmpty) {
      return clasico;
    }

    for (final tema in todos) {
      if (tema.id == id.trim()) {
        return tema;
      }
    }

    return clasico;
  }

  static void cambiarTema(ActivityTheme tema) {
    temaActual.value = tema;
  }

  static void cambiarTemaPorId(String? id) {
    temaActual.value = getById(id);
  }

  static bool esTemaActual(String id) {
    return temaActual.value.id == id;
  }
}
