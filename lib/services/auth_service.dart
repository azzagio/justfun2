import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:simple_dating_app/services/database_service.dart';
import '../models/user_model.dart'; // Ajouté pour utiliser UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password, String name, int? age, String? gender, List<String>? lookingFor) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      await _databaseService.createUser(
        UserModel(
          id: result.user!.uid,
          name: name,
          age: age,
          bio: null, // Ajouter un bio par défaut ou laisser nullable
          gender: gender,
          interestedIn: lookingFor, // Utiliser directement la liste
          photos: [], // Initialiser avec une liste vide
          location: null, // Initialiser avec null
          preferences: null, // Initialiser avec null
        ),
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if this is a new user and create profile if needed
      if (result.additionalUserInfo!.isNewUser) {
        String email = googleUser.email;
        String name = googleUser.displayName ?? 'User';

        await _databaseService.createUser(
          UserModel(
            id: result.user!.uid,
            name: name,
            age: null, // Age non fourni, reste null
            bio: null, // Ajouter un bio par défaut ou laisser nullable
            gender: null, // Gender non fourni, reste null
            interestedIn: null, // LookingFor non fourni, reste null
            photos: [], // Initialiser avec une liste vide
            location: null, // Initialiser avec null
            preferences: null, // Initialiser avec null
          ),
        );
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}