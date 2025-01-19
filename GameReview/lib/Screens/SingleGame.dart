import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SingleGame extends StatefulWidget {
  final int gameId;
  const SingleGame({Key? key, required this.gameId}) : super(key: key);

  @override
  State<SingleGame> createState() => _SingleGameState();
}

class _SingleGameState extends State<SingleGame> {
  Map<String, dynamic>? gameData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGameDetails();
  }

  Future<void> fetchGameDetails() async {
    const String apiUrl = "https://free-to-play-games-database.p.rapidapi.com/api/game";
    const Map<String, String> headers = {
      'x-rapidapi-host': 'free-to-play-games-database.p.rapidapi.com',
      'x-rapidapi-key': '4fc32dc1f9mshee7fb920c383e24p13a8fbjsn170c8a964d5f',
    };

    final response = await http.get(Uri.parse('$apiUrl?id=${widget.gameId}'), headers: headers);
    if (response.statusCode == 200) {
      setState(() {
        gameData = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(gameData?['title'] ?? "Game Details")),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            :  SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(gameData!['thumbnail'] ?? "", fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(
                  gameData!['title'] ?? "",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  gameData!['short_description'] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (gameData!['minimum_system_requirements'] != null) ...[
                  const Text(
                    "Memory Requirements:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(gameData!['minimum_system_requirements']['memory'] ?? "N/A"),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
