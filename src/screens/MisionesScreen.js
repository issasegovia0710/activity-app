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
import { programarNotificacionesTarea } from '../utils/notificacionesTareas';

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

const REPETICIONES = [
    { id: 1, valor: 'una vez', etiqueta: 'Una vez' },
    { id: 2, valor: 'diario', etiqueta: 'Diario' },
    { id: 3, valor: 'lunes a viernes', etiqueta: 'L-V' },
    { id: 4, valor: 'sabado domingo', etiqueta: 'S-D' },
    { id: 5, valor: 'personalizada', etiqueta: 'Personalizada' },
];

const DIAS = [
    { codigo: 'L', nombre: 'Lunes', corto: 'L', jsDay: 1 },
    { codigo: 'M', nombre: 'Martes', corto: 'M', jsDay: 2 },
    { codigo: 'MI', nombre: 'Miércoles', corto: 'MI', jsDay: 3 },
    { codigo: 'J', nombre: 'Jueves', corto: 'J', jsDay: 4 },
    { codigo: 'V', nombre: 'Viernes', corto: 'V', jsDay: 5 },
    { codigo: 'S', nombre: 'Sábado', corto: 'S', jsDay: 6 },
    { codigo: 'D', nombre: 'Domingo', corto: 'D', jsDay: 0 },
];

