import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Animated,
  Dimensions,
  Easing,
} from 'react-native';
// Importación corregida para quitar el Warning amarillo
import { SafeAreaView } from 'react-native-safe-area-context'; 
import { Ionicons } from '@expo/vector-icons';

import api from '../config/api';
import storage from '../config/storage';

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

export default function LoginScreen({ onLogin, tema }) {
  const temaSeguro = tema || TEMA_DEFAULT;

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [transitioning, setTransitioning] = useState(false);

  const fadeAnim = useState(new Animated.Value(0))[0];
  const slideAnim = useState(new Animated.Value(45))[0];
  const scaleAnim = useState(new Animated.Value(0.92))[0];
  const floatAnim = useState(new Animated.Value(0))[0];
  const runnerAnim = useState(new Animated.Value(0))[0];
  const buttonScale = useState(new Animated.Value(1))[0];
  const glowAnim = useState(new Animated.Value(0))[0];

  const transitionOpacity = useState(new Animated.Value(0))[0];
  const transitionScale = useState(new Animated.Value(0.2))[0];
  const transitionRunnerX = useState(new Animated.Value(-width))[0];
  const transitionPortalScale = useState(new Animated.Value(0))[0];
  const transitionPortalOpacity = useState(new Animated.Value(0))[0];
  const loginBoxExit = useState(new Animated.Value(1))[0];

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 900,
        useNativeDriver: false, // Corregido a false
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 850,
        easing: Easing.out(Easing.back(1.4)),
        useNativeDriver: false, // Corregido a false
      }),
      Animated.timing(scaleAnim, {
        toValue: 1,
        duration: 850,
        easing: Easing.out(Easing.back(1.2)),
        useNativeDriver: false, // Corregido a false
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
        Animated.timing(runnerAnim, {
          toValue: 1,
          duration: 700,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(runnerAnim, {
          toValue: 0,
          duration: 700,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    ).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(glowAnim, {
          toValue: 1,
          duration: 1300,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: false,
        }),
        Animated.timing(glowAnim, {
          toValue: 0,
          duration: 1300,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: false,
        }),
      ])
    ).start();
  }, [
    fadeAnim,
    slideAnim,
    scaleAnim,
    floatAnim,
    runnerAnim,
    glowAnim,
  ]);

  const handlePressIn = () => {
    Animated.spring(buttonScale, {
      toValue: 0.96,
      useNativeDriver: true,
      speed: 30,
      bounciness: 5,
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(buttonScale, {
      toValue: 1,
      useNativeDriver: true,
      speed: 25,
      bounciness: 8,
    }).start();
  };

  const startLoginTransition = (usuario) => {
    setTransitioning(true);

    transitionOpacity.setValue(0);
    transitionScale.setValue(0.2);
    transitionRunnerX.setValue(-width);
    transitionPortalScale.setValue(0);
    transitionPortalOpacity.setValue(0);
    loginBoxExit.setValue(1);

    Animated.sequence([
      Animated.parallel([
        Animated.timing(loginBoxExit, {
          toValue: 0.92,
          duration: 180,
          easing: Easing.out(Easing.ease),
          useNativeDriver: false, // Corregido a false
        }),
        Animated.timing(transitionOpacity, {
          toValue: 1,
          duration: 260,
          easing: Easing.out(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(transitionScale, {
          toValue: 1,
          duration: 400,
          easing: Easing.out(Easing.back(1.8)),
          useNativeDriver: true,
        }),
      ]),
      Animated.parallel([
        Animated.timing(transitionRunnerX, {
          toValue: width,
          duration: 850,
          easing: Easing.inOut(Easing.cubic),
          useNativeDriver: true,
        }),
        Animated.sequence([
          Animated.delay(230),
          Animated.parallel([
            Animated.timing(transitionPortalOpacity, {
              toValue: 1,
              duration: 220,
              useNativeDriver: true,
            }),
            Animated.timing(transitionPortalScale, {
              toValue: 1,
              duration: 420,
              easing: Easing.out(Easing.back(1.5)),
              useNativeDriver: true,
            }),
          ]),
          Animated.parallel([
            Animated.timing(transitionPortalScale, {
              toValue: 8,
              duration: 520,
              easing: Easing.in(Easing.cubic),
              useNativeDriver: true,
            }),
            Animated.timing(transitionPortalOpacity, {
              toValue: 0.95,
              duration: 520,
              useNativeDriver: true,
            }),
          ]),
        ]),
      ]),
    ]).start(() => {
      onLogin(usuario);
    });
  };

  const handleLogin = async () => {
    if (!username.trim() || !password.trim()) {
      Alert.alert('Atención', 'Ingresa tu usuario y contraseña, por favor.');
      return;
    }

    setLoading(true);

    try {
      const response = await api.post('/auth/login', {
        nombre_usuario: username.trim(),
        contrasena: password.trim(),
      });

      if (response.data.status === 'ok') {
        const token = response.data.token;
        const usuario = response.data.usuario;

        if (!token) {
          Alert.alert(
            'Error de sesión',
            'El servidor no regresó token. Revisa authController.js.'
          );
          setLoading(false);
          return;
        }

        if (!usuario || !usuario.id) {
          Alert.alert(
            'Error de usuario',
            'El servidor no regresó usuario.id. Revisa authController.js.'
          );
          setLoading(false);
          return;
        }

        await storage.setItem('token', token);
        await storage.setItem('usuario', JSON.stringify(usuario));

        console.log('Login exitoso:', usuario);

        setLoading(false);
        startLoginTransition(usuario);
      } else {
        Alert.alert(
          'Fallo al entrar',
          response.data.mensaje || 'No se pudo iniciar sesión'
        );
        setLoading(false);
      }
    } catch (error) {
      const errorMsg =
        error.response?.data?.mensaje ||
        error.response?.data?.detalle ||
        'No se pudo conectar con el servidor';

      console.error('Error en login:', error.response?.data || error.message);

      Alert.alert('Fallo al entrar', errorMsg);
      setLoading(false);
    }
  };

  const glowBorderColor = glowAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [
      temaSeguro.borde || '#c7d2fe',
      temaSeguro.primario || '#818cf8',
    ],
  });

  const glowShadowOpacity = glowAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.15, 0.35],
  });

  const runnerTranslateX = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [-8, 8],
  });

  const runnerTranslateY = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -6],
  });

  const runnerRotate = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['-4deg', '4deg'],
  });

  const shadowScale = runnerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 0.82],
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
          <Ionicons name="star" size={26} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleTwo,
            {
              backgroundColor: `${temaSeguro.aviso}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="diamond" size={28} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleThree,
            {
              backgroundColor: `${temaSeguro.exito}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="flash" size={24} color="#ffffff" />
        </Animated.View>

        <Animated.View
          style={[
            styles.bubble,
            styles.bubbleFour,
            {
              backgroundColor: `${temaSeguro.secundario}33`,
              transform: [{ translateY: floatAnim }],
            },
          ]}
        >
          <Ionicons name="planet" size={25} color="#ffffff" />
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
          styles.loginBox,
          {
            opacity: fadeAnim,
            backgroundColor: temaSeguro.tarjeta,
            borderColor: glowBorderColor,
            shadowColor: temaSeguro.primario,
            shadowOpacity: glowShadowOpacity,
            transform: [
              { translateY: slideAnim },
              { scale: Animated.multiply(scaleAnim, loginBoxExit) },
            ],
          },
        ]}
      >
        <View style={styles.runnerScene}>
          <Animated.View
            style={[
              styles.runnerShadow,
              {
                transform: [{ scaleX: shadowScale }],
              },
            ]}
          />

          <Animated.View
            style={[
              styles.runnerWrap,
              {
                backgroundColor: temaSeguro.primario,
                shadowColor: temaSeguro.primario,
                transform: [
                  { translateX: runnerTranslateX },
                  { translateY: runnerTranslateY },
                  { rotate: runnerRotate },
                ],
              },
            ]}
          >
            <View style={[styles.runnerHead, { backgroundColor: temaSeguro.barraXp }]}>
              <Ionicons name="happy" size={28} color="#ffffff" />
            </View>

            <View style={styles.runnerBody}>
              <Ionicons name="walk" size={42} color="#ffffff" />
            </View>

            <View style={styles.speedLines}>
              <View style={[styles.speedLineOne, { backgroundColor: temaSeguro.barraXp }]} />
              <View style={[styles.speedLineTwo, { backgroundColor: temaSeguro.primario }]} />
              <View style={[styles.speedLineThree, { backgroundColor: temaSeguro.secundario }]} />
            </View>
          </Animated.View>
        </View>

        <Text style={[styles.title, { color: temaSeguro.texto }]}>
          Activity Day Life
        </Text>

        <Text style={[styles.subtitle, { color: temaSeguro.textoSuave }]}>
          Corre hacia tus metas diarias
        </Text>

        <View
          style={[
            styles.gameMessageBox,
            {
              backgroundColor: `${temaSeguro.barraXp}18`,
              borderColor: `${temaSeguro.barraXp}66`,
            },
          ]}
        >
          <Ionicons name="sparkles" size={20} color={temaSeguro.barraXp} />
          <Text style={[styles.gameMessageText, { color: '#92400e' }]}>
            Prepara tu aventura del día
          </Text>
        </View>

        <View
          style={[
            styles.inputContainer,
            {
              borderColor: temaSeguro.borde,
              backgroundColor: '#f8fafc',
            },
          ]}
        >
          <Ionicons name="person-outline" size={22} color={temaSeguro.primario} />

          <TextInput
            style={styles.input}
            placeholder="Nombre de usuario"
            placeholderTextColor="#94a3b8"
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
            autoCorrect={false}
            editable={!loading && !transitioning}
          />
        </View>

        <View
          style={[
            styles.inputContainer,
            {
              borderColor: temaSeguro.borde,
              backgroundColor: '#f8fafc',
            },
          ]}
        >
          <Ionicons name="lock-closed-outline" size={22} color={temaSeguro.primario} />

          <TextInput
            style={styles.input}
            placeholder="Contraseña"
            secureTextEntry
            placeholderTextColor="#94a3b8"
            value={password}
            onChangeText={setPassword}
            autoCapitalize="none"
            autoCorrect={false}
            editable={!loading && !transitioning}
          />
        </View>

        <Animated.View
          style={[
            styles.buttonAnimatedWrap,
            {
              transform: [{ scale: buttonScale }],
            },
          ]}
        >
          <TouchableOpacity
            style={[
              styles.btnPrimary,
              {
                backgroundColor: temaSeguro.primario,
                shadowColor: temaSeguro.primario,
              },
              (loading || transitioning) && styles.btnDisabled,
            ]}
            onPress={handleLogin}
            onPressIn={handlePressIn}
            onPressOut={handlePressOut}
            disabled={loading || transitioning}
            activeOpacity={0.9}
          >
            {loading ? (
              <View style={styles.loadingContent}>
                <ActivityIndicator color="#ffffff" />
                <Text style={styles.loadingText}>Abriendo camino...</Text>
              </View>
            ) : transitioning ? (
              <View style={styles.buttonContent}>
                <Ionicons name="checkmark-circle" size={22} color="#ffffff" />
                <Text style={styles.btnText}>Acceso concedido</Text>
              </View>
            ) : (
              <View style={styles.buttonContent}>
                <Ionicons name="rocket" size={22} color="#ffffff" />
                <Text style={styles.btnText}>Entrar al Sistema</Text>
              </View>
            )}
          </TouchableOpacity>
        </Animated.View>

        <View style={styles.bottomIcons}>
          <View style={styles.miniBadge}>
            <Ionicons name="footsteps" size={16} color={temaSeguro.primario} />
          </View>

          <View style={styles.miniBadge}>
            <Ionicons name="flag" size={16} color={temaSeguro.secundario} />
          </View>

          <View style={styles.miniBadge}>
            <Ionicons name="sparkles" size={16} color={temaSeguro.barraXp} />
          </View>
        </View>

        <Text style={styles.footerText}>v1.0.0 - Desarrollo Local</Text>
      </Animated.View>

      {transitioning && (
        <Animated.View
          style={[
            styles.transitionOverlay,
            {
              pointerEvents: 'none',
              backgroundColor: temaSeguro.fondo,
              opacity: transitionOpacity,
              transform: [{ scale: transitionScale }],
            },
          ]}
        >
          <Animated.View
            style={[
              styles.portal,
              {
                backgroundColor: temaSeguro.primario,
                opacity: transitionPortalOpacity,
                transform: [{ scale: transitionPortalScale }],
              },
            ]}
          />

          <Animated.View
            style={[
              styles.transitionRunner,
              {
                transform: [{ translateX: transitionRunnerX }],
              },
            ]}
          >
            <View style={styles.transitionSpeedLines}>
              <View style={[styles.transitionLineOne, { backgroundColor: temaSeguro.barraXp }]} />
              <View style={[styles.transitionLineTwo, { backgroundColor: temaSeguro.primario }]} />
              <View style={[styles.transitionLineThree, { backgroundColor: temaSeguro.secundario }]} />
            </View>

            <View
              style={[
                styles.transitionRunnerCircle,
                {
                  backgroundColor: temaSeguro.primario,
                },
              ]}
            >
              <View
                style={[
                  styles.transitionRunnerHead,
                  { backgroundColor: temaSeguro.barraXp },
                ]}
              >
                <Ionicons name="happy" size={24} color="#ffffff" />
              </View>

              <Ionicons name="walk" size={46} color="#ffffff" />
            </View>
          </Animated.View>

          <View style={styles.transitionTextBox}>
            <Text style={styles.transitionTitle}>Entrando...</Text>
            <Text style={[styles.transitionSubtitle, { color: temaSeguro.borde }]}>
              Preparando tu tablero
            </Text>
          </View>
        </Animated.View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#312e81',
    justifyContent: 'center',
    alignItems: 'center',
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
    borderColor: 'rgba(255, 255, 255, 0.22)',
  },
  bubbleOne: {
    top: height * 0.12,
    left: width * 0.12,
  },
  bubbleTwo: {
    top: height * 0.2,
    right: width * 0.1,
    width: 72,
    height: 72,
    borderRadius: 36,
  },
  bubbleThree: {
    bottom: height * 0.13,
    left: width * 0.14,
  },
  bubbleFour: {
    bottom: height * 0.22,
    right: width * 0.16,
    width: 62,
    height: 62,
    borderRadius: 31,
  },
  circleLarge: {
    position: 'absolute',
    width: 260,
    height: 260,
    borderRadius: 130,
    top: -80,
    right: -80,
  },
  circleSmall: {
    position: 'absolute',
    width: 180,
    height: 180,
    borderRadius: 90,
    bottom: -50,
    right: 20,
  },
  loginBox: {
    width: width > 500 ? 460 : '88%',
    padding: 34,
    backgroundColor: '#ffffff',
    borderRadius: 34,
    alignItems: 'center',
    borderWidth: 2,
    shadowColor: '#818cf8',
    shadowOffset: { width: 0, height: 12 },
    shadowRadius: 24,
    elevation: 12,
  },
  runnerScene: {
    width: 145,
    height: 125,
    marginTop: -86,
    marginBottom: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  runnerWrap: {
    width: 105,
    height: 105,
    borderRadius: 52.5,
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 5,
    borderColor: '#ffffff',
    shadowColor: '#6366f1',
    shadowOffset: { width: 0, height: 9 },
    shadowOpacity: 0.35,
    shadowRadius: 18,
    elevation: 9,
  },
  runnerHead: {
    position: 'absolute',
    top: 11,
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: '#f59e0b',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#ffffff',
    zIndex: 2,
  },
  runnerBody: {
    marginTop: 32,
  },
  runnerShadow: {
    position: 'absolute',
    bottom: 7,
    width: 78,
    height: 12,
    borderRadius: 999,
    backgroundColor: 'rgba(30, 41, 59, 0.18)',
  },
  speedLines: {
    position: 'absolute',
    left: -28,
    top: 32,
  },
  speedLineOne: {
    width: 26,
    height: 4,
    borderRadius: 999,
    backgroundColor: '#facc15',
    marginBottom: 7,
  },
  speedLineTwo: {
    width: 18,
    height: 4,
    borderRadius: 999,
    backgroundColor: '#38bdf8',
    marginBottom: 7,
    marginLeft: 8,
  },
  speedLineThree: {
    width: 30,
    height: 4,
    borderRadius: 999,
    backgroundColor: '#fb7185',
  },
  title: {
    fontSize: 32,
    fontWeight: '900',
    color: '#1e293b',
    textAlign: 'center',
    letterSpacing: -1,
  },
  subtitle: {
    fontSize: 15,
    color: '#64748b',
    marginBottom: 20,
    marginTop: 7,
    textAlign: 'center',
  },
  gameMessageBox: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fffbeb',
    borderWidth: 1,
    borderColor: '#fde68a',
    borderRadius: 18,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginBottom: 20,
  },
  gameMessageText: {
    color: '#92400e',
    fontSize: 13,
    fontWeight: '900',
    marginLeft: 8,
    textAlign: 'center',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
    borderRadius: 18,
    paddingHorizontal: 18,
    marginBottom: 16,
    width: '100%',
    height: 60,
    borderWidth: 1.5,
    borderColor: '#dbeafe',
  },
  input: {
    flex: 1,
    marginLeft: 12,
    color: '#1e293b',
    fontSize: 16,
    height: '100%',
    fontWeight: '600',
    outlineStyle: 'none',
  },
  buttonAnimatedWrap: {
    width: '100%',
    marginTop: 8,
  },
  btnPrimary: {
    backgroundColor: '#4F46E5',
    width: '100%',
    paddingVertical: 18,
    borderRadius: 18,
    alignItems: 'center',
    shadowColor: '#4F46E5',
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.32,
    shadowRadius: 10,
    elevation: 6,
  },
  btnDisabled: {
    backgroundColor: '#94a3b8',
    shadowOpacity: 0,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    color: '#ffffff',
    fontWeight: '800',
    fontSize: 15,
    marginLeft: 10,
  },
  btnText: {
    color: '#ffffff',
    fontWeight: '900',
    fontSize: 16,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginLeft: 9,
  },
  bottomIcons: {
    flexDirection: 'row',
    marginTop: 18,
    gap: 10,
  },
  miniBadge: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#f8fafc',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  footerText: {
    marginTop: 18,
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '600',
  },
  transitionOverlay: {
    position: 'absolute',
    width,
    height,
    backgroundColor: '#312e81',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 50,
  },
  portal: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#818cf8',
    borderWidth: 10,
    borderColor: '#ffffff',
    shadowColor: '#ffffff',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.9,
    shadowRadius: 30,
    elevation: 20,
  },
  transitionRunner: {
    position: 'absolute',
    width,
    height: 140,
    top: height * 0.42,
    left: 0,
    justifyContent: 'center',
    alignItems: 'center',
  },
  transitionRunnerCircle: {
    width: 108,
    height: 108,
    borderRadius: 54,
    backgroundColor: '#4F46E5',
    borderWidth: 5,
    borderColor: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#ffffff',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.55,
    shadowRadius: 18,
    elevation: 12,
  },
  transitionRunnerHead: {
    position: 'absolute',
    top: 8,
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#f59e0b',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#ffffff',
    zIndex: 3,
  },
  transitionSpeedLines: {
    position: 'absolute',
    left: width * 0.36,
    zIndex: 3,
  },
  transitionLineOne: {
    width: 70,
    height: 6,
    borderRadius: 999,
    backgroundColor: '#facc15',
    marginBottom: 12,
  },
  transitionLineTwo: {
    width: 52,
    height: 6,
    borderRadius: 999,
    backgroundColor: '#38bdf8',
    marginBottom: 12,
    marginLeft: 18,
  },
  transitionLineThree: {
    width: 82,
    height: 6,
    borderRadius: 999,
    backgroundColor: '#fb7185',
  },
  transitionTextBox: {
    position: 'absolute',
    bottom: height * 0.18,
    alignItems: 'center',
  },
  transitionTitle: {
    color: '#ffffff',
    fontSize: 30,
    fontWeight: '900',
    letterSpacing: -0.5,
  },
  transitionSubtitle: {
    color: '#c7d2fe',
    fontSize: 15,
    fontWeight: '700',
    marginTop: 6,
  },
});