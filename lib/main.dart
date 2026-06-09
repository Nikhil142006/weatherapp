import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
import 'screens/otp_login.dart';
import 'screens/alerts_screen.dart';
import 'screens/crop_advisory_screen.dart';
import 'screens/cultivation_screen.dart';



// ------------------ NOTIFICATIONS ------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> showNotification(String title, String body) async {
  if (kIsWeb) return;

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'weather_alerts',
    'Weather Alerts',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

// ------------------ ALERT STORAGE ------------------
Future<void> saveAlert(String alert) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> alerts = prefs.getStringList('alerts') ?? [];
  alerts.add(alert);
  await prefs.setStringList('alerts', alerts);
}

Future<List<String>> getAlerts() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('alerts') ?? [];
}

// ------------------ BACKGROUND TASK ------------------
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      "Weather Alert",
      "⛈️ Thunderstorm in your area!",
      platformDetails,
    );

    await saveAlert(
        "⛈️ Thunderstorm alert received at ${DateFormat('hh:mm a').format(DateTime.now())}");

    return Future.value(true);
  });
}

// ------------------ MAIN APP ENTRY ------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await initNotifications();
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerPeriodicTask(
      "weatherTask",
      "checkWeather",
      frequency: const Duration(minutes: 15),
    );
  }

  runApp(const WeatherApp());
}

// ------------------ WEATHER APP ------------------
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "🌾 Smart Farmer's Weather App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OTPLoginScreen(),
        '/home': (context) => const WeatherHome(),
        '/alerts': (context) => const AlertsScreen(),
        '/advisory': (context) => const CropAdvisoryScreen(),
        '/cultivation': (context) => const CultivationScreen(),

      },
    );
  }
}

// ------------------ WEATHER HOME SCREEN ------------------
class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final String apiKey = "e8163f87f893d24dab4ec3932fa5ef89";
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>> forecastData = [];
  bool isLoading = false;

  Future<void> fetchWeather(String city) async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        weatherData = jsonDecode(response.body);
      });
      await fetchForecast(city);
    } else {
      setState(() {
        weatherData = null;
        forecastData = [];
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("City not found!")));
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchForecast(String city) async {
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> list = [];
      for (var i = 0; i < data['list'].length; i += 8) {
        final item = data['list'][i];
        list.add({
          'date': item['dt_txt'],
          'temp': item['main']['temp'].toDouble(),
          'humidity': item['main']['humidity'],
          'wind': item['wind']['speed'].toDouble(),
          'rain': (item['rain'] != null && item['rain']['3h'] != null)
              ? item['rain']['3h'].toDouble()
              : 0.0,
          'condition': item['weather'][0]['main'],
        });
      }
      setState(() => forecastData = list);
    }
  }

  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case "clear":
        return "assets/images/weather/sun.png";
      case "clouds":
        return "assets/images/weather/cloud.png";
      case "rain":
        return "assets/images/weather/rain.png";
      case "thunderstorm":
        return "assets/images/weather/thunderstorm.png";
      default:
        return "assets/images/weather/sun.png";
    }
  }

  String getDayName(String dateTimeStr) {
    DateTime date = DateTime.parse(dateTimeStr);
    return DateFormat('EEE').format(date);
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() => isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enable Location Services!")));
      setState(() => isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Location permission permanently denied!")));
      setState(() => isLoading = false);
      return;
    }

    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        weatherData = data;
      });
      await fetchForecast(data['name']);
    } else {
      setState(() {
        weatherData = null;
        forecastData = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to fetch location weather!")));
    }
    setState(() => isLoading = false);
  }

  Future<void> checkLiveAlerts() async {
    if (weatherData == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Check weather first!")));
      return;
    }

    final condition = weatherData!['weather'][0]['main'].toString();
    if (condition.contains("Rain") || condition.contains("Thunderstorm")) {
      final alertMsg =
          "⚠️ $condition detected in ${weatherData!['name']} at ${DateFormat('hh:mm a').format(DateTime.now())}";
      await showNotification("Weather Alert", alertMsg);
      await saveAlert(alertMsg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No severe weather alerts right now.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.height * 0.27;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("🌾 Smart Farmer's Weather App"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: fetchWeatherByLocation,
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text("Farmer's Menu",
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.amber),
              title: const Text("View Alerts"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/alerts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text("Check Live Alerts"),
              onTap: () {
                Navigator.pop(context);
                checkLiveAlerts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.orangeAccent),
              title: const Text("Cultivation Techniques"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cultivation');
              },
            ),

            ListTile(
              leading: const Icon(Icons.eco, color: Colors.lightGreenAccent),
              title: const Text("Crop Advisory"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/advisory');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TypeAheadField<String>(
              suggestionsCallback: (pattern) async {
                final cities = [
                  "Delhi",
                  "Mumbai",
                  "Chennai",
                  "Hyderabad",
                  "London",
                  "New York"
                ];
                return cities
                    .where((city) =>
                    city.toLowerCase().startsWith(pattern.toLowerCase()))
                    .toList();
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter city name",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: fetchWeather,
                );
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSelected: (String suggestion) {
                _controller.text = suggestion;
                fetchWeather(suggestion);
              },
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            else if (weatherData != null)
              Expanded(
                child: ListView(
                  children: [
                    // Current Weather Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${weatherData!['name']}, ${weatherData!['sys']['country']}",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            getWeatherIcon(
                                weatherData!['weather'][0]['main'].toString()),
                            width: 80,
                            height: 80,
                          ),
                          Text(
                            "${weatherData!['main']['temp']}°C",
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            weatherData!['weather'][0]['description']
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Forecast
                    if (forecastData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🌤 5-Day Forecast (Agriculture Insights)",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: cardHeight,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: forecastData.length,
                              itemBuilder: (context, index) {
                                final day = forecastData[index];
                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        getDayName(day['date']),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Image.asset(
                                        getWeatherIcon(day['condition']),
                                        width: 40,
                                      ),
                                      Text(
                                        "${day['temp'].toStringAsFixed(0)}°C",
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.water_drop,
                                              color: Colors.blueAccent,
                                              size: 16),
                                          Text("${day['humidity']}%",
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.air,
                                              color: Colors.cyanAccent,
                                              size: 16),
                                          Text("${day['wind']} m/s",
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.grain,
                                              color: Colors.lightGreen,
                                              size: 16),
                                          Text("${day['rain']}mm",
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
