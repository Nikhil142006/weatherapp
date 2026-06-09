import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CropAdvisoryScreen extends StatelessWidget {
  const CropAdvisoryScreen({super.key});

  // Determine season based on current month
  String getCurrentSeason() {
    final month = DateTime.now().month;
    if ([6, 7, 8, 9].contains(month)) return "Kharif";
    if ([10, 11, 12, 1].contains(month)) return "Rabi";
    return "Zaid";
  }

  // Get seasonal advice text
  String getSeasonalAdvice(String season) {
    switch (season) {
      case "Kharif":
        return "☀️ Kharif Season (June–Sept)\n\n✅ Ideal crops: Rice, Maize, Cotton, Soybean\n💧 Ensure proper irrigation and pest control.\n⚡ Keep fields drained during heavy rains.";
      case "Rabi":
        return "🌾 Rabi Season (Oct–Jan)\n\n✅ Ideal crops: Wheat, Barley, Mustard, Peas\n🔥 Protect crops from frost.\n💧 Maintain moderate soil moisture.";
      case "Zaid":
        return "🌿 Zaid Season (Feb–May)\n\n✅ Ideal crops: Cucumber, Watermelon, Vegetables\n💧 Irrigate regularly.\n🌤 Protect from high summer temperatures.";
      default:
        return "🌱 Mixed cropping season – suitable for vegetables and pulses.";
    }
  }

  // Daily advice based on day/time
  String getDailyTip() {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return "🌞 Morning Tip:\nGood time to irrigate crops and apply fertilizers before high sun.";
    } else if (hour < 16) {
      return "🌤 Afternoon Tip:\nAvoid pesticide spraying during hot sun — wait until evening.";
    } else {
      return "🌙 Evening Tip:\nInspect crops for pests. Light irrigation helps retain soil moisture overnight.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String season = getCurrentSeason();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("🌾 Crop Advisory"),
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Smart Crop Guidance",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Personalized farming tips and seasonal recommendations.",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Current Season Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Season: $season",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  getSeasonalAdvice(season),
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Tip Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 36),
                const SizedBox(height: 8),
                Text(
                  "Today's Tip",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  getDailyTip(),
                  style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // General Farming Tips
          Text(
            "🌱 General Farming Tips",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            "🧑‍🌾 Regularly check soil moisture using simple finger test.",
            "💨 Avoid pesticide spraying on windy days.",
            "🌦️ Apply fertilizers after rain for better absorption.",
            "🌳 Use organic mulch to retain soil moisture and prevent weeds.",
            "🌡️ Monitor temperature changes – adjust irrigation accordingly.",
          ].map(
                (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 18)),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              "Updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
