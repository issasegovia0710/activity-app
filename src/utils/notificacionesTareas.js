import { Alert, Linking, Platform } from 'react-native';
import * as Notifications from 'expo-notifications';
import storage from '../config/storage';

const CANAL_TAREAS = 'tareas';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

const limpiarTexto = (valor) => {
  if (valor === null || valor === undefined) {
    return '';
  }

  return String(valor).trim();
};

const crearCanalAndroid = async () => {
  if (Platform.OS !== 'android') {
    return;
  }

  await Notifications.setNotificationChannelAsync(CANAL_TAREAS, {
    name: 'Tareas',
    importance: Notifications.AndroidImportance.MAX,
    vibrationPattern: [0, 250, 250, 250],
    lightColor: '#5B4BF2',
    sound: 'default',
    lockscreenVisibility: Notifications.AndroidNotificationVisibility.PUBLIC,
  });
};

export const inicializarNotificaciones = async () => {
  try {
    if (Platform.OS === 'web') {
      console.log('Las notificaciones locales no funcionan en web.');
      return false;
    }

    await crearCanalAndroid();

    const permisosActuales = await Notifications.getPermissionsAsync();

    console.log('Permisos actuales de notificaciones:', permisosActuales);

    let estadoFinal = permisosActuales.status;

    if (estadoFinal !== 'granted') {
      const permisosSolicitados = await Notifications.requestPermissionsAsync();
      console.log('Permisos solicitados:', permisosSolicitados);
      estadoFinal = permisosSolicitados.status;
    }

    if (estadoFinal !== 'granted') {
      Alert.alert(
        'Permiso de notificaciones',
        'No se autorizó el permiso. Actívalo manualmente en la configuración del teléfono.',
        [
          {
            text: 'Abrir configuración',
            onPress: () => Linking.openSettings(),
          },
          {
            text: 'Cancelar',
            style: 'cancel',
          },
        ]
      );

      return false;
    }

    return true;
  } catch (error) {
    console.log('Error inicializando notificaciones:', error);
    return false;
  }
};

const convertirFechaLocal = (valor) => {
  if (!valor) {
    return null;
  }

  if (valor instanceof Date) {
    if (Number.isNaN(valor.getTime())) {
      return null;
    }

    return valor;
  }

  const textoOriginal = String(valor).trim();

  if (!textoOriginal) {
    return null;
  }

  const textoLimpio = textoOriginal
    .replace('T', ' ')
    .replace(/\.\d+/, '')
    .replace(/Z$/i, '')
    .replace(/([+-]\d{2}:?\d{2})$/, '')
    .trim();

  const match = textoLimpio.match(
    /^(\d{4})-(\d{2})-(\d{2})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$/
  );

  if (!match) {
    const fechaFallback = new Date(textoOriginal);

    if (Number.isNaN(fechaFallback.getTime())) {
      return null;
    }

    return fechaFallback;
  }

  const year = Number(match[1]);
  const month = Number(match[2]) - 1;
  const day = Number(match[3]);
  const hours = Number(match[4] || 0);
  const minutes = Number(match[5] || 0);
  const seconds = Number(match[6] || 0);

  const fecha = new Date(year, month, day, hours, minutes, seconds, 0);

  if (Number.isNaN(fecha.getTime())) {
    return null;
  }

  return fecha;
};

const obtenerIdTarea = (tarea) => {
  return limpiarTexto(
    tarea?.id ||
      tarea?.id_tarea ||
      tarea?.idActividad ||
      tarea?.id_actividad ||
      tarea?._id ||
      tarea?.folio ||
      tarea?.nombre ||
      tarea?.titulo ||
      `tarea-${Date.now()}`
  );
};

const obtenerTituloTarea = (tarea) => {
  return limpiarTexto(
    tarea?.titulo ||
      tarea?.nombre ||
      tarea?.actividad ||
      tarea?.descripcion ||
      'Tarea'
  ) || 'Tarea';
};

const obtenerFechaExpiracion = (tarea) => {
  return convertirFechaLocal(
    tarea?.fechaExpiracion ||
      tarea?.fecha_expiracion ||
      tarea?.fechaVencimiento ||
      tarea?.fecha_vencimiento ||
      tarea?.fechaFin ||
      tarea?.fecha_fin ||
      tarea?.vence ||
      tarea?.deadline ||
      tarea?.expira
  );
};

