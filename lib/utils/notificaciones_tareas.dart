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
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentSound: true,
          defaultPresentBadge: false,
          defaultPresentBanner: true,
          defaultPresentList: true,
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
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
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

  static DateTime? obtenerFechaInicio(Map<String, dynamic> tarea) {
    return convertirFechaLocal(
      tarea['fechaInicioNotificacion'] ??
          tarea['fechaInicio'] ??
          tarea['fecha_inicio'] ??
          tarea['fechaHabilitacion'] ??
          tarea['fecha_habilitacion'] ??
          tarea['inicio'] ??
          tarea['empieza'],
    );
  }

  static DateTime? obtenerFechaExpiracion(Map<String, dynamic> tarea) {
    return convertirFechaLocal(
      tarea['fechaExpiracion'] ??
          tarea['fecha_expiracion'] ??
          tarea['fechaLimiteCumplimiento'] ??
          tarea['fecha_limite_cumplimiento'] ??
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

  static DateTime? _fechaFuturaSegura(
    DateTime? fecha, {
    int segundosMinimos = 5,
  }) {
    if (fecha == null) {
      return null;
    }

    final ahora = DateTime.now();
    final minimo = ahora.add(Duration(seconds: segundosMinimos));

    if (fecha.isBefore(minimo) || fecha.isAtSameMomentAs(minimo)) {
      return null;
    }

    return fecha;
  }

  static Future<void> _programarNotificacion({
    required int id,
    required String title,
    required String body,
    required DateTime fecha,
    required Map<String, dynamic> payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _toTzDateTime(fecha),
      notificationDetails: _detallesNotificacion(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode(payload),
    );
  }

  static Future<int?> probarNotificacionInmediataIos() async {
    try {
      final tienePermiso = await inicializarNotificaciones();

      debugPrint('Permiso notificaciones iOS inmediata: $tienePermiso');

      if (!tienePermiso) {
        debugPrint('No hay permiso para mostrar notificaciones.');
        return null;
      }

      final id = _generarIdNotificacion(
        'prueba-inmediata-ios',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await _plugin.show(
        id: id,
        title: 'Prueba inmediata ✅',
        body: 'Si ves esto, iOS ya permite notificaciones locales.',
        notificationDetails: _detallesNotificacion(),
        payload: jsonEncode({
          'tipo': 'prueba_inmediata_ios',
        }),
      );

      debugPrint('Notificación inmediata enviada: $id');

      return id;
    } catch (error) {
      debugPrint('Error enviando notificación inmediata iOS: $error');
      return null;
    }
  }

  static Future<int?> probarNotificacionProgramadaIos() async {
    try {
      final tienePermiso = await inicializarNotificaciones();

      debugPrint('Permiso notificaciones iOS programada: $tienePermiso');

      if (!tienePermiso) {
        debugPrint('No hay permiso para programar notificaciones.');
        return null;
      }

      final id = _generarIdNotificacion(
        'prueba-programada-ios',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      final fechaProgramada = DateTime.now().add(
        const Duration(seconds: 20),
      );

      await _programarNotificacion(
        id: id,
        title: 'Prueba programada ⏰',
        body: 'Esta notificación estaba programada, no salió por el botón.',
        fecha: fechaProgramada,
        payload: {
          'tipo': 'prueba_programada_ios',
        },
      );

      debugPrint('Notificación programada iOS: $id');
      debugPrint('Fecha programada: $fechaProgramada');

      return id;
    } catch (error) {
      debugPrint('Error programando notificación iOS: $error');
      return null;
    }
  }

  static Future<int?> probarNotificacionLocal() async {
    return probarNotificacionProgramadaIos();
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
      final fechaInicio = obtenerFechaInicio(tarea);
      final fechaExpiracion = obtenerFechaExpiracion(tarea);

      await cancelarNotificacionesTarea(idTarea);

      final idsProgramados = <int>[];

      final fechaInicioSegura = _fechaFuturaSegura(
        fechaInicio,
        segundosMinimos: 5,
      );

      if (fechaInicioSegura != null) {
        final idHabilitada = _generarIdNotificacion(
          idTarea,
          'habilitada',
        );

        await _programarNotificacion(
          id: idHabilitada,
          title: 'Tarea habilitada ✅',
          body: '$tituloTarea ya está activa.',
          fecha: fechaInicioSegura,
          payload: {
            'tipo': 'tarea_habilitada',
            'idTarea': idTarea,
          },
        );

        idsProgramados.add(idHabilitada);
      }

      if (fechaExpiracion != null) {
        final diezMinutosAntes = fechaExpiracion.subtract(
          const Duration(minutes: 10),
        );

        final fechaDiezMinutosSegura = _fechaFuturaSegura(
          diezMinutosAntes,
          segundosMinimos: 5,
        );

        if (fechaDiezMinutosSegura != null) {
          final idDiezMinutos = _generarIdNotificacion(
            idTarea,
            '10_minutos_antes',
          );

          await _programarNotificacion(
            id: idDiezMinutos,
            title: 'Tu tarea está por expirar ⏳',
            body: '$tituloTarea vence en 10 minutos.',
            fecha: fechaDiezMinutosSegura,
            payload: {
              'tipo': 'tarea_10_minutos_antes',
              'idTarea': idTarea,
            },
          );

          idsProgramados.add(idDiezMinutos);
        }

        final fechaExpiracionSegura = _fechaFuturaSegura(
          fechaExpiracion,
          segundosMinimos: 5,
        );

        if (fechaExpiracionSegura != null) {
          final idExpirada = _generarIdNotificacion(
            idTarea,
            'expirada',
          );

          await _programarNotificacion(
            id: idExpirada,
            title: 'Tarea expirada ⚠️',
            body: '$tituloTarea ya expiró.',
            fecha: fechaExpiracionSegura,
            payload: {
              'tipo': 'tarea_expirada',
              'idTarea': idTarea,
            },
          );

          idsProgramados.add(idExpirada);
        }
      }

      await StorageService.setItem(
        'notificaciones_tarea_$idTarea',
        jsonEncode(idsProgramados),
      );

      debugPrint('Notificaciones programadas para tarea $idTarea: $idsProgramados');
      debugPrint('Fecha inicio detectada: $fechaInicio');
      debugPrint('Fecha expiración detectada: $fechaExpiracion');

      return {
        'ok': true,
        'ids': idsProgramados,
        'mensaje': idsProgramados.isEmpty
            ? 'No había fechas futuras para programar.'
            : 'Notificaciones programadas correctamente.',
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