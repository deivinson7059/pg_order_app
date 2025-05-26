
# Aplicación de Gestión de Pedidos en Ruta

Una aplicación Flutter completa para la gestión de pedidos de entrega con seguimiento en tiempo real, sincronización offline y mapas integrados.

## 🚀 Características Principales

### 📱 Funcionalidades Core
- **Gestión de Pedidos**: Crear, visualizar y actualizar pedidos en tiempo real
- **Base de Datos Local**: SQLite para funcionamiento offline completo
- **Sincronización Inteligente**: Sync automático cuando hay conexión
- **Seguimiento GPS**: Tracking en tiempo real con almacenamiento de rutas
- **Mapas Integrados**: Google Maps para visualización de rutas y clientes

### 🔧 Arquitectura Técnica
- **Gestión de Estados**: BLoC Pattern para manejo de estados robusto
- **Inyección de Dependencias**: GetIt para arquitectura escalable
- **Almacenamiento Local**: SQLite con sincronización inteligente
- **Comunicación en Tiempo Real**: Socket.IO para ubicación en vivo
- **Trabajo en Segundo Plano**: WorkManager para sync automático

### 🌐 Conectividad
- **Modo Offline**: Funcionalidad completa sin conexión
- **Auto-Sync**: Sincronización automática cada 30 minutos
- **Actualización de Productos**: Refresh automático cada 5 horas
- **Socket en Tiempo Real**: Ubicación compartida instantánea

## 🛠️ Configuración del Proyecto

### Prerrequisitos
```bash
Flutter SDK >= 3.0.0
Dart >= 3.0.0
Android Studio / VS Code
Google Maps API Key
```

### Instalación
1. **Clonar el repositorio**
```bash
git clone <url-del-repo>
cd pedidos_ruta_app
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Google Maps**
   - Obtener API Key de Google Cloud Console
   - Añadir al `android/app/src/main/AndroidManifest.xml`
   - Añadir al `ios/Runner/AppDelegate.swift`

4. **Generar código**
```bash
flutter packages pub run build_runner build
```

### Configuración de APIs
Actualizar las URLs en `lib/core/utils/constants.dart`:
```dart
static const String baseUrl = 'https://tu-api.com/';
static const String socketUrl = 'https://tu-socket.com';
```

## 📦 Estructura del Proyecto

```
lib/
├── core/
│   ├── database/          # SQLite y helpers
│   ├── models/           # Modelos de datos
│   ├── services/         # APIs y servicios
│   ├── network/          # Conectividad
│   ├── di/              # Inyección de dependencias
│   ├── theme/           # Temas de la app
│   └── utils/           # Utilidades y constantes
├── presentation/
│   ├── blocs/           # Gestión de estados BLoC
│   ├── screens/         # Pantallas principales
│   └── widgets/         # Widgets reutilizables
└── main.dart           # Punto de entrada
```

## 🔌 APIs Requeridas

### Endpoints Backend
```
GET  /products         # Lista de productos
GET  /clients          # Lista de clientes
POST /orders           # Sincronizar pedido
POST /route-points     # Sincronizar puntos de ruta
GET  /orders/{id}      # Detalle de pedido
```

### Socket Events
```
- connect: Conexión establecida
- join: Unirse a sala de usuario
- location: Enviar ubicación
- location_update: Recibir ubicación
```

## 🚀 Uso de la Aplicación

### 1. Autenticación
- Login con credenciales
- Sesión persistente local

### 2. Gestión de Pedidos
- Visualizar lista de pedidos
- Crear nuevos pedidos
- Actualizar estados (Pendiente → En Progreso → Completado)
- Sincronización automática

### 3. Seguimiento GPS
- Activación automática al iniciar la app
- Almacenamiento local de puntos de ruta
- Visualización en mapa en tiempo real

### 4. Modo Offline
- Funcionalidad completa sin conexión
- Sincronización automática al reconectar
- Indicadores visuales de estado de sync

## ⚙️ Configuraciones Avanzadas

### Personalizar Intervalos de Sync
```dart
// En constants.dart
static const int syncIntervalMinutes = 30;      // Sync general
static const int productRefreshHours = 5;       // Productos
static const int routeSyncMinutes = 15;         // Rutas
```

### Configurar Ubicación
```dart
// En location_bloc.dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10, // metros
)
```

## 🐛 Debugging y Logs

La aplicación incluye logging detallado:
- Errores de sincronización
- Estados de conexión
- Operaciones de base de datos
- Eventos de ubicación

## 📱 Plataformas Soportadas

- ✅ Android (API 21+)
- ✅ iOS (13.0+)
- 🔄 Web (en desarrollo)

## 🔐 Permisos Necesarios

### Android
- `INTERNET`: Conexión a APIs
- `ACCESS_FINE_LOCATION`: GPS preciso
- `ACCESS_BACKGROUND_LOCATION`: Tracking en segundo plano
- `WAKE_LOCK`: Mantener procesos activos

### iOS
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# o para App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Para soporte técnico o consultas:
- Email: soporte@tudominio.com
- Issues: GitHub Issues
- Documentación: Wiki del proyecto

---

**Desarrollado con ❤️ para optimizar las entregas en Colombia** 🇨🇴