const eliminarStorageItem = async (key) => {
  try {
    if (storage.removeItem) {
      await storage.removeItem(key);
      return;
    }

    if (storage.deleteItem) {
      await storage.deleteItem(key);
      return;
    }

    await storage.setItem(key, '');
  } catch (error) {
    console.log(`Error eliminando ${key}:`, error.message);
  }
};

export const probarNotificacionLocal = async () => {
  try {
    const tienePermiso = await inicializarNotificaciones();

    if (!tienePermiso) {
      console.log('No se pudo probar notificación porque no hay permiso.');
      return null;
    }

    const id = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Prueba de notificación ✅',
        body: 'Si ves esto, las notificaciones locales ya funcionan.',
        sound: 'default',
        data: {
          tipo: 'prueba_notificacion',
        },
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: 2,
        channelId: CANAL_TAREAS,
      },
    });

    console.log('Notificación de prueba programada:', id);

    return id;
  } catch (error) {
    console.log('Error probando notificación local:', error);
    return null;
  }
};

export const cancelarNotificacionesTarea = async (idTarea) => {
  try {
    const idLimpio = limpiarTexto(idTarea);

    if (!idLimpio) {
      return;
    }

    const key = `notificaciones_tarea_${idLimpio}`;
    const guardadas = await storage.getItem(key);

    if (!guardadas) {
      return;
    }

    const ids = JSON.parse(guardadas);

    if (Array.isArray(ids)) {
      for (const id of ids) {
        if (id) {
          await Notifications.cancelScheduledNotificationAsync(id);
        }
      }
    }

    await eliminarStorageItem(key);
  } catch (error) {
    console.log('Error cancelando notificaciones de tarea:', error);
  }
};

export const programarNotificacionesTarea = async (tarea) => {
  try {
    const tienePermiso = await inicializarNotificaciones();

    if (!tienePermiso) {
      return {
        ok: false,
        ids: [],
        mensaje: 'No hay permiso para notificaciones.',
      };
    }

    const idTarea = obtenerIdTarea(tarea);
    const tituloTarea = obtenerTituloTarea(tarea);
    const fechaExpiracion = obtenerFechaExpiracion(tarea);

    await cancelarNotificacionesTarea(idTarea);

    const idsProgramados = [];
    const ahora = new Date();

    const idHabilitada = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Tarea habilitada ✅',
        body: `${tituloTarea} ya está activa.`,
        sound: 'default',
        data: {
          tipo: 'tarea_habilitada',
          idTarea,
        },
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: 2,
        channelId: CANAL_TAREAS,
      },
    });

    idsProgramados.push(idHabilitada);

    if (fechaExpiracion) {
      const tiempoExpiracion = fechaExpiracion.getTime();
      const diezMinutosAntes = new Date(tiempoExpiracion - 10 * 60 * 1000);

      if (diezMinutosAntes > ahora) {
        const idDiezMinutos = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tu tarea está por expirar ⏳',
            body: `${tituloTarea} vence en 10 minutos.`,
            sound: 'default',
            data: {
              tipo: 'tarea_10_minutos_antes',
              idTarea,
            },
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: diezMinutosAntes,
            channelId: CANAL_TAREAS,
          },
        });

        idsProgramados.push(idDiezMinutos);
      }

      if (fechaExpiracion > ahora) {
        const idExpirada = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tarea expirada ⚠️',
            body: `${tituloTarea} ya expiró.`,
            sound: 'default',
            data: {
              tipo: 'tarea_expirada',
              idTarea,
            },
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: fechaExpiracion,
            channelId: CANAL_TAREAS,
          },
        });

        idsProgramados.push(idExpirada);
      }
    }

    await storage.setItem(
      `notificaciones_tarea_${idTarea}`,
      JSON.stringify(idsProgramados)
    );

    console.log('Notificaciones programadas:', idsProgramados);

    return {
      ok: true,
      ids: idsProgramados,
      mensaje: 'Notificaciones programadas correctamente.',
    };
  } catch (error) {
    console.log('Error programando notificaciones de tarea:', error);

    return {
      ok: false,
      ids: [],
      mensaje: error.message,
    };
  }
};