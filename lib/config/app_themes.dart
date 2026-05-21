import 'package:flutter/material.dart';

class ActivityTheme {
  final String id;
  final String nombre;
  final String descripcion;
  final Color fondo;
  final Color fondoSecundario;
  final Color primario;
  final Color secundario;
  final Color tarjeta;
  final Color texto;
  final Color textoSuave;
  final Color borde;
  final Color barraXp;
  final Color peligro;
  final Color exito;
  final Color aviso;
  final Color suavePrimario;
  final Color suaveSecundario;

  const ActivityTheme({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fondo,
    required this.fondoSecundario,
    required this.primario,
    required this.secundario,
    required this.tarjeta,
    required this.texto,
    required this.textoSuave,
    required this.borde,
    required this.barraXp,
    required this.peligro,
    required this.exito,
    required this.aviso,
    required this.suavePrimario,
    required this.suaveSecundario,
  });
}

class AppThemes {
  static const ActivityTheme clasico = ActivityTheme(
    id: 'clasico',
    nombre: 'Clásico',
    descripcion: 'Morado principal del juego',
    fondo: Color(0xFF312E81),
    fondoSecundario: Color(0xFF4C1D95),
    primario: Color(0xFF4F46E5),
    secundario: Color(0xFFEC4899),
    tarjeta: Color(0xFFFFFFFF),
    texto: Color(0xFF1E293B),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFC7D2FE),
    barraXp: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    suavePrimario: Color(0xFFEEF2FF),
    suaveSecundario: Color(0xFFFCE7F3),
  );

  static const ActivityTheme noche = ActivityTheme(
    id: 'noche',
    nombre: 'Noche',
    descripcion: 'Oscuro, cómodo y elegante',
    fondo: Color(0xFF0F172A),
    fondoSecundario: Color(0xFF1E293B),
    primario: Color(0xFF38BDF8),
    secundario: Color(0xFF818CF8),
    tarjeta: Color(0xFFFFFFFF),
    texto: Color(0xFF1E293B),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFBAE6FD),
    barraXp: Color(0xFF38BDF8),
    peligro: Color(0xFFEF4444),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    suavePrimario: Color(0xFFE0F2FE),
    suaveSecundario: Color(0xFFEDE9FE),
  );

  static const ActivityTheme dulce = ActivityTheme(
    id: 'dulce',
    nombre: 'Dulce',
    descripcion: 'Rosa, suave y brillante',
    fondo: Color(0xFF831843),
    fondoSecundario: Color(0xFF9D174D),
    primario: Color(0xFFEC4899),
    secundario: Color(0xFFF59E0B),
    tarjeta: Color(0xFFFFFFFF),
    texto: Color(0xFF1E293B),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFFBCFE8),
    barraXp: Color(0xFFF59E0B),
    peligro: Color(0xFFEF4444),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    suavePrimario: Color(0xFFFCE7F3),
    suaveSecundario: Color(0xFFFFFBEB),
  );

  static const ActivityTheme bosque = ActivityTheme(
    id: 'bosque',
    nombre: 'Bosque',
    descripcion: 'Verde, fresco y tranquilo',
    fondo: Color(0xFF064E3B),
    fondoSecundario: Color(0xFF065F46),
    primario: Color(0xFF10B981),
    secundario: Color(0xFF84CC16),
    tarjeta: Color(0xFFFFFFFF),
    texto: Color(0xFF1E293B),
    textoSuave: Color(0xFF64748B),
    borde: Color(0xFFBBF7D0),
    barraXp: Color(0xFF84CC16),
    peligro: Color(0xFFEF4444),
    exito: Color(0xFF16A34A),
    aviso: Color(0xFFF59E0B),
    suavePrimario: Color(0xFFD1FAE5),
    suaveSecundario: Color(0xFFECFCCB),
  );

  static const List<ActivityTheme> todos = [
    clasico,
    noche,
    dulce,
    bosque,
  ];

  static ActivityTheme getById(String? id) {
    if (id == null || id.trim().isEmpty) {
      return clasico;
    }

    return todos.firstWhere(
      (theme) => theme.id == id,
      orElse: () => clasico,
    );
  }
}