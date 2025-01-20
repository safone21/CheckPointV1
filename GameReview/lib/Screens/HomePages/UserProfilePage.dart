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

  // Stats (en dur, à adapter si vous voulez les récupérer depuis Firestore)
  final int reviewCount = 25;
  final int followingCount = 30;
  final int likeCount = 50;

  File? coverImage; // Image sélectionnée pour la cover
  final String defaultCoverImage = 'assets/default_cover_image.jpg';

  // Champs récupérés depuis Firestore
  String? _firstName;  // correspond à "nom" ou "firstname" selon la structure
  String? _lastName;   // correspond à "prenom" ou "lastname"
  String? _email;

  @override
  void initState() {
    super.initState();
    _getUserData(); // On va chercher les infos Firestore de l'utilisateur
  }

  /// Récupère les infos de l'utilisateur connecté : UID -> doc('users') -> champs
  Future<void> _getUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Personne n'est connecté
        return;
      }
      final userId = currentUser.uid;

      // Lecture du document Firestore (collection 'users', doc == UID)
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnap.exists) {
        // Aucune donnée trouvée
        return;
      }

      final data = docSnap.data();
      if (data == null) return;

      // Mettez ici les clés exactes que vous avez dans Firestore :
      // Ex : "nom", "prenom", "email"
      setState(() {
        _firstName = data['nom'] ?? '';
        _lastName  = data['prenom'] ?? '';
        _email     = data['email'] ?? '';
      });
    } catch (e) {
      print('Erreur lors de la récupération des données : $e');
    }
  }

  /// Sélectionne l'image de couverture (depuis caméra ou galerie)
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

  /// Montre un bottomSheet avec "Choisir depuis la galerie" ou "Prendre une photo"
  void showImageSourceOptions() {
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

  /// Construction de la partie haute (image de couverture + photo de profil)
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

  /// Image de couverture (avec le bouton d'édition)
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
              onPressed: showImageSourceOptions,
            ),
          ),
        ),
      ],
    );
  }

  /// Photo de profil (par défaut un asset)
  Widget buildProfileImage() {
    return CircleAvatar(
      radius: profileHeight / 2,
      backgroundColor: Colors.teal,
      backgroundImage: const AssetImage("assets/user.jpeg"),
    );
  }

  /// Contenu principal (nom, email, stats, etc.)
  Widget buildContent() {
    // Concatène firstName + lastName (ou affiche "..." si null)
    final fullName = '${_firstName ?? '...'} ${_lastName ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom complet
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

          // Slogan / description courte
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

          // Icons sociaux
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

  /// Icone ronde cliquable pour lancer une URL (par ex. réseaux sociaux)
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

  /// Barre de stats (Reviews, Following, Likes)
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

  /// Lance l'URL donnée (Facebook, Instagram, etc.)
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Construit un "bloc" stat (nombre + libellé)
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

  /// Séparateur vertical entre les stats
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
