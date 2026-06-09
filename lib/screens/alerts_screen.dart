import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // for WeatherHome widget

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final CollectionReference alertsRef =
  FirebaseFirestore.instance.collection('alerts');

  List<String> localAlerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLocalAlerts();
  }

  Future<void> loadLocalAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      localAlerts = prefs.getStringList('alerts') ?? [];
      isLoading = false;
    });
  }

  Future<void> clearLocalAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alerts');
    setState(() {
      localAlerts.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Local alerts cleared")),
    );
  }

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}  ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🌩 Live Weather Alerts'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Clear Local Alerts",
            onPressed: clearLocalAlerts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: alertsRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator(color: Colors.green));
                }

                final docs = snapshot.data?.docs ?? [];

                return docs.isEmpty
                    ? const Center(
                  child: Text(
                    "No alerts found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final message = doc['message'] ?? 'No message';
                    final timestamp =
                    formatTimestamp(doc['timestamp'] as Timestamp?);

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.cloud,
                            color: Colors.lightBlueAccent),
                        title: Text(message,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          timestamp,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ------------- Continue Button -------------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_ios),
              label: const Text(
                "Continue to Weather App",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WeatherHome()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
