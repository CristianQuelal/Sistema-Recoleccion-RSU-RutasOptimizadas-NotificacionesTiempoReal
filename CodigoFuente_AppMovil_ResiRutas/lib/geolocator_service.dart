// Importacion de paquetes necesarios
import 'package:geolocator/geolocator.dart';

class GeolocatorService { // Define una nueva clase llamada GeolocatorService
  Future<Position> determinePosition() async { // Método asíncrono que devuelve un objeto Future<Position>
    // Verifica si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // Si los servicios de ubicación están desactivados, lanza una excepción
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados.');
    }
    // Verifica los permisos de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    // Condicional para verificar i los permisos han sido denegados, solicita el permiso al usuario
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // Si el permiso es denegado nuevamente, lanza una excepción
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados');
      }
    }
    // Si los permisos han sido denegados permanentemente, lanza una excepción
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación fueron permanentemente denegados, no podemos solicitar permisos.');
    }
    // Si los servicios de ubicación están habilitados y los permisos han sido otorgados,
    // obtiene la posición actual del dispositivo y devuelve un objeto Position
    return Geolocator.getCurrentPosition();
  }
}
