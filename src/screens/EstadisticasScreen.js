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

export default function EstadisticasScreen({ route, navigation, tema }) {
  const temaSeguro = tema || route?.params?.tema || TEMA_DEFAULT;

  const usuarioInicial = route?.params?.usuario || null;
  const misionesIniciales = route?.params?.misiones || [];

  const [usuario, setUsuario] = useState(usuarioInicial);
  const [nivelInfo, setNivelInfo] = useState(route?.params?.nivelInfo || null);
  const [misiones, setMisiones] = useState(misionesIniciales);
  const [cargando, setCargando] = useState(true);

  const fadeAnim = useState(new Animated.Value(0))[0];
  const slideAnim = useState(new Animated.Value(35))[0];
  const floatAnim = useState(new Animated.Value(0))[0];

  const xpTotal = Number(usuario?.exp || 0);
  const nivelActual = Number(usuario?.nivel || nivelInfo?.nivel || 1);

  const expNivelActual = Number(nivelInfo?.exp_nivel_actual || 0);
  const expSiguienteNivel = Number(nivelInfo?.exp_siguiente_nivel || 0);
  const expParaSubir = Number(nivelInfo?.exp_para_subir || 0);
  const porcentajeNivel = Number(nivelInfo?.porcentaje || 0);

  const xpDentroDelNivel =
    expSiguienteNivel > expNivelActual
      ? xpTotal - expNivelActual
      : xpTotal;

  const xpNecesariaDelNivel =
    expSiguienteNivel > expNivelActual
      ? expSiguienteNivel - expNivelActual
      : 0;

  const progresoNivel = `${Math.max(0, Math.min(100, porcentajeNivel))}%`;

  const misionesTotales = misiones.length;

  const misionesCompletadas = misiones.filter(
    (mision) =>
      mision.estatus === 'completada' ||
      mision.completada === true
  ).length;

  const misionesNoCumplidas = misiones.filter(
    (mision) => mision.estatus === 'no_cumplida'
  ).length;

  const misionesPendientes = misiones.filter(
    (mision) => mision.estatus === 'pendiente'
  ).length;

  const misionesEnProceso = misiones.filter(
    (mision) => mision.estadoTiempo === 'en_proceso'
  ).length;

  const misionesPorAbrir = misiones.filter(
    (mision) => mision.estadoTiempo === 'por_abrir'
  ).length;

  const porcentajeCompletado =
    misionesTotales > 0
      ? Math.round((misionesCompletadas / misionesTotales) * 100)
      : 0;

  useEffect(() => {
    iniciarAnimaciones();
    cargarDatos();
  }, []);

  const iniciarAnimaciones = () => {
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
  };

  const cargarDatos = async () => {
    try {
      setCargando(true);

      const [nivelResponse, actividadesResponse] = await Promise.all([
        api.get('/auth/nivel'),
        api.get('/actividades'),
      ]);

      if (nivelResponse.data?.usuario) {
        setUsuario(nivelResponse.data.usuario);
      }

      if (nivelResponse.data?.nivel_info) {
        setNivelInfo(nivelResponse.data.nivel_info);
      }

      if (actividadesResponse.data?.actividades) {
        setMisiones(actividadesResponse.data.actividades);
      }
    } catch (error) {
      console.log(
        'Error al cargar estadísticas:',
        error.response?.data || error.message
      );
    } finally {
      setCargando(false);
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
          <Ionicons name="bar-chart" size={24} color="#ffffff" />
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
          <Ionicons name="trophy" size={24} color="#ffffff" />
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
            <Text style={styles.title}>Estadísticas</Text>
            <Text style={[styles.subtitle, { color: temaSeguro.borde }]}>
              Resumen de progreso del jugador
            </Text>
          </View>

          <TouchableOpacity
            style={[
              styles.refreshButton,
              {
                borderColor: temaSeguro.borde,
              },
            ]}
            onPress={cargarDatos}
            activeOpacity={0.85}
          >
            <Ionicons
              name="refresh-outline"
              size={22}
              color={temaSeguro.primario}
            />
          </TouchableOpacity>
        </View>

        {cargando ? (
          <View style={styles.loadingBox}>
            <ActivityIndicator size="large" color="#ffffff" />
            <Text style={styles.loadingText}>Cargando estadísticas...</Text>
          </View>
        ) : (
          <ScrollView
            style={styles.scrollArea}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            <View style={[styles.bigStatCard, { backgroundColor: temaSeguro.tarjeta }]}>
              <View style={[styles.bigStatIcon, { backgroundColor: temaSeguro.primario }]}>
                <Ionicons name="flash" size={34} color="#ffffff" />
              </View>

              <Text style={[styles.bigStatValue, { color: temaSeguro.texto }]}>
                {xpTotal}
              </Text>

              <Text style={[styles.bigStatLabel, { color: temaSeguro.textoSuave }]}>
                Experiencia total
              </Text>

              <View style={styles.levelRow}>
                <Text style={[styles.levelText, { color: temaSeguro.textoSuave }]}>
                  Nivel {nivelActual}
                </Text>

                <Text style={[styles.levelText, { color: temaSeguro.textoSuave }]}>
                  {xpNecesariaDelNivel > 0
                    ? `${xpDentroDelNivel} / ${xpNecesariaDelNivel} XP`
                    : 'Nivel máximo'}
                </Text>
              </View>

              <View style={styles.xpBarBackground}>
                <View
                  style={[
                    styles.xpBarFill,
                    {
                      width: progresoNivel,
                      backgroundColor: temaSeguro.barraXp,
                    },
                  ]}
                />
              </View>

              <Text style={styles.nextLevelText}>
                {expParaSubir > 0
                  ? `Faltan ${expParaSubir} XP para el siguiente nivel`
                  : 'Nivel máximo alcanzado'}
              </Text>
            </View>

            <View style={styles.statsGrid}>
              <InfoCard
                icon="trophy-outline"
                label="Nivel actual"
                value={nivelActual}
                color={temaSeguro.primario}
                bg={temaSeguro.suavePrimario || '#ede9fe'}
                tema={temaSeguro}
              />

              <InfoCard
                icon="hourglass-outline"
                label="XP del nivel"
                value={
                  xpNecesariaDelNivel > 0
                    ? `${xpDentroDelNivel}/${xpNecesariaDelNivel}`
                    : `${xpTotal}`
                }
                color={temaSeguro.barraXp}
                bg="#fffbeb"
                tema={temaSeguro}
              />

              <InfoCard
                icon="flag-outline"
                label="Pendientes"
                value={misionesPendientes}
                color={temaSeguro.secundario}
                bg={temaSeguro.suaveSecundario || '#fce7f3'}
                tema={temaSeguro}
              />

              <InfoCard
                icon="play-circle-outline"
                label="En proceso"
                value={misionesEnProceso}
                color="#14b8a6"
                bg="#ccfbf1"
                tema={temaSeguro}
              />

              <InfoCard
                icon="hourglass-outline"
                label="Próximas"
                value={misionesPorAbrir}
                color="#0ea5e9"
                bg="#e0f2fe"
                tema={temaSeguro}
              />

              <InfoCard
                icon="checkmark-done-outline"
                label="Completadas"
                value={misionesCompletadas}
                color={temaSeguro.exito}
                bg="#dcfce7"
                tema={temaSeguro}
              />

              <InfoCard
                icon="close-circle-outline"
                label="No cumplidas"
                value={misionesNoCumplidas}
                color={temaSeguro.peligro}
                bg="#fee2e2"
                tema={temaSeguro}
              />

              <InfoCard
                icon="list-outline"
                label="Total"
                value={misionesTotales}
                color="#7c3aed"
                bg="#f3e8ff"
                tema={temaSeguro}
              />
            </View>

            <View style={[styles.progressSummaryCard, { backgroundColor: temaSeguro.tarjeta }]}>
              <View style={styles.progressHeaderRow}>
                <View>
                  <Text style={[styles.progressSummaryTitle, { color: temaSeguro.texto }]}>
                    Avance de misiones
                  </Text>

                  <Text style={[styles.progressSummaryText, { color: temaSeguro.textoSuave }]}>
                    {misionesCompletadas} de {misionesTotales} misiones completadas
                  </Text>
                </View>

                <Text
                  style={[
                    styles.progressSummaryPercent,
                    { color: temaSeguro.primario },
                  ]}
                >
                  {porcentajeCompletado}%
                </Text>
              </View>

              <View style={styles.progressSummaryBar}>
                <View
                  style={[
                    styles.progressSummaryFill,
                    {
                      width: `${porcentajeCompletado}%`,
                      backgroundColor: temaSeguro.primario,
                    },
                  ]}
                />
              </View>
            </View>

            <View style={[styles.progressSummaryCard, { backgroundColor: temaSeguro.tarjeta }]}>
              <Text style={[styles.progressSummaryTitle, { color: temaSeguro.texto }]}>
                Resumen rápido
              </Text>

              <View style={styles.summaryLine}>
                <Ionicons
                  name="person-circle-outline"
                  size={19}
                  color={temaSeguro.primario}
                />

                <Text style={styles.summaryLineText}>
                  Jugador: {usuario?.nombre_usuario || 'Sin usuario'}
                </Text>
              </View>

              <View style={styles.summaryLine}>
                <Ionicons
                  name="sparkles-outline"
                  size={19}
                  color={temaSeguro.barraXp}
                />

                <Text style={styles.summaryLineText}>
                  EXP total acumulada: {xpTotal}
                </Text>
              </View>

              <View style={styles.summaryLine}>
                <Ionicons
                  name="trending-up-outline"
                  size={19}
                  color={temaSeguro.exito}
                />

                <Text style={styles.summaryLineText}>
                  Progreso del nivel: {porcentajeNivel}%
                </Text>
              </View>
            </View>

            <View style={styles.bottomSpace} />
          </ScrollView>
        )}
      </Animated.View>
    </SafeAreaView>
  );
}

function InfoCard({ icon, label, value, color, bg, tema }) {
  const temaSeguro = tema || TEMA_DEFAULT;

  return (
    <View style={[styles.infoCard, { backgroundColor: temaSeguro.tarjeta }]}>
      <View style={[styles.infoIcon, { backgroundColor: bg }]}>
        <Ionicons name={icon} size={22} color={color} />
      </View>

      <Text style={[styles.infoValue, { color: temaSeguro.texto }]}>
        {value}
      </Text>

      <Text style={[styles.infoLabel, { color: temaSeguro.textoSuave }]}>
        {label}
      </Text>
    </View>
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
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 2,
    borderColor: '#c7d2fe',
  },
  refreshButton: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 10,
    borderWidth: 2,
    borderColor: '#c7d2fe',
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
  loadingBox: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
    marginTop: 12,
  },
  scrollArea: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 28,
  },
  bigStatCard: {
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
  bigStatIcon: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  bigStatValue: {
    fontSize: 42,
    fontWeight: '900',
    color: '#1e293b',
  },
  bigStatLabel: {
    color: '#64748b',
    fontSize: 14,
    fontWeight: '800',
    marginTop: 2,
  },
  levelRow: {
    width: '100%',
    marginTop: 14,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  levelText: {
    color: '#64748b',
    fontSize: 13,
    fontWeight: '900',
  },
  nextLevelText: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '800',
    marginTop: 9,
    textAlign: 'center',
  },
  xpBarBackground: {
    width: '100%',
    height: 12,
    backgroundColor: '#e2e8f0',
    borderRadius: 999,
    overflow: 'hidden',
    marginTop: 10,
  },
  xpBarFill: {
    height: '100%',
    backgroundColor: '#f59e0b',
    borderRadius: 999,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  infoCard: {
    width: (width - 46) / 2,
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  infoIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  infoValue: {
    fontSize: 24,
    fontWeight: '900',
    color: '#1e293b',
  },
  infoLabel: {
    color: '#64748b',
    fontSize: 12,
    fontWeight: '800',
    marginTop: 2,
    textAlign: 'center',
  },
  progressSummaryCard: {
    backgroundColor: '#ffffff',
    borderRadius: 24,
    padding: 18,
    marginTop: 14,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 15,
    elevation: 5,
  },
  progressHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  progressSummaryTitle: {
    color: '#1e293b',
    fontSize: 16,
    fontWeight: '900',
  },
  progressSummaryPercent: {
    color: '#4F46E5',
    fontSize: 34,
    fontWeight: '900',
    marginLeft: 10,
  },
  progressSummaryBar: {
    height: 12,
    backgroundColor: '#e2e8f0',
    borderRadius: 999,
    overflow: 'hidden',
    marginTop: 12,
  },
  progressSummaryFill: {
    height: '100%',
    backgroundColor: '#4F46E5',
    borderRadius: 999,
  },
  progressSummaryText: {
    color: '#64748b',
    fontSize: 13,
    fontWeight: '700',
    marginTop: 4,
  },
  summaryLine: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
  },
  summaryLineText: {
    color: '#475569',
    fontSize: 13,
    fontWeight: '800',
    marginLeft: 8,
    flex: 1,
  },
  bottomSpace: {
    height: 10,
  },
});