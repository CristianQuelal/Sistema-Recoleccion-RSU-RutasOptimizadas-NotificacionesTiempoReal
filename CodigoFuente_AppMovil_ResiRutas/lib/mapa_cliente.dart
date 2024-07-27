//Importacion de paquetes necesarios
import 'dart:async'; // Importa el paquete para trabajar con funciones asíncronas y temporizadores
import 'dart:convert'; // Importa el paquete para codificación y decodificación de JSON
import 'package:flutter/material.dart'; // Importa el paquete Flutter para UI
import 'package:flutter_map/flutter_map.dart'; // Importa Flutter Map para integrar mapas
import 'package:latlong2/latlong.dart'; // Importa el paquete para manejar coordenadas geográficas
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core para la inicialización de Firebase
import 'package:firebase_database/firebase_database.dart'; // Importa Firebase Realtime Database
import 'package:geolocator/geolocator.dart'; // Importa el paquete para obtener la ubicación del dispositivo
import 'package:http/http.dart' as http; // Importa el paquete HTTP para realizar solicitudes HTTP
import 'package:resirutas/notificaciones_push.dart'; // Importa las notificaciones push
import 'firebase_options.dart'; // Importa las opciones de configuración de Firebase
import 'package:flutter_svg/flutter_svg.dart'; // Importa SVG para mostrar imágenes vectoriales
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart'; // Importa para reproducir tonos


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: MapaCliente())); // Ejecuta la aplicación Flutter
}

class MapaCliente extends StatefulWidget {
  const MapaCliente({super.key});
  @override
  MapaClienteState createState() => MapaClienteState();
}

class MapaClienteState extends State<MapaCliente> {
  late Timer timer; // Temporizador para actualizar los marcadores
  final MapController mapController = MapController(); // Controlador del mapa
  final dbRef = FirebaseDatabase.instance.ref();
  List<Marker> markers = []; // Lista de marcadores en el mapa
  List<Polyline> polylines = []; // Lista de polilíneas en el mapa
  String distance = ''; // Variable para la distancia
  String distanceInt = ''; // Variable para la distancia redondeada
  String speed = ''; // Variable para la velocidad
  String arrivalTime = ''; //Variable para almacenar el tiempo de llegada
  bool nearAlertShown = false; // Variable para indicar si se mostró la alerta de cercanía
  bool arrivalTimeAlertShown = false; // Variable para indicar si se mostró la alerta del tiempo de llegada
  bool arrivalAlertShown = false; // Variable para indicar si se mostró la alerta de llegada

  @override
  void initState() {
    super.initState();
    cargarMarcadores(); // Carga los marcadores cuando el widget está inicializado
    timer = Timer.periodic(const Duration(seconds: 60), (_) => cargarMarcadores()); // Actualiza los marcadores cada 60 segundos
  }

