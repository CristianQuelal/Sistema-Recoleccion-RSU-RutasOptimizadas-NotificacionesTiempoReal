//Importacion de paquetes necesarios
import 'package:flutter/material.dart'; // Importa el paquete para obtener las herramientas de GUI de flutter
import 'package:flutter_map/flutter_map.dart'; // Importa el paquete flutter_map para mostrar el mapa en la aplicación.
import 'package:latlong2/latlong.dart'; // Importa el paquete latlong2 para manejar coordenadas geográficas.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa el paquete cloud_firestore para interactuar con Cloud Firestore.
import 'package:firebase_core/firebase_core.dart'; // Importa el paquete firebase_core para inicializar Firebase.
import 'firebase_options.dart'; // Importa las opciones de configuración de Firebase.
import 'ruta.dart'; // Importa la pantalla RutaScreen.
import 'main.dart'; // Importa la pantalla principal
import 'package:flutter_svg/flutter_svg.dart'; // Importa el paquete flutter_svg para mostrar imágenes SVG.

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que la instancia de WidgetsBinding esté inicializada.
  await Firebase.initializeApp(    // Inicializa Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: MapScreen()));  // Ejecuta la aplicación con MaterialApp como widget raíz y MapScreen como pantalla inicial
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Maneja el evento de retroceso (volver atrás) de la pantalla.
        onWillPop: () async {
      // Muestra un diálogo de confirmación antes de salir de la pantalla
      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Advertencia"),
            content: const Text("Se cerrará la sesión, ¿Está seguro de que desea salir?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("Aceptar"),
                onPressed: () {
                  // Redirige a la página principal
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage(title: 'ResiRutas')),
                  );
                },
              ),
            ],
          );
        },
      );
      return confirm ?? false;
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de Recolección'),
        automaticallyImplyLeading: false, // Oculta el botón de retroceso en la AppBar.
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escucha los cambios en la base de datos de clientes de Cloud Firestore.
        stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          // Crea una lista de marcadores (Marker) a partir de los datos de la bdd.
          List<Marker> markers = snapshot.data!.docs.map((doc) {
            double latitud = double.parse(doc.get('Latitud').toString());
            double longitud = double.parse(doc.get('Longitud').toString());
            return Marker( //Creacion del marcador en mapa
              point: LatLng(latitud, longitud),
              width: 25,
              height: 25,
              child: SvgPicture.asset(
                'assets/trashas.svg', // Ruta del archivo SVG del icono del camión
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: MapController(),
            options: const MapOptions(
              initialCenter: LatLng(0.586202, -77.825026), // Coordenadas iniciales del mapa.
              initialZoom: 16.50,  // Nivel de zoom inicial del mapa.
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
              MarkerLayer(markers: markers), // Capa de marcadores en el mapa.
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navega a la pantalla RutaScreen cuando se presiona el botón.
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => RutaScreen()),
          );
        },
        label: const Text('RUTA DE RECOLECCIÓN'),
        icon: const Icon(Icons.route),
        elevation: 4.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Configura la forma y el margen de la barra de navegación inferior para acomodar el FloatingActionButton.
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[],
         ),
       ),
     ),
    );
  }
}