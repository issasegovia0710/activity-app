import { Platform } from 'react-native';
import * as Device from 'expo-device';
import * as Notifications from 'expo-notifications';

import storage from '../config/storage';

const CANAL_TAREAS = 'activity-day-life-tareas';

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

const obtenerIdTarea = (tarea) => {
  return limpiarTexto(
    tarea?.id ||
      tarea?.id_tarea ||
      tarea?.idTarea ||
      tarea?._id ||
      tarea?.folio ||
      tarea?.nombre ||
      tarea?.titulo ||
      `tarea-${Date.now()}`
  );
};

const obtenerTituloTarea = (tarea) => {
  const titulo =
    tarea?.titulo ||
    tarea?.nombre ||
    tarea?.actividad ||
    tarea?.descripcion ||
    'Tarea';

  return limpiarTexto(titulo) || 'Tarea';
};

const obtenerFechaExpiracion = (tarea) => {
  const fechaDirecta =
    tarea?.fechaExpiracion ||
    tarea?.fecha_expiracion ||
    tarea?.fechaVencimiento ||
    tarea?.fecha_vencimiento ||
    tarea?.fechaFin ||
    tarea?.fecha_fin ||
    tarea?.vence ||
    tarea?.deadline ||
    tarea?.expira;

  const hora =
    tarea?.horaExpiracion ||
    tarea?.hora_expiracion ||
    tarea?.horaVencimiento ||
    tarea?.hora_vencimiento ||
    tarea?.horaFin ||
    tarea?.hora_fin;

  if (!fechaDirecta) {
    return null;
  }

  let textoFecha = limpiarTexto(fechaDirecta);

  if (hora && /^\d{4}-\d{2}-\d{2}$/.test(textoFecha)) {
    textoFecha = `${textoFecha} ${limpiarTexto(hora)}`;
  }

  textoFecha = textoFecha.replace(' ', 'T');

  const fecha = new Date(textoFecha);

  if (Number.isNaN(fecha.getTime())) {
    return null;
  }

  return fecha;
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

export const inicializarNotificaciones = async () => {
  try {
    if (Platform.OS === 'web') {
      console.log('Las notificaciones locales de Expo no se usan en web.');
      return false;
    }

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync(CANAL_TAREAS, {
        name: 'Tareas',
        importance: Notifications.AndroidImportance.MAX,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: '#5B4BF2',
        sound: 'default',
      });
    }

    if (!Device.isDevice) {
      console.log('Las notificaciones deben probarse en un dispositivo físico.');
      return false;
    }

    const permisosActuales = await Notifications.getPermissionsAsync();

    let estadoFinal = permisosActuales.status;

    if (estadoFinal !== 'granted') {
      const nuevosPermisos = await Notifications.requestPermissionsAsync();
      estadoFinal = nuevosPermisos.status;
    }

    if (estadoFinal !== 'granted') {
      console.log('Permiso de notificaciones denegado.');
      return false;
    }

    return true;
  } catch (error) {
    console.log('Error inicializando notificaciones:', error.message);
    return false;
  }
};

export const mostrarNotificacionInmediata = async ({
  titulo = 'Activity Day Life',
  cuerpo = '',
  data = {},
}) => {
  try {
    const permiso = await inicializarNotificaciones();

    if (!permiso) {
      return null;
    }

    const idNotificacion = await Notifications.scheduleNotificationAsync({
      content: {
        title: titulo,
        body: cuerpo,
        sound: true,
        data,
      },
      trigger: null,
    });

    return idNotificacion;
  } catch (error) {
    console.log('Error mostrando notificación inmediata:', error.message);
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
    console.log('Error cancelando notificaciones de tarea:', error.message);
  }
};

export const programarNotificacionesTarea = async (tarea, opciones = {}) => {
  try {
    const permiso = await inicializarNotificaciones();

    if (!permiso) {
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
    const ahora = Date.now();

    const notificarHabilitada = opciones.notificarHabilitada !== false;
    const notificarDiezMinutosAntes = opciones.notificarDiezMinutosAntes !== false;
    const notificarExpirada = opciones.notificarExpirada !== false;

    if (notificarHabilitada) {
      const idHabilitada = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Tarea habilitada ✅',
          body: `${tituloTarea} ya está activa.`,
          sound: true,
          data: {
            tipo: 'tarea_habilitada',
            idTarea,
            tarea,
          },
        },
        trigger: null,
      });

      idsProgramados.push(idHabilitada);
    }

    if (!fechaExpiracion) {
      await storage.setItem(
        `notificaciones_tarea_${idTarea}`,
        JSON.stringify(idsProgramados)
      );

      return {
        ok: true,
        ids: idsProgramados,
        mensaje: 'Se notificó tarea habilitada, pero no se encontró fecha de expiración.',
      };
    }

    const tiempoExpiracion = fechaExpiracion.getTime();
    const diezMinutosAntes = new Date(tiempoExpiracion - 10 * 60 * 1000);

    if (notificarDiezMinutosAntes) {
      if (diezMinutosAntes.getTime() > ahora) {
        const idDiezMinutos = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tu tarea está por expirar ⏳',
            body: `${tituloTarea} vence en 10 minutos.`,
            sound: true,
            data: {
              tipo: 'tarea_10_minutos_antes',
              idTarea,
              tarea,
            },
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: diezMinutosAntes,
            channelId: CANAL_TAREAS,
          },
        });

        idsProgramados.push(idDiezMinutos);
      } else if (tiempoExpiracion > ahora) {
        const idVencePronto = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tu tarea vence pronto ⏳',
            body: `${tituloTarea} vence en menos de 10 minutos.`,
            sound: true,
            data: {
              tipo: 'tarea_vence_pronto',
              idTarea,
              tarea,
            },
          },
          trigger: null,
        });

        idsProgramados.push(idVencePronto);
      }
    }

    if (notificarExpirada) {
      if (tiempoExpiracion > ahora) {
        const idExpirada = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tarea expirada ⚠️',
            body: `${tituloTarea} ya expiró.`,
            sound: true,
            data: {
              tipo: 'tarea_expirada',
              idTarea,
              tarea,
            },
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: fechaExpiracion,
            channelId: CANAL_TAREAS,
          },
        });

        idsProgramados.push(idExpirada);
      } else {
        const idYaExpirada = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Tarea expirada ⚠️',
            body: `${tituloTarea} ya estaba expirada.`,
            sound: true,
            data: {
              tipo: 'tarea_expirada',
              idTarea,
              tarea,
            },
          },
          trigger: null,
        });

        idsProgramados.push(idYaExpirada);
      }
    }

    await storage.setItem(
      `notificaciones_tarea_${idTarea}`,
      JSON.stringify(idsProgramados)
    );

    return {
      ok: true,
      ids: idsProgramados,
      mensaje: 'Notificaciones programadas correctamente.',
    };
  } catch (error) {
    console.log('Error programando notificaciones de tarea:', error.message);

    return {
      ok: false,
      ids: [],
      mensaje: error.message,
    };
  }
};