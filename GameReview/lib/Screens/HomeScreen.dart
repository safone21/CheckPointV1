import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:games/Screens/HomePages/GamesListFetch.dart';


import 'HomePages/UserProfilePage.dart';
import 'LoginScreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int pageIndex = 0;

  final List<Widget> pages = [
    GamesList(),
    UserProfile()
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          backgroundColor: Colors.teal[700],
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Handle notifications action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications clicked')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                // Handle heart action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Heart clicked')),
                );
              },
            ),
          ],
        ),
        body: pages[pageIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: pageIndex,
          onTap: (int index) async {
            if (index == 2) {
              // Handle sign out for the third tab
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            } else {
              // Update the page index for navigation
              setState(() {
                pageIndex = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: 'Sign Out',
            ),
          ],
        ),
      ),
    );
  }
}