// Importacion de librerias necesarias
import 'dart:async'; // Importa el paquete async para utilizar temporizadores
import 'package:flutter/material.dart'; // Importa el paquete flutter para construir la UI
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firebase Firestore para interactuar con la base de datos
import 'package:geolocator/geolocator.dart'; // Importa Geolocator para obtener la ubicación del dispositivo
import 'mapa_cliente.dart';  // Importa el widget del mapa del cliente

class ClientesForm extends StatefulWidget {
  const ClientesForm({super.key}); // Constructor de la clase


  @override
  ClientesFormState createState() => ClientesFormState(); // Crea el estado del widget
}

class ClientesFormState extends State<ClientesForm> {
  // Controladores para los campos de nombre y apellido
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  bool _esBotonHabilitado = false;  // Variable para habilitar/deshabilitar el botón
  Timer? _timer; // Temporizador para verificar la habilitación del botón

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { // Inicia el temporizador para verificar la habilitación del botón
      _verificarHabilitacionBoton();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela el temporizador al salir del widget
    super.dispose();
  }

  void _verificarHabilitacionBoton() {
    // Verifica si el botón debe estar habilitado según el día y la hora
    final ahora = DateTime.now();
    final diaDeLaSemana = ahora.weekday;
    final hora = ahora.hour;
    final minuto = ahora.minute;

    bool debeHabilitarse = diaDeLaSemana != 1 && (hora == 7 || (hora == 8 && minuto == 0));

    if (debeHabilitarse != _esBotonHabilitado) {
      setState(() {
        _esBotonHabilitado = debeHabilitarse; // Actualiza el estado del botón
      });
    }
  }

  bool esValido(String valor) {
    return valor.isNotEmpty && RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(valor);  // Verifica si el valor es válido
  }


  Future<void> guardarDatos(BuildContext context) async {
    String nombre = _nombreController.text;
    String apellido = _apellidoController.text;

    if (!esValido(nombre) || !esValido(apellido)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, ingresa un Nombre y Apellido válidos.'))
      );
      return;
    }

    // Capturar el BuildContext antes de entrar en el ámbito asíncrono
    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high); // Obtiene la posición actual del dispositivo

      await FirebaseFirestore.instance.collection('clientes').add({
        'Nombre': nombre,
        'Apellido': apellido,
        'Latitud': position.latitude,
        'Longitud': position.longitude,
      }); // Guarda los datos del cliente en Firestore

      // Mostrar SnackBar
      scaffoldContext.showSnackBar(
        const SnackBar(content: Text('Datos de cliente guardados con éxito')),
      );

      _nombreController.clear(); // Limpia el campo de nombre
      _apellidoController.clear(); // Limpia el campo de apellido

      // Navegar a MapaCliente después de un breve retraso
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>
                const MapaCliente()) //Llamado a la interfaz de mapa cliente
        );
      });
    } catch (e) {
      //Manejo de errores en caso de que no se puedan guardar los datos del cliente
      String errorMessage = 'Error al guardar los datos del cliente, ';
      if (e.toString().contains(
          'User denied permissions to access the device\'s location')) {
        _mostrarDialogoPermisos(context); // Mostrar diálogo de permisos
        errorMessage +=
        'los permisos necesarios se encuentran denegados.';
      } else {
        errorMessage += 'informe al administrador si el error continua';
        print('Error al guardar los datos del cliente: $e'); // Imprimir el error en la consola
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _mostrarDialogoPermisos(BuildContext context) {
    // Muestra un diálogo para pedir permisos de ubicación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos necesarios'),
          content: const Text(
              'Para otorgar los permisos de ubicación. '
                  'Ve a Configuraciones > Aplicaciones > ResiRutas o da clic en Configuración.'
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de Servicio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'AVISO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo podrá realizar servicios de recolección de 7:00 am a 8:00 am de Martes a Domingo',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _esBotonHabilitado ? () => guardarDatos(context) : null,
                child: const Text('Aceptar'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Atrás'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}