import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:games/Screens/SingleGame.dart';
import 'package:http/http.dart' as http;

class GamesList extends StatefulWidget {
  const GamesList({Key? key}) : super(key: key);

  @override
  State<GamesList> createState() => _GamesListState();
}

class _GamesListState extends State<GamesList> {
  List<dynamic> allGames = [];
  List<dynamic> games = [];
  TextEditingController searchController = TextEditingController();
  List<String> genres = [];
  int currentPage = 0;
  final int itemsPerPage = 20;
  List<dynamic> paginatedGames = [];


  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  void extractGenres() {
    Set<String> uniqueGenres = {};
    for (var game in allGames) {
      if (game['genre'] != null) {
        uniqueGenres.add(game['genre'].toString());
      }
    }
    setState(() {
      genres = uniqueGenres.toList();
    });
  }

  void updatePaginatedGames() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (currentPage + 1) * itemsPerPage;

    setState(() {
      paginatedGames = games.length > startIndex
          ? games.sublist(startIndex, endIndex > games.length ? games.length : endIndex)
          : [];
    });
  }

  void nextPage() {
    if ((currentPage + 1) * itemsPerPage < games.length) {
      setState(() {
        currentPage++;
        updatePaginatedGames();
      });
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
        updatePaginatedGames();
      });
    }
  }

  Future<void> fetchGames() async {
    const String apiUrl = "https://free-to-play-games-database.p.rapidapi.com/api/games";
    const Map<String, String> headers = {
      'x-rapidapi-host': 'free-to-play-games-database.p.rapidapi.com',
      'x-rapidapi-key': '7241930f33mshff5ff272ac1edb5p106802jsn7808d1ee7367',
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          allGames = json.decode(response.body);
          games = allGames;
          updatePaginatedGames();
        });
        extractGenres();
      } else {
        debugPrint("Failed to fetch games: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void fetchGamesByGenre(String genre) async {
    setState(() {
      games = allGames.where((game) => game['genre'] == genre).toList();
      currentPage = 0;
      updatePaginatedGames();
    });
  }

  void searchGames(String query) {
    setState(() {
      games = allGames.where((game) {
        return game['title'].toLowerCase().contains(query.toLowerCase());
      }).toList();
      currentPage = 0;
      updatePaginatedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.only(left: 10, right: 10, top: 35, bottom: 35),
              child: Expanded(
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    searchGames(query);
                  },
                ),
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.all(10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        fetchGamesByGenre(genres[index]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        genres[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: games.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: paginatedGames.length,
                        itemBuilder: (context, index) {
                          final game = paginatedGames[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SingleGame(gameId: game["id"])));
                            },
                            child: GameCard(
                              title: game['title'],
                              imageUrl: game['thumbnail'],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Add pagination controls
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: currentPage > 0 ? previousPage : null,
                          color: Colors.white,
                        ),
                        Text(
                          '${currentPage + 1} / ${(games.length / itemsPerPage).ceil()}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: (currentPage + 1) * itemsPerPage < games.length ? nextPage : null,
                          color: Colors.white,
                        ),
                      ],
                    ),
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

class GameCard extends StatelessWidget {
  final String title;
  final String imageUrl;

  const GameCard({
    Key? key,
    required this.title,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}