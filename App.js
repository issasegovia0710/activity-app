import React, { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View } from 'react-native';

import storage from './src/config/storage';
import api from './src/config/api';
import TEMAS from './src/config/themes';

import LoginScreen from './src/screens/LoginScreen';
import DashboardScreen from './src/screens/DashboardScreen';
import MisionesScreen from './src/screens/MisionesScreen';
import ActivitisDashScreen from './src/screens/ActivitisDashScreen';
import EstadisticasScreen from './src/screens/EstadisticasScreen';
import AjustesScreen from './src/screens/AjustesScreen';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState('Login');
  const [usuario, setUsuario] = useState(null);
  const [routeParams, setRouteParams] = useState({});
  const [cargandoSesion, setCargandoSesion] = useState(true);

  const [temaActual, setTemaActual] = useState('clasico');
  const tema = TEMAS[temaActual] || TEMAS.clasico;

  useEffect(() => {
    revisarSesion();
  }, []);

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

  const cargarTemaGuardado = async () => {
    try {
      const temaGuardado = await storage.getItem('tema_app');

      if (temaGuardado && TEMAS[temaGuardado]) {
        setTemaActual(temaGuardado);
      }
    } catch (error) {
      console.log('Error al cargar tema:', error.message);
    }
  };

  const cambiarTemaGlobal = async (nuevoTema) => {
    try {
      if (!TEMAS[nuevoTema]) {
        return;
      }

      setTemaActual(nuevoTema);
      await storage.setItem('tema_app', nuevoTema);
    } catch (error) {
      console.log('Error al guardar tema:', error.message);
    }
  };

  const limpiarSesionCompleta = async () => {
    await eliminarStorageItem('token');
    await eliminarStorageItem('usuario');

    if (api.defaults?.headers?.common?.Authorization) {
      delete api.defaults.headers.common.Authorization;
    }

    setUsuario(null);
    setRouteParams({});
    setCurrentScreen('Login');
  };

  const revisarSesion = async () => {
    try {
      await cargarTemaGuardado();

      const tokenGuardado = await storage.getItem('token');
      const usuarioGuardado = await storage.getItem('usuario');

      if (tokenGuardado && usuarioGuardado) {
        const usuarioParseado = JSON.parse(usuarioGuardado);

        setUsuario(usuarioParseado);
        setRouteParams({
          usuario: usuarioParseado,
        });
        setCurrentScreen('Dashboard');
      } else {
        setUsuario(null);
        setRouteParams({});
        setCurrentScreen('Login');
      }
    } catch (error) {
      console.log('Error al revisar sesión:', error.message);
      await limpiarSesionCompleta();
    } finally {
      setCargandoSesion(false);
    }
  };

  const navigateTo = (screenName, params = {}) => {
    setRouteParams({
      ...params,
      usuario,
      tema,
      temaActual,
    });

    setCurrentScreen(screenName);
  };

  const goBack = () => {
    setRouteParams({
      usuario,
      tema,
      temaActual,
    });

    setCurrentScreen('Dashboard');
  };

  const goToMisiones = () => {
    setRouteParams({
      usuario,
      tema,
      temaActual,
    });

    setCurrentScreen('Misiones');
  };

  const handleLogin = async (usuarioLogueado) => {
    setUsuario(usuarioLogueado);

    setRouteParams({
      usuario: usuarioLogueado,
      tema,
      temaActual,
    });

    setCurrentScreen('Dashboard');
  };

  const handleLogout = async () => {
    try {
      await limpiarSesionCompleta();
    } catch (error) {
      console.log('Error al cerrar sesión:', error.message);

      setUsuario(null);
      setRouteParams({});
      setCurrentScreen('Login');
    }
  };

  const navigation = {
    navigate: navigateTo,
    goBack,
    goToMisiones,
  };

  const route = {
    params: {
      ...routeParams,
      usuario,
      tema,
      temaActual,
    },
  };

  if (cargandoSesion) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: tema?.fondo || '#312e81',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <ActivityIndicator size="large" color="#ffffff" />
      </View>
    );
  }

  return (
    <>
      <StatusBar style="light" />

      {currentScreen === 'Login' && (
        <LoginScreen
          onLogin={handleLogin}
          tema={tema}
          temaActual={temaActual}
        />
      )}

      {currentScreen === 'Dashboard' && (
        <DashboardScreen
          usuario={usuario}
          onLogout={handleLogout}
          navigation={navigation}
          tema={tema}
          temaActual={temaActual}
        />
      )}

      {currentScreen === 'Misiones' && (
        <MisionesScreen
          route={route}
          navigation={navigation}
          tema={tema}
          temaActual={temaActual}
        />
      )}

      {currentScreen === 'ActivitisDash' && (
        <ActivitisDashScreen
          route={route}
          navigation={navigation}
          tema={tema}
          temaActual={temaActual}
        />
      )}

      {currentScreen === 'Estadisticas' && (
        <EstadisticasScreen
          route={route}
          navigation={navigation}
          tema={tema}
          temaActual={temaActual}
        />
      )}

      {currentScreen === 'Ajustes' && (
        <AjustesScreen
          route={route}
          navigation={navigation}
          onLogout={handleLogout}
          tema={tema}
          temaActual={temaActual}
          cambiarTemaGlobal={cambiarTemaGlobal}
        />
      )}
    </>
  );
}