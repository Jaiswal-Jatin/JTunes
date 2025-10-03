import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/models/user_model.dart';
import 'package:j3tunes/screens/adaptive_layout.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_scaffold.dart';
import 'package:j3tunes/screens/mobile_ui/bottom_navigation_page.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
    return null;
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String address,
    required DateTime dob,
  }) async {
    print('[AuthService] Attempting to sign up with email: $email');
    try {
      print('[AuthService] Calling createUserWithEmailAndPassword...');
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      print(
          '[AuthService] Firebase Auth user created successfully: ${user?.uid}');

      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          mobile: mobile,
          address: address,
          dob: dob,
        );
        print(
            '[AuthService] Saving user data to Firestore: ${userModel.toMap()}');
        // Ensure the data is saved before returning success
        await _firestore // This was already awaited, which is correct.
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        print('[AuthService] User data saved to Firestore successfully.');
        return null;
      }
      print('[AuthService] User registration failed, user object is null.');
      return 'User registration failed.';
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException: ${e.message}');
      return e.message;
    } on FirebaseException catch (e) {
      print(
          '[AuthService] FirebaseException (Firestore?): ${e.message}');
      return e.message ?? 'A Firestore error occurred.';
    } catch (e) {
      print('[AuthService] Unknown error during signup: ${e.toString()}');
      return 'An unknown error occurred: ${e.toString()}';
    }
  }

  Future<String?> signIn(
      {required String email,
      required String password,
      required bool rememberMe}) async {
    print('[AuthService] Attempting to sign in with email: $email');
    try {
      print('[AuthService] Calling signInWithEmailAndPassword...');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('[AuthService] Sign in successful for $email');
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        print('[AuthService] Remembering email.');
        await prefs.setString('remembered_email', email);
      } else {
        print('[AuthService] Forgetting email.');
        await prefs.remove('remembered_email');
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('[AuthService] SignIn FirebaseAuthException: ${e.message}');
      return e.message;
    } catch (e) {
      print('[AuthService] Unknown error during sign in: ${e.toString()}');
      return 'An unknown error occurred.';
    }
  }

  Future<String?> signInWithGoogle() async {
    print('[AuthService] Starting Google Sign-In flow.');
    try {
      print('[AuthService] Calling GoogleSignIn.instance.signIn()');
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        print('[AuthService] Google sign in was cancelled by the user.');
        return 'Google sign in was cancelled.';
      }

      print('[AuthService] Google user signed in: ${googleUser.email}');
      print('[AuthService] Getting Google Auth credentials...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, // accessToken is no longer directly available from GoogleSignInAuthentication in v7.x
        idToken: googleAuth.idToken,
      );

      print('[AuthService] Signing in to Firebase with Google credential...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      print(
          '[AuthService] Firebase user signed in with Google: ${user?.uid}');

      if (user != null) {
        // Check if user exists in Firestore, if not, create a new entry
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        print(
            '[AuthService] Checking if user exists in Firestore: ${docSnap.exists}');
        if (!docSnap.exists) {
          final userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'JTunes User',
            email: user.email ?? '',
            mobile: user.phoneNumber ?? '',
            address: '', // Address is not provided by Google
            dob: DateTime.now(), // DOB is not provided, use current date as placeholder
          );
          print(
              '[AuthService] User does not exist. Creating new document in Firestore: ${userModel.toMap()}');
          await docRef.set(userModel.toMap());
          print('[AuthService] New user document created successfully.');
        }
      }
      print('[AuthService] Google Sign-In process successful.');
      return null; // Success
    } catch (e) {
      print('[AuthService] Error during Google Sign-In: ${e.toString()}');
      return e.toString();
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    // Navigate to login screen after logout
    showToast(context, 'Logged out successfully');
    NavigationManager.router.go('/login');
  }

  Future<String?> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toMap());
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is logged in, show main app
          return AdaptiveLayout(
            mobileLayout: (context) =>
                BottomNavigationPage(child: NavigationManager.router.configuration as StatefulNavigationShell),
            desktopLayout: (context) =>
                 DesktopScaffold(child: NavigationManager.router.configuration as StatefulNavigationShell),
          );
        }
        // User is not logged in, redirect to login
        // This part is tricky with go_router's shell routes.
        // The redirection is better handled in the router setup.
        // This widget is more for showing a loading spinner during auth state check.
        // The actual navigation logic will be in the router.
        // For now, we can return an empty container as router will redirect.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
