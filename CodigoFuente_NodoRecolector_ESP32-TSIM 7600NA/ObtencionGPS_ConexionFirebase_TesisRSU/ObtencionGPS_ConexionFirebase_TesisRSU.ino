/***************************************************************
  CODIGO DE PROGRAMACION DEL BLOQUE DE OBTENCIÓN DE DATOS
  PARA OBTENER LOS DATOS DE GPS Y ENVIAR A BDD DE FIREBASE
  TESIS: SISTEMA DE RECOLECCIÓN DE RESIDUOS SOLIDOS URBANOS
  BASADO EN OPTIMIZACIÓN DE RUTAS Y NOTIFICACIÓN EN TIEMPO
  REAL PARA EL BARRIO CENTENARIO, CIUDAD DE SAN GABRIEL
  AUTOR: CRISTIAN QUELAL
  CORREO: ciquelalg@utn.edu.ec | quelal.cristian21@gmail.com
  Nota: Este codigo es una adaptacion del codigo base AllFunctions.ino
  del repositorio oficial de Github del microcontrolador ESP32 T-SIM7600X
  Link: https://github.com/Xinyuan-LilyGO/T-SIM7600X/blob/master/examples/AllFunctions/AllFunctions.ino
***************************************************************/

// Definiciones de pines y la velocidad de la comunicación serial
#define UART_BAUD           115200         //Velocidad de baudios para el puerto serial
#define MODEM_TX            27             //Pin TX del módulo GSM        
#define MODEM_RX            26             //Pin RX del módulo GSM
#define MODEM_PWRKEY        4              //Pin para encender/apagar el módulo GSM
#define MODEM_FLIGHT        25             //Pin de control de modo vuelo del módulo GSM
#define LED_PIN             12             //Pin para el LED indicador

// Definiciones de configuración del módulo GSM
#define TINY_GSM_MODEM_SIM7600             //Define el módulo GSM utilizado como SIM7600               
#define SerialMon Serial                   //Define el puerto serial para la comunicación con la consola de monitoreo
#define SerialAT Serial1                   //Define el puerto serial para la comunicación con el módulo GSM
#define TINY_GSM_DEBUG SerialMon           //Define el puerto serial para la salida de depuración de TinyGSM

//Definiciones de las pruebas habilitadas de conectividad con TinyGSM
#define TINY_GSM_TEST_GPRS          true
#define TINY_GSM_TEST_GPS           true
#define TINY_GSM_TEST_TCP           true
#define TINY_GSM_TEST_TEMPERATURE   true
#define TINY_GSM_TEST_TIME          true


// Credenciales GPRS para la conexion con la red movil Claro
const char apn[] = "internet.claro.com.ec";                                                                 //APN para la conexión GPRS
const char gprsUser[] = "claro";                                                                            //Usuario para la conexión GPRS
const char gprsPass[] = "claro";                                                                            //Contraseña para la conexión GPRS

// Credenciales para la conexion con la BDD FIREBASE
const char server[]  = "residuos-solidos-urbanos2023-default-rtdb.firebaseio.com";                          //Servidor Firebase
const String resource  = "o7FMq7rrQeSkm48OoijD2sCDwEL7tbZRz0AMZVx5";                                        //Token de autenticación
const int port = 443;                                                                                       //Puerto de conexión
const String var  = "/";                                                                                    //Variable para el recurso en la BDD

//Librerias 
#include "SSLClient.h"                                                                                      //Cliente SSL: Proporciona la funcionalidad para establecer conexiones seguras mediante SSL/TLS
#include "certs.h"                                                                                          //Certificados SSL: Contiene los certificados SSL necesarios para la comunicación segura
#include <TinyGsmClient.h>                                                                                  //Cliente GSM: Permite la comunicación con el módulo GSM para el envío y recepción de datos
#include <ArduinoHttpClient.h>                                                                              //Cliente HTTP: Facilita el envío de solicitudes HTTP y la recepción de respuestas desde un servidor
#include <ArduinoJson.h>                                                                                    //Librería Arduino JSON: Ofrece herramientas para crear, enviar y procesar datos JSON de manera sencilla y eficiente

//Variables para controlar el tiempo de ejecución
unsigned long previousMillis = 0;   //Variable para almacenar el tiempo del último ciclo de ejecución
const long interval = 5000;  //Define el intervalo deseado para el envio de datos (5 segundos)

//Inicialización del cliente GSM
TinyGsm modem(SerialAT);                                                                                    //Crea un objeto TinyGsm para la comunicación GSM, utilizando la instancia de SerialAT


