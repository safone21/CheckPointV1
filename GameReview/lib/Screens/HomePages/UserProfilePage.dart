import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final double profileHeight = 144;
  final double coverHeight = 280;

  // Stats (hard-coded example)
  final int reviewCount = 25;
  final int followingCount = 30;
  final int likeCount = 50;

  // Cover image
  File? coverImage;
  final String defaultCoverImage = 'assets/default_cover_image.jpg';

  // Profile image
  File? profileImage; // <--- NEW: store the selected profile image

  // User info from Firestore
  String? _firstName;
  String? _lastName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  /// Retrieve the connected user’s data from Firestore (collection 'users').
  Future<void> _getUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return; // No one is signed in
      }
      final userId = currentUser.uid;

      // Read the Firestore document (collection 'users', doc == UID)
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnap.exists) return;

      final data = docSnap.data();
      if (data == null) return;

      // Adjust keys based on your Firestore structure:
      setState(() {
        _firstName = data['nom'] ?? '';
        _lastName = data['prenom'] ?? '';
        _email = data['email'] ?? '';
      });
    } catch (e) {
      print('Error retrieving user data: $e');
    }
  }

  /// Pick an image for the cover from camera or gallery
  Future<void> pickCoverImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          coverImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking cover image: $e');
    }
  }

  /// Show a bottom sheet to pick the cover image source
  void showCoverImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickCoverImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickCoverImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick an image for the profile from camera or gallery
  Future<void> pickProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking profile image: $e');
    }
  }

  /// Show a bottom sheet to pick the profile image source
  void showProfileImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Heart clicked')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildTop(),
          buildContent(),
        ],
      ),
    );
  }

  /// Top section with cover + profile
  Widget buildTop() {
    final top = coverHeight - profileHeight / 2;
    final bottom = profileHeight / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(bottom: bottom),
          child: buildCoverImage(),
        ),
        Positioned(
          top: top,
          child: buildProfileImage(),
        ),
      ],
    );
  }

  /// Cover image area (with edit button)
  Widget buildCoverImage() {
    return Stack(
      children: [
        SizedBox(
          height: coverHeight,
          width: double.infinity,
          child: coverImage != null
              ? Image.file(
            coverImage!,
            fit: BoxFit.cover,
          )
              : Image.asset(
            defaultCoverImage,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[800]),
              onPressed: showCoverImageSourceOptions,
            ),
          ),
        ),
      ],
    );
  }

  /// Profile image (with first letter if no image)
  Widget buildProfileImage() {
    // Combine first & last name
    final fullName = '${_firstName ?? ''} ${_lastName ?? ''}'.trim();
    // Take the first letter if we have a name, otherwise "?"
    final initialLetter =
    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: profileHeight / 2,
          // If the user picked a profileImage, display it
          backgroundImage:
          profileImage != null ? FileImage(profileImage!) : null,
          // If there's no profileImage, use a colored background + initial
          backgroundColor: Colors.teal,
          child: profileImage == null
              ? Text(
            initialLetter,
            style: const TextStyle(
              fontSize: 40,
              color: Colors.white,
            ),
          )
              : null,
        ),
        // Small edit button in the bottom-right corner of the avatar
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: showProfileImageSourceOptions,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, color: Colors.grey[800]),
            ),
          ),
        ),
      ],
    );
  }

  /// Main content: name, email, stats, social icons, etc.
  Widget buildContent() {
    final fullName = '${_firstName ?? '...'} ${_lastName ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Center(
            child: Text(
              fullName.isEmpty ? 'Utilisateur' : fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Short desc
          Center(
            child: Text(
              'Gaming and Netflix',
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email
          Center(
            child: Text(
              _email ?? 'Email inconnu',
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Social icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSocialIcon(FontAwesomeIcons.facebook,
                  'https://www.facebook.com/yourprofile'),
              const SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.instagram,
                  'https://www.instagram.com/yourprofile'),
              const SizedBox(width: 12),
              buildSocialIcon(
                  FontAwesomeIcons.twitter, 'https://twitter.com/yourprofile'),
              const SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.snapchat,
                  'https://www.snapchat.com/add/yourprofile'),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
          buildStats(),
          const SizedBox(height: 16),

          // About
          const Text(
            'About : ',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Avid gamer with a passion for exploring immersive virtual worlds. "
                "I enjoy sharing insights, reviews, and tips about the latest games. "
                "Always on the lookout for new adventures and challenges in gaming. "
                "Connecting with like-minded gamers is what I love the most!",
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single social icon circle that launches a URL
  Widget buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.teal,
        child: Icon(
          icon,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Stats row (Reviews, Following, Likes)
  Widget buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildStatItem('Reviews', reviewCount),
          buildDivider(),
          buildStatItem('Following', followingCount),
          buildDivider(),
          buildStatItem('Likes', likeCount),
        ],
      ),
    );
  }

  /// Helper to launch an external URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Builds a single stat block with count + label
  Widget buildStatItem(String label, int count) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Divider between stats
  Widget buildDivider() {
    return SizedBox(
      height: 24,
      child: VerticalDivider(
        color: Colors.grey[300],
        thickness: 1,
      ),
    );
  }
}
