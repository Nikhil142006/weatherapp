import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CultivationScreen extends StatefulWidget {
  const CultivationScreen({super.key});

  @override
  State<CultivationScreen> createState() => _CultivationScreenState();
}

class _CultivationScreenState extends State<CultivationScreen> {
  final List<Map<String, String>> videos = [
    {
      "title": "🌾 Modern Rice Cultivation Techniques",
      "url": "https://www.youtube.com/watch?v=kT1R7Hkps5M"
    },
    {
      "title": "🌽 Maize Farming Tips for Beginners",
      "url": "https://www.youtube.com/watch?v=nfMLKP1nXK0"
    },
    {
      "title": "☘️ Organic Fertilizer Preparation at Home",
      "url": "https://www.youtube.com/watch?v=4Wo8XfCIvu8"
    },
    {
      "title": "🥔 Potato Cultivation Process Explained",
      "url": "https://www.youtube.com/watch?v=CEEiP-DfOfY"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎥 Cultivation Techniques"),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final videoId = YoutubePlayer.convertUrlToId(videos[index]['url']!);
          final controller = YoutubePlayerController(
            initialVideoId: videoId!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
            ),
          );
          return Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YoutubePlayer(
                    controller: controller,
                    showVideoProgressIndicator: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    videos[index]['title']!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