//Configuración de clientes para comunicación GSM, SSL y HTTP
TinyGsmClient base_client(modem);                                                                           //Crea un cliente GSM utilizando el objeto modem como base para la comunicación
SSLClient secure_layer(&base_client);                                                                       //Crea un cliente SSL utilizando el cliente GSM base para establecer conexiones seguras
HttpClient client(secure_layer, server, port);                                                              //Crea un cliente HTTP utilizando el cliente SSL para enviar solicitudes HTTP al servidor


void setup() {
  //Definicion de variables
  bool res; 
  String ret; 
  SerialMon.begin(115200);
  delay(10);                                                                                               //Iniciar comunicación serial para monitoreo
  SerialAT.begin(UART_BAUD, SERIAL_8N1, MODEM_RX, MODEM_TX);                                                //Iniciar comunicación serial para módem GSM
  //Configura la velocidad de transmisión a 115200 baudios (UART_BAUD), (SERIAL_8N1)8 bits de datos, sin paridad y 1 bit de parada.
  //Utiliza los pines MODEM_RX y MODEM_TX para la recepción y transmisión de datos, respectivamente.
  
 //Configuracion de Luz indicadora de la placa
  pinMode(LED_PIN, OUTPUT);                                                                                 //Configurar pin de la led como salida
  digitalWrite(LED_PIN, LOW);                                                                               //Configurar el estado del pin de la led como bajo/apagado

  //Configuracion de encendido de MODEM
  pinMode(MODEM_PWRKEY, OUTPUT);                                                                            //Configurar pin de control de encendido del módem
  digitalWrite(MODEM_PWRKEY, HIGH);                                                                         //Configurar pin de control de encendido del módem en alto/activado
  delay(1000);                                                                                               //Esperar un período para que el módem se inicialice completamente
  digitalWrite(MODEM_PWRKEY, LOW);                                                                          //Apagar el pin de control de encendido del módem              
  delay(10000); 
  
 
  //Configuracion Modo de vuelo del MODEM
  pinMode(MODEM_FLIGHT, OUTPUT);                                                                            //Configurar pin de del modo vuelo del modem GSM/GPRS como salida
  digitalWrite(MODEM_FLIGHT, HIGH);                                                                         //Configurar el estado del pin del modo vuelo del modem GSM/GPRS en alto            


  //Agregar certificado de autoridad (CA) al cliente SSL
  secure_layer.setCACert(root_ca);

  //Establecer tiempo de espera para respuestas HTTP
  client.setHttpResponseTimeout(30 * 1000);                                                                //30 segundos de tiempo de espera para las respuestas HTTP
  
  
  //Inicio de Modem
  if (!modem.init()) {                                                                                     //Verifica si la inicialización del módem fue exitosa
      DBG("Inicializando Modem..........");                                                                //Muestra un mensaje
      delay(5000);                                                                                         //Espera 5 segundos antes de volver a intentar la inicialización
    }else{
      DBG("Modem inicializado exitosamente"); 
    }
  
  #if TINY_GSM_TEST_GPRS
    /*  Modo de seleccion de conexion a red: 
        2 – Automatico
        13 – GSM Only
        14 – WCDMA Only
        38 – LTE Only
        19 – GSM+WCDMA Only
        48 – Any but LTE
        39 – GSM+WCDMA+LTE Only
        51 – GSM+LTE Only
        54 – WCDMA+LTE Only
   */
      ret = modem.setNetworkMode(38);
      DBG("Modo de Red:", ret); 


      uint8_t mode = modem.getGNSSMode();
      DBG("Modo de GNSS :", mode);

      /**
      CGNSSMODE: <gnss_mode>,<dpo_mode>
      Configuracion del modo de GNSS
      gnss_mode:
          0 : GLONASS
          1 : BEIDOU
          2 : GALILEO
          3 : QZSS
      dpo_mode (ahorro de energia) :
          0 deshabilitado
          1 habilitado
      */
      modem.setGNSSMode(0, 0);
      delay(2000);

      String name = modem.getModemName();                                                                     //Obtener el nombre del módem
      DBG("Nombre del Modem:", name); 

      String modemInfo = modem.getModemInfo();                                                                //Obtener información del módem         
      DBG("Informacion del Modem:", modemInfo); 

      //Conexion a la red movil
      DBG("Esperando la conexión a la red movil..");
      if (!modem.waitForNetwork(600000L)) {                                                                   // El parámetro de esta función representa el tiempo máximo de espera en milisegundos (600000 milisegundos en este caso, equivalente a 10 minutos)                        
      DBG("Red movil no disponible, volviendo a intentar en 5s");
      delay(5000);
      return;
      }
 
      //Verificacion de que la red movil este conectada
      if (modem.isNetworkConnected()) {
      DBG("Red movil conectada");
      }

  #endif

  #if TINY_GSM_TEST_GPRS
    // Conexion Modulo GSM/GPRS
    DBG("Conectando al APN: ", apn);
    if (!modem.gprsConnect(apn, gprsUser, gprsPass)) {                                                       //Intenta establecer una conexión GPRS utilizando las credenciales proporcionadas
      DBG("Fallo la conexión al APN, volviendo a intentar en 5s");                                             //Espera 5 segundos antes de volver a intentar la conexión
      delay(5000);
      return;
    }

    // Verificar si la conexión GPRS está establecida
    res = modem.isGprsConnected(); 
    DBG("GPRS estado:", res ? "Conectado" : "No Conectado");                                                  //Muestra el estado de la conexión GPRS (Conectado/No Conectado)
    DBG("Conexion establecida con: ", apn);

    //Obtener información de la tarjeta SIM
    String ccid = modem.getSimCCID();                                                                         //Obtiene el número ICCID((Integrated Circuit Card Identifier)) de la tarjeta SIM
    DBG("CCID:", ccid); 
    String imei = modem.getIMEI();                                                                            //Obtiene el número IMEI(International Mobile Equipment Identity) del módem
    DBG("IMEI:", imei); 
    String imsi = modem.getIMSI();                                                                            //Obtiene el número IMSI(International Mobile Subscriber Identity) de la tarjeta SIM
    DBG("IMSI:", imsi); 
    String cop = modem.getOperator();                                                                         //Obtiene el nombre del operador de red 
    DBG("Operador:", cop); 
    IPAddress local = modem.localIP();
    //Obtener la dirección IP local 
    DBG("Direccion IP Local asignada:", local); 
    //Obtener la calidad de la señal
    int csq = modem.getSignalQuality();
    int signalStrength; 
    if (csq == 99) {
      signalStrength = -999; // Señal no conocida o no detectable
    } else {
      signalStrength = -113 + 2 * csq;
    }
    DBG("Potencia de la señal de la red móvil:", signalStrength, " dBm");

  #endif

  #if TINY_GSM_TEST_GPS && defined TINY_GSM_MODEM_HAS_GPS
        //Habilitar GPS si el módulo GPRS está conectado
        modem.enableGPS();
        DBG("Modem GPS Habilitado");
        delay(2000);
  #endif      
 
}


