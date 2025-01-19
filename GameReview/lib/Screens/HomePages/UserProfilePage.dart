import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final double profileHeight = 144;
  final double coverHeight = 280;
  final int reviewCount = 25;
  final int followingCount = 30;
  final int likeCount = 50;
  File? coverImage; // To store the selected image file
  final String defaultCoverImage = 'assets/default_cover_image.jpg';


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
      print('Error picking image: $e');
    }
  }
  void showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickCoverImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildTop(),
          buildContent(),
        ],
      ),
    );
  }

  Widget buildTop() {
    // Calcule la position verticale de l'image de profil
    final top = coverHeight - profileHeight / 2;
    final bottom = profileHeight / 2;

    // Utilisation de Stack pour superposer les widgets (image de couverture et photo de profil)
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(bottom: bottom), child: buildCoverImage()),
        Positioned(
          // Définit la distance entre la photo de profil et le haut de l'écran
          top: top,
          child: buildProfileImage(),
        ),
      ],
    );
  }
  Widget buildCoverImage() {
    return Stack(
      children: [
        Container(
          height: coverHeight,
          width: double.infinity,
          child: coverImage != null
              ? Image.file(
            coverImage!,
            fit: BoxFit.cover,
          )
              :

          Image.asset(
            defaultCoverImage,  // Default image if no cover image is selected
            fit: BoxFit.cover,
          ),

        ),
        // Add edit button
        Positioned(
          bottom: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[800]),
              onPressed: showImageSourceOptions,
            ),
          ),
        ),
      ],
    );
  }
  Widget buildProfileImage() {
    return CircleAvatar(
      radius: profileHeight / 2,
      backgroundColor: Colors.teal,
      //backgroundImage: NetworkImage(''),
      backgroundImage: AssetImage("assets/user.jpeg"),
    );
  }
  Widget buildContent() {
    // Sample data for counts
    int reviewCount = 25;
    int followingCount = 30;
    int likeCount = 50;

    // Placeholder pour le contenu principal
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              " Mohamed Amine Tabaei",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Gaming and Netflix',
              style: TextStyle(
                fontSize: 18,
                height: 1.5, // Espacement entre les lignes
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 16),
          //Social Media Accounts
          Center(
            child: Text(
              'Medaminetabaei@gmail.com',
              style: TextStyle(
                fontSize: 18,
                height: 1.5, // Espacement entre les lignes
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 16),
          /*Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSocialIcon(FontAwesomeIcons.facebook),
              SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.instagram),
              SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.twitter),
              SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.snapchat),
              SizedBox(width: 12),
            ],
          ),
          */
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSocialIcon(FontAwesomeIcons.facebook,
                  'https://www.facebook.com/yourprofile'),
              SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.instagram,
                  'https://www.instagram.com/yourprofile'),
              SizedBox(width: 12),
              buildSocialIcon(
                  FontAwesomeIcons.twitter, 'https://twitter.com/yourprofile'),
              SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.snapchat,
                  'https://www.snapchat.com/add/yourprofile'),
              SizedBox(width: 12),
            ],
          ),
          SizedBox(height: 16),
          buildStats(),

          SizedBox(height: 16),
          Text(
            'About : ',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Avid gamer with a passion for exploring immersive virtual worlds. "
                "I enjoy sharing insights, reviews, and tips about the latest games. "
                "Always on the lookout for new adventures and challenges in gaming. "
                "Connecting with like-minded gamers is what I love the most!",
            style: TextStyle(
              fontSize: 18,
              height: 1.5, // Espacement entre les lignes
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  Widget buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchURL(url), // This will open the URL when clicked
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.teal, // Background color of the icon
        child: Icon(
          icon,
          size: 32,
          color: Colors.white, // Icon color
        ),
      ),
    );
  }
  Widget buildStats() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
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
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  buildStatItem(String label, int count) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
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
  buildDivider() {
    return Container(
      height: 24,
      child: VerticalDivider(
        color: Colors.grey[300],
        thickness: 1,
      ),
    );
  }
}