  @override
  void dispose() {
    // Detén el temporizador cuando el widget se elimine
    timer.cancel();
    dbRef.onValue.drain();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Función para manejar el botón de retroceso del dispositivo
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Advertencia'),
          content: const Text(
              'Si sales de esta pantalla, NO podrás ver los detalles de la recolección ni recibir notificaciones.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
    return shouldPop ?? false;
  }

  void cargarMarcadores() async {
    // Función para cargar los marcadores en el mapa
    Position position = await Geolocator.getCurrentPosition( // Obtiene la posición actual del dispositivo
        desiredAccuracy: LocationAccuracy.high);
    LatLng currentLocation = LatLng(position.latitude, position.longitude); // Crea la ubicación actual

    Marker currentLocationMarker = Marker(
      // Crea un marcador para la ubicación actual
      point: currentLocation,
      width: 80,
      height: 80,
      child: const Icon(Icons.my_location, color: Colors.blue),
    );

    mapController.move(currentLocation, 16.0); // Mueve la cámara del mapa a la ubicación actual

    dbRef.onValue.listen((event) async {
      // Escucha cambios en la base de datos Firebase
      if (mounted) { // Verifica si el widget aún está montado
        final data = event.snapshot.value as Map<dynamic, dynamic>?; // Obtiene los datos de Firebase
        if (data != null) {
          final lat = double.tryParse(data['lat'].toString()) ??
              0.0; // Obtiene la latitud de los datos
          final lng = double.tryParse(data['lng'].toString()) ??
              0.0; // Obtiene la longitud de los datos
          LatLng currentPointB = LatLng(
              lat, lng); // Crea la ubicación del punto B
          final marker = Marker(
            // Creacion de un marcador para el punto B
            point: currentPointB,
            width: 27,
            height: 27,
            child: SvgPicture.asset(
              'assets/recolectores.svg', // Ruta del archivo SVG del camión
            ),
          );

          // Definicion de parametros HTTP para la api de mapbox para obtener la ruta entre la ubicación actual y el punto B
          String url = "https://api.mapbox.com/directions/v5/mapbox/driving/$lng,$lat;${position
              .longitude},${position
              .latitude}?alternatives=false&geometries=geojson&overview=full&steps=false&access_token=pk.eyJ1IjoibmFjaG93ZWIiLCJhIjoiY2x1aXZqanJvMDMxMDJqbzYyaHQyZmNpaSJ9.PAcdHk9w-Hgng4h8S-2Ijw";
          var response = await http.get(
              Uri.parse(url)); // Realiza la solicitud HTTP
          var json = jsonDecode(response.body); // Decodifica la respuesta JSON
          var points = (json['routes'][0]['geometry']['coordinates'] as List)
              .map((e) => LatLng(e[1], e[0]))
              .toList(); // Obtiene los puntos de la ruta

          // Capturando la velocidad directamente desde la base de datos
          final speedData = data['speed'].toString();
          speed = "$speedData Km/h"; // Mostrando la velocidad tal como está en la base de datos
          double speedInKmPerHour = double.parse(speedData);
          // Obtener la distancia calculada por MapBox
          distance = "${json['routes'][0]['distance']} m";
          double dist = double.parse(
              distance.split(" ")[0]); // Distancia en metros
          int distanceIntTemp = dist.round();
          // Convertir la distancia de metros a kilómetros
          double distanceInKm = dist / 1000;

          if (speedInKmPerHour == 0) {
            // Si la velocidad es cero, el recolector está detenido
            arrivalTime = "Recolector detenido";
          } else {
            // Calcular el tiempo en horas y convertirlo a minutos
            double timeInHours = distanceInKm / speedInKmPerHour;
            int arrivalTimeMinutes = (timeInHours * 60).round(); // Convertir a minutos y redondea

            // Obtener la duración calculada por MapBox
            //double durationSeconds = json['routes'][0]['duration']; // Duración en segundos
            //int arrivalTimeMinutes = (durationSeconds / 60).round(); // Convertir a minutos y redondea

            if (arrivalTimeMinutes == 0) {
              arrivalTime =
              "< 1 min."; // Si el tiempo es menor a un minuto a mostrar cuando el tiempo de llegada sea 0 minutos
            } else {
              arrivalTime =
              "$arrivalTimeMinutes min."; // Tiempo estimado de llegada
            }

            // Mostrar el mensaje de diálogo de notificacion una vez que se haya calculado el tiempo de llegada
            if (arrivalTimeMinutes > 0 && !arrivalTimeAlertShown) {
              showArrivalDialog(arrivalTimeMinutes);
              arrivalTimeAlertShown = true;
            }

            // Mostrar el mensaje de diálogo de notificacion una vez que el recolector este a <= 200m de distancia del punto
            if (dist <= 200 && !nearAlertShown) {
              showNearAlertShow(dist);
              nearAlertShown = true;
            }

            // Mostrar el mensaje de diálogo de notificacion una vez que el recolector este a <= 10m de distancia del punto
            if (dist <= 10 && !arrivalAlertShown) {
              showArrivalAlertShown(dist);
              arrivalAlertShown = true;
            }
          }

          setState(() {
            distanceInt = '$distanceIntTemp m';; // Actualiza distanceInt
            markers = [currentLocationMarker, marker];  // Actualiza los marcadores en el mapa
            polylines = [ // Actualiza las polilíneas en el mapa
              Polyline(
                points: points,
                strokeWidth: 4.0,
                color: const Color(0xFF4285F4),
              )
            ];
          });
        }
      }
    });
  }

