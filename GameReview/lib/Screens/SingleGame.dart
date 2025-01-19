import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  final _descriptionController = TextEditingController();
  double _rating = 3.0;

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
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(gameData!['thumbnail'], fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(
                  gameData!['title'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  gameData!['short_description'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text('Genre: ${gameData!['genre']}'),
                const SizedBox(height: 8),
                Text('Platform: ${gameData!['platform']}'),
                const SizedBox(height: 8),
                Text('Publisher: ${gameData!['publisher']}'),
                const SizedBox(height: 8),
                Text('Developer: ${gameData!['developer']}'),
                const SizedBox(height: 8),
                Text('Release Date: ${gameData!['release_date']}'),
                const SizedBox(height: 16),
                Text('Minimum System Requirements:'),
                const SizedBox(height: 8),
                Text('OS: ${gameData!['minimum_system_requirements']['os']}'),
                const SizedBox(height: 4),
                Text('Processor: ${gameData!['minimum_system_requirements']['processor']}'),
                const SizedBox(height: 4),
                Text('Memory: ${gameData!['minimum_system_requirements']['memory']}'),
                const SizedBox(height: 4),
                Text('Graphics: ${gameData!['minimum_system_requirements']['graphics']}'),
                const SizedBox(height: 4),
                Text('Storage: ${gameData!['minimum_system_requirements']['storage']}'),
                const SizedBox(height: 16),
                Text('Screenshots:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                gameData!['screenshots'] != null
                    ? SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gameData!['screenshots'].length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Image.network(
                          gameData!['screenshots'][index]['image'],
                          fit: BoxFit.cover,
                          height: 200,
                          width: 300,
                        ),
                      );
                    },
                  ),
                )
                    : const Text('No screenshots available.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter your review ...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 5,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rate Your Experience !',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) => setState(() => _rating = rating),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _submitReview,
                    child: const Text(
                      'Add Review',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitReview() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to add a review.')),
        );
        return;
      }

      final userId = currentUser.uid;

      final reviewsRef = FirebaseFirestore.instance.collection('reviews');

      final reviewData = {
        'gameId': widget.gameId,
        'userId': userId,
        'description': _descriptionController.text.trim(),
        'rating': _rating,
        'timestamp': DateTime.now(),
      };

      await reviewsRef.add(reviewData);

      _descriptionController.clear();
      setState(() => _rating = 3.0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
    }
  }
}
