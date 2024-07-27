//Importación de paquetes necesarios
import 'package:flutter/material.dart'; // Paquete Flutter para UI
import 'package:firebase_auth/firebase_auth.dart'; // Paquete Firebase Authentication
import 'mapa_recolectores.dart'; // Importa la pantalla de MapaRecolectores

class RecolectoresForm extends StatelessWidget { //Creacion de widget publico
  RecolectoresForm({super.key}); //Constructor

  // Controlador para el campos de usuario y contraseña
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Estructura básica de la pantalla
      appBar: AppBar(
        title: const Text('Acceso Recolector'), // Título de la AppBar
      ),
      body: SingleChildScrollView( // Permite desplazamiento vertical
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
            const Text(
            'LOGIN',  // Título del formulario
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // Espacio entre elementos
          const Text( // Instrucciones del formulario
            'Por favor, ingrese las credenciales asignadas por el administrador del sistema',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20), // Espacio entre elementos
              TextField( // Campo de texto para el usuario
                controller: _usuarioController,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 20),
              TextField( // Campo de texto para la contraseña
                controller: _claveController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true, // Oculta el texto de la contraseña
              ),
              const SizedBox(height: 20),
          SizedBox( // Botón de aceptar
            width: double.infinity, // Ancho igual al ancho disponible
            child: ElevatedButton(
                onPressed: () async { // Función llamada al presionar el botón
                  try {
                    // Intenta iniciar sesión con las credenciales proporcionadas
                    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _usuarioController.text,
                      password: _claveController.text,
                    );
                    print('Inicio de sesión exitoso: ${userCredential.user?.email}'); // Imprime el email del usuario
                    ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje en la parte inferior de la pantalla
                      const SnackBar(
                        content: Text('Correo y contraseña correctos'),
                        duration: Duration(seconds: 2), // Duración del mensaje
                      ),
                    );
                    // Navega a la pantalla de MapScreen después del inicio de sesión exitoso
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    });
                  } on FirebaseAuthException catch (e) { // Captura de excepciones de Firebase Auth
                    print('Error al iniciar sesión: $e');  // Imprime el error
                    _showErrorDialog(context, 'Por favor, revise sus credenciales y vuelva a intentarlo.'); // Muestra un diálogo de error
                  }
                },
                child: const Text('Aceptar'),
              ),
          ),
              const SizedBox(height: 10), // Espacio vertical entre elementos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Navega hacia atrás
                  },
                  child: const Text('Atrás'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) { // Método para mostrar un diálogo de error
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credenciales Incorrectas'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}