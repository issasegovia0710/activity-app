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
  ActivityIndicator,
  Switch,
  TextInput,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import api from '../config/api';
import storage from '../config/storage';
import TEMAS from '../config/themes';

const { width, height } = Dimensions.get('window');

export default function AjustesScreen({
  route,
  navigation,
  onLogout,
  tema,
  temaActual,
  cambiarTemaGlobal,
}) {
  const usuario = route?.params?.usuario;

  const temaSeguro = tema || TEMAS.clasico;
  const temaActualSeguro = temaActual || temaSeguro.id || 'clasico';

  const [notificacionesActivas, setNotificacionesActivas] = useState(true);
  const [recordatorioMisiones, setRecordatorioMisiones] = useState(true);
  const [alertaAntesDeVencer, setAlertaAntesDeVencer] = useState(true);

  const [bloqueoSesion, setBloqueoSesion] = useState(false);
  const [confirmarAntesDeCompletar, setConfirmarAntesDeCompletar] = useState(true);

  const [nombreVisible, setNombreVisible] = useState(
    usuario?.nombre_usuario || 'Jugador'
  );

  const [modalActivo, setModalActivo] = useState(null);
  const [mostrarConfirmLogout, setMostrarConfirmLogout] = useState(false);
  const [cerrandoSesion, setCerrandoSesion] = useState(false);

  const fadeAnim = useState(new Animated.Value(0))[0];
  const slideAnim = useState(new Animated.Value(35))[0];
  const floatAnim = useState(new Animated.Value(0))[0];

  const modalOpacity = useState(new Animated.Value(0))[0];
  const modalScale = useState(new Animated.Value(0.88))[0];
  const modalTranslateY = useState(new Animated.Value(26))[0];

  const logoutOverlayOpacity = useState(new Animated.Value(0))[0];
  const logoutCardScale = useState(new Animated.Value(0.82))[0];
  const logoutCardTranslateY = useState(new Animated.Value(30))[0];
  const logoutIconRotate = useState(new Animated.Value(0))[0];
  const logoutIconPulse = useState(new Animated.Value(1))[0];

  useEffect(() => {
    cargarPreferencias();

    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 750,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 750,
        easing: Easing.out(Easing.back(1.2)),
        useNativeDriver: true,
      }),
    ]).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(floatAnim, {
          toValue: -8,
          duration: 1500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(floatAnim, {
          toValue: 0,
          duration: 1500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, []);

  const cargarPreferencias = async () => {
    try {
      const notificacionesGuardadas = await storage.getItem('notificaciones_activas');
      const recordatorioGuardado = await storage.getItem('recordatorio_misiones');
      const alertaGuardada = await storage.getItem('alerta_antes_vencer');
      const bloqueoGuardado = await storage.getItem('bloqueo_sesion');
      const confirmarGuardado = await storage.getItem('confirmar_completar');
      const nombreGuardado = await storage.getItem('nombre_visible');

      if (notificacionesGuardadas !== null && notificacionesGuardadas !== undefined) {
        setNotificacionesActivas(notificacionesGuardadas === 'true');
      }

      if (recordatorioGuardado !== null && recordatorioGuardado !== undefined) {
        setRecordatorioMisiones(recordatorioGuardado === 'true');
      }

      if (alertaGuardada !== null && alertaGuardada !== undefined) {
        setAlertaAntesDeVencer(alertaGuardada === 'true');
      }

      if (bloqueoGuardado !== null && bloqueoGuardado !== undefined) {
        setBloqueoSesion(bloqueoGuardado === 'true');
      }

      if (confirmarGuardado !== null && confirmarGuardado !== undefined) {
        setConfirmarAntesDeCompletar(confirmarGuardado === 'true');
      }

      if (nombreGuardado) {
        setNombreVisible(nombreGuardado);
      }
    } catch (error) {
      console.log('Error al cargar preferencias:', error.message);
    }
  };

  const guardarPreferencia = async (key, value) => {
    try {
      await storage.setItem(key, String(value));
    } catch (error) {
      console.log(`No se pudo guardar ${key}:`, error.message);
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

  const abrirModal = (tipo) => {
    setModalActivo(tipo);

    modalOpacity.setValue(0);
    modalScale.setValue(0.88);
    modalTranslateY.setValue(26);

    Animated.parallel([
      Animated.timing(modalOpacity, {
        toValue: 1,
        duration: 240,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.spring(modalScale, {
        toValue: 1,
        friction: 5,
        tension: 80,
        useNativeDriver: true,
      }),
      Animated.timing(modalTranslateY, {
        toValue: 0,
        duration: 260,
        easing: Easing.out(Easing.back(1.2)),
        useNativeDriver: true,
      }),
    ]).start();
  };

  const cerrarModal = () => {
    Animated.parallel([
      Animated.timing(modalOpacity, {
        toValue: 0,
        duration: 190,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(modalScale, {
        toValue: 0.88,
        duration: 190,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(modalTranslateY, {
        toValue: 24,
        duration: 190,
        easing: Easing.in(Easing.ease),
        useNativeDriver: true,
      }),
    ]).start(() => {
      setModalActivo(null);
    });
  };

  const cambiarTema = async (idTema) => {
    if (!TEMAS[idTema]) {
      return;
    }

    if (cambiarTemaGlobal) {
      await cambiarTemaGlobal(idTema);
      return;
    }

    await storage.setItem('tema_app', idTema);
  };

  const guardarNombreVisible = async () => {
    const nombreLimpio = String(nombreVisible || '').trim();

    if (!nombreLimpio) {
      setNombreVisible(usuario?.nombre_usuario || 'Jugador');
      return;
    }

    await guardarPreferencia('nombre_visible', nombreLimpio);
    cerrarModal();
  };

  const cambiarNotificaciones = async (valor) => {
    setNotificacionesActivas(valor);
    await guardarPreferencia('notificaciones_activas', valor);

    if (!valor) {
      setRecordatorioMisiones(false);
      setAlertaAntesDeVencer(false);
      await guardarPreferencia('recordatorio_misiones', false);
      await guardarPreferencia('alerta_antes_vencer', false);
    }
  };

  const cambiarRecordatorioMisiones = async (valor) => {
    setRecordatorioMisiones(valor);
    await guardarPreferencia('recordatorio_misiones', valor);
  };

  const cambiarAlertaAntesDeVencer = async (valor) => {
    setAlertaAntesDeVencer(valor);
    await guardarPreferencia('alerta_antes_vencer', valor);
  };

  const cambiarBloqueoSesion = async (valor) => {
    setBloqueoSesion(valor);
    await guardarPreferencia('bloqueo_sesion', valor);
  };

  const cambiarConfirmarCompletar = async (valor) => {
    setConfirmarAntesDeCompletar(valor);
    await guardarPreferencia('confirmar_completar', valor);
  };

  const abrirConfirmacionCerrarSesion = () => {
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
    if (cerrandoSesion) {
      return;
    }

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
          duration: 330,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(logoutIconPulse, {
          toValue: 1,
          duration: 330,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ]),
      { iterations: 2 }
    ).start();

    Animated.timing(logoutIconRotate, {
      toValue: 1,
      duration: 850,
      easing: Easing.inOut(Easing.ease),
      useNativeDriver: true,
    }).start();
  };

  const cerrarSesion = async () => {
    try {
      ejecutarAnimacionCierre();

      await new Promise((resolve) => setTimeout(resolve, 900));

      await eliminarStorageItem('token');
      await eliminarStorageItem('usuario');

      if (api.defaults?.headers?.common?.Authorization) {
        delete api.defaults.headers.common.Authorization;
      }

      if (onLogout) {
        await onLogout();
        return;
      }

      if (navigation?.navigate) {
        navigation.navigate('Login');
      }
    } catch (error) {
      console.log('Error al cerrar sesión desde ajustes:', error.message);

      if (onLogout) {
        await onLogout();
      }
    }
  };

  const regresar = () => {
    if (navigation?.goBack) {
      navigation.goBack();
      return;
    }

    if (navigation?.navigate) {
      navigation.navigate('Dashboard');
    }
  };

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
              backgroundColor: 'rgba(255, 255, 255, 0.14)',
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="settings" size={24} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleTwo,
            {
              backgroundColor: 'rgba(236, 72, 153, 0.2)',
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="person" size={24} color="#ffffff" />
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
          styles.content,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }],
          },
        ]}
      >
        <View style={styles.header}>
          <TouchableOpacity
            style={[
              styles.backButton,
              {
                backgroundColor: temaSeguro.primario,
                borderColor: temaSeguro.borde,
              },
            ]}
            onPress={regresar}
            activeOpacity={0.85}
          >
            <Ionicons name="chevron-back" size={24} color="#ffffff" />
          </TouchableOpacity>

          <View style={styles.headerTextBox}>
            <Text style={styles.title}>Ajustes</Text>
            <Text style={styles.subtitle}>Cuenta, preferencias y sesión</Text>
          </View>
        </View>

        <ScrollView
          style={styles.scrollArea}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          <TouchableOpacity
            style={styles.profileCard}
            activeOpacity={0.9}
            onPress={() => abrirModal('perfil')}
          >
            <View style={[styles.profileAvatar, { backgroundColor: temaSeguro.primario }]}>
              <Ionicons name="person" size={38} color="#ffffff" />
            </View>

            <Text style={styles.profileName}>
              {nombreVisible || usuario?.nombre_usuario || 'Jugador'}
            </Text>

            <Text style={styles.profileSubtitle}>Toca para ver información del perfil</Text>

            <View style={styles.profileMiniRow}>
              <Ionicons name="mail-outline" size={15} color="#64748b" />
              <Text style={styles.profileMiniText}>
                {usuario?.correo || 'Sin correo registrado'}
              </Text>
            </View>

            <View style={styles.profileMiniRow}>
              <Ionicons name="flash-outline" size={15} color={temaSeguro.barraXp} />
              <Text style={styles.profileMiniText}>
                Nivel {usuario?.nivel || 1} • {usuario?.exp || 0} XP
              </Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.optionCard}
            onPress={() => abrirModal('notificaciones')}
            activeOpacity={0.88}
          >
            <View style={styles.optionIcon}>
              <Ionicons
                name="notifications-outline"
                size={22}
                color={temaSeguro.primario}
              />
            </View>

            <View style={styles.optionTextBox}>
              <Text style={styles.optionTitle}>Notificaciones</Text>
              <Text style={styles.optionSubtitle}>
                {notificacionesActivas ? 'Activas' : 'Desactivadas'}
              </Text>
            </View>

            <View
              style={[
                styles.statusPill,
                {
                  backgroundColor: notificacionesActivas ? '#dcfce7' : '#fee2e2',
                },
              ]}
            >
              <Text
                style={[
                  styles.statusPillText,
                  {
                    color: notificacionesActivas ? '#16a34a' : '#b91c1c',
                  },
                ]}
              >
                {notificacionesActivas ? 'ON' : 'OFF'}
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={22} color="#94a3b8" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.optionCard}
            onPress={() => abrirModal('tema')}
            activeOpacity={0.88}
          >
            <View style={[styles.optionIcon, { backgroundColor: temaSeguro.suaveSecundario }]}>
              <Ionicons
                name="color-palette-outline"
                size={22}
                color={temaSeguro.secundario}
              />
            </View>

            <View style={styles.optionTextBox}>
              <Text style={styles.optionTitle}>Tema visual</Text>
              <Text style={styles.optionSubtitle}>
                {temaSeguro.nombre} • {temaSeguro.descripcion}
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={22} color="#94a3b8" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.optionCard}
            onPress={() => abrirModal('seguridad')}
            activeOpacity={0.88}
          >
            <View style={[styles.optionIcon, { backgroundColor: '#fffbeb' }]}>
              <Ionicons name="shield-checkmark-outline" size={22} color="#f59e0b" />
            </View>

            <View style={styles.optionTextBox}>
              <Text style={styles.optionTitle}>Seguridad</Text>
              <Text style={styles.optionSubtitle}>
                Sesión, confirmaciones y protección
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={22} color="#94a3b8" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.infoGameCard}
            activeOpacity={0.9}
            onPress={() => abrirModal('app')}
          >
            <View style={[styles.infoGameIcon, { backgroundColor: temaSeguro.primario }]}>
              <Ionicons name="game-controller-outline" size={28} color="#ffffff" />
            </View>

            <View style={styles.optionTextBox}>
              <Text style={styles.optionTitle}>Información de la app</Text>
              <Text style={styles.optionSubtitle}>
                Activity DayLife • Misiones y progreso
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={22} color="#94a3b8" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.logoutButton}
            onPress={abrirConfirmacionCerrarSesion}
            activeOpacity={0.85}
          >
            <Ionicons name="log-out-outline" size={22} color="#ffffff" />
            <Text style={styles.logoutText}>Cerrar sesión</Text>
          </TouchableOpacity>

          <View style={styles.bottomSpace} />
        </ScrollView>
      </Animated.View>

      {modalActivo ? (
        <Animated.View
          style={[
            styles.modalOverlay,
            {
              opacity: modalOpacity,
            },
          ]}
        >
          <Animated.View
            style={[
              styles.modalCard,
              {
                transform: [
                  { scale: modalScale },
                  { translateY: modalTranslateY },
                ],
              },
            ]}
          >
            <View style={styles.modalHeader}>
              <View
                style={[
                  styles.modalHeaderIcon,
                  { backgroundColor: temaSeguro.primario },
                ]}
              >
                <Ionicons
                  name={
                    modalActivo === 'perfil'
                      ? 'person-outline'
                      : modalActivo === 'notificaciones'
                        ? 'notifications-outline'
                        : modalActivo === 'tema'
                          ? 'color-palette-outline'
                          : modalActivo === 'seguridad'
                            ? 'shield-checkmark-outline'
                            : 'game-controller-outline'
                  }
                  size={24}
                  color="#ffffff"
                />
              </View>

              <Text style={styles.modalTitle}>
                {modalActivo === 'perfil'
                  ? 'Información del perfil'
                  : modalActivo === 'notificaciones'
                    ? 'Notificaciones'
                    : modalActivo === 'tema'
                      ? 'Tema visual'
                      : modalActivo === 'seguridad'
                        ? 'Seguridad'
                        : 'Información de la app'}
              </Text>

              <TouchableOpacity
                style={styles.modalCloseButton}
                onPress={cerrarModal}
                activeOpacity={0.85}
              >
                <Ionicons name="close" size={22} color="#475569" />
              </TouchableOpacity>
            </View>

            <ScrollView
              style={styles.modalScroll}
              showsVerticalScrollIndicator={false}
            >
              {modalActivo === 'perfil' ? (
                <View>
                  <View style={styles.profileBigBox}>
                    <View
                      style={[
                        styles.profileAvatarLarge,
                        { backgroundColor: temaSeguro.primario },
                      ]}
                    >
                      <Ionicons name="person" size={42} color="#ffffff" />
                    </View>

                    <Text style={styles.profileModalName}>
                      {usuario?.nombre_usuario || 'Jugador'}
                    </Text>

                    <Text style={styles.profileModalSub}>
                      Perfil local de la sesión actual
                    </Text>
                  </View>

                  <InfoRow
                    icon="person-circle-outline"
                    label="Usuario"
                    value={usuario?.nombre_usuario || 'No disponible'}
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="mail-outline"
                    label="Correo"
                    value={usuario?.correo || 'No disponible'}
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="flash-outline"
                    label="Experiencia"
                    value={`${usuario?.exp || 0} XP`}
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="trophy-outline"
                    label="Nivel"
                    value={`${usuario?.nivel || 1}`}
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="calendar-outline"
                    label="Fecha de alta"
                    value={usuario?.alta ? String(usuario.alta).slice(0, 10) : 'No disponible'}
                    color={temaSeguro.primario}
                  />

                  <Text style={styles.inputLabel}>Nombre visible en ajustes</Text>

                  <TextInput
                    style={styles.textInput}
                    value={nombreVisible}
                    onChangeText={setNombreVisible}
                    placeholder="Nombre visible"
                    placeholderTextColor="#94a3b8"
                  />

                  <TouchableOpacity
                    style={[
                      styles.saveButton,
                      { backgroundColor: temaSeguro.primario },
                    ]}
                    onPress={guardarNombreVisible}
                    activeOpacity={0.9}
                  >
                    <Ionicons name="save-outline" size={18} color="#ffffff" />
                    <Text style={styles.saveButtonText}>Guardar nombre visible</Text>
                  </TouchableOpacity>
                </View>
              ) : null}

              {modalActivo === 'notificaciones' ? (
                <View>
                  <SettingSwitch
                    icon="notifications-outline"
                    title="Notificaciones generales"
                    subtitle="Permite avisos dentro de la app"
                    value={notificacionesActivas}
                    onValueChange={cambiarNotificaciones}
                    color={temaSeguro.primario}
                  />

                  <SettingSwitch
                    icon="flag-outline"
                    title="Recordatorio de misiones"
                    subtitle="Avisos sobre misiones pendientes"
                    value={recordatorioMisiones}
                    onValueChange={cambiarRecordatorioMisiones}
                    disabled={!notificacionesActivas}
                    color={temaSeguro.primario}
                  />

                  <SettingSwitch
                    icon="alarm-outline"
                    title="Alerta antes de vencer"
                    subtitle="Aviso cuando una misión esté por terminar"
                    value={alertaAntesDeVencer}
                    onValueChange={cambiarAlertaAntesDeVencer}
                    disabled={!notificacionesActivas}
                    color={temaSeguro.primario}
                  />

                  <View style={styles.noticeBox}>
                    <Ionicons name="information-circle-outline" size={20} color="#0369a1" />
                    <Text style={styles.noticeText}>
                      Estas opciones quedan guardadas localmente. Para notificaciones reales en iPhone después se conecta con Expo Notifications.
                    </Text>
                  </View>
                </View>
              ) : null}

              {modalActivo === 'tema' ? (
                <View>
                  {Object.values(TEMAS).map((item) => (
                    <TouchableOpacity
                      key={item.id}
                      style={[
                        styles.themeOption,
                        temaActualSeguro === item.id && styles.themeOptionSelected,
                        temaActualSeguro === item.id && { borderColor: item.primario },
                      ]}
                      onPress={() => cambiarTema(item.id)}
                      activeOpacity={0.9}
                    >
                      <View style={styles.themeColorsRow}>
                        <View style={[styles.themeColorDot, { backgroundColor: item.fondo }]} />
                        <View style={[styles.themeColorDot, { backgroundColor: item.primario }]} />
                        <View style={[styles.themeColorDot, { backgroundColor: item.secundario }]} />
                      </View>

                      <View style={styles.themeTextBox}>
                        <Text style={styles.themeName}>{item.nombre}</Text>
                        <Text style={styles.themeDescription}>{item.descripcion}</Text>
                      </View>

                      {temaActualSeguro === item.id ? (
                        <Ionicons name="checkmark-circle" size={24} color={item.primario} />
                      ) : (
                        <Ionicons name="ellipse-outline" size={24} color="#cbd5e1" />
                      )}
                    </TouchableOpacity>
                  ))}

                  <View style={styles.noticeBox}>
                    <Ionicons name="color-palette-outline" size={20} color="#0369a1" />
                    <Text style={styles.noticeText}>
                      El tema queda guardado de forma global. Las pantallas que reciban la propiedad tema cambiarán automáticamente.
                    </Text>
                  </View>
                </View>
              ) : null}

              {modalActivo === 'seguridad' ? (
                <View>
                  <SettingSwitch
                    icon="lock-closed-outline"
                    title="Bloqueo de sesión"
                    subtitle="Preparado para pedir acceso al volver"
                    value={bloqueoSesion}
                    onValueChange={cambiarBloqueoSesion}
                    color={temaSeguro.primario}
                  />

                  <SettingSwitch
                    icon="checkmark-done-outline"
                    title="Confirmar antes de completar"
                    subtitle="Evita completar misiones por accidente"
                    value={confirmarAntesDeCompletar}
                    onValueChange={cambiarConfirmarCompletar}
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="shield-checkmark-outline"
                    label="Estado de sesión"
                    value="Sesión activa"
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="key-outline"
                    label="Token"
                    value="Guardado localmente"
                    color={temaSeguro.primario}
                  />

                  <TouchableOpacity
                    style={styles.securityLogoutButton}
                    onPress={() => {
                      cerrarModal();
                      setTimeout(() => abrirConfirmacionCerrarSesion(), 220);
                    }}
                    activeOpacity={0.9}
                  >
                    <Ionicons name="log-out-outline" size={20} color="#ffffff" />
                    <Text style={styles.securityLogoutText}>Cerrar sesión segura</Text>
                  </TouchableOpacity>
                </View>
              ) : null}

              {modalActivo === 'app' ? (
                <View>
                  <InfoRow
                    icon="game-controller-outline"
                    label="Aplicación"
                    value="Activity DayLife"
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="layers-outline"
                    label="Módulos"
                    value="Misiones, estadísticas y ajustes"
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="phone-portrait-outline"
                    label="Uso"
                    value="Compatible con web e iPhone"
                    color={temaSeguro.primario}
                  />

                  <InfoRow
                    icon="server-outline"
                    label="Conexión"
                    value="API local / servidor"
                    color={temaSeguro.primario}
                  />

                  <View style={styles.noticeBox}>
                    <Ionicons name="sparkles-outline" size={20} color="#0369a1" />
                    <Text style={styles.noticeText}>
                      Esta sección puede crecer para mostrar versión, soporte, políticas y exportación de progreso.
                    </Text>
                  </View>
                </View>
              ) : null}
            </ScrollView>
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
                ? 'Limpiando tu sesión y regresando al inicio.'
                : 'Tu avance queda guardado. Para volver tendrás que iniciar sesión de nuevo.'}
            </Text>

            {cerrandoSesion ? (
              <View style={styles.logoutLoadingBox}>
                <ActivityIndicator color="#ef4444" />
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
                  style={styles.logoutAcceptButton}
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

function InfoRow({ icon, label, value, color = '#4F46E5' }) {
  return (
    <View style={styles.infoRow}>
      <View style={styles.infoRowIcon}>
        <Ionicons name={icon} size={19} color={color} />
      </View>

      <View style={styles.infoRowTextBox}>
        <Text style={styles.infoRowLabel}>{label}</Text>
        <Text style={styles.infoRowValue}>{value}</Text>
      </View>
    </View>
  );
}

function SettingSwitch({
  icon,
  title,
  subtitle,
  value,
  onValueChange,
  disabled = false,
  color = '#4F46E5',
}) {
  return (
    <View style={[styles.settingSwitchCard, disabled && styles.settingDisabled]}>
      <View style={styles.settingSwitchLeft}>
        <View style={styles.settingSwitchIcon}>
          <Ionicons name={icon} size={21} color={disabled ? '#94a3b8' : color} />
        </View>

        <View style={styles.settingSwitchTextBox}>
          <Text style={[styles.settingSwitchTitle, disabled && styles.disabledText]}>
            {title}
          </Text>
          <Text style={[styles.settingSwitchSubtitle, disabled && styles.disabledSubText]}>
            {subtitle}
          </Text>
        </View>
      </View>

      <Switch
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
        trackColor={{ false: '#cbd5e1', true: '#c7d2fe' }}
        thumbColor={value ? color : '#f8fafc'}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
  },
  circleLarge: {
    position: 'absolute',
    width: 280,
    height: 280,
    borderRadius: 140,
    top: -95,
    right: -90,
  },
  circleSmall: {
    position: 'absolute',
    width: 190,
    height: 190,
    borderRadius: 95,
    bottom: -45,
    right: 15,
  },
  content: {
    flex: 1,
    paddingHorizontal: 18,
    paddingTop: 18,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  backButton: {
    width: 46,
    height: 46,
    borderRadius: 23,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 2,
  },
  headerTextBox: {
    flex: 1,
  },
  title: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '900',
  },
  subtitle: {
    color: '#c7d2fe',
    fontSize: 13,
    fontWeight: '700',
    marginTop: 3,
  },
  scrollArea: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 28,
  },
  profileCard: {
    backgroundColor: '#ffffff',
    borderRadius: 28,
    padding: 24,
    alignItems: 'center',
    marginBottom: 14,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  profileAvatar: {
    width: 82,
    height: 82,
    borderRadius: 41,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
    borderWidth: 4,
    borderColor: '#ede9fe',
  },
  profileName: {
    fontSize: 26,
    fontWeight: '900',
    color: '#1e293b',
    textAlign: 'center',
  },
  profileSubtitle: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '800',
    marginTop: 4,
    textAlign: 'center',
  },
  profileMiniRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    maxWidth: '100%',
  },
  profileMiniText: {
    color: '#64748b',
    fontSize: 12,
    fontWeight: '800',
    marginLeft: 5,
    textAlign: 'center',
  },
  optionCard: {
    backgroundColor: '#ffffff',
    borderRadius: 22,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  optionIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#eef2ff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  optionTextBox: {
    flex: 1,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: '#1e293b',
  },
  optionSubtitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748b',
    marginTop: 2,
  },
  statusPill: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    marginRight: 8,
  },
  statusPillText: {
    fontSize: 10,
    fontWeight: '900',
  },
  infoGameCard: {
    backgroundColor: '#ffffff',
    borderRadius: 22,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  infoGameIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  logoutButton: {
    backgroundColor: '#ef4444',
    borderRadius: 22,
    paddingVertical: 16,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius: 15,
    elevation: 5,
    marginTop: 4,
  },
  logoutText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
    marginLeft: 8,
  },
  bottomSpace: {
    height: 10,
  },
  modalOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    width,
    height,
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 900,
    paddingHorizontal: 18,
  },
  modalCard: {
    width: '100%',
    maxWidth: 410,
    maxHeight: height * 0.84,
    backgroundColor: '#ffffff',
    borderRadius: 30,
    padding: 20,
    borderWidth: 2,
    borderColor: '#e2e8f0',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.2,
    shadowRadius: 26,
    elevation: 18,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalHeaderIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  modalTitle: {
    flex: 1,
    color: '#1e293b',
    fontSize: 19,
    fontWeight: '900',
  },
  modalCloseButton: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#f1f5f9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalScroll: {
    maxHeight: height * 0.68,
  },
  profileBigBox: {
    alignItems: 'center',
    backgroundColor: '#f8fafc',
    borderRadius: 22,
    padding: 18,
    marginBottom: 12,
  },
  profileAvatarLarge: {
    width: 86,
    height: 86,
    borderRadius: 43,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 5,
    borderColor: '#ede9fe',
    marginBottom: 10,
  },
  profileModalName: {
    color: '#1e293b',
    fontSize: 22,
    fontWeight: '900',
    textAlign: 'center',
  },
  profileModalSub: {
    color: '#64748b',
    fontSize: 12,
    fontWeight: '800',
    marginTop: 4,
    textAlign: 'center',
  },
  infoRow: {
    backgroundColor: '#f8fafc',
    borderRadius: 18,
    padding: 13,
    marginBottom: 9,
    flexDirection: 'row',
    alignItems: 'center',
  },
  infoRowIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#eef2ff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  infoRowTextBox: {
    flex: 1,
  },
  infoRowLabel: {
    color: '#64748b',
    fontSize: 11,
    fontWeight: '900',
    textTransform: 'uppercase',
  },
  infoRowValue: {
    color: '#1e293b',
    fontSize: 14,
    fontWeight: '900',
    marginTop: 2,
  },
  inputLabel: {
    color: '#334155',
    fontSize: 13,
    fontWeight: '900',
    marginTop: 8,
    marginBottom: 7,
  },
  textInput: {
    backgroundColor: '#f8fafc',
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: '#1e293b',
    fontSize: 15,
    fontWeight: '800',
  },
  saveButton: {
    marginTop: 12,
    borderRadius: 18,
    paddingVertical: 14,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
  },
  saveButtonText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '900',
    marginLeft: 7,
  },
  settingSwitchCard: {
    backgroundColor: '#f8fafc',
    borderRadius: 19,
    padding: 14,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingDisabled: {
    opacity: 0.55,
  },
  settingSwitchLeft: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingSwitchIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#eef2ff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  settingSwitchTextBox: {
    flex: 1,
  },
  settingSwitchTitle: {
    color: '#1e293b',
    fontSize: 14,
    fontWeight: '900',
  },
  settingSwitchSubtitle: {
    color: '#64748b',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  disabledText: {
    color: '#94a3b8',
  },
  disabledSubText: {
    color: '#cbd5e1',
  },
  noticeBox: {
    backgroundColor: '#e0f2fe',
    borderRadius: 18,
    padding: 13,
    flexDirection: 'row',
    marginTop: 10,
  },
  noticeText: {
    flex: 1,
    color: '#0369a1',
    fontSize: 12,
    fontWeight: '800',
    lineHeight: 18,
    marginLeft: 8,
  },
  themeOption: {
    backgroundColor: '#f8fafc',
    borderRadius: 20,
    padding: 14,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#e2e8f0',
  },
  themeOptionSelected: {
    backgroundColor: '#ffffff',
  },
  themeColorsRow: {
    flexDirection: 'row',
    marginRight: 10,
  },
  themeColorDot: {
    width: 17,
    height: 17,
    borderRadius: 8.5,
    marginRight: -4,
    borderWidth: 2,
    borderColor: '#ffffff',
  },
  themeTextBox: {
    flex: 1,
  },
  themeName: {
    color: '#1e293b',
    fontSize: 15,
    fontWeight: '900',
  },
  themeDescription: {
    color: '#64748b',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  securityLogoutButton: {
    backgroundColor: '#ef4444',
    borderRadius: 18,
    paddingVertical: 14,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
    marginTop: 12,
  },
  securityLogoutText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '900',
    marginLeft: 7,
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