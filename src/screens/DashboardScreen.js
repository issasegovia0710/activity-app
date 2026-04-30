import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  SafeAreaView,
  TouchableOpacity,
  ScrollView,
  Animated,
  Dimensions,
  Easing,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import api from '../config/api';
import storage from '../config/storage';

const { width, height } = Dimensions.get('window');

const COLORES_TIPOS = [
  '#4F46E5',
  '#f59e0b',
  '#ec4899',
  '#14b8a6',
  '#7c3aed',
  '#0ea5e9',
  '#ef4444',
  '#16a34a',
];

const VEINTICUATRO_HORAS_MS = 24 * 60 * 60 * 1000;

export default function DashboardScreen({ usuario, onLogout, navigation, tema }) {
  const temaSeguro = tema || {
    fondo: '#312e81',
    primario: '#4F46E5',
    secundario: '#ec4899',
    tarjeta: '#ffffff',
    texto: '#1e293b',
    textoSuave: '#64748b',
    borde: '#c7d2fe',
    barraXp: '#f59e0b',
    peligro: '#ef4444',
    exito: '#16a34a',
    aviso: '#f59e0b',
    suavePrimario: '#eef2ff',
    suaveSecundario: '#fce7f3',
  };

  const [xpTotal, setXpTotal] = useState(Number(usuario?.exp || 0));
  const [nivelActual, setNivelActual] = useState(Number(usuario?.nivel || 1));
  const [nivelInfo, setNivelInfo] = useState(null);
  const [mostrarLevelUp, setMostrarLevelUp] = useState(false);

  const [misiones, setMisiones] = useState([]);
  const [cargandoMisiones, setCargandoMisiones] = useState(false);
  const [ahoraTick, setAhoraTick] = useState(new Date());

  const [mostrarConfirmLogout, setMostrarConfirmLogout] = useState(false);
  const [cerrandoSesion, setCerrandoSesion] = useState(false);

  const fadeAnim = useState(new Animated.Value(0))[0];
  const slideAnim = useState(new Animated.Value(35))[0];
  const headerScale = useState(new Animated.Value(0.94))[0];
  const floatAnim = useState(new Animated.Value(0))[0];
  const glowAnim = useState(new Animated.Value(0))[0];
  const runnerAnim = useState(new Animated.Value(0))[0];

  const levelUpOpacity = useState(new Animated.Value(0))[0];
  const levelUpScale = useState(new Animated.Value(0.7))[0];

  const logoutOverlayOpacity = useState(new Animated.Value(0))[0];
  const logoutCardScale = useState(new Animated.Value(0.82))[0];
  const logoutCardTranslateY = useState(new Animated.Value(30))[0];
  const logoutIconRotate = useState(new Animated.Value(0))[0];
  const logoutIconPulse = useState(new Animated.Value(1))[0];

  const progresoNivel = nivelInfo
    ? `${Number(nivelInfo.porcentaje || 0)}%`
    : '0%';

  const expParaSubir = nivelInfo
    ? Number(nivelInfo.exp_para_subir || 0)
    : 0;

  const misionesPendientes = misiones.filter(
    (mision) => mision.estatus === 'pendiente'
  ).length;

  const misionesEnProceso = misiones.filter(
    (mision) => mision.estadoTiempo === 'en_proceso'
  ).length;

  const misionesPorAbrir = misiones.filter(
    (mision) => mision.estadoTiempo === 'por_abrir'
  ).length;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 850,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 850,
        easing: Easing.out(Easing.back(1.25)),
        useNativeDriver: true,
      }),
      Animated.timing(headerScale, {
        toValue: 1,
        duration: 850,
        easing: Easing.out(Easing.back(1.2)),
        useNativeDriver: true,
      }),
    ]).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(floatAnim, {
          toValue: -10,
          duration: 1600,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(floatAnim, {
          toValue: 0,
          duration: 1600,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    ).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(glowAnim, {
          toValue: 1,
          duration: 1400,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: false,
        }),
        Animated.timing(glowAnim, {
          toValue: 0,
          duration: 1400,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: false,
        }),
      ])
    ).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(runnerAnim, {
          toValue: 1,
          duration: 650,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(runnerAnim, {
          toValue: 0,
          duration: 650,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [fadeAnim, slideAnim, headerScale, floatAnim, glowAnim, runnerAnim]);

  useEffect(() => {
    cargarNivelUsuario();
    cargarMisionesDelDia();
  }, []);

  useEffect(() => {
    const intervalo = setInterval(() => {
      setAhoraTick(new Date());
    }, 1000);

    return () => clearInterval(intervalo);
  }, []);

  useEffect(() => {
    setMisiones((misionesActuales) =>
      recalcularCuentasRegresivas(misionesActuales)
    );
  }, [ahoraTick]);

  const convertirFecha = (valor) => {
    if (!valor) return null;

    if (valor instanceof Date) {
      if (Number.isNaN(valor.getTime())) return null;
      return valor;
    }

    const fecha = new Date(String(valor).replace(' ', 'T'));

    if (Number.isNaN(fecha.getTime())) {
      return null;
    }

    return fecha;
  };

  const obtenerFechaKey = (fecha = new Date()) => {
    const year = fecha.getFullYear();
    const month = String(fecha.getMonth() + 1).padStart(2, '0');
    const day = String(fecha.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  };

  const esMismaFecha = (fechaA, fechaB) => {
    if (!fechaA || !fechaB) return false;

    return obtenerFechaKey(fechaA) === obtenerFechaKey(fechaB);
  };

  const formatearHora = (fecha) => {
    if (!fecha || Number.isNaN(fecha.getTime())) return null;

    const horas = String(fecha.getHours()).padStart(2, '0');
    const minutos = String(fecha.getMinutes()).padStart(2, '0');

    return `${horas}:${minutos}`;
  };

  const formatearFechaCorta = (fecha) => {
    if (!fecha || Number.isNaN(fecha.getTime())) return '';

    const day = String(fecha.getDate()).padStart(2, '0');
    const month = String(fecha.getMonth() + 1).padStart(2, '0');

    return `${day}/${month}`;
  };

  const formatearFechaHora = (fecha) => {
    if (!fecha || Number.isNaN(fecha.getTime())) return '--/-- --:--';

    const fechaTexto = formatearFechaCorta(fecha);
    const horaTexto = formatearHora(fecha);

    return `${fechaTexto} ${horaTexto}`;
  };

  const formatearCuentaRegresiva = (fechaObjetivo, fechaActual = new Date()) => {
    if (!fechaObjetivo) return '';

    const diferencia = fechaObjetivo.getTime() - fechaActual.getTime();

    if (diferencia <= 0) {
      return 'Ya abrió';
    }

    const horas = Math.floor(diferencia / (1000 * 60 * 60));
    const minutos = Math.floor((diferencia % (1000 * 60 * 60)) / (1000 * 60));
    const segundos = Math.floor((diferencia % (1000 * 60)) / 1000);

    return `${String(horas).padStart(2, '0')}:${String(minutos).padStart(2, '0')}:${String(segundos).padStart(2, '0')}`;
  };

  const obtenerColorPorTipo = (tipo) => {
    const texto = String(tipo || '').toLowerCase();
    let total = 0;

    for (let i = 0; i < texto.length; i += 1) {
      total += texto.charCodeAt(i);
    }

    return COLORES_TIPOS[total % COLORES_TIPOS.length];
  };

  const obtenerIconoPorTipo = (tipo) => {
    const texto = String(tipo || '').toLowerCase();

    if (texto.includes('vida') || texto.includes('diaria')) return 'home-outline';
    if (texto.includes('escuela') || texto.includes('estudio')) return 'school-outline';
    if (texto.includes('trabajo')) return 'briefcase-outline';
    if (texto.includes('salud')) return 'heart-outline';
    if (texto.includes('casa')) return 'construct-outline';

    return 'flag-outline';
  };

  const obtenerEstadoTiempo = (actividad, fechaInicio, fechaFin, ahora = new Date()) => {
    if (actividad.estatus === 'completada') return 'completada';
    if (actividad.estatus === 'no_cumplida') return 'no_cumplida';

    if (!fechaInicio) return 'sin_fecha';

    if (fechaInicio > ahora) {
      const diferencia = fechaInicio.getTime() - ahora.getTime();

      if (diferencia <= VEINTICUATRO_HORAS_MS) {
        return 'por_abrir';
      }

      return 'futura';
    }

    if (fechaInicio <= ahora && fechaFin && ahora <= fechaFin) {
      return 'en_proceso';
    }

    if (fechaFin && fechaFin < ahora) {
      return 'vencida';
    }

    if (fechaInicio < ahora && !fechaFin) {
      return 'atrasada';
    }

    return 'activa';
  };

  const debeMostrarseEnDashboard = (actividad) => {
    const fechaInicio = convertirFecha(actividad.fecha_inicio);
    const ahora = new Date();

    if (!fechaInicio) return false;

    if (actividad.estatus === 'completada' || actividad.estatus === 'no_cumplida') {
      return esMismaFecha(fechaInicio, ahora);
    }

    if (actividad.estatus !== 'pendiente') {
      return false;
    }

    if (fechaInicio < ahora) {
      return true;
    }

    if (esMismaFecha(fechaInicio, ahora)) {
      return true;
    }

    const diferencia = fechaInicio.getTime() - ahora.getTime();

    if (diferencia > 0 && diferencia <= VEINTICUATRO_HORAS_MS) {
      return true;
    }

    return false;
  };

  const mapearActividadAMision = (actividad) => {
    const fechaInicio = convertirFecha(actividad.fecha_inicio);
    const fechaFin = convertirFecha(actividad.fecha_fin);
    const ahora = new Date();
    const estadoTiempo = obtenerEstadoTiempo(actividad, fechaInicio, fechaFin, ahora);

    return {
      ...actividad,
      titulo: actividad.nombre,
      categoria: actividad.tipo || 'Sin categoría',
      xp: Number(actividad.valor_exp || 0),
      color: obtenerColorPorTipo(actividad.tipo),
      icono: obtenerIconoPorTipo(actividad.tipo),
      completada: actividad.estatus === 'completada',
      noCumplida: actividad.estatus === 'no_cumplida',
      fechaInicio,
      fechaFin,
      fechaInicioTexto: formatearFechaHora(fechaInicio),
      fechaFinTexto: formatearFechaHora(fechaFin),
      fechaCorta: formatearFechaCorta(fechaInicio),
      horaInicio: formatearHora(fechaInicio),
      horaFinal: formatearHora(fechaFin),
      vencida: estadoTiempo === 'vencida',
      atrasada: estadoTiempo === 'atrasada',
      enProceso: estadoTiempo === 'en_proceso',
      porAbrir: estadoTiempo === 'por_abrir',
      estadoTiempo,
      cuentaRegresiva: estadoTiempo === 'por_abrir'
        ? formatearCuentaRegresiva(fechaInicio, ahoraTick)
        : '',
      penalizacion: Math.ceil(Number(actividad.valor_exp || 0) / 2),
    };
  };

  const ordenarMisiones = (misionesLista) => {
    const pesoEstado = {
      vencida: 1,
      atrasada: 2,
      en_proceso: 3,
      activa: 4,
      por_abrir: 5,
      completada: 6,
      no_cumplida: 7,
      futura: 8,
      sin_fecha: 9,
    };

    return [...misionesLista].sort((a, b) => {
      const pesoA = pesoEstado[a.estadoTiempo] || 99;
      const pesoB = pesoEstado[b.estadoTiempo] || 99;

      if (pesoA !== pesoB) {
        return pesoA - pesoB;
      }

      const tiempoA = a.fechaInicio ? a.fechaInicio.getTime() : 0;
      const tiempoB = b.fechaInicio ? b.fechaInicio.getTime() : 0;

      return tiempoA - tiempoB;
    });
  };

  const obtenerMisionesParaDashboard = (actividades) => {
    return ordenarMisiones(
      actividades
        .filter(debeMostrarseEnDashboard)
        .map(mapearActividadAMision)
    );
  };

  const recalcularCuentasRegresivas = (misionesActuales) => {
    return misionesActuales.map((mision) => {
      const fechaInicio = convertirFecha(mision.fecha_inicio);
      const fechaFin = convertirFecha(mision.fecha_fin);
      const estadoTiempo = obtenerEstadoTiempo(mision, fechaInicio, fechaFin, ahoraTick);

      return {
        ...mision,
        fechaInicio,
        fechaFin,
        fechaInicioTexto: formatearFechaHora(fechaInicio),
        fechaFinTexto: formatearFechaHora(fechaFin),
        estadoTiempo,
        vencida: estadoTiempo === 'vencida',
        atrasada: estadoTiempo === 'atrasada',
        enProceso: estadoTiempo === 'en_proceso',
        porAbrir: estadoTiempo === 'por_abrir',
        cuentaRegresiva: estadoTiempo === 'por_abrir'
          ? formatearCuentaRegresiva(fechaInicio, ahoraTick)
          : '',
      };
    });
  };

  const actualizarUsuarioEnStorage = async (usuarioActualizado) => {
    try {
      if (!usuarioActualizado) return;

      await storage.setItem('usuario', JSON.stringify(usuarioActualizado));
    } catch (error) {
      console.log('No se pudo actualizar usuario en storage:', error.message);
    }
  };

  const mostrarAnimacionLevelUp = () => {
    setMostrarLevelUp(true);
    levelUpOpacity.setValue(0);
    levelUpScale.setValue(0.7);

    Animated.parallel([
      Animated.timing(levelUpOpacity, {
        toValue: 1,
        duration: 350,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.spring(levelUpScale, {
        toValue: 1,
        friction: 4,
        tension: 70,
        useNativeDriver: true,
      }),
    ]).start(() => {
      setTimeout(() => {
        Animated.parallel([
          Animated.timing(levelUpOpacity, {
            toValue: 0,
            duration: 350,
            easing: Easing.in(Easing.ease),
            useNativeDriver: true,
          }),
          Animated.timing(levelUpScale, {
            toValue: 0.8,
            duration: 350,
            easing: Easing.in(Easing.ease),
            useNativeDriver: true,
          }),
        ]).start(() => {
          setMostrarLevelUp(false);
        });
      }, 1700);
    });
  };

  const cargarNivelUsuario = async () => {
    try {
      const response = await api.get('/auth/nivel');

      if (response.data?.usuario) {
        setXpTotal(Number(response.data.usuario.exp || 0));
        setNivelActual(Number(response.data.usuario.nivel || 1));
        setNivelInfo(response.data.nivel_info || null);

        await actualizarUsuarioEnStorage(response.data.usuario);
      }
    } catch (error) {
      console.log('Error al cargar nivel:', error.response?.data || error.message);
    }
  };

  const guardarExpEnBackend = async (nuevoExp) => {
    const response = await api.put('/auth/exp', {
      exp: Number(nuevoExp),
    });

    if (response.data?.usuario) {
      const usuarioActualizado = response.data.usuario;

      setXpTotal(Number(usuarioActualizado.exp || 0));
      setNivelActual(Number(usuarioActualizado.nivel || 1));
      setNivelInfo(response.data.nivel_info || null);

      await actualizarUsuarioEnStorage(usuarioActualizado);

      if (response.data.subio_nivel) {
        mostrarAnimacionLevelUp();
      }
    }

    return response.data;
  };

  const guardarActividadEnBackend = async (actividadActualizada) => {
    await api.put(`/actividades/${actividadActualizada.id}`, {
      nombre: actividadActualizada.nombre,
      descripcion: actividadActualizada.descripcion || null,
      tipo: actividadActualizada.tipo || null,
      prioridad: actividadActualizada.prioridad || 'media',
      valor_exp: Number(actividadActualizada.valor_exp || 0),
      duracion_horas:
        actividadActualizada.duracion_horas === undefined ||
        actividadActualizada.duracion_horas === null ||
        actividadActualizada.duracion_horas === ''
          ? null
          : Number(actividadActualizada.duracion_horas),
      fecha_inicio: actividadActualizada.fecha_inicio,
      actividad_autoacompletable: Number(
        actividadActualizada.actividad_autoacompletable || 0
      ),
      repetecion: actividadActualizada.repetecion || null,
      estatus: actividadActualizada.estatus || 'pendiente',
      auxiliar: actividadActualizada.auxiliar || null,
    });
  };

  const procesarVencidasEnBackend = async () => {
    try {
      await api.post('/actividades/procesar-vencidas');
      await cargarNivelUsuario();
    } catch (error) {
      console.log(
        'Error al procesar vencidas:',
        error.response?.data || error.message
      );
    }
  };

  const cargarMisionesDelDia = async () => {
    try {
      setCargandoMisiones(true);

      await procesarVencidasEnBackend();

      const response = await api.get('/actividades');
      const actividades = response.data?.actividades || [];
      const misionesDashboard = obtenerMisionesParaDashboard(actividades);

      setMisiones(misionesDashboard);
    } catch (error) {
      console.log(
        'Error al cargar misiones del dashboard:',
        error.response?.data || error.message
      );

      Alert.alert(
        'Error',
        error.response?.data?.mensaje ||
        'No se pudieron cargar las misiones del dashboard.'
      );
    } finally {
      setCargandoMisiones(false);
    }
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
      console.log(`No se pudo eliminar ${key}:`, error.message);
    }
  };

  const iniciarAnimacionConfirmLogout = () => {
    setMostrarConfirmLogout(true);
    setCerrandoSesion(false);

    logoutOverlayOpacity.setValue(0);
    logoutCardScale.setValue(0.82);
    logoutCardTranslateY.setValue(30);
    logoutIconRotate.setValue(0);
    logoutIconPulse.setValue(1);

    Animated.parallel([
      Animated.timing(logoutOverlayOpacity, {
        toValue: 1,
        duration: 260,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.spring(logoutCardScale, {
        toValue: 1,
        friction: 5,
        tension: 80,
        useNativeDriver: true,
      }),
      Animated.timing(logoutCardTranslateY, {
        toValue: 0,
        duration: 280,
        easing: Easing.out(Easing.back(1.2)),
        useNativeDriver: true,
      }),
    ]).start();
  };

  const cancelarCerrarSesion = () => {
    Animated.parallel([
      Animated.timing(logoutOverlayOpacity, {
        toValue: 0,
        duration: 200,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(logoutCardScale, {
        toValue: 0.86,
        duration: 200,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(logoutCardTranslateY, {
        toValue: 22,
        duration: 200,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
    ]).start(() => {
      setMostrarConfirmLogout(false);
      setCerrandoSesion(false);
    });
  };

  const ejecutarAnimacionCierre = () => {
    setCerrandoSesion(true);

    Animated.loop(
      Animated.sequence([
        Animated.timing(logoutIconPulse, {
          toValue: 1.12,
          duration: 360,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(logoutIconPulse, {
          toValue: 1,
          duration: 360,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ]),
      { iterations: 2 }
    ).start();

    Animated.timing(logoutIconRotate, {
      toValue: 1,
      duration: 900,
      easing: Easing.inOut(Easing.ease),
      useNativeDriver: true,
    }).start();
  };

  const cerrarSesion = async () => {
    try {
      ejecutarAnimacionCierre();

      await new Promise((resolve) => setTimeout(resolve, 950));

      await eliminarStorageItem('token');
      await eliminarStorageItem('usuario');

      if (api.defaults?.headers?.common?.Authorization) {
        delete api.defaults.headers.common.Authorization;
      }

      setMisiones([]);
      setNivelInfo(null);
      setXpTotal(0);
      setNivelActual(1);

      if (onLogout) {
        await onLogout();
      }
    } catch (error) {
      console.log('Error al cerrar sesión:', error.message);

      if (onLogout) {
        await onLogout();
      }
    }
  };

  const navegarAScreen = (screenName) => {
    if (!navigation || !navigation.navigate) {
      Alert.alert(
        'Navegación no disponible',
        'Revisa que DashboardScreen esté conectado con App.js.'
      );
      return;
    }

    navigation.navigate(screenName, {
      usuario,
      xpTotal,
      nivelActual,
      nivelInfo,
      misiones,
    });
  };

  const completarMision = async (misionSeleccionada) => {
    if (!misionSeleccionada || misionSeleccionada.estatus !== 'pendiente') {
      return;
    }

    try {
      const nuevoXp =
        Number(xpTotal || 0) + Number(misionSeleccionada.valor_exp || 0);

      await api.put(`/actividades/${misionSeleccionada.id}/completar`);
      await guardarExpEnBackend(nuevoXp);

      Alert.alert(
        'Misión completada',
        `Ganaste ${Number(misionSeleccionada.valor_exp || 0)} puntos de experiencia.`
      );

      cargarMisionesDelDia();
    } catch (error) {
      console.log('Error al completar misión:', error.response?.data || error.message);

      Alert.alert(
        'Error',
        error.response?.data?.mensaje ||
        'No se pudo completar la misión.'
      );
    }
  };

  const glowBorderColor = glowAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [temaSeguro.borde || '#c7d2fe', temaSeguro.primario || '#818cf8'],
  });

  const runnerTranslateY = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -5],
  });

  const runnerRotate = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['-3deg', '3deg'],
  });

  const logoutRotation = logoutIconRotate.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: temaSeguro.fondo }]}>
      <View style={styles.backgroundDecorations}>
        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleOne,
            {
              backgroundColor: `${temaSeguro.primario}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="star" size={24} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleTwo,
            {
              backgroundColor: `${temaSeguro.barraXp}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="flash" size={24} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleThree,
            {
              backgroundColor: `${temaSeguro.secundario}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="diamond" size={25} color="#ffffff" />
        </Animated.View>

        <View
          style={[
            styles.circleLarge,
            { backgroundColor: `${temaSeguro.primario}55` },
          ]}
        />

        <View
          style={[
            styles.circleSmall,
            { backgroundColor: `${temaSeguro.secundario}33` },
          ]}
        />
      </View>

      <Animated.View
        style={[
          styles.mainContent,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }],
          },
        ]}
      >
        <Animated.View
          style={[
            styles.headerCard,
            {
              borderColor: glowBorderColor,
              transform: [{ scale: headerScale }],
            },
          ]}
        >
          <View style={styles.headerTop}>
            <View style={styles.userInfo}>
              <View
                style={[
                  styles.avatarBox,
                  {
                    backgroundColor: temaSeguro.primario,
                    borderColor: temaSeguro.borde,
                  },
                ]}
              >
                <Animated.View
                  style={[
                    styles.avatarRunner,
                    {
                      transform: [
                        { translateY: runnerTranslateY },
                        { rotate: runnerRotate },
                      ],
                    },
                  ]}
                >
                  <Ionicons name="walk" size={34} color="#ffffff" />
                </Animated.View>
              </View>

              <View style={styles.nameBlock}>
                <Text style={styles.usernameText}>
                  {usuario?.nombre_usuario || 'Jugador'}
                </Text>

                <View style={styles.userLevelRow}>
                  <Ionicons name="flash" size={14} color={temaSeguro.barraXp} />
                  <Text style={styles.userLevelText}>
                    Nivel {nivelActual} • {xpTotal} XP total
                  </Text>
                </View>

                <Text style={styles.userLevelSubText}>
                  {expParaSubir > 0
                    ? `Faltan ${expParaSubir} XP para el siguiente nivel`
                    : 'Nivel máximo alcanzado'}
                </Text>
              </View>
            </View>

            <TouchableOpacity
              style={[
                styles.logoutButton,
                {
                  backgroundColor: temaSeguro.peligro,
                  shadowColor: temaSeguro.peligro,
                },
              ]}
              onPress={iniciarAnimacionConfirmLogout}
              activeOpacity={0.8}
            >
              <Ionicons name="log-out-outline" size={22} color="#ffffff" />
            </TouchableOpacity>
          </View>

          <View style={styles.compactXpBarBackground}>
            <View
              style={[
                styles.compactXpBarFill,
                {
                  width: progresoNivel,
                  backgroundColor: temaSeguro.barraXp,
                },
              ]}
            />
          </View>

          <View style={styles.missionsSummaryRow}>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryNumber}>{misionesPendientes}</Text>
              <Text style={styles.summaryLabel}>Pendientes</Text>
            </View>

            <View style={styles.summaryCard}>
              <Text style={styles.summaryNumber}>{misionesEnProceso}</Text>
              <Text style={styles.summaryLabel}>En proceso</Text>
            </View>

            <View style={styles.summaryCard}>
              <Text style={styles.summaryNumber}>{misionesPorAbrir}</Text>
              <Text style={styles.summaryLabel}>Próximas</Text>
            </View>
          </View>
        </Animated.View>

        <View style={styles.tabsRow}>
          <ScreenButton
            title="Misiones"
            icon="flag-outline"
            color={temaSeguro.primario}
            onPress={() => navegarAScreen('Misiones')}
          />

          <ScreenButton
            title="Estadísticas"
            icon="bar-chart-outline"
            color={temaSeguro.aviso}
            onPress={() => navegarAScreen('Estadisticas')}
          />

          <ScreenButton
            title="Ajustes"
            icon="settings-outline"
            color={temaSeguro.secundario}
            onPress={() => navegarAScreen('Ajustes')}
          />
        </View>

        <View style={styles.panelHeader}>
          <View>
            <Text style={styles.panelTitle}>Misiones activas</Text>
            <Text style={styles.panelSubtitle}>
              Pendientes, del día y próximas 24 horas
            </Text>
          </View>

          <TouchableOpacity
            style={styles.panelIcon}
            onPress={cargarMisionesDelDia}
            activeOpacity={0.85}
          >
            <Ionicons name="refresh-outline" size={24} color={temaSeguro.primario} />
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.scrollArea}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {cargandoMisiones ? (
            <View style={styles.loadingBox}>
              <ActivityIndicator color="#ffffff" />
              <Text style={styles.loadingText}>Cargando misiones...</Text>
            </View>
          ) : misiones.length === 0 ? (
            <View style={styles.emptyBox}>
              <Ionicons name="moon-outline" size={42} color="#ffffff" />
              <Text style={styles.emptyTitle}>Sin misiones visibles</Text>
              <Text style={styles.emptyText}>
                No hay misiones pendientes, del día ni próximas en 24 horas.
              </Text>
            </View>
          ) : (
            misiones.map((mision, index) => (
              <AnimatedMissionCard
                key={mision.id}
                mision={mision}
                index={index}
                onComplete={() => completarMision(mision)}
              />
            ))
          )}

          <View style={styles.bottomSpace} />
        </ScrollView>
      </Animated.View>

      {mostrarLevelUp ? (
        <Animated.View
          style={[
            styles.levelUpOverlay,
            {
              opacity: levelUpOpacity,
            },
          ]}
        >
          <Animated.View
            style={[
              styles.levelUpCard,
              {
                transform: [{ scale: levelUpScale }],
              },
            ]}
          >
            <View style={[styles.levelUpIcon, { backgroundColor: temaSeguro.barraXp }]}>
              <Ionicons name="trophy" size={52} color="#ffffff" />
            </View>

            <Text style={styles.levelUpTitle}>¡Subiste de nivel!</Text>
            <Text style={styles.levelUpText}>Ahora eres nivel {nivelActual}</Text>

            <View style={styles.levelUpSparkRow}>
              <Ionicons name="star" size={20} color="#facc15" />
              <Ionicons name="sparkles" size={24} color="#facc15" />
              <Ionicons name="star" size={20} color="#facc15" />
            </View>
          </Animated.View>
        </Animated.View>
      ) : null}

      {mostrarConfirmLogout ? (
        <Animated.View
          style={[
            styles.logoutOverlay,
            {
              opacity: logoutOverlayOpacity,
            },
          ]}
        >
          <Animated.View
            style={[
              styles.logoutConfirmCard,
              {
                transform: [
                  { scale: logoutCardScale },
                  { translateY: logoutCardTranslateY },
                ],
              },
            ]}
          >
            <Animated.View
              style={[
                styles.logoutConfirmIcon,
                {
                  backgroundColor: temaSeguro.peligro,
                  transform: [
                    { rotate: logoutRotation },
                    { scale: logoutIconPulse },
                  ],
                },
              ]}
            >
              <Ionicons
                name={cerrandoSesion ? 'sync-outline' : 'log-out-outline'}
                size={44}
                color="#ffffff"
              />
            </Animated.View>

            <Text style={styles.logoutConfirmTitle}>
              {cerrandoSesion ? 'Cerrando sesión...' : '¿Cerrar sesión?'}
            </Text>

            <Text style={styles.logoutConfirmText}>
              {cerrandoSesion
                ? 'Guardando salida y limpiando tu sesión.'
                : 'Tu avance queda guardado. Para volver tendrás que iniciar sesión de nuevo.'}
            </Text>

            {cerrandoSesion ? (
              <View style={styles.logoutLoadingBox}>
                <ActivityIndicator color={temaSeguro.peligro} />
                <Text style={styles.logoutLoadingText}>Saliendo del tablero</Text>
              </View>
            ) : (
              <View style={styles.logoutActionsRow}>
                <TouchableOpacity
                  style={styles.logoutCancelButton}
                  onPress={cancelarCerrarSesion}
                  activeOpacity={0.85}
                >
                  <Text style={styles.logoutCancelText}>Cancelar</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[
                    styles.logoutAcceptButton,
                    {
                      backgroundColor: temaSeguro.peligro,
                      shadowColor: temaSeguro.peligro,
                    },
                  ]}
                  onPress={cerrarSesion}
                  activeOpacity={0.85}
                >
                  <Ionicons name="log-out-outline" size={18} color="#ffffff" />
                  <Text style={styles.logoutAcceptText}>Salir</Text>
                </TouchableOpacity>
              </View>
            )}
          </Animated.View>
        </Animated.View>
      ) : null}
    </SafeAreaView>
  );
}

function ScreenButton({ title, icon, color, onPress }) {
  const scaleAnim = useState(new Animated.Value(1))[0];

  const pressIn = () => {
    Animated.spring(scaleAnim, {
      toValue: 0.94,
      useNativeDriver: true,
      speed: 30,
      bounciness: 4,
    }).start();
  };

  const pressOut = () => {
    Animated.spring(scaleAnim, {
      toValue: 1,
      useNativeDriver: true,
      speed: 25,
      bounciness: 7,
    }).start();
  };

  return (
    <Animated.View style={[styles.tabButtonWrap, { transform: [{ scale: scaleAnim }] }]}>
      <TouchableOpacity
        style={styles.tabButton}
        onPress={onPress}
        onPressIn={pressIn}
        onPressOut={pressOut}
        activeOpacity={0.9}
      >
        <View style={[styles.tabIconBox, { backgroundColor: color }]}>
          <Ionicons name={icon} size={22} color="#ffffff" />
        </View>

        <Text style={styles.tabButtonText}>{title}</Text>
      </TouchableOpacity>
    </Animated.View>
  );
}

function AnimatedMissionCard({ mision, index, onComplete }) {
  const cardFade = useState(new Animated.Value(0))[0];
  const cardSlide = useState(new Animated.Value(35))[0];
  const cardScale = useState(new Animated.Value(1))[0];

  useEffect(() => {
    Animated.sequence([
      Animated.delay(index * 100),
      Animated.parallel([
        Animated.timing(cardFade, {
          toValue: 1,
          duration: 450,
          easing: Easing.out(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(cardSlide, {
          toValue: 0,
          duration: 450,
          easing: Easing.out(Easing.back(1.12)),
          useNativeDriver: true,
        }),
      ]),
    ]).start();
  }, [cardFade, cardSlide, index]);

  const pressIn = () => {
    Animated.spring(cardScale, {
      toValue: 0.97,
      useNativeDriver: true,
      speed: 25,
      bounciness: 4,
    }).start();
  };

  const pressOut = () => {
    Animated.spring(cardScale, {
      toValue: 1,
      useNativeDriver: true,
      speed: 25,
      bounciness: 6,
    }).start();
  };

  const completada = mision.estatus === 'completada';
  const noCumplida = mision.estatus === 'no_cumplida';
  const porAbrir = mision.estadoTiempo === 'por_abrir';
  const atrasada = mision.estadoTiempo === 'atrasada';
  const vencida = mision.estadoTiempo === 'vencida';
  const enProceso = mision.estadoTiempo === 'en_proceso';

  const obtenerTextoEstado = () => {
    if (completada) return 'Terminada';
    if (noCumplida) return 'No cumplida';
    if (vencida) return 'Vencida';
    if (atrasada) return 'Atrasada';
    if (enProceso) return 'En proceso';
    if (porAbrir) return 'Abre pronto';
    return 'Activa';
  };

  return (
    <Animated.View
      style={[
        styles.missionCardAnimated,
        {
          opacity: cardFade,
          transform: [{ translateY: cardSlide }, { scale: cardScale }],
        },
      ]}
    >
      <TouchableOpacity
        style={[
          styles.missionCard,
          completada && styles.missionCardCompleted,
          noCumplida && styles.missionCardLate,
          vencida && styles.missionCardLate,
          atrasada && styles.missionCardWarning,
          enProceso && styles.missionCardProcess,
          porAbrir && styles.missionCardSoon,
        ]}
        activeOpacity={0.9}
        onPressIn={pressIn}
        onPressOut={pressOut}
      >
        <View style={[styles.missionIconBox, { backgroundColor: mision.color }]}>
          <Ionicons name={mision.icono} size={25} color="#ffffff" />
        </View>

        <View style={styles.missionContent}>
          <View style={styles.missionTopRow}>
            <Text style={styles.missionCategory}>{mision.categoria}</Text>

            <View
              style={[
                styles.missionStatusBadge,
                completada && styles.missionStatusBadgeDone,
                noCumplida && styles.missionStatusBadgeLate,
                vencida && styles.missionStatusBadgeLate,
                atrasada && styles.missionStatusBadgeWarning,
                enProceso && styles.missionStatusBadgeProcess,
                porAbrir && styles.missionStatusBadgeSoon,
              ]}
            >
              <Text
                style={[
                  styles.missionStatusText,
                  completada && styles.missionStatusTextDone,
                  noCumplida && styles.missionStatusTextLate,
                  vencida && styles.missionStatusTextLate,
                  atrasada && styles.missionStatusTextWarning,
                  enProceso && styles.missionStatusTextProcess,
                  porAbrir && styles.missionStatusTextSoon,
                ]}
              >
                {obtenerTextoEstado()}
              </Text>
            </View>
          </View>

          <Text style={styles.missionTitle}>{mision.titulo}</Text>
          <Text style={styles.missionDescription}>
            {mision.descripcion || 'Sin descripción'}
          </Text>

          <View style={styles.scheduleBox}>
            <Ionicons name="calendar-outline" size={15} color="#6366f1" />
            <Text style={styles.scheduleText}>
              Inicio {mision.fechaInicioTexto || '--/-- --:--'}
            </Text>
          </View>

          <View style={styles.scheduleBox}>
            <Ionicons name="flag-outline" size={15} color="#6366f1" />
            <Text style={styles.scheduleText}>
              Final {mision.fechaFinTexto || '--/-- --:--'}
            </Text>
          </View>

          {enProceso ? (
            <View style={styles.processBox}>
              <Ionicons name="play-circle-outline" size={16} color="#047857" />
              <Text style={styles.processText}>
                La misión está dentro de su rango de tiempo.
              </Text>
            </View>
          ) : null}

          {porAbrir ? (
            <View style={styles.countdownBox}>
              <Ionicons name="hourglass-outline" size={16} color="#0369a1" />
              <Text style={styles.countdownText}>
                Abre en {mision.cuentaRegresiva}
              </Text>
            </View>
          ) : null}

          {atrasada ? (
            <View style={styles.warningBox}>
              <Ionicons name="alert-circle-outline" size={16} color="#92400e" />
              <Text style={styles.warningText}>
                Ya inició, todavía puedes cumplirla.
              </Text>
            </View>
          ) : null}

          {noCumplida ? (
            <View style={styles.penaltyBox}>
              <Ionicons name="warning-outline" size={16} color="#b91c1c" />
              <Text style={styles.penaltyText}>
                No cumplida. Penalización: -{mision.penalizacion} XP
              </Text>
            </View>
          ) : null}

          {vencida && !noCumplida ? (
            <View style={styles.penaltyBox}>
              <Ionicons name="warning-outline" size={16} color="#b91c1c" />
              <Text style={styles.penaltyText}>
                Vencida. Si es autoacompletable, se cerrará al actualizar.
              </Text>
            </View>
          ) : null}

          <View style={styles.missionBottomRow}>
            <View style={styles.missionXpBox}>
              <Ionicons name="flash-outline" size={15} color="#f59e0b" />
              <Text style={styles.missionXpText}>+{mision.xp} XP</Text>
            </View>

            <TouchableOpacity
              style={[
                styles.completeButton,
                completada && styles.completeButtonDone,
                noCumplida && styles.completeButtonDisabled,
                porAbrir && styles.completeButtonLocked,
              ]}
              onPress={onComplete}
              disabled={completada || noCumplida || porAbrir}
              activeOpacity={0.85}
            >
              <Ionicons
                name={
                  completada
                    ? 'checkmark-done'
                    : noCumplida
                      ? 'close'
                      : porAbrir
                        ? 'lock-closed-outline'
                        : 'checkmark'
                }
                size={18}
                color="#ffffff"
              />

              <Text style={styles.completeButtonText}>
                {completada
                  ? 'Lista'
                  : noCumplida
                    ? 'Cerrada'
                    : porAbrir
                      ? 'Bloqueada'
                      : 'Completar'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#312e81',
    overflow: 'hidden',
  },
  backgroundDecorations: {
    position: 'absolute',
    width,
    height,
    top: 0,
    left: 0,
  },
  bubble: {
    position: 'absolute',
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: 'rgba(255, 255, 255, 0.14)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  bubbleOne: {
    top: height * 0.08,
    left: width * 0.08,
  },
  bubbleTwo: {
    top: height * 0.15,
    right: width * 0.1,
    backgroundColor: 'rgba(250, 204, 21, 0.2)',
  },
  bubbleThree: {
    bottom: height * 0.1,
    left: width * 0.12,
    backgroundColor: 'rgba(45, 212, 191, 0.17)',
  },
  circleLarge: {
    position: 'absolute',
    width: 280,
    height: 280,
    borderRadius: 140,
    backgroundColor: 'rgba(99, 102, 241, 0.32)',
    top: -95,
    right: -90,
  },
  circleSmall: {
    position: 'absolute',
    width: 190,
    height: 190,
    borderRadius: 95,
    backgroundColor: 'rgba(236, 72, 153, 0.16)',
    bottom: -45,
    right: 15,
  },
  mainContent: {
    flex: 1,
    paddingHorizontal: 18,
    paddingTop: 18,
  },
  headerCard: {
    backgroundColor: '#ffffff',
    borderRadius: 26,
    padding: 16,
    borderWidth: 2,
    shadowColor: '#818cf8',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.25,
    shadowRadius: 22,
    elevation: 10,
  },
  headerTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  avatarBox: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 4,
    borderColor: '#ede9fe',
  },
  avatarRunner: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  nameBlock: {
    flex: 1,
  },
  usernameText: {
    fontSize: 24,
    color: '#1e293b',
    fontWeight: '900',
  },
  userLevelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  userLevelText: {
    color: '#64748b',
    fontSize: 13,
    fontWeight: '800',
    marginLeft: 4,
  },
  userLevelSubText: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '800',
    marginTop: 2,
  },
  logoutButton: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.28,
    shadowRadius: 10,
    elevation: 5,
  },
  compactXpBarBackground: {
    height: 10,
    backgroundColor: '#e2e8f0',
    borderRadius: 999,
    overflow: 'hidden',
    marginTop: 14,
  },
  compactXpBarFill: {
    height: '100%',
    backgroundColor: '#f59e0b',
    borderRadius: 999,
  },
  missionsSummaryRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: '#f8fafc',
    borderRadius: 18,
    paddingVertical: 11,
    alignItems: 'center',
  },
  summaryNumber: {
    color: '#1e293b',
    fontSize: 21,
    fontWeight: '900',
  },
  summaryLabel: {
    color: '#64748b',
    fontSize: 10,
    fontWeight: '900',
    marginTop: 2,
  },
  tabsRow: {
    flexDirection: 'row',
    marginTop: 14,
    gap: 10,
  },
  tabButtonWrap: {
    flex: 1,
  },
  tabButton: {
    backgroundColor: '#ffffff',
    borderRadius: 20,
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: 'center',
    minHeight: 82,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 14,
    elevation: 5,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  tabIconBox: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 7,
  },
  tabButtonText: {
    color: '#1e293b',
    fontSize: 11,
    fontWeight: '900',
    textAlign: 'center',
  },
  panelHeader: {
    marginTop: 16,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  panelTitle: {
    color: '#ffffff',
    fontSize: 23,
    fontWeight: '900',
  },
  panelSubtitle: {
    color: '#c7d2fe',
    fontSize: 13,
    fontWeight: '700',
    marginTop: 3,
  },
  panelIcon: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollArea: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 28,
  },
  loadingBox: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  loadingText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '800',
    marginTop: 10,
  },
  emptyBox: {
    backgroundColor: 'rgba(255, 255, 255, 0.14)',
    borderRadius: 24,
    padding: 24,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.22)',
  },
  emptyTitle: {
    color: '#ffffff',
    fontSize: 22,
    fontWeight: '900',
    marginTop: 12,
  },
  emptyText: {
    color: '#c7d2fe',
    fontSize: 13,
    fontWeight: '700',
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 19,
  },
  missionCardAnimated: {
    marginBottom: 14,
  },
  missionCard: {
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 16,
    flexDirection: 'row',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  missionCardCompleted: {
    opacity: 0.75,
  },
  missionCardLate: {
    backgroundColor: '#fff1f2',
    borderWidth: 1.5,
    borderColor: '#fecdd3',
  },
  missionCardWarning: {
    backgroundColor: '#fffbeb',
    borderWidth: 1.5,
    borderColor: '#fde68a',
  },
  missionCardProcess: {
    backgroundColor: '#ecfdf5',
    borderWidth: 1.5,
    borderColor: '#bbf7d0',
  },
  missionCardSoon: {
    backgroundColor: '#eff6ff',
    borderWidth: 1.5,
    borderColor: '#bfdbfe',
  },
  missionIconBox: {
    width: 58,
    height: 58,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
    borderWidth: 3,
    borderColor: '#f8fafc',
  },
  missionContent: {
    flex: 1,
  },
  missionTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  missionCategory: {
    fontSize: 12,
    color: '#64748b',
    fontWeight: '900',
    textTransform: 'uppercase',
  },
  missionStatusBadge: {
    backgroundColor: '#eef2ff',
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  missionStatusBadgeDone: {
    backgroundColor: '#dcfce7',
  },
  missionStatusBadgeLate: {
    backgroundColor: '#fee2e2',
  },
  missionStatusBadgeWarning: {
    backgroundColor: '#fef3c7',
  },
  missionStatusBadgeProcess: {
    backgroundColor: '#d1fae5',
  },
  missionStatusBadgeSoon: {
    backgroundColor: '#dbeafe',
  },
  missionStatusText: {
    fontSize: 10,
    color: '#4F46E5',
    fontWeight: '900',
  },
  missionStatusTextDone: {
    color: '#16a34a',
  },
  missionStatusTextLate: {
    color: '#b91c1c',
  },
  missionStatusTextWarning: {
    color: '#92400e',
  },
  missionStatusTextProcess: {
    color: '#047857',
  },
  missionStatusTextSoon: {
    color: '#0369a1',
  },
  missionTitle: {
    fontSize: 17,
    color: '#1e293b',
    fontWeight: '900',
    marginTop: 7,
  },
  missionDescription: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '600',
    marginTop: 4,
    lineHeight: 18,
  },
  scheduleBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eef2ff',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginTop: 10,
    alignSelf: 'flex-start',
  },
  scheduleText: {
    color: '#4F46E5',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 5,
  },
  processBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#d1fae5',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginTop: 10,
  },
  processText: {
    color: '#047857',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 6,
    flex: 1,
  },
  countdownBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#dbeafe',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginTop: 10,
  },
  countdownText: {
    color: '#0369a1',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 6,
    flex: 1,
  },
  warningBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fef3c7',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginTop: 10,
  },
  warningText: {
    color: '#92400e',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 6,
    flex: 1,
  },
  penaltyBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fee2e2',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 8,
    marginTop: 10,
  },
  penaltyText: {
    color: '#b91c1c',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 6,
    flex: 1,
  },
  missionBottomRow: {
    marginTop: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  missionXpBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fffbeb',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  missionXpText: {
    color: '#92400e',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 4,
  },
  completeButton: {
    backgroundColor: '#4F46E5',
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  completeButtonDone: {
    backgroundColor: '#16a34a',
  },
  completeButtonDisabled: {
    backgroundColor: '#94a3b8',
  },
  completeButtonLocked: {
    backgroundColor: '#64748b',
  },
  completeButtonText: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 5,
  },
  bottomSpace: {
    height: 10,
  },
  levelUpOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width,
    height,
    backgroundColor: 'rgba(15, 23, 42, 0.78)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 999,
  },
  levelUpCard: {
    width: '82%',
    maxWidth: 360,
    backgroundColor: '#ffffff',
    borderRadius: 32,
    padding: 28,
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#facc15',
    shadowColor: '#facc15',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.35,
    shadowRadius: 24,
    elevation: 20,
  },
  levelUpIcon: {
    width: 92,
    height: 92,
    borderRadius: 46,
    backgroundColor: '#f59e0b',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 5,
    borderColor: '#fef3c7',
    marginBottom: 16,
  },
  levelUpTitle: {
    color: '#1e293b',
    fontSize: 26,
    fontWeight: '900',
    textAlign: 'center',
  },
  levelUpText: {
    color: '#64748b',
    fontSize: 16,
    fontWeight: '800',
    textAlign: 'center',
    marginTop: 8,
  },
  levelUpSparkRow: {
    flexDirection: 'row',
    gap: 14,
    marginTop: 18,
    alignItems: 'center',
  },
  logoutOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width,
    height,
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
    paddingHorizontal: 22,
  },
  logoutConfirmCard: {
    width: '100%',
    maxWidth: 370,
    backgroundColor: '#ffffff',
    borderRadius: 32,
    padding: 26,
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#fecaca',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 15 },
    shadowOpacity: 0.28,
    shadowRadius: 26,
    elevation: 20,
  },
  logoutConfirmIcon: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 6,
    borderColor: '#fee2e2',
    marginBottom: 16,
  },
  logoutConfirmTitle: {
    color: '#1e293b',
    fontSize: 25,
    fontWeight: '900',
    textAlign: 'center',
  },
  logoutConfirmText: {
    color: '#64748b',
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
    marginTop: 9,
    lineHeight: 20,
  },
  logoutActionsRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 22,
    width: '100%',
  },
  logoutCancelButton: {
    flex: 1,
    backgroundColor: '#f1f5f9',
    paddingVertical: 14,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
  },
  logoutCancelText: {
    color: '#334155',
    fontSize: 15,
    fontWeight: '900',
  },
  logoutAcceptButton: {
    flex: 1,
    backgroundColor: '#ef4444',
    paddingVertical: 14,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.24,
    shadowRadius: 12,
    elevation: 7,
  },
  logoutAcceptText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '900',
    marginLeft: 6,
  },
  logoutLoadingBox: {
    marginTop: 20,
    backgroundColor: '#fff1f2',
    borderRadius: 18,
    paddingHorizontal: 18,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
  },
  logoutLoadingText: {
    color: '#b91c1c',
    fontSize: 14,
    fontWeight: '900',
    marginLeft: 10,
  },
});