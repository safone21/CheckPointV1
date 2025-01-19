import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'HomeScreen.dart';
import 'LoginScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? nomValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nom';
    }
    return null;
  }

  String? prenomValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un prénom';
    }
    return null;
  }
  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with email and password
        final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Store additional user data in Firestore
        if (userCredential.user != null) {
          // Store data in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid) // Use Firebase Auth UID as document ID
              .set({
            'nom': _nomController.text,
            'prenom': _prenomController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send email verification
          await userCredential.user!.sendEmailVerification();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Compte créé avec succès. Un e-mail de vérification a été envoyé.')),
          );

          // Navigate to LoginScreen (you can also inform the user to check their email)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                prefilledEmail: _emailController.text,
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'weak-password':
            message = 'Le mot de passe est trop faible.';
            break;
          case 'email-already-in-use':
            message = 'Un compte existe déjà avec cet email.';
            break;
          case 'invalid-email':
            message = 'L\'email n\'est pas valide.';
            break;
          default:
            message = 'Une erreur est survenue. Veuillez réessayer.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add "Sign Up" label here
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20), // Add some space between the title and the form

                // Name field
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 1),
                    ),
                  ),
                  validator: nomValidator,
                ),
                SizedBox(height: 15),

                // First Name field
                TextFormField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 1),
                    ),
                  ),
                  validator: prenomValidator,
                ),
                SizedBox(height: 15),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 1),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                ),
                SizedBox(height: 15),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.teal, width: 1),
                    ),
                  ),
                  obscureText: true,
                  validator: passwordValidator,
                ),
                SizedBox(height: 15),

                // Sign Up Button
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Button color
                      foregroundColor: Colors.white, // Text color
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: Text('S\'inscrire'),
                  ),

                // Button to go back to Login screen
                TextButton(
                  onPressed: () {
                    // Navigate back to Login screen
                    Navigator.pop(context); // This pops the current screen (sign-up) from the stack and returns to the previous screen (login).
                  },
                  child: Text(
                    'Déjà un compte ? Se connecter',
                    style: TextStyle(

                      fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}