      void showArrivalDialog(int minutes) {
     // Función para mostrar el diálogo del tiempo de llegada
      String mensaje = "El recolector llegará en $minutes minutos aproximadamente";
      FlutterRingtonePlayer.play(
          fromAsset: "assets/sounds/sound_alert.mp3"); // Reproduce el sonido de notificación
      mostrarNotificaciones(mensaje); // Muestra la notificación push
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Tiempo de Llegada"),
            content: Text(
                mensaje),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    void showNearAlertShow(double dist) {
      // Función para mostrar la alerta de carcania del recolector
      String mensaje = "El recolector está aproximadamente ${dist.round()} m de llegar a su ubicación.";
      FlutterRingtonePlayer.play(
          fromAsset: "assets/sounds/sound_alert.mp3"); // Reproduce el sonido de notificación
      mostrarNotificaciones(mensaje); // Muestra la notificación push con el argumento
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Alerta"),
            content: Text(mensaje),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    void showArrivalAlertShown(double dist) {
      // Función para mostrar la alerta de llegada al punto de recolección
      String mensaje = "El recolector está arrivando a su ubicación, salga ¡Ahora!.";
      FlutterRingtonePlayer.play(
          fromAsset: "assets/sounds/sound_alert.mp3"); // Reproduce el sonido de notificación
      mostrarNotificaciones(mensaje); // Muestra la notificación push con el argumeto
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Alerta"),
            content: Text(mensaje), // Usar el mismo mensaje
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: _onWillPop, // Maneja el evento de retroceso del dispositivo
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Detalles de Recolección'),
            automaticallyImplyLeading: false,
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: LatLng(0.586202, -77.825026),
                  initialZoom: 16.50,
                ),
                children: [
                  // Stilo del mapa para mostrar desde la api de mapbox
                  TileLayer(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/quelalcristian21/clvcvussm01cp01ql6poa48e4/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoicXVlbGFsY3Jpc3RpYW4yMSIsImEiOiJjbHZjdGJmNDQwbmc5MnZtOTZ5M2JiMzZ4In0.a4b66UwkybJCH8_Zl5gslQ',
                    additionalOptions: const {
                      'accessToken': 'sk.eyJ1IjoicXVlbGFsY3Jpc3RpYW4yMSIsImEiOiJjbHZjdnFyeHQwbjZwMmpvMDFnMWdoaHNyIn0.6rUWDcl2rKBGIhII-8XL6Q',
                      'id': 'mapbox.streets',
                    },
                  ),
                  MarkerLayer(markers: markers), // Capa de marcadores en el mapa
                  PolylineLayer(polylines: polylines),  //polilíneas en el mapa
                ],
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  // Contenedor para mostrar detalles de recorrido
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detalles de recorrido',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Distancia: $distanceInt'), // Mostrar la distancia entre el recolector y el punto de recoleccion
                      Text('Llegada: $arrivalTime'), // Mostrar el tiempo de llegada
                    ],
                  ),
                ),
              )
            ],
          ),
          floatingActionButton: Column(
            // Columna de botones flotantes para acercar y alejar el mapa
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "zoomIn",
                onPressed: () =>
                    mapController.move(
                        mapController.camera.center, mapController.camera.zoom + 1),
                mini: true,
                child:const Icon(Icons.add), // Icono de zoom in
              ),
              const SizedBox(height: 4),
              FloatingActionButton(
                heroTag: "zoomOut",
                onPressed: () =>
                    mapController.move(
                        mapController.camera.center, mapController.camera.zoom - 1),
                mini: true,
                child: const Icon(Icons.remove), // Icono de zoom out
              ),
            ],
          ),
        ),
      );
    }
  }