void loop() {

  #if TINY_GSM_TEST_TEMPERATURE && defined TINY_GSM_MODEM_HAS_TEMPERATURE
      float temp = modem.getTemperature();
      if (temp == 0){
       DBG("Obteniendo temperatura del modem GSM/GPRS...");
      }else{
        DBG("Temperatura Modem GSM/GPRS:", temp, "°C");
      }
  #endif

  #if TINY_GSM_TEST_TIME && defined TINY_GSM_MODEM_HAS_TIME
      int year3 = 0;
      int month3 = 0;
      int day3 = 0;
      int hour3 = 0;
      int min3 = 0;
      int sec3 = 0;
      float timezone = 0;
      for (int8_t i = 5; i; i--) {
        if (modem.getNetworkTime(&year3, &month3, &day3, &hour3, &min3, &sec3,
                                &timezone)) {
          DBG("Sincronizando Fecha y Hora de la red móvil.....");                        
          break;
        } else {
          DBG("Obteniendo Fecha y Hora de red móvil.......");
          delay(5000);
          continue;
        }
      }
  #endif

  //Obtiene el tiempo actual en milisegundos
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {  //Verifica si ha pasado el intervalo deseado desde la última ejecución
    previousMillis = currentMillis;   // Actualiza el tiempo de la última ejecución
    
        // Se inicializan las variables para almacenar la latitud, longitud, velocidad, altitud,precisión y los componentes de la fecha/hora
        float lat2      = 0;
        float lon2      = 0;
        float speed2    = 0;
        float speed_kmh = 0;
        float alt2      = 0;
        int   vsat2     = 0;
        int   usat2     = 0;
        float accuracy2 = 0;
        int   year2     = 0;
        int   month2    = 0;
        int   day2      = 0;
        int   hour2     = 0;
        int   min2      = 0;
        int   sec2      = 0;

        DBG("Obteniendo datos GPS.....");
        for (;;) {                                                        //Bucle infinito para obtener continuamente las coordenadas GPS                                                                                                                                                                                          
          digitalWrite(LED_PIN, !digitalRead(LED_PIN));                   //Alternar el estado del LED

            if (modem.getGPS(&lat2, &lon2, &speed2, &alt2, &vsat2, &usat2, &accuracy2,
                            &year2, &month2, &day2, &hour2, &min2, &sec2)) {      //Se intenta obtener las coordenadas GPS del módem
              //Si se obtienen con éxito las coordenadas, se muestran en el monitor serial
              DBG("Coordenadas Obtenidas: ""Latitude:", String(lat2, 8), "° \tLongitude:", String(lon2, 8), " °");
              // Convertir la velocidad de m/s a km/h
              //float speed_kmh = speed2 * 3.6;
              DBG("Altitud:", alt2, " m");
              DBG("Velocidad:", speed2, " km/h\tPrecicion:", accuracy2, " m");
              //Formatear la fecha y la hora en strings
              char dateStr3[11];
              sprintf(dateStr3, "%02d/%02d/%04d", day3, month3, year3);
              char timeStr3[9];
              sprintf(timeStr3, "%02d:%02d:%02d", hour3, min3, sec3);
              DBG("Fecha:", dateStr3);
              DBG("Hora:", timeStr3);
              DBG("Timezone:", timezone);
              break;
            }else{
              //Si falla la obtención de las coordenadas GPS, se muestra un mensaje y se espera antes de intentarlo nuevamente
              DBG("Estableciendo conexión con Antena GPS.......");
              delay(5000);
              continue;
            } 
        } 

          StaticJsonDocument<256> jsonBuffer; //Se define el tamaño del búfer para almacenar el objeto JSON
          // Se asignan los valores de las variables de coordenadas y tiempo al objeto JSON
          jsonBuffer["lat"] = lat2;
          jsonBuffer["lng"] = lon2;
          jsonBuffer["speed"] = speed2;
          jsonBuffer["altura"] = alt2;
          jsonBuffer["precicion"] = accuracy2;
          jsonBuffer["fecha"] = String(day3) + "/" + String(month3) + "/" + String(year3);
          jsonBuffer["hora"] = String(hour3) + ":" + String(min3) + ":" + String(sec3);

          //Convertir el objeto JSON a una cadena de texto
          String postData;
          serializeJson(jsonBuffer, postData);      //Se serializa el objeto JSON en una cadena de texto para poder enviarlo como datos de la solicitud HTTP.
        
          //Se construye la URL para la solicitud HTTP, incluyendo la variable "var" y el recurso de autenticación.
            String URL = var + ".json?auth=" + resource;
          //Se define el tipo de contenido de la solicitud HTTP como "application/json".  
            String contentType = "application/json";


        const int MAX_RETRIES = 3;
        int retries = 0;

        while (retries < MAX_RETRIES) {  
          DBG("Conectando al servidor ", server, " por el puerto ", port);

          //Se envía una solicitud HTTP PUT al servidor Firebase con la URL, el tipo de contenido y los datos del objeto JSON.
          client.put(URL, contentType, postData);

          //Se obtiene el código de estado de la respuesta HTTP y el cuerpo de la respuesta.
          int status_code = client.responseStatusCode();
          String response = client.responseBody();

          //Se muestran en el monitor serial el código de estado y la respuesta recibida del servidor.
          DBG("Código de Estado: ", status_code);

          // Verificar si el código de estado es diferente de 200
          if (status_code == 200) {
            DBG("Datos enviados a Firebase: ", response);
            // Se cierra la conexión con el servidor Firebase.  
            client.stop();
            break;  // Salir del bucle si el envío fue exitoso
            } else {
                DBG("Error en el envío de datos a Firebase. Intento ", retries + 1, " de ", MAX_RETRIES);
                retries++;
                delay(1000);  // Esperar un segundo antes de reintentar
            }
        }

        if (retries == MAX_RETRIES) {
            DBG("No se pudo establecer conexión con Firebase después de ", MAX_RETRIES, " intentos.");
            DBG("Se procederá a reiniciar el módem.");
            setup();  // Función para reiniciar el módem
        }

       unsigned long endMillis = millis();  //Obtiene el tiempo al finalizar la ejecución del código
       DBG("Tiempo de ejecución: ", endMillis - currentMillis, " ms");  //Muestra el tiempo que tomó ejecutar el código
       
       //código para compensar el tiempo de ejecución 
       unsigned long executionTime = endMillis - currentMillis; //Calcula el tiempo total de ejecución
       if (executionTime < interval) {   // Si la ejecución tomó menos tiempo que el intervalo deseado, espera la diferencia para mantener el intervalo constante
          delay(interval - executionTime);
        }
      
      DBG(" "); 
      DBG(".................................");    
      DBG(".....PROCESANDO NUEVOS DATOS....."); 
      DBG(".................................");
      DBG(" ");    
  }       
}