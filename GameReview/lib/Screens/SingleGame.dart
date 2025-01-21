import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchGameDetails();
    fetchReviews();
  }

  /// Fetch game details from the external API
  Future<void> fetchGameDetails() async {
    const String apiUrl =
        "https://free-to-play-games-database.p.rapidapi.com/api/game";
    const Map<String, String> headers = {
      'x-rapidapi-host': 'free-to-play-games-database.p.rapidapi.com',
      'x-rapidapi-key': '4fc32dc1f9mshee7fb920c383e24p13a8fbjsn170c8a964d5f',
    };

    final response = await http.get(
      Uri.parse('$apiUrl?id=${widget.gameId}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      setState(() {
        gameData = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  /// Fetch all reviews for this `gameId`, including user info
  Future<void> fetchReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('gameId', isEqualTo: widget.gameId)
          .get();

      final List<Map<String, dynamic>> loadedReviews = [];
      for (var doc in reviewsSnapshot.docs) {
        final reviewData = doc.data();

        // Add the docId so we can update/delete the specific document
        reviewData['docId'] = doc.id;

        final userId = reviewData['userId'];

        // Fetch the user's details using the userId
        if (userId != null) {
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userSnapshot.exists) {
            final userData = userSnapshot.data();
            if (userData != null) {
              reviewData['userName'] = userData['prenom'] ?? 'Anonymous';
              reviewData['userInitial'] =
              (userData['prenom']?.isNotEmpty ?? false)
                  ? userData['prenom'][0].toUpperCase()
                  : '?';
            }
          } else {
            reviewData['userName'] = 'Anonymous';
            reviewData['userInitial'] = '?';
          }
        } else {
          reviewData['userName'] = 'Anonymous';
          reviewData['userInitial'] = '?';
        }

        loadedReviews.add(reviewData);
      }

      setState(() {
        reviews = loadedReviews;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  /// Submit (Add) a new review
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
          const SnackBar(
              content: Text('You must be logged in to submit a review.')),
        );
        return;
      }

      final userId = currentUser.uid;
      final reviewsRef = FirebaseFirestore.instance.collection('reviews');

      // Prepare the review data
      final reviewData = {
        'gameId': widget.gameId,
        'userId': userId,
        'description': _descriptionController.text.trim(),
        'rating': _rating,
        'timestamp': DateTime.now(),
      };

      // Add the review to Firestore
      await reviewsRef.add(reviewData);

      // Clear the form
      _descriptionController.clear();
      setState(() => _rating = 3.0);

      // Fetch reviews again to update the list
      fetchReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you for your feedback! Your review has been added.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
      print('Error submitting review: $e');
    }
  }

  /// Delete a review from Firestore
  Future<void> _deleteReview(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('reviews').doc(docId).delete();
      // Re-fetch to update the UI
      fetchReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete review.')),
      );
      print('Error deleting review: $e');
    }
  }

  /// Update a review in Firestore
  Future<void> _updateReview(String docId, String newDesc, double newRating) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(docId)
          .update({
        'description': newDesc,
        'rating': newRating,
      });
      // Refresh
      fetchReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update review.')),
      );
      print('Error updating review: $e');
    }
  }

  /// Show a dialog (or bottomSheet) for updating the review
  void _showUpdateDialog(Map<String, dynamic> review) {
    // Pre-fill with the existing data
    final TextEditingController descController =
    TextEditingController(text: review['description'] ?? '');
    double ratingValue = (review['rating'] is num) ? review['rating'] * 1.0 : 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Update Your Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                RatingBar.builder(
                  initialRating: ratingValue,
                  minRating: 1,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) => ratingValue = rating,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDesc = descController.text.trim();
                if (newDesc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a description.')),
                  );
                  return;
                }
                // Update in Firestore
                await _updateReview(review['docId'], newDesc, ratingValue);
                if (!mounted) return;
                Navigator.of(context).pop(); // close dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid; // null if not logged in

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(gameData?['title'] ?? "Game Details"),
          backgroundColor: Colors.teal[700],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Image
                Image.network(
                  gameData?['thumbnail'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Placeholder(fallbackHeight: 200),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  gameData?['title'] ?? 'Unknown Game',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Short description
                Text(
                  gameData?['short_description'] ??
                      'No description available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Game info card
                Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Genre: ${gameData?['genre'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text('Platform: ${gameData?['platform'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text('Publisher: ${gameData?['publisher'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text('Developer: ${gameData?['developer'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text(
                            'Release Date: ${gameData?['release_date'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Minimum system requirements
                Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Minimum System Requirements:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          if (gameData?['minimum_system_requirements'] !=
                              null)
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'OS: ${gameData?['minimum_system_requirements']?['os'] ?? 'N/A'}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Processor: ${gameData?['minimum_system_requirements']?['processor'] ?? 'N/A'}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Memory: ${gameData?['minimum_system_requirements']?['memory'] ?? 'N/A'}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Graphics: ${gameData?['minimum_system_requirements']?['graphics'] ?? 'N/A'}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Storage: ${gameData?['minimum_system_requirements']?['storage'] ?? 'N/A'}'),
                              ],
                            )
                          else
                            const Text(
                              'No minimum system requirements available.',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Screenshots
                const Text(
                  'Screenshots:',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                gameData?['screenshots'] != null
                    ? SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gameData!['screenshots'].length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Image.network(
                          gameData!['screenshots'][index]['image'],
                          fit: BoxFit.cover,
                          height: 200,
                          width: 300,
                          errorBuilder: (_, __, ___) =>
                          const Placeholder(
                              fallbackHeight: 200,
                              fallbackWidth: 300),
                        ),
                      );
                    },
                  ),
                )
                    : const Text('No screenshots available.'),

                const SizedBox(height: 16),

                // ----------- ADD A NEW REVIEW -----------
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter your review ...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 5,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rate Your Experience!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) => setState(() => _rating = rating),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: _submitReview,
                    child: const Text(
                      'Add Review',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // ----------- EXISTING REVIEWS -----------
                const Text(
                  'Reviews:',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final userName = review['userName'] ?? 'Anonymous';
                    final userInitial = review['userInitial'] ?? '?';
                    final docId = review['docId'];
                    final userId = review['userId'];
                    final timestamp = review['timestamp'];
                    final formattedDate = (timestamp != null)
                        ? DateFormat('yyyy-MM-dd HH:mm')
                        .format(timestamp.toDate())
                        : 'Unknown Date';

                    // Check if the current user is the owner of this review
                    final isOwner = (currentUserId != null && userId == currentUserId);

                    // Generate random border color for the avatar
                    final random = Random();
                    final borderColor = Color.fromARGB(
                      255,
                      random.nextInt(256),
                      random.nextInt(256),
                      random.nextInt(256),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Avatar with random border color
                            Container(
                              padding: const EdgeInsets.all(2), // Border width
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor, width: 3),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Text(
                                  userInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Review info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Rating: ${review['rating']}'),
                                  Text('Review: ${review['description']}'),
                                  Text('Date: $formattedDate'),
                                ],
                              ),
                            ),
                            // If user is the owner, show update/delete icons
                            if (isOwner) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _showUpdateDialog(review),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteReview(docId),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