export default function MisionesScreen({ route, navigation, tema }) {
    const temaSeguro = tema || route?.params?.tema || TEMA_DEFAULT;
    const usuario = route?.params?.usuario;

    const coloresTipos = [
        temaSeguro.primario,
        temaSeguro.barraXp,
        temaSeguro.secundario,
        '#14b8a6',
        '#7c3aed',
        '#0ea5e9',
        temaSeguro.peligro,
        temaSeguro.exito,
    ];

    const [tipos, setTipos] = useState([]);
    const [cargandoTipos, setCargandoTipos] = useState(false);

    const [tipoSeleccionado, setTipoSeleccionado] = useState(null);
    const [mostrarFormulario, setMostrarFormulario] = useState(false);
    const [guardando, setGuardando] = useState(false);

    const [nombre, setNombre] = useState('');
    const [descripcion, setDescripcion] = useState('');
    const [tipoTexto, setTipoTexto] = useState('');
    const [prioridad, setPrioridad] = useState('media');
    const [duracionHoras, setDuracionHoras] = useState('');
    const [repetecion, setRepetecion] = useState('una vez');

    const [fechaUnica, setFechaUnica] = useState('');
    const [horaInicio, setHoraInicio] = useState('');

    const [diasPersonalizados, setDiasPersonalizados] = useState({});
    const [horasPersonalizadas, setHorasPersonalizadas] = useState({});

    const [actividadAutoacompletable, setActividadAutoacompletable] = useState(false);

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
        cargarTipos();
    }, []);

    const cargarTipos = async () => {
        try {
            setCargandoTipos(true);

            const response = await api.get('/actividades/tipos');
            const tiposDB = response.data?.tipos || [];

            const tiposFormateados = tiposDB.map((tipo, index) => ({
                id: tipo.id || index + 1,
                nombre: tipo.nombre,
                descripcion: 'Ver, editar y administrar actividades de esta categoría.',
                icono: obtenerIconoTipo(tipo.nombre),
                color: coloresTipos[index % coloresTipos.length],
                fondo: temaSeguro.suavePrimario,
            }));

            setTipos(tiposFormateados);
        } catch (error) {
            console.log('Error al cargar tipos:', error.response?.data || error.message);

            Alert.alert(
                'Error',
                error.response?.data?.mensaje ||
                'No se pudieron cargar las categorías desde la base de datos.'
            );
        } finally {
            setCargandoTipos(false);
        }
    };

    const obtenerIconoTipo = (tipo) => {
        const texto = String(tipo || '').toLowerCase();

        if (texto.includes('vida') || texto.includes('diaria')) return 'home-outline';
        if (texto.includes('escuela') || texto.includes('estudio')) return 'school-outline';
        if (texto.includes('trabajo')) return 'briefcase-outline';
        if (texto.includes('salud')) return 'heart-outline';
        if (texto.includes('casa')) return 'construct-outline';

        return 'albums-outline';
    };

    const obtenerFechaHoy = () => {
        const fecha = new Date();
        const year = fecha.getFullYear();
        const month = String(fecha.getMonth() + 1).padStart(2, '0');
        const day = String(fecha.getDate()).padStart(2, '0');

        return `${year}-${month}-${day}`;
    };

    const obtenerHoraActual = () => {
        const fecha = new Date();
        const hours = String(fecha.getHours()).padStart(2, '0');
        const minutes = String(fecha.getMinutes()).padStart(2, '0');

        return `${hours}:${minutes}`;
    };

    const abrirFormulario = (tipo = null) => {
        setTipoSeleccionado(tipo);
        setMostrarFormulario(true);

        setNombre('');
        setDescripcion('');
        setTipoTexto(tipo?.nombre || '');
        setPrioridad('media');
        setDuracionHoras('');
        setRepetecion('una vez');

        setFechaUnica(obtenerFechaHoy());
        setHoraInicio(obtenerHoraActual());

        setDiasPersonalizados({});
        setHorasPersonalizadas({});

        setActividadAutoacompletable(false);

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

    const cerrarFormulario = () => {
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
            setMostrarFormulario(false);
            setTipoSeleccionado(null);
        });
    };

    const irAClasificacion = (categoria) => {
        navigation.navigate('ActivitisDash', {
            tipo: categoria.nombre,
            categoria,
            usuario,
            tema: temaSeguro,
        });
    };

    const calcularExpPorPrioridad = () => {
        if (prioridad === 'baja') return 5;
        if (prioridad === 'media') return 15;
        if (prioridad === 'alta') return 25;
        return 15;
    };

    const calcularBonusPorHoras = () => {
        const horas = Number(duracionHoras);

        if (!duracionHoras.trim() || Number.isNaN(horas) || horas <= 0) {
            return 0;
        }

        return Math.ceil(horas * 5);
    };

    const valorExpCalculado = calcularExpPorPrioridad() + calcularBonusPorHoras();

    const seleccionarRepeticion = (repeticionSeleccionada) => {
        setRepetecion(repeticionSeleccionada);

        if (repeticionSeleccionada !== 'personalizada') {
            setDiasPersonalizados({});
            setHorasPersonalizadas({});
        }
    };

    const cambiarDiaPersonalizado = (codigo) => {
        setDiasPersonalizados((actual) => {
            const nuevoValor = !actual[codigo];

            const nuevoObjeto = {
                ...actual,
                [codigo]: nuevoValor,
            };

            if (nuevoValor) {
                setHorasPersonalizadas((horasActuales) => ({
                    ...horasActuales,
                    [codigo]: horasActuales[codigo] || obtenerHoraActual(),
                }));
            }

            if (!nuevoValor) {
                setHorasPersonalizadas((horasActuales) => {
                    const copia = { ...horasActuales };
                    delete copia[codigo];
                    return copia;
                });
            }

            return nuevoObjeto;
        });
    };

    const cambiarHoraPersonalizada = (codigo, valor) => {
        setHorasPersonalizadas((actual) => ({
            ...actual,
            [codigo]: valor,
        }));
    };

    const fechaValida = (fecha) => {
        const fechaTexto = String(fecha || '').trim();

        if (!fechaTexto) return false;

        const regex = /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/;
        const match = fechaTexto.match(regex);

        if (!match) return false;

        const year = Number(match[1]);
        const month = Number(match[2]);
        const day = Number(match[3]);

        const fechaObj = new Date(year, month - 1, day);

        return (
            fechaObj.getFullYear() === year &&
            fechaObj.getMonth() === month - 1 &&
            fechaObj.getDate() === day
        );
    };

    const horaValida = (hora) => {
        const horaTexto = String(hora || '').trim();

        if (!horaTexto) return false;

        const regex = /^([0-9]{1,2}):([0-9]{2})$/;
        const match = horaTexto.match(regex);

        if (!match) return false;

        const horas = Number(match[1]);
        const minutos = Number(match[2]);

        return horas >= 0 && horas <= 23 && minutos >= 0 && minutos <= 59;
    };

    const normalizarHora = (hora) => {
        const horaTexto = String(hora || '').trim();

        if (!horaTexto) return '';

        const partes = horaTexto.split(':');

        if (partes.length !== 2) return horaTexto;

        const h = partes[0];
        const m = partes[1];

        if (h === '' || m === '') return horaTexto;

        return `${Number(h)}:${String(m).padStart(2, '0')}`;
    };

    const formatearFechaMysql = (fecha) => {
        const year = fecha.getFullYear();
        const month = String(fecha.getMonth() + 1).padStart(2, '0');
        const day = String(fecha.getDate()).padStart(2, '0');
        const hours = String(fecha.getHours()).padStart(2, '0');
        const minutes = String(fecha.getMinutes()).padStart(2, '0');
        const seconds = String(fecha.getSeconds()).padStart(2, '0');

        return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    };

    const construirDateDesdeMysql = (fechaMysql) => {
        if (!fechaMysql) {
            return null;
        }

        const fecha = new Date(String(fechaMysql).replace(' ', 'T'));

        if (Number.isNaN(fecha.getTime())) {
            return null;
        }

        return fecha;
    };

    const calcularFechaExpiracionMision = (fechaInicioMysql, duracionFinal) => {
        if (!duracionFinal || Number.isNaN(Number(duracionFinal)) || Number(duracionFinal) <= 0) {
            return null;
        }

        const fechaInicio = construirDateDesdeMysql(fechaInicioMysql);

        if (!fechaInicio) {
            return null;
        }

        return new Date(fechaInicio.getTime() + Number(duracionFinal) * 60 * 60 * 1000);
    };

    const obtenerIdActividadRespuesta = (response, actividad) => {
        const data = response?.data || {};

        return (
            data?.actividad?.id ||
            data?.actividad?.id_actividad ||
            data?.actividad?.idActividad ||
            data?.id ||
            data?.id_actividad ||
            data?.idActividad ||
            data?.actividadId ||
            `${actividad.nombre}-${actividad.fecha_inicio}`
        );
    };

    const construirFechaInicioMysql = (fecha, hora) => {
        if (!fechaValida(fecha) || !horaValida(hora)) {
            return null;
        }

        return `${String(fecha).trim()} ${normalizarHora(hora)}:00`;
    };

    const construirFechaConHora = (fechaBase, hora) => {
        if (!horaValida(hora)) {
            return null;
        }

        const partes = normalizarHora(hora).split(':');
        const horas = Number(partes[0]);
        const minutos = Number(partes[1]);

        const fecha = new Date(fechaBase);
        fecha.setHours(horas, minutos, 0, 0);

        return fecha;
    };

    const buscarProximaFechaPorDias = (diasPermitidos, hora) => {
        if (!horaValida(hora)) {
            return null;
        }

        const ahora = new Date();

        for (let i = 0; i <= 14; i += 1) {
            const candidataBase = new Date();
            candidataBase.setDate(ahora.getDate() + i);

            const codigoDia = DIAS.find((dia) => dia.jsDay === candidataBase.getDay())?.codigo;

            if (!diasPermitidos.includes(codigoDia)) {
                continue;
            }

            const candidata = construirFechaConHora(candidataBase, hora);

            if (!candidata) {
                continue;
            }

            if (candidata > ahora) {
                return formatearFechaMysql(candidata);
            }
        }

        return null;
    };

    const construirRepeticion = (modoPreview = false) => {
        if (repetecion === 'una vez') return 'una vez';

        if (repetecion === 'diario') {
            return 'diario';
        }

        if (repetecion === 'lunes a viernes') {
            return 'lunes a viernes';
        }

        if (repetecion === 'sabado domingo') {
            return 'sabado domingo';
        }

        if (repetecion === 'personalizada') {
            const diasSeleccionados = DIAS.filter((dia) => diasPersonalizados[dia.codigo]);

            if (diasSeleccionados.length === 0) {
                return modoPreview ? 'Selecciona días y horas' : null;
            }

            const partes = [];

            for (const dia of diasSeleccionados) {
                const horaDia = horasPersonalizadas[dia.codigo];

                if (!horaValida(horaDia)) {
                    if (modoPreview) partes.push(`${dia.codigo}-pendiente`);
                    continue;
                }

                partes.push(`${dia.codigo}-${normalizarHora(horaDia)}`);
            }

            if (partes.length === 0) {
                return modoPreview ? 'Completa las horas seleccionadas' : null;
            }

            return partes.join(', ');
        }

        return null;
    };

    const obtenerFechaInicioParaGuardar = () => {
        if (repetecion === 'una vez') {
            return construirFechaInicioMysql(fechaUnica, horaInicio);
        }

        if (repetecion === 'diario') {
            return buscarProximaFechaPorDias(
                ['L', 'M', 'MI', 'J', 'V', 'S', 'D'],
                horaInicio
            );
        }

        if (repetecion === 'lunes a viernes') {
            return buscarProximaFechaPorDias(
                ['L', 'M', 'MI', 'J', 'V'],
                horaInicio
            );
        }

        if (repetecion === 'sabado domingo') {
            return buscarProximaFechaPorDias(
                ['S', 'D'],
                horaInicio
            );
        }

        if (repetecion === 'personalizada') {
            const diasSeleccionados = DIAS.filter((dia) => diasPersonalizados[dia.codigo]);
            const candidatas = [];

            for (const dia of diasSeleccionados) {
                const horaDia = horasPersonalizadas[dia.codigo];

                if (!horaValida(horaDia)) {
                    continue;
                }

                const fechaProxima = buscarProximaFechaPorDias([dia.codigo], horaDia);

                if (!fechaProxima) {
                    continue;
                }

                candidatas.push({
                    fecha: fechaProxima,
                    timestamp: new Date(fechaProxima.replace(' ', 'T')).getTime(),
                });
            }

            if (candidatas.length === 0) {
                return null;
            }

            candidatas.sort((a, b) => a.timestamp - b.timestamp);

            return candidatas[0].fecha;
        }

        return null;
    };

    const validarRepeticion = () => {
        if (repetecion === 'una vez') {
            if (!fechaValida(fechaUnica)) {
                Alert.alert(
                    'Fecha inválida',
                    'Escribe la fecha en formato YYYY-MM-DD. Ejemplo: 2026-04-27'
                );
                return false;
            }

            if (!horaValida(horaInicio)) {
                Alert.alert(
                    'Hora inválida',
                    'Escribe una hora válida en formato H:MM o HH:MM. Ejemplo: 6:00'
                );
                return false;
            }

            return true;
        }

        if (
            repetecion === 'diario' ||
            repetecion === 'lunes a viernes' ||
            repetecion === 'sabado domingo'
        ) {
            if (!horaValida(horaInicio)) {
                Alert.alert(
                    'Hora inválida',
                    'Escribe una hora válida en formato H:MM o HH:MM. Ejemplo: 6:00'
                );
                return false;
            }

            return true;
        }

        if (repetecion === 'personalizada') {
            const diasSeleccionados = DIAS.filter((dia) => diasPersonalizados[dia.codigo]);

            if (diasSeleccionados.length === 0) {
                Alert.alert('Faltan días', 'Selecciona al menos un día.');
                return false;
            }

            for (const dia of diasSeleccionados) {
                const horaDia = horasPersonalizadas[dia.codigo];

                if (!horaValida(horaDia)) {
                    Alert.alert(
                        'Hora inválida',
                        `Escribe una hora válida para ${dia.nombre}. Ejemplo: 6:00`
                    );
                    return false;
                }
            }

            return true;
        }

        return true;
    };

    const guardarMision = async () => {
        if (!tipoTexto.trim()) {
            Alert.alert('Falta tipo', 'Escribe o elige un tipo/categoría para la misión.');
            return;
        }

        if (!nombre.trim()) {
            Alert.alert('Falta nombre', 'Escribe el nombre de la misión.');
            return;
        }

        if (
            duracionHoras.trim() &&
            (Number.isNaN(Number(duracionHoras)) || Number(duracionHoras) <= 0)
        ) {
            Alert.alert('Duración inválida', 'La duración debe ser un número mayor a 0.');
            return;
        }

        if (!validarRepeticion()) return;

        const duracionFinal =
            duracionHoras.trim() && !Number.isNaN(Number(duracionHoras))
                ? Number(duracionHoras)
                : null;

        const fechaInicioFinal = obtenerFechaInicioParaGuardar();

        if (!fechaInicioFinal) {
            Alert.alert('Falta fecha de inicio', 'No se pudo calcular la próxima fecha de inicio.');
            return;
        }

        const nuevaActividad = {
            nombre: nombre.trim(),
            descripcion: descripcion.trim() || null,
            tipo: tipoTexto.trim(),
            prioridad,
            valor_exp: valorExpCalculado,
            duracion_horas: duracionFinal,
            fecha_inicio: fechaInicioFinal,
            actividad_autoacompletable: actividadAutoacompletable ? 1 : 0,
            repetecion: construirRepeticion(false),
            estatus: 'pendiente',
            auxiliar: null,
        };

        try {
            setGuardando(true);

            const response = await api.post('/actividades', nuevaActividad);

            const fechaExpiracionCalculada = calcularFechaExpiracionMision(
                fechaInicioFinal,
                duracionFinal
            );

            const actividadParaNotificaciones = {
                id: obtenerIdActividadRespuesta(response, nuevaActividad),
                id_tarea: obtenerIdActividadRespuesta(response, nuevaActividad),
                titulo: nuevaActividad.nombre,
                nombre: nuevaActividad.nombre,
                descripcion: nuevaActividad.descripcion,
                tipo: nuevaActividad.tipo,
                prioridad: nuevaActividad.prioridad,
                estatus: nuevaActividad.estatus,
                fechaInicio: fechaInicioFinal,
                fecha_inicio: fechaInicioFinal,
                fechaExpiracion: fechaExpiracionCalculada
                    ? formatearFechaMysql(fechaExpiracionCalculada)
                    : null,
                fecha_expiracion: fechaExpiracionCalculada
                    ? formatearFechaMysql(fechaExpiracionCalculada)
                    : null,
                duracion_horas: duracionFinal,
                actividad_autoacompletable: nuevaActividad.actividad_autoacompletable,
            };

            const resultadoNotificaciones = await programarNotificacionesTarea(
                actividadParaNotificaciones
            );

            if (!resultadoNotificaciones?.ok) {
                console.log(
                    'La misión se guardó, pero no se pudieron programar notificaciones:',
                    resultadoNotificaciones?.mensaje
                );
            }

            Alert.alert(
                'Misión creada',
                response.data?.mensaje || 'La misión se dio de alta correctamente.'
            );

            setGuardando(false);
            cerrarFormulario();
            cargarTipos();
        } catch (error) {
            console.log('Error al guardar misión:', error.response?.data || error.message);

            const mensaje =
                error.response?.data?.mensaje ||
                error.response?.data?.detalle ||
                'No se pudo guardar la misión. Revisa el backend o la sesión.';

            Alert.alert('Error', mensaje);
            setGuardando(false);
        }
    };

    const renderCamposRepeticion = () => {
        if (repetecion === 'una vez') {
            return (
                <>
                    <Text style={styles.inputLabel}>Fecha y hora de inicio</Text>

                    <View style={styles.dateTimeRow}>
                        <View style={[styles.inputContainer, styles.dateInputBox]}>
                            <Ionicons name="calendar-outline" size={20} color={temaSeguro.primario} />
                            <TextInput
                                style={styles.input}
                                placeholder="YYYY-MM-DD"
                                placeholderTextColor="#94a3b8"
                                value={fechaUnica}
                                onChangeText={setFechaUnica}
                                editable={!guardando}
                            />
                        </View>

                        <View style={[styles.inputContainer, styles.timeInputBox]}>
                            <Ionicons name="time-outline" size={20} color={temaSeguro.primario} />
                            <TextInput
                                style={styles.input}
                                placeholder="6:00"
                                placeholderTextColor="#94a3b8"
                                value={horaInicio}
                                onChangeText={setHoraInicio}
                                editable={!guardando}
                            />
                        </View>
                    </View>

                    <View style={styles.repetitionPreviewBox}>
                        <Text style={styles.repetitionPreviewLabel}>Se guardará como:</Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Inicio: {obtenerFechaInicioParaGuardar() || 'pendiente'}
                        </Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Repetición: una vez
                        </Text>
                    </View>
                </>
            );
        }

        if (
            repetecion === 'diario' ||
            repetecion === 'lunes a viernes' ||
            repetecion === 'sabado domingo'
        ) {
            return (
                <>
                    <Text style={styles.inputLabel}>Hora de inicio</Text>

                    <View style={styles.inputContainer}>
                        <Ionicons name="time-outline" size={20} color={temaSeguro.primario} />
                        <TextInput
                            style={styles.input}
                            placeholder="6:00"
                            placeholderTextColor="#94a3b8"
                            value={horaInicio}
                            onChangeText={setHoraInicio}
                            editable={!guardando}
                        />
                    </View>

                    <View style={styles.repetitionPreviewBox}>
                        <Text style={styles.repetitionPreviewLabel}>Se guardará como:</Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Próxima fecha: {obtenerFechaInicioParaGuardar() || 'pendiente'}
                        </Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Repetición: {construirRepeticion(true)}
                        </Text>
                    </View>
                </>
            );
        }

        if (repetecion === 'personalizada') {
            return (
                <>
                    <Text style={styles.inputLabel}>Selecciona días y hora</Text>

                    <View style={styles.daysGrid}>
                        {DIAS.map((dia) => {
                            const activo = !!diasPersonalizados[dia.codigo];

                            return (
                                <TouchableOpacity
                                    key={dia.codigo}
                                    style={[
                                        styles.dayButton,
                                        activo && {
                                            backgroundColor: temaSeguro.primario,
                                            borderColor: temaSeguro.primario,
                                        },
                                    ]}
                                    onPress={() => cambiarDiaPersonalizado(dia.codigo)}
                                    activeOpacity={0.85}
                                    disabled={guardando}
                                >
                                    <Text style={[styles.dayButtonText, activo && styles.dayButtonTextActive]}>
                                        {dia.corto}
                                    </Text>
                                </TouchableOpacity>
                            );
                        })}
                    </View>

                    {DIAS.filter((dia) => diasPersonalizados[dia.codigo]).map((dia) => (
                        <View key={dia.codigo} style={styles.customDateTimeBox}>
                            <Text style={styles.customHourDay}>{dia.nombre}</Text>

                            <View style={styles.inputContainer}>
                                <Ionicons name="time-outline" size={18} color={temaSeguro.primario} />
                                <TextInput
                                    style={styles.input}
                                    placeholder="6:00"
                                    placeholderTextColor="#94a3b8"
                                    value={horasPersonalizadas[dia.codigo] || ''}
                                    onChangeText={(valor) => cambiarHoraPersonalizada(dia.codigo, valor)}
                                    editable={!guardando}
                                />
                            </View>
                        </View>
                    ))}

                    <View style={styles.repetitionPreviewBox}>
                        <Text style={styles.repetitionPreviewLabel}>Se guardará como:</Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Próxima fecha: {obtenerFechaInicioParaGuardar() || 'pendiente'}
                        </Text>
                        <Text style={styles.repetitionPreviewValue}>
                            Repetición: {construirRepeticion(true)}
                        </Text>
                    </View>
                </>
            );
        }

        return null;
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
                    <Ionicons name="flag" size={24} color="#ffffff" />
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
                    <Ionicons name="rocket" size={24} color="#ffffff" />
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
                        onPress={() => navigation.goBack()}
                        activeOpacity={0.85}
                    >
                        <Ionicons name="chevron-back" size={24} color="#ffffff" />
                    </TouchableOpacity>

                    <View style={styles.headerTextBox}>
                        <Text style={styles.title}>Misiones</Text>
                        <Text style={[styles.subtitle, { color: temaSeguro.borde }]}>
                            {usuario?.nombre_usuario || 'Jugador'}, crea o revisa tus categorías
                        </Text>
                    </View>
                </View>

                <View style={[styles.infoCard, { backgroundColor: temaSeguro.tarjeta }]}>
                    <View
                        style={[
                            styles.infoIcon,
                            {
                                backgroundColor: temaSeguro.primario,
                                borderColor: temaSeguro.borde,
                            },
                        ]}
                    >
                        <Ionicons name="albums-outline" size={28} color="#ffffff" />
                    </View>

                    <View style={styles.infoTextBox}>
                        <Text style={[styles.infoTitle, { color: temaSeguro.texto }]}>
                            Categorías de misiones
                        </Text>
                        <Text style={[styles.infoSubtitle, { color: temaSeguro.textoSuave }]}>
                            Toca una categoría para ver sus actividades. También puedes crear una nueva.
                        </Text>
                    </View>
                </View>

                <TouchableOpacity
                    style={[
                        styles.newTypeButton,
                        {
                            backgroundColor: temaSeguro.primario,
                            shadowColor: temaSeguro.primario,
                        },
                    ]}
                    onPress={() => abrirFormulario(null)}
                    activeOpacity={0.85}
                >
                    <Ionicons name="add-circle-outline" size={23} color="#ffffff" />
                    <Text style={styles.newTypeButtonText}>Crear nueva misión</Text>
                </TouchableOpacity>

                <ScrollView
                    style={styles.scrollArea}
                    contentContainerStyle={styles.scrollContent}
                    showsVerticalScrollIndicator={false}
                >
                    {cargandoTipos ? (
                        <View style={styles.loadingBox}>
                            <ActivityIndicator color="#ffffff" />
                            <Text style={styles.loadingText}>Cargando tipos...</Text>
                        </View>
                    ) : tipos.length === 0 ? (
                        <View style={styles.emptyBox}>
                            <Ionicons name="folder-open-outline" size={42} color="#ffffff" />
                            <Text style={styles.emptyTitle}>Aún no hay tipos</Text>
                            <Text style={styles.emptyText}>
                                Crea una misión para que aparezca su categoría.
                            </Text>
                        </View>
                    ) : (
                        <View style={styles.categoriesGrid}>
                            {tipos.map((tipo, index) => (
                                <AnimatedCategoryCard
                                    key={`${tipo.nombre}-${index}`}
                                    categoria={tipo}
                                    index={index}
                                    onPress={() => irAClasificacion(tipo)}
                                    onCreate={() => abrirFormulario(tipo)}
                                    tema={temaSeguro}
                                />
                            ))}
                        </View>
                    )}

                    <View style={styles.bottomSpace} />
                </ScrollView>
            </Animated.View>

            {mostrarFormulario && (
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
                                    {
                                        backgroundColor: tipoSeleccionado?.color || temaSeguro.primario,
                                    },
                                ]}
                            >
                                <Ionicons
                                    name={tipoSeleccionado?.icono || 'albums-outline'}
                                    size={26}
                                    color="#ffffff"
                                />
                            </View>

                            <View style={styles.formHeaderTextBox}>
                                <Text style={[styles.formTitle, { color: temaSeguro.texto }]}>
                                    Nueva misión
                                </Text>
                                <Text style={[styles.formSubtitle, { color: temaSeguro.textoSuave }]}>
                                    {tipoSeleccionado ? tipoSeleccionado.nombre : 'Nuevo tipo/categoría'}
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
                                onPress={cerrarFormulario}
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
                            <Text style={styles.inputLabel}>Tipo / categoría</Text>
                            <View style={styles.inputContainer}>
                                <Ionicons name="albums-outline" size={20} color={temaSeguro.primario} />
                                <TextInput
                                    style={styles.input}
                                    placeholder="Ej. Vida diaria, Escuela, Trabajo"
                                    placeholderTextColor="#94a3b8"
                                    value={tipoTexto}
                                    onChangeText={setTipoTexto}
                                    editable={!guardando}
                                />
                            </View>

                            <Text style={styles.inputHelp}>
                                Puedes usar un tipo existente o escribir uno nuevo.
                            </Text>

                            <Text style={styles.inputLabel}>Nombre de la misión</Text>
                            <View style={styles.inputContainer}>
                                <Ionicons name="pencil-outline" size={20} color={temaSeguro.primario} />
                                <TextInput
                                    style={styles.input}
                                    placeholder="Ej. Hacer tarea"
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
                                    placeholder="Describe brevemente la misión"
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

                            <Text style={styles.inputLabel}>Repetición</Text>
                            <View style={styles.repetitionGrid}>
                                {REPETICIONES.map((item) => (
                                    <TouchableOpacity
                                        key={item.id}
                                        style={[
                                            styles.repetitionButton,
                                            repetecion === item.valor && {
                                                backgroundColor: temaSeguro.primario,
                                                borderColor: temaSeguro.primario,
                                            },
                                        ]}
                                        onPress={() => seleccionarRepeticion(item.valor)}
                                        activeOpacity={0.85}
                                        disabled={guardando}
                                    >
                                        <Text
                                            style={[
                                                styles.repetitionText,
                                                repetecion === item.valor && styles.repetitionTextActive,
                                            ]}
                                        >
                                            {item.etiqueta}
                                        </Text>
                                    </TouchableOpacity>
                                ))}
                            </View>

                            {renderCamposRepeticion()}

                            <Text style={styles.inputLabel}>Actividad autoacompletable</Text>
                            <TouchableOpacity
                                style={[
                                    styles.autoBox,
                                    actividadAutoacompletable && {
                                        backgroundColor: temaSeguro.suavePrimario,
                                        borderColor: temaSeguro.primario,
                                    },
                                ]}
                                onPress={() => setActividadAutoacompletable(!actividadAutoacompletable)}
                                activeOpacity={0.85}
                                disabled={guardando}
                            >
                                <View
                                    style={[
                                        styles.autoIconBox,
                                        actividadAutoacompletable && {
                                            backgroundColor: temaSeguro.primario,
                                        },
                                    ]}
                                >
                                    <Ionicons
                                        name={actividadAutoacompletable ? 'checkmark' : 'close'}
                                        size={18}
                                        color="#ffffff"
                                    />
                                </View>

                                <View style={styles.autoTextBox}>
                                    <Text
                                        style={[
                                            styles.autoTitle,
                                            actividadAutoacompletable && { color: temaSeguro.primario },
                                        ]}
                                    >
                                        {actividadAutoacompletable ? 'Activada' : 'Desactivada'}
                                    </Text>
                                    <Text
                                        style={[
                                            styles.autoDescription,
                                            actividadAutoacompletable && { color: temaSeguro.primario },
                                        ]}
                                    >
                                        Si expira, se marcará como no cumplida y restará la mitad de XP.
                                    </Text>
                                </View>
                            </TouchableOpacity>

                            <Text style={styles.inputLabel}>Experiencia asignada automáticamente</Text>
                            <View style={[styles.expAutoBox, { backgroundColor: temaSeguro.fondoSecundario }]}>
                                <View style={[styles.expIconBox, { backgroundColor: temaSeguro.barraXp }]}>
                                    <Ionicons name="flash" size={24} color="#ffffff" />
                                </View>

                                <View style={styles.expTextBox}>
                                    <Text style={styles.expValue}>{valorExpCalculado} XP</Text>
                                    <Text style={styles.expDescription}>
                                        Se calcula por prioridad y duración
                                    </Text>
                                </View>
                            </View>

                            <View style={styles.expBreakdownBox}>
                                <View style={styles.expBreakdownRow}>
                                    <Text style={styles.expBreakdownLabel}>Prioridad</Text>
                                    <Text style={styles.expBreakdownValue}>
                                        +{calcularExpPorPrioridad()} XP
                                    </Text>
                                </View>

                                <View style={styles.expBreakdownRow}>
                                    <Text style={styles.expBreakdownLabel}>Horas</Text>
                                    <Text style={styles.expBreakdownValue}>
                                        +{calcularBonusPorHoras()} XP
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
                                onPress={guardarMision}
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
                                        <Text style={styles.saveButtonText}>Guardar misión</Text>
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

function AnimatedCategoryCard({ categoria, index, onPress, onCreate, tema }) {
    const temaSeguro = tema || TEMA_DEFAULT;

    const cardFade = useState(new Animated.Value(0))[0];
    const cardSlide = useState(new Animated.Value(35))[0];
    const cardScale = useState(new Animated.Value(1))[0];

    useEffect(() => {
        Animated.sequence([
            Animated.delay(index * 90),
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
            toValue: 0.96,
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

    return (
        <Animated.View
            style={[
                styles.categoryCardAnimated,
                {
                    opacity: cardFade,
                    transform: [{ translateY: cardSlide }, { scale: cardScale }],
                },
            ]}
        >
            <TouchableOpacity
                style={[styles.categoryCard, { backgroundColor: temaSeguro.tarjeta }]}
                onPress={onPress}
                onPressIn={pressIn}
                onPressOut={pressOut}
                activeOpacity={0.9}
            >
                <View style={[styles.categoryIconBox, { backgroundColor: categoria.color }]}>
                    <Ionicons name={categoria.icono} size={30} color="#ffffff" />
                </View>

                <Text style={[styles.categoryTitle, { color: temaSeguro.texto }]}>
                    {categoria.nombre}
                </Text>
                <Text style={[styles.categoryDescription, { color: temaSeguro.textoSuave }]}>
                    {categoria.descripcion}
                </Text>

                <View style={styles.categoryAction}>
                    <Text style={[styles.categoryActionText, { color: categoria.color }]}>
                        Ver actividades
                    </Text>
                    <Ionicons name="chevron-forward" size={18} color={categoria.color} />
                </View>

                <TouchableOpacity
                    style={[styles.categoryCreateButton, { borderColor: categoria.color }]}
                    onPress={onCreate}
                    activeOpacity={0.85}
                >
                    <Ionicons name="add" size={16} color={categoria.color} />
                    <Text style={[styles.categoryCreateText, { color: categoria.color }]}>
                        Crear aquí
                    </Text>
                </TouchableOpacity>
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
    newTypeButton: {
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
    newTypeButtonText: {
        color: '#ffffff',
        fontSize: 15,
        fontWeight: '900',
        marginLeft: 8,
    },
    scrollArea: { flex: 1 },
    scrollContent: { paddingBottom: 28 },
    categoriesGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
    categoryCardAnimated: { width: (width - 48) / 2 },
    categoryCard: {
        backgroundColor: '#ffffff',
        borderRadius: 24,
        padding: 16,
        minHeight: 228,
        shadowColor: '#000000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.08,
        shadowRadius: 15,
        elevation: 5,
    },
    categoryIconBox: {
        width: 58,
        height: 58,
        borderRadius: 20,
        justifyContent: 'center',
        alignItems: 'center',
        marginBottom: 12,
        borderWidth: 3,
        borderColor: '#f8fafc',
    },
    categoryTitle: { fontSize: 18, color: '#1e293b', fontWeight: '900' },
    categoryDescription: {
        color: '#64748b',
        fontSize: 12,
        fontWeight: '700',
        lineHeight: 17,
        marginTop: 6,
        flex: 1,
    },
    categoryAction: {
        marginTop: 12,
        borderRadius: 999,
        paddingVertical: 8,
        paddingHorizontal: 10,
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#f8fafc',
    },
    categoryActionText: { fontSize: 12, fontWeight: '900', marginRight: 5 },
    categoryCreateButton: {
        marginTop: 8,
        borderWidth: 1.5,
        borderRadius: 999,
        paddingVertical: 8,
        paddingHorizontal: 8,
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
    },
    categoryCreateText: {
        fontSize: 12,
        fontWeight: '900',
        marginLeft: 4,
    },
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
    inputHelp: {
        color: '#64748b',
        fontSize: 12,
        fontWeight: '700',
        marginTop: 6,
        marginBottom: 4,
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
    dateTimeRow: {
        flexDirection: 'row',
        gap: 8,
        width: '100%',
    },
    dateInputBox: {
        flex: 1.25,
    },
    timeInputBox: {
        flex: 0.85,
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
    repetitionGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
    repetitionButton: {
        backgroundColor: '#ffffff',
        borderWidth: 1.5,
        borderColor: '#e2e8f0',
        borderRadius: 999,
        paddingVertical: 10,
        paddingHorizontal: 12,
    },
    repetitionText: { color: '#64748b', fontSize: 12, fontWeight: '900' },
    repetitionTextActive: { color: '#ffffff' },
    repetitionPreviewBox: {
        backgroundColor: '#f8fafc',
        borderRadius: 16,
        padding: 12,
        marginTop: 10,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    repetitionPreviewLabel: { color: '#64748b', fontSize: 12, fontWeight: '800' },
    repetitionPreviewValue: {
        color: '#1e293b',
        fontSize: 13,
        fontWeight: '900',
        marginTop: 4,
    },
    daysGrid: { flexDirection: 'row', gap: 7, marginBottom: 10 },
    dayButton: {
        flex: 1,
        height: 38,
        borderRadius: 19,
        backgroundColor: '#ffffff',
        borderWidth: 1.5,
        borderColor: '#e2e8f0',
        justifyContent: 'center',
        alignItems: 'center',
    },
    dayButtonText: { color: '#64748b', fontSize: 12, fontWeight: '900' },
    dayButtonTextActive: { color: '#ffffff' },
    customDateTimeBox: {
        backgroundColor: '#f8fafc',
        borderRadius: 18,
        padding: 10,
        marginBottom: 10,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    customHourDay: {
        color: '#334155',
        fontSize: 13,
        fontWeight: '900',
        marginBottom: 8,
    },
    autoBox: {
        backgroundColor: '#f8fafc',
        borderRadius: 18,
        padding: 12,
        flexDirection: 'row',
        alignItems: 'center',
        borderWidth: 1.5,
        borderColor: '#e2e8f0',
    },
    autoIconBox: {
        width: 36,
        height: 36,
        borderRadius: 18,
        backgroundColor: '#94a3b8',
        justifyContent: 'center',
        alignItems: 'center',
        marginRight: 10,
    },
    autoTextBox: {
        flex: 1,
    },
    autoTitle: {
        color: '#334155',
        fontSize: 14,
        fontWeight: '900',
    },
    autoDescription: {
        color: '#64748b',
        fontSize: 12,
        fontWeight: '700',
        marginTop: 2,
        lineHeight: 17,
    },
    expAutoBox: {
        backgroundColor: '#1e1b4b',
        borderRadius: 18,
        padding: 14,
        flexDirection: 'row',
        alignItems: 'center',
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
    expDescription: { color: '#c7d2fe', fontSize: 12, fontWeight: '700', marginTop: 2 },
    expBreakdownBox: {
        backgroundColor: '#f8fafc',
        borderWidth: 1,
        borderColor: '#e2e8f0',
        borderRadius: 16,
        padding: 12,
        marginTop: 10,
    },
    expBreakdownRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 6,
    },
    expBreakdownLabel: { color: '#64748b', fontSize: 12, fontWeight: '800' },
    expBreakdownValue: { color: '#1e293b', fontSize: 12, fontWeight: '900' },
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