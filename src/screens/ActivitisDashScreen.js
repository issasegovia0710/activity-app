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
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import api from '../config/api';

const { width, height } = Dimensions.get('window');

const TEMA_DEFAULT = {
  fondo: '#312e81',
  fondoSecundario: '#4c1d95',
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

const PRIORIDADES = [
  { id: 1, nombre: 'baja', etiqueta: 'Baja', color: '#16a34a' },
  { id: 2, nombre: 'media', etiqueta: 'Media', color: '#f59e0b' },
  { id: 3, nombre: 'alta', etiqueta: 'Alta', color: '#ef4444' },
];

export default function ActivitisDashScreen({ route, navigation, tema }) {
  const temaSeguro = tema || route?.params?.tema || TEMA_DEFAULT;

  const tipo = route?.params?.tipo || '';
  const categoria = route?.params?.categoria || null;

  const [actividades, setActividades] = useState([]);
  const [cargando, setCargando] = useState(false);
  const [guardando, setGuardando] = useState(false);

  const [actividadEditando, setActividadEditando] = useState(null);
  const [mostrarEditor, setMostrarEditor] = useState(false);

  const [nombre, setNombre] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [prioridad, setPrioridad] = useState('media');
  const [duracionHoras, setDuracionHoras] = useState('');
  const [estatus, setEstatus] = useState('pendiente');

  const fadeAnim = useState(new Animated.Value(0))[0];
  const slideAnim = useState(new Animated.Value(35))[0];
  const floatAnim = useState(new Animated.Value(0))[0];

  const overlayOpacity = useState(new Animated.Value(0))[0];
  const modalScale = useState(new Animated.Value(0.92))[0];
  const modalTranslateY = useState(new Animated.Value(45))[0];

  useEffect(() => {
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
  }, [fadeAnim, slideAnim, floatAnim]);

  useEffect(() => {
    cargarActividades();
  }, [tipo]);

  const cargarActividades = async () => {
    try {
      setCargando(true);

      const response = await api.get('/actividades');
      const lista = response.data?.actividades || [];

      const filtradas = lista.filter(
        (actividad) =>
          String(actividad.tipo || '').trim().toLowerCase() ===
          String(tipo || '').trim().toLowerCase()
      );

      setActividades(filtradas);
    } catch (error) {
      console.log('Error al cargar actividades:', error.response?.data || error.message);

      Alert.alert(
        'Error',
        error.response?.data?.mensaje ||
          'No se pudieron cargar las actividades.'
      );
    } finally {
      setCargando(false);
    }
  };

  const calcularExpPorPrioridad = () => {
    if (prioridad === 'baja') return 5;
    if (prioridad === 'media') return 15;
    if (prioridad === 'alta') return 25;
    return 15;
  };

  const calcularBonusPorHoras = () => {
    const horas = Number(duracionHoras);

    if (!String(duracionHoras || '').trim() || Number.isNaN(horas) || horas <= 0) {
      return 0;
    }

    return Math.ceil(horas * 5);
  };

  const valorExpCalculado = calcularExpPorPrioridad() + calcularBonusPorHoras();

  const abrirEditor = (actividad) => {
    setActividadEditando(actividad);
    setMostrarEditor(true);

    setNombre(actividad.nombre || '');
    setDescripcion(actividad.descripcion || '');
    setPrioridad(actividad.prioridad || 'media');
    setDuracionHoras(
      actividad.duracion_horas === null ||
        actividad.duracion_horas === undefined
        ? ''
        : String(actividad.duracion_horas)
    );
    setEstatus(actividad.estatus || 'pendiente');

    overlayOpacity.setValue(0);
    modalScale.setValue(0.92);
    modalTranslateY.setValue(45);

    Animated.parallel([
      Animated.timing(overlayOpacity, {
        toValue: 1,
        duration: 240,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(modalScale, {
        toValue: 1,
        duration: 320,
        easing: Easing.out(Easing.back(1.15)),
        useNativeDriver: true,
      }),
      Animated.timing(modalTranslateY, {
        toValue: 0,
        duration: 320,
        easing: Easing.out(Easing.back(1.15)),
        useNativeDriver: true,
      }),
    ]).start();
  };

  const cerrarEditor = () => {
    if (guardando) return;

    Animated.parallel([
      Animated.timing(overlayOpacity, {
        toValue: 0,
        duration: 180,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(modalScale, {
        toValue: 0.94,
        duration: 180,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
      Animated.timing(modalTranslateY, {
        toValue: 35,
        duration: 180,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }),
    ]).start(() => {
      setMostrarEditor(false);
      setActividadEditando(null);
    });
  };

  const guardarEdicion = async () => {
    if (!actividadEditando?.id) {
      Alert.alert('Error', 'No se encontró el id de la actividad.');
      return;
    }

    if (!nombre.trim()) {
      Alert.alert('Falta nombre', 'Escribe el nombre de la actividad.');
      return;
    }

    if (
      String(duracionHoras || '').trim() &&
      (Number.isNaN(Number(duracionHoras)) || Number(duracionHoras) < 0)
    ) {
      Alert.alert('Duración inválida', 'La duración debe ser un número válido.');
      return;
    }

    const duracionFinal =
      String(duracionHoras || '').trim() && !Number.isNaN(Number(duracionHoras))
        ? Number(duracionHoras)
        : null;

    const actividadActualizada = {
      nombre: nombre.trim(),
      descripcion: descripcion.trim() || null,
      tipo,
      prioridad,
      valor_exp: valorExpCalculado,
      duracion_horas: duracionFinal,
      repetecion: actividadEditando.repetecion || null,
      estatus,
      auxiliar: actividadEditando.auxiliar || null,
    };

    try {
      setGuardando(true);

      await api.put(`/actividades/${actividadEditando.id}`, actividadActualizada);

      Alert.alert('Actividad actualizada', 'La actividad se editó correctamente.');

      setGuardando(false);
      cerrarEditor();
      cargarActividades();
    } catch (error) {
      console.log('Error al editar actividad:', error.response?.data || error.message);

      const mensaje =
        error.response?.data?.mensaje ||
        error.response?.data?.detalle ||
        'No se pudo editar la actividad.';

      Alert.alert('Error', mensaje);
      setGuardando(false);
    }
  };

  const eliminarActividad = (actividad) => {
    Alert.alert(
      'Eliminar actividad',
      `¿Seguro que quieres eliminar "${actividad.nombre}"?`,
      [
        {
          text: 'Cancelar',
          style: 'cancel',
        },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.delete(`/actividades/${actividad.id}`);
              Alert.alert('Eliminada', 'La actividad fue eliminada.');
              cargarActividades();
            } catch (error) {
              console.log('Error al eliminar:', error.response?.data || error.message);

              Alert.alert(
                'Error',
                error.response?.data?.mensaje ||
                  'No se pudo eliminar la actividad.'
              );
            }
          },
        },
      ]
    );
  };

  const cambiarEstatusRapido = async (actividad) => {
    const nuevoEstatus =
      actividad.estatus === 'completada' ? 'pendiente' : 'completada';

    const actividadActualizada = {
      nombre: actividad.nombre,
      descripcion: actividad.descripcion || null,
      tipo: actividad.tipo,
      prioridad: actividad.prioridad || 'media',
      valor_exp: actividad.valor_exp,
      duracion_horas: actividad.duracion_horas,
      repetecion: actividad.repetecion || null,
      estatus: nuevoEstatus,
      auxiliar: actividad.auxiliar || null,
    };

    try {
      await api.put(`/actividades/${actividad.id}`, actividadActualizada);
      cargarActividades();
    } catch (error) {
      console.log('Error al cambiar estatus:', error.response?.data || error.message);

      Alert.alert(
        'Error',
        error.response?.data?.mensaje ||
          'No se pudo cambiar el estatus.'
      );
    }
  };

  const obtenerColorPrioridad = (valor) => {
    if (valor === 'baja') return temaSeguro.exito;
    if (valor === 'media') return temaSeguro.aviso;
    if (valor === 'alta') return temaSeguro.peligro;

    return '#64748b';
  };

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
          <Ionicons name="list" size={24} color="#ffffff" />
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
          <Ionicons name="create" size={24} color="#ffffff" />
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
            onPress={() => navigation.navigate('Misiones')}
            activeOpacity={0.85}
          >
            <Ionicons name="chevron-back" size={24} color="#ffffff" />
          </TouchableOpacity>

          <View style={styles.headerTextBox}>
            <Text style={styles.title}>{tipo || 'Actividades'}</Text>
            <Text style={[styles.subtitle, { color: temaSeguro.borde }]}>
              Actividades de esta clasificación
            </Text>
          </View>
        </View>

        <View style={[styles.infoCard, { backgroundColor: temaSeguro.tarjeta }]}>
          <View
            style={[
              styles.infoIcon,
              {
                backgroundColor: categoria?.color || temaSeguro.primario,
                borderColor: temaSeguro.borde,
              },
            ]}
          >
            <Ionicons
              name={categoria?.icono || 'albums-outline'}
              size={28}
              color="#ffffff"
            />
          </View>

          <View style={styles.infoTextBox}>
            <Text style={[styles.infoTitle, { color: temaSeguro.texto }]}>
              Panel de actividades
            </Text>
            <Text style={[styles.infoSubtitle, { color: temaSeguro.textoSuave }]}>
              Puedes editar, eliminar o marcar actividades como completadas.
            </Text>
          </View>
        </View>

        <TouchableOpacity
          style={[
            styles.reloadButton,
            {
              backgroundColor: temaSeguro.primario,
              shadowColor: temaSeguro.primario,
            },
          ]}
          onPress={cargarActividades}
          activeOpacity={0.85}
        >
          <Ionicons name="refresh" size={20} color="#ffffff" />
          <Text style={styles.reloadButtonText}>Actualizar lista</Text>
        </TouchableOpacity>

        <ScrollView
          style={styles.scrollArea}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {cargando ? (
            <View style={styles.loadingBox}>
              <ActivityIndicator color="#ffffff" />
              <Text style={styles.loadingText}>Cargando actividades...</Text>
            </View>
          ) : actividades.length === 0 ? (
            <View style={styles.emptyBox}>
              <Ionicons name="clipboard-outline" size={44} color="#ffffff" />
              <Text style={styles.emptyTitle}>Sin actividades</Text>
              <Text style={styles.emptyText}>
                Todavía no hay actividades guardadas en esta clasificación.
              </Text>
            </View>
          ) : (
            actividades.map((actividad, index) => (
              <ActivityCard
                key={actividad.id}
                actividad={actividad}
                index={index}
                onEdit={() => abrirEditor(actividad)}
                onDelete={() => eliminarActividad(actividad)}
                onToggleStatus={() => cambiarEstatusRapido(actividad)}
                obtenerColorPrioridad={obtenerColorPrioridad}
                tema={temaSeguro}
              />
            ))
          )}

          <View style={styles.bottomSpace} />
        </ScrollView>
      </Animated.View>

      {mostrarEditor && (
        <Animated.View
          style={[
            styles.overlay,
            {
              pointerEvents: 'auto',
              opacity: overlayOpacity,
            },
          ]}
        >
          <View style={styles.overlayBackdrop} />

          <Animated.View
            style={[
              styles.modalCard,
              {
                backgroundColor: temaSeguro.tarjeta,
                borderColor: temaSeguro.borde,
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
                  styles.formCategoryIcon,
                  { backgroundColor: temaSeguro.primario },
                ]}
              >
                <Ionicons name="create-outline" size={26} color="#ffffff" />
              </View>

              <View style={styles.formHeaderTextBox}>
                <Text style={[styles.formTitle, { color: temaSeguro.texto }]}>
                  Editar actividad
                </Text>
                <Text style={[styles.formSubtitle, { color: temaSeguro.textoSuave }]}>
                  {tipo}
                </Text>
              </View>

              <TouchableOpacity
                style={[
                  styles.closeFormButton,
                  {
                    backgroundColor: temaSeguro.peligro,
                    shadowColor: temaSeguro.peligro,
                  },
                ]}
                onPress={cerrarEditor}
                activeOpacity={0.85}
                disabled={guardando}
              >
                <Ionicons name="close" size={22} color="#ffffff" />
              </TouchableOpacity>
            </View>

            <ScrollView
              style={styles.modalScroll}
              contentContainerStyle={styles.modalScrollContent}
              showsVerticalScrollIndicator={false}
              keyboardShouldPersistTaps="handled"
            >
              <Text style={styles.inputLabel}>Nombre</Text>
              <View style={styles.inputContainer}>
                <Ionicons name="pencil-outline" size={20} color={temaSeguro.primario} />
                <TextInput
                  style={styles.input}
                  placeholder="Nombre de la actividad"
                  placeholderTextColor="#94a3b8"
                  value={nombre}
                  onChangeText={setNombre}
                  editable={!guardando}
                />
              </View>

              <Text style={styles.inputLabel}>Descripción</Text>
              <View style={[styles.inputContainer, styles.textAreaContainer]}>
                <Ionicons name="document-text-outline" size={20} color={temaSeguro.primario} />
                <TextInput
                  style={[styles.input, styles.textArea]}
                  placeholder="Descripción"
                  placeholderTextColor="#94a3b8"
                  value={descripcion}
                  onChangeText={setDescripcion}
                  multiline
                  editable={!guardando}
                />
              </View>

              <Text style={styles.inputLabel}>Prioridad</Text>
              <View style={styles.priorityRow}>
                {PRIORIDADES.map((item) => (
                  <TouchableOpacity
                    key={item.id}
                    style={[
                      styles.priorityButton,
                      prioridad === item.nombre && {
                        backgroundColor: item.color,
                        borderColor: item.color,
                      },
                    ]}
                    onPress={() => setPrioridad(item.nombre)}
                    activeOpacity={0.85}
                    disabled={guardando}
                  >
                    <Text
                      style={[
                        styles.priorityText,
                        prioridad === item.nombre && styles.priorityTextActive,
                      ]}
                    >
                      {item.etiqueta}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>

              <Text style={styles.inputLabel}>Duración estimada en horas</Text>
              <View style={styles.inputContainer}>
                <Ionicons name="time-outline" size={20} color={temaSeguro.primario} />
                <TextInput
                  style={styles.input}
                  placeholder="Ej. 1.5"
                  placeholderTextColor="#94a3b8"
                  value={duracionHoras}
                  onChangeText={setDuracionHoras}
                  keyboardType="decimal-pad"
                  editable={!guardando}
                />
              </View>

              <Text style={styles.inputLabel}>Estatus</Text>
              <View style={styles.statusRow}>
                <TouchableOpacity
                  style={[
                    styles.statusButton,
                    estatus === 'pendiente' && styles.statusButtonPendingActive,
                  ]}
                  onPress={() => setEstatus('pendiente')}
                  activeOpacity={0.85}
                  disabled={guardando}
                >
                  <Text
                    style={[
                      styles.statusButtonText,
                      estatus === 'pendiente' && styles.statusButtonTextPendingActive,
                    ]}
                  >
                    Pendiente
                  </Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[
                    styles.statusButton,
                    estatus === 'completada' && styles.statusButtonDoneActive,
                  ]}
                  onPress={() => setEstatus('completada')}
                  activeOpacity={0.85}
                  disabled={guardando}
                >
                  <Text
                    style={[
                      styles.statusButtonText,
                      estatus === 'completada' && styles.statusButtonTextDoneActive,
                    ]}
                  >
                    Completada
                  </Text>
                </TouchableOpacity>
              </View>

              <Text style={styles.inputLabel}>Experiencia recalculada</Text>
              <View style={[styles.expAutoBox, { backgroundColor: temaSeguro.fondoSecundario }]}>
                <View style={[styles.expIconBox, { backgroundColor: temaSeguro.barraXp }]}>
                  <Ionicons name="flash" size={24} color="#ffffff" />
                </View>

                <View style={styles.expTextBox}>
                  <Text style={styles.expValue}>{valorExpCalculado} XP</Text>
                  <Text style={styles.expDescription}>
                    Se recalcula por prioridad y duración
                  </Text>
                </View>
              </View>

              <TouchableOpacity
                style={[
                  styles.saveButton,
                  {
                    backgroundColor: temaSeguro.primario,
                    shadowColor: temaSeguro.primario,
                  },
                  guardando && styles.saveButtonDisabled,
                ]}
                onPress={guardarEdicion}
                activeOpacity={0.85}
                disabled={guardando}
              >
                {guardando ? (
                  <>
                    <ActivityIndicator color="#ffffff" />
                    <Text style={styles.saveButtonText}>Guardando...</Text>
                  </>
                ) : (
                  <>
                    <Ionicons name="save-outline" size={22} color="#ffffff" />
                    <Text style={styles.saveButtonText}>Guardar cambios</Text>
                  </>
                )}
              </TouchableOpacity>
            </ScrollView>
          </Animated.View>
        </Animated.View>
      )}
    </SafeAreaView>
  );
}

function ActivityCard({
  actividad,
  index,
  onEdit,
  onDelete,
  onToggleStatus,
  obtenerColorPrioridad,
  tema,
}) {
  const temaSeguro = tema || TEMA_DEFAULT;

  const cardFade = useState(new Animated.Value(0))[0];
  const cardSlide = useState(new Animated.Value(35))[0];
  const cardScale = useState(new Animated.Value(1))[0];

  useEffect(() => {
    Animated.sequence([
      Animated.delay(index * 80),
      Animated.parallel([
        Animated.timing(cardFade, {
          toValue: 1,
          duration: 430,
          easing: Easing.out(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(cardSlide, {
          toValue: 0,
          duration: 430,
          easing: Easing.out(Easing.back(1.12)),
          useNativeDriver: true,
        }),
      ]),
    ]).start();
  }, [cardFade, cardSlide, index]);

  const pressIn = () => {
    Animated.spring(cardScale, {
      toValue: 0.98,
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

  const prioridadColor = obtenerColorPrioridad(actividad.prioridad);
  const completada = actividad.estatus === 'completada';

  return (
    <Animated.View
      style={[
        styles.activityCardAnimated,
        {
          opacity: cardFade,
          transform: [{ translateY: cardSlide }, { scale: cardScale }],
        },
      ]}
    >
      <TouchableOpacity
        style={[
          styles.activityCard,
          completada ? styles.activityCardDone : styles.activityCardPending,
        ]}
        onPressIn={pressIn}
        onPressOut={pressOut}
        activeOpacity={0.92}
      >
        <View style={styles.activityHeader}>
          <View
            style={[
              styles.activityIcon,
              {
                backgroundColor: completada ? temaSeguro.exito : prioridadColor,
              },
            ]}
          >
            <Ionicons
              name={completada ? 'checkmark' : 'flag-outline'}
              size={24}
              color="#ffffff"
            />
          </View>

          <View style={styles.activityTextBox}>
            <View style={styles.activityTitleRow}>
              <Text style={styles.activityTitle}>
                {actividad.nombre}
              </Text>

              <View
                style={[
                  styles.statusBadge,
                  completada ? styles.statusBadgeDone : styles.statusBadgePending,
                ]}
              >
                <Text
                  style={[
                    styles.statusBadgeText,
                    completada ? styles.statusBadgeTextDone : styles.statusBadgeTextPending,
                  ]}
                >
                  {completada ? 'Completada' : 'Pendiente'}
                </Text>
              </View>
            </View>

            <Text style={styles.activityDescription}>
              {actividad.descripcion || 'Sin descripción'}
            </Text>
          </View>
        </View>

        <View style={styles.metaRow}>
          <View style={[styles.metaBadge, { backgroundColor: `${prioridadColor}22` }]}>
            <Text style={[styles.metaText, { color: prioridadColor }]}>
              {actividad.prioridad || 'sin prioridad'}
            </Text>
          </View>

          <View style={styles.metaBadge}>
            <Text style={styles.metaText}>{actividad.valor_exp || 0} XP</Text>
          </View>

          <View style={styles.metaBadge}>
            <Text style={styles.metaText}>
              {actividad.duracion_horas ? `${actividad.duracion_horas} h` : 'sin horas'}
            </Text>
          </View>
        </View>

        {actividad.repetecion ? (
          <View style={styles.repeatBox}>
            <Ionicons name="repeat-outline" size={16} color={temaSeguro.primario} />
            <Text style={[styles.repeatText, { color: temaSeguro.primario }]}>
              {actividad.repetecion}
            </Text>
          </View>
        ) : (
          <View style={styles.repeatBox}>
            <Ionicons name="calendar-outline" size={16} color="#475569" />
            <Text style={[styles.repeatText, { color: '#475569' }]}>
              Una vez
            </Text>
          </View>
        )}

        <View style={styles.actionsRow}>
          <TouchableOpacity
            style={[
              styles.actionButton,
              completada ? styles.actionButtonPending : styles.actionButtonDone,
            ]}
            onPress={onToggleStatus}
            activeOpacity={0.85}
          >
            <Ionicons
              name={completada ? 'return-down-back-outline' : 'checkmark-circle-outline'}
              size={18}
              color={completada ? '#92400e' : '#166534'}
            />
            <Text
              style={[
                styles.actionButtonText,
                completada ? styles.actionButtonTextPending : styles.actionButtonTextDone,
              ]}
            >
              {completada ? 'Pendiente' : 'Completar'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.actionButtonEdit, { backgroundColor: temaSeguro.primario }]}
            onPress={onEdit}
            activeOpacity={0.85}
          >
            <Ionicons name="create-outline" size={18} color="#ffffff" />
            <Text style={styles.actionButtonTextWhite}>Editar</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.actionButtonDelete, { backgroundColor: temaSeguro.peligro }]}
            onPress={onDelete}
            activeOpacity={0.85}
          >
            <Ionicons name="trash-outline" size={18} color="#ffffff" />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#312e81', overflow: 'hidden' },
  backgroundDecorations: { position: 'absolute', width, height, top: 0, left: 0 },
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
  bubbleOne: { top: height * 0.08, left: width * 0.08 },
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
  content: { flex: 1, paddingHorizontal: 18, paddingTop: 18 },
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: 16 },
  backButton: {
    width: 46,
    height: 46,
    borderRadius: 23,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 2,
  },
  headerTextBox: { flex: 1 },
  title: { color: '#ffffff', fontSize: 28, fontWeight: '900' },
  subtitle: { color: '#c7d2fe', fontSize: 13, fontWeight: '700', marginTop: 3 },
  infoCard: {
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  infoIcon: {
    width: 56,
    height: 56,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
    borderWidth: 3,
  },
  infoTextBox: { flex: 1 },
  infoTitle: { fontSize: 18, color: '#1e293b', fontWeight: '900' },
  infoSubtitle: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '700',
    marginTop: 3,
    lineHeight: 18,
  },
  reloadButton: {
    backgroundColor: '#4F46E5',
    borderRadius: 20,
    paddingVertical: 14,
    paddingHorizontal: 16,
    marginBottom: 14,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#4F46E5',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.28,
    shadowRadius: 14,
    elevation: 6,
  },
  reloadButtonText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '900',
    marginLeft: 8,
  },
  scrollArea: { flex: 1 },
  scrollContent: { paddingBottom: 28 },
  loadingBox: { alignItems: 'center', paddingVertical: 40 },
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
  activityCardAnimated: { width: '100%', marginBottom: 14 },
  activityCard: {
    borderRadius: 24,
    padding: 16,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
    borderWidth: 1.5,
  },
  activityCardPending: {
    backgroundColor: '#ffffff',
    borderColor: '#e2e8f0',
  },
  activityCardDone: {
    backgroundColor: '#f0fdf4',
    borderColor: '#86efac',
  },
  activityHeader: { flexDirection: 'row', alignItems: 'center' },
  activityIcon: {
    width: 54,
    height: 54,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 3,
    borderColor: '#f8fafc',
  },
  activityTextBox: { flex: 1 },
  activityTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
  },
  activityTitle: {
    color: '#0f172a',
    fontSize: 17,
    fontWeight: '900',
    flexShrink: 1,
  },
  activityDescription: {
    color: '#475569',
    fontSize: 12,
    fontWeight: '800',
    marginTop: 4,
    lineHeight: 17,
  },
  statusBadge: {
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderWidth: 1,
  },
  statusBadgePending: {
    backgroundColor: '#fef3c7',
    borderColor: '#f59e0b',
  },
  statusBadgeDone: {
    backgroundColor: '#dcfce7',
    borderColor: '#22c55e',
  },
  statusBadgeText: {
    fontSize: 10,
    fontWeight: '900',
  },
  statusBadgeTextPending: {
    color: '#92400e',
  },
  statusBadgeTextDone: {
    color: '#166534',
  },
  metaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 14,
  },
  metaBadge: {
    backgroundColor: '#f8fafc',
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: '#e2e8f0',
  },
  metaText: {
    color: '#334155',
    fontSize: 12,
    fontWeight: '900',
  },
  repeatBox: {
    marginTop: 12,
    backgroundColor: '#eef2ff',
    borderRadius: 16,
    padding: 10,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#c7d2fe',
  },
  repeatText: {
    color: '#4F46E5',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 7,
    flex: 1,
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 14,
  },
  actionButton: {
    flex: 1,
    borderRadius: 16,
    paddingVertical: 11,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
  },
  actionButtonDone: {
    backgroundColor: '#dcfce7',
    borderColor: '#22c55e',
  },
  actionButtonPending: {
    backgroundColor: '#fef3c7',
    borderColor: '#f59e0b',
  },
  actionButtonEdit: {
    flex: 1,
    borderRadius: 16,
    paddingVertical: 11,
    backgroundColor: '#4F46E5',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  actionButtonDelete: {
    width: 48,
    borderRadius: 16,
    paddingVertical: 11,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center',
  },
  actionButtonText: {
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 5,
  },
  actionButtonTextDone: {
    color: '#166534',
  },
  actionButtonTextPending: {
    color: '#92400e',
  },
  actionButtonTextWhite: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '900',
    marginLeft: 5,
  },
  overlay: {
    position: 'absolute',
    width,
    height,
    top: 0,
    left: 0,
    zIndex: 999,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  overlayBackdrop: {
    position: 'absolute',
    width,
    height,
    backgroundColor: 'rgba(15, 23, 42, 0.78)',
  },
  modalCard: {
    width: '100%',
    maxWidth: 520,
    maxHeight: height * 0.88,
    backgroundColor: '#ffffff',
    borderRadius: 30,
    padding: 18,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.25,
    shadowRadius: 24,
    elevation: 16,
    borderWidth: 2,
    borderColor: '#c7d2fe',
  },
  modalHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 14 },
  formCategoryIcon: {
    width: 54,
    height: 54,
    borderRadius: 18,
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 3,
    borderColor: '#f8fafc',
  },
  formHeaderTextBox: { flex: 1 },
  formTitle: { color: '#1e293b', fontSize: 20, fontWeight: '900' },
  formSubtitle: { color: '#64748b', fontSize: 13, fontWeight: '700', marginTop: 2 },
  closeFormButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#ef4444',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 5,
  },
  modalScroll: { maxHeight: height * 0.72 },
  modalScrollContent: { paddingBottom: 8 },
  inputLabel: {
    color: '#334155',
    fontSize: 13,
    fontWeight: '900',
    marginBottom: 7,
    marginTop: 8,
  },
  inputContainer: {
    minHeight: 54,
    borderWidth: 1.5,
    borderColor: '#dbeafe',
    backgroundColor: '#f8fafc',
    borderRadius: 16,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
  },
  textAreaContainer: { minHeight: 88, alignItems: 'flex-start', paddingTop: 14 },
  input: {
    flex: 1,
    marginLeft: 10,
    color: '#1e293b',
    fontSize: 15,
    fontWeight: '700',
    outlineStyle: 'none',
  },
  textArea: { minHeight: 60, textAlignVertical: 'top' },
  priorityRow: { flexDirection: 'row', gap: 10, marginBottom: 4 },
  priorityButton: {
    flex: 1,
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    backgroundColor: '#ffffff',
    borderRadius: 999,
    paddingVertical: 11,
    alignItems: 'center',
  },
  priorityText: { color: '#64748b', fontSize: 13, fontWeight: '900' },
  priorityTextActive: { color: '#ffffff' },
  statusRow: { flexDirection: 'row', gap: 10 },
  statusButton: {
    flex: 1,
    borderRadius: 999,
    paddingVertical: 12,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    backgroundColor: '#ffffff',
  },
  statusButtonPendingActive: {
    backgroundColor: '#fef3c7',
    borderColor: '#f59e0b',
  },
  statusButtonDoneActive: {
    backgroundColor: '#dcfce7',
    borderColor: '#22c55e',
  },
  statusButtonText: {
    color: '#64748b',
    fontSize: 13,
    fontWeight: '900',
  },
  statusButtonTextPendingActive: {
    color: '#92400e',
  },
  statusButtonTextDoneActive: {
    color: '#166534',
  },
  expAutoBox: {
    backgroundColor: '#1e1b4b',
    borderRadius: 18,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  expIconBox: {
    width: 52,
    height: 52,
    borderRadius: 18,
    backgroundColor: '#f59e0b',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 3,
    borderColor: '#ffffff',
  },
  expTextBox: { flex: 1 },
  expValue: { color: '#ffffff', fontSize: 24, fontWeight: '900' },
  expDescription: {
    color: '#c7d2fe',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  saveButton: {
    backgroundColor: '#4F46E5',
    borderRadius: 18,
    paddingVertical: 16,
    marginTop: 18,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#4F46E5',
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 6,
  },
  saveButtonDisabled: { backgroundColor: '#94a3b8', shadowOpacity: 0 },
  saveButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '900',
    marginLeft: 8,
  },
  bottomSpace: { height: 20 },
});