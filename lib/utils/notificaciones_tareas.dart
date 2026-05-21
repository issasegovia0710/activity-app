import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/storage_service.dart';

class NotificacionesTareas {
  static const String canalTareas = 'tareas';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  static Future<bool> inicializarNotificaciones() async {
    try {
      if (kIsWeb) {
        debugPrint('Las notificaciones locales no funcionan en web.');
        return false;
      }

      if (!_inicializado) {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );

        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _plugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('Notificación presionada: ${response.payload}');
          },
        );

        await _crearCanalAndroid();

        _inicializado = true;
      }

      final permisoAndroid = await _solicitarPermisoAndroid();
      final permisoIos = await _solicitarPermisoIos();

      return permisoAndroid && permisoIos;
    } catch (error) {
      debugPrint('Error inicializando notificaciones: $error');
      return false;
    }
  }

  static Future<void> _crearCanalAndroid() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return;
    }

    const channel = AndroidNotificationChannel(
      canalTareas,
      'Tareas',
      description: 'Notificaciones de tareas y misiones',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      ledColor: Color(0xFF5B4BF2),
    );

    await androidPlugin.createNotificationChannel(channel);
  }

  static Future<bool> _solicitarPermisoAndroid() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true;
    }

    final permiso = await androidPlugin.requestNotificationsPermission();

    return permiso ?? true;
  }

  static Future<bool> _solicitarPermisoIos() async {
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin == null) {
      return true;
    }

    final permiso = await iosPlugin.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );

    return permiso ?? false;
  }

  static NotificationDetails _detallesNotificacion() {
    const androidDetails = AndroidNotificationDetails(
      canalTareas,
      'Tareas',
      channelDescription: 'Notificaciones de tareas y misiones',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static String _limpiarTexto(dynamic valor) {
    if (valor == null) {
      return '';
    }

    return valor.toString().trim();
  }

  static DateTime? convertirFechaLocal(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is DateTime) {
      return valor;
    }

    final textoOriginal = valor.toString().trim();

    if (textoOriginal.isEmpty) {
      return null;
    }

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
    final hours = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(5) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(6) ?? '0') ?? 0;

    return DateTime(
      year,
      month,
      day,
      hours,
      minutes,
      seconds,
    );
  }

  static String obtenerIdTarea(Map<String, dynamic> tarea) {
    return _limpiarTexto(
      tarea['id'] ??
          tarea['id_tarea'] ??
          tarea['idActividad'] ??
          tarea['id_actividad'] ??
          tarea['_id'] ??
          tarea['folio'] ??
          tarea['nombre'] ??
          tarea['titulo'] ??
          'tarea-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static String obtenerTituloTarea(Map<String, dynamic> tarea) {
    final titulo = _limpiarTexto(
      tarea['titulo'] ??
          tarea['nombre'] ??
          tarea['actividad'] ??
          tarea['descripcion'] ??
          'Tarea',
    );

    if (titulo.isEmpty) {
      return 'Tarea';
    }

    return titulo;
  }

  static DateTime? obtenerFechaExpiracion(Map<String, dynamic> tarea) {
    return convertirFechaLocal(
      tarea['fechaExpiracion'] ??
          tarea['fecha_expiracion'] ??
          tarea['fechaVencimiento'] ??
          tarea['fecha_vencimiento'] ??
          tarea['fechaFin'] ??
          tarea['fecha_fin'] ??
          tarea['vence'] ??
          tarea['deadline'] ??
          tarea['expira'],
    );
  }

  static int _generarIdNotificacion(
    String idTarea,
    String tipo,
  ) {
    final texto = '$idTarea-$tipo';
    int hash = 0;

    for (int i = 0; i < texto.length; i++) {
      hash = 0x1fffffff & (hash + texto.codeUnitAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    if (hash == 0) {
      return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
    }

    return hash;
  }

  static tz.TZDateTime _toTzDateTime(DateTime fecha) {
    return tz.TZDateTime.from(fecha, tz.local);
  }

  static Future<int?> probarNotificacionLocal() async {
    try {
      final tienePermiso = await inicializarNotificaciones();

      if (!tienePermiso) {
        debugPrint('No se pudo probar notificación porque no hay permiso.');
        return null;
      }

      final id = _generarIdNotificacion(
        'prueba',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await _plugin.zonedSchedule(
        id: id,
        title: 'Prueba de notificación ✅',
        body: 'Si ves esto, las notificaciones locales ya funcionan.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 2),
        ),
        notificationDetails: _detallesNotificacion(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'tipo': 'prueba_notificacion',
        }),
      );

      debugPrint('Notificación de prueba programada: $id');

      return id;
    } catch (error) {
      debugPrint('Error probando notificación local: $error');
      return null;
    }
  }

  static Future<void> cancelarNotificacionesTarea(dynamic idTarea) async {
    try {
      final idLimpio = _limpiarTexto(idTarea);

      if (idLimpio.isEmpty) {
        return;
      }

      final key = 'notificaciones_tarea_$idLimpio';
      final guardadas = await StorageService.getItem(key);

      if (guardadas == null || guardadas.isEmpty) {
        return;
      }

      final ids = jsonDecode(guardadas);

      if (ids is List) {
        for (final id in ids) {
          final idInt = int.tryParse(id.toString());

          if (idInt != null) {
            await _plugin.cancel(id: idInt);
          }
        }
      }

      await StorageService.removeItem(key);
    } catch (error) {
      debugPrint('Error cancelando notificaciones de tarea: $error');
    }
  }

  static Future<Map<String, dynamic>> programarNotificacionesTarea(
    Map<String, dynamic> tarea,
  ) async {
    try {
      final tienePermiso = await inicializarNotificaciones();

      if (!tienePermiso) {
        return {
          'ok': false,
          'ids': <int>[],
          'mensaje': 'No hay permiso para notificaciones.',
        };
      }

      final idTarea = obtenerIdTarea(tarea);
      final tituloTarea = obtenerTituloTarea(tarea);
      final fechaExpiracion = obtenerFechaExpiracion(tarea);

      await cancelarNotificacionesTarea(idTarea);

      final idsProgramados = <int>[];
      final ahora = DateTime.now();

      final idHabilitada = _generarIdNotificacion(
        idTarea,
        'habilitada',
      );

      await _plugin.zonedSchedule(
        id: idHabilitada,
        title: 'Tarea habilitada ✅',
        body: '$tituloTarea ya está activa.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 2),
        ),
        notificationDetails: _detallesNotificacion(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'tipo': 'tarea_habilitada',
          'idTarea': idTarea,
        }),
      );

      idsProgramados.add(idHabilitada);

      if (fechaExpiracion != null) {
        final diezMinutosAntes = fechaExpiracion.subtract(
          const Duration(minutes: 10),
        );

        if (diezMinutosAntes.isAfter(ahora)) {
          final idDiezMinutos = _generarIdNotificacion(
            idTarea,
            '10_minutos_antes',
          );

          await _plugin.zonedSchedule(
            id: idDiezMinutos,
            title: 'Tu tarea está por expirar ⏳',
            body: '$tituloTarea vence en 10 minutos.',
            scheduledDate: _toTzDateTime(diezMinutosAntes),
            notificationDetails: _detallesNotificacion(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: jsonEncode({
              'tipo': 'tarea_10_minutos_antes',
              'idTarea': idTarea,
            }),
          );

          idsProgramados.add(idDiezMinutos);
        }

        if (fechaExpiracion.isAfter(ahora)) {
          final idExpirada = _generarIdNotificacion(
            idTarea,
            'expirada',
          );

          await _plugin.zonedSchedule(
            id: idExpirada,
            title: 'Tarea expirada ⚠️',
            body: '$tituloTarea ya expiró.',
            scheduledDate: _toTzDateTime(fechaExpiracion),
            notificationDetails: _detallesNotificacion(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: jsonEncode({
              'tipo': 'tarea_expirada',
              'idTarea': idTarea,
            }),
          );

          idsProgramados.add(idExpirada);
        }
      }

      await StorageService.setItem(
        'notificaciones_tarea_$idTarea',
        jsonEncode(idsProgramados),
      );

      debugPrint('Notificaciones programadas: $idsProgramados');

      return {
        'ok': true,
        'ids': idsProgramados,
        'mensaje': 'Notificaciones programadas correctamente.',
      };
    } catch (error) {
      debugPrint('Error programando notificaciones de tarea: $error');

      return {
        'ok': false,
        'ids': <int>[],
        'mensaje': error.toString(),
      };
    }
  }
}