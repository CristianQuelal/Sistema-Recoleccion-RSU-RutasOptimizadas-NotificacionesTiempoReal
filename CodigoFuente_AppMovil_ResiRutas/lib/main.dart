//Importacion de paquetes necesarios
import 'package:flutter/material.dart'; // Importa el paquete principal de Flutter
import 'package:resirutas/notificaciones_push.dart';
import 'clientes_form.dart'; // Importa la pantalla del formulario de clientes
import 'formulario_recolectores.dart'; // Importa la pantalla del formulario de recolectores
import 'firebase_options.dart'; // Importa la configuración de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Importa flutter_svg
import 'package:permission_handler/permission_handler.dart'; // Importa permission_handler


void main() async { // Función principal de la aplicación
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que los widgets estén inicializados
  // Solicitar permisos al iniciar la aplicación
  await requestPermissions();
  // Inicializar Notificaciones
  await initNotifications();
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Ejecuta la aplicación MyApp
}
// Función para solicitar permisos
Future<void> requestPermissions() async {
  // Lista de permisos que necesitas solicitar
  List<Permission> permissions = [
    Permission.location,
    Permission.notification,
  ];


  // Solicitar permisos
  for (var permission in permissions) {
    await permission.request(); // Solicita el permiso sin asignar el resultado
  }
}

class MyApp extends StatelessWidget { // Clase principal de la aplicación
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Construye el widget MaterialApp
      title: 'ResiRutas', // Título de la aplicación
      theme: ThemeData( // Tema de la aplicación
        primarySwatch: Colors.blue,  // Color primario
      ),
      home: const MyHomePage(title: 'ResiRutas'),  // Pantalla de inicio
    );
  }
}

class MyHomePage extends StatelessWidget {   // Pantalla de inicio de la aplicación
  final String title;  // Título de la pantalla

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,  // Deshabilita el botón de retroceso
      ),
      body: OrientationBuilder(  // Construye un OrientationBuilder para manejar la orientación
        builder: (context, orientation) {
          return SingleChildScrollView( // Permite desplazamiento vertical
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 100), // Espacio entre la parte superior y la imagen
                    // Muestra una imagen SVG
                    SvgPicture.asset(
                      'assets/Curious-pana.svg',
                      width: orientation == Orientation.portrait ? 300.0 : 200.0, //Ancho basado en la orientacion
                      height: orientation == Orientation.portrait ? 300.0 : 200.0, //Altura basado en la orientacion
                    ),
                    const SizedBox(height: 20), // Espacio entre la imagen y el texto "Accesos"
                    const Text(
                      'Accesos:',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20), // Espacio entre el texto "Accesos" y el primer botón
                    SizedBox(
                      width: double.infinity, // Hace que el SizedBox tenga el ancho completo
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15), // Ajusta el padding del botón
                        ),
                        onPressed: () { // Función a ejecutar al presionar el botón
                          Navigator.push( // Navega a la siguiente pantalla
                            context,
                            MaterialPageRoute(builder: (context) => ClientesForm()),  // Pantalla del formulario de clientes
                          );
                        },
                        child: const Text('CLIENTES'),
                      ),
                    ),
                    const SizedBox(height: 20), // Espacio entre los dos botones
                    SizedBox(
                      width: double.infinity, // Hace que el SizedBox tenga el ancho completo
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom( // Estilo del botón
                          padding: const EdgeInsets.all(15), // Ajusta el padding(espacio interior entre el contenido de un widget y sus bordes) del botón
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecolectoresForm()), // Pantalla del formulario de recolectores
                          );
                        },
                        child: const Text('RECOLECTORES'), // Texto del botón
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}