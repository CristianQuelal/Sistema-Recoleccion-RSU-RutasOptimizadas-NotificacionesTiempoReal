//Importacion de paquetes necesarios
import 'package:flutter/material.dart'; // Importa el paquete de Flutter para construir interfaces de usuario
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart'; // Importa la biblioteca de navegación Mapbox
import 'package:geolocator/geolocator.dart';  // Importa la biblioteca Geolocator para obtener la posición geográfica
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore para trabajar con la base de datos en la nube
import 'package:flutter_svg/svg.dart';  // Importación para usar SvgPicture

class RutaScreen extends StatefulWidget {
  @override
  // Crea una instancia de la clase _RutaScreenState cuando se crea el widget RutaScreen
  _RutaScreenState createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  // Instancia de MapBoxNavigation para manejar la navegación
  final MapBoxNavigation _navigation = MapBoxNavigation();
  // Instancia de FirebaseFirestore para acceder a la base de datos
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Registra el listener de eventos de ruta en el método initState
    _navigation.registerRouteEventListener(_onRouteEvent);
  }
// Método que maneja los eventos de ruta
  Future<void> _onRouteEvent(RouteEvent e) async {
    // Verifica el tipo de evento recibido
    switch (e.eventType) {
    // Evento que se produce cuando el progreso de la ruta cambia
      case MapBoxEvent.progress_change:
        print('Ruta cambio: $e');
      // Evento que se produce cuando se está construyendo la ruta
      case MapBoxEvent.route_building:
    // Imprime el evento en la consola
        print('Ruta construyendo: $e');
        break;
      default:
      // Si se recibe cualquier otro evento, no se realiza ninguna acción
        break;
    }
  }

  // Método para iniciar la navegación
  Future<void> _iniciarNavegacion(BuildContext context) async {
    // Verificar si los permisos de ubicación ya están concedidos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      // Mostrar diálogo de permisos si los permisos están denegados
      _mostrarDialogoPermisos(context);
      return; // Salir del método si los permisos no están concedidos
    }

    // Obtener la posición actual del dispositivo
    Position startPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // Crear lista de puntos de ruta (waypoints) con el punto de inicio
    List<WayPoint> wayPoints = [
      WayPoint(
        name: "Inicio",
        latitude: startPosition.latitude,
        longitude: startPosition.longitude,
      ),
    ];

    // Obtener datos de clientes desde Firestore
    var clientesSnapshot = await _firestore.collection('clientes').get();
    List<WayPoint> destinationPoints = [];

    // Crear puntos de destino basados en los datos de clientes
    for (var doc in clientesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double? lat = data['Latitud']?.toDouble();
      double? lng = data['Longitud']?.toDouble();
      if (lat != null && lng != null) {
        destinationPoints.add(
          WayPoint(
            name: "Destino",
            latitude: lat,
            longitude: lng,
          ),
        );
      }
    }

    // Ordenar puntos de destino basados en la distancia al punto inicial
    destinationPoints.sort((a, b) {
      double distA = Geolocator.distanceBetween(
          startPosition.latitude, startPosition.longitude,
          a.latitude ?? 0.0, a.longitude ?? 0.0);
      double distB = Geolocator.distanceBetween(
          startPosition.latitude, startPosition.longitude,
          b.latitude ?? 0.0, b.longitude ?? 0.0);
      return distA.compareTo(distB);
    }); destinationPoints.sort((a, b) {
      double distA = Geolocator.distanceBetween(
        startPosition.latitude,
        startPosition.longitude,
        a.latitude ?? 0.0,
        a.longitude ?? 0.0,
      );
      double distB = Geolocator.distanceBetween(
        startPosition.latitude,
        startPosition.longitude,
        b.latitude ?? 0.0,
        b.longitude ?? 0.0,
      );
      return distA.compareTo(distB);
    });

    // Agregar puntos ordenados a wayPoints
    wayPoints.addAll(destinationPoints);

    // Verificar si hay suficientes puntos para iniciar la navegación
    if (wayPoints.length < 2) {
      // Muestra un diálogo indicando que no hay suficientes destinos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Navegación no posible"),
            content: const Text(
                "No hay suficientes destinos para iniciar la navegación."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;  // Salir del método si no hay suficientes puntos de destino
    }

    // Configuración de opciones para Intefaz de MapBoxNavigation
    var options = MapBoxOptions(
      initialLatitude: startPosition.latitude,  // Latitud inicial para centrar el mapa al inicio de la navegación
      initialLongitude: startPosition.longitude,   // Longitud inicial para centrar el mapa al inicio de la navegación
      zoom: 15.0,   // Nivel de zoom inicial del mapa
      tilt: 0.0, // Ángulo de inclinación inicial del mapa
      bearing: 0.0, // Orientación inicial del mapa en grados
      enableRefresh: true,  // Habilita la actualización automática de la ruta
      alternatives: true,  // Permite rutas alternativas
      isOptimized: true,  // Optimiza la ruta para la navegación
      voiceInstructionsEnabled: true, // Habilita las instrucciones de voz durante la navegación
      bannerInstructionsEnabled: true, // Habilita las instrucciones en banner durante la navegación
      allowsUTurnAtWayPoints: true,   // Permite hacer giros en U en los puntos de ruta
      mode: MapBoxNavigationMode.drivingWithTraffic, // Modo de navegación (con tráfico, sin tráfico, etc.)
      units: VoiceUnits.metric,   // Unidades de voz para las instrucciones de navegación
      simulateRoute: true,  // Simula la ruta sin conexión a internet
      animateBuildRoute: true, // Animación al construir la ruta en el mapa
      longPressDestinationEnabled: false, //Agrega un punto mas al mapa si se mantiene presionado la pantalla
      language: "es", // Idioma de las instrucciones de navegación
    );
    // Iniciar navegación con las opciones y waypoints configurados
    await _navigation.startNavigation(
      options: options,
      wayPoints: wayPoints,
    );
  }

  // Método para mostrar diálogo de permisos
  void _mostrarDialogoPermisos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos necesarios'),
          content: const Text(
              'Para iniciar la navegación, necesitas otorgar los permisos de ubicación. Ve a Configuraciones > Aplicaciones > ResiRutas para otorgar los permisos manualmente o da clic en Configuración.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings(); // Abre la configuración de la app
                Navigator.of(context).pop();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }

  // Método para terminar el recorrido
  Future<void> _terminarRecorrido(BuildContext context) async {
    // Muestra un diálogo de confirmación
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar"),
          content: const Text("¿Está seguro de que desea terminar el recorrido?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    // Salir del método si no se confirma la terminación
    if (!confirm) return;

    // Muestra un indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(), // Indicador de carga
        );
      },
    );

    // Borrar todos los datos de la colección clientes en Firestore
    var collection = FirebaseFirestore.instance.collection('clientes');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    // Cierra el indicador de carga
    Navigator.of(context).pop();

    // Mostrar mensaje de recorrido terminado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recorrido terminado'),
      ),
    );
  }

// Método build para construir la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navegación a Clientes"),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      '¿Tienes todo listo para iniciar?',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20), // Espacio entre elementos
                    SvgPicture.asset(
                      'assets/recolector.svg',
                      width: constraints.maxWidth * 0.8,
                      height: constraints.maxWidth * 0.8,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _iniciarNavegacion(context),
                      child: const Text('COMENZAR LA NAVEGACIÓN'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _terminarRecorrido(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('TERMINAR RECORRIDO'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    //método utilizado para liberar los recursos que se hayan asignado en el objeto State
    super.dispose();
  }
}
