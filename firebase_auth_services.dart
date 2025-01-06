import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthServices{
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
  }) async {

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
          'userId': credential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("User registered and details saved successfully!");
        return credential.user;
      }
    } catch (e) {
      print("An error occurred: $e");
    }

    return null;
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User signed in successfully: ${credential.user?.email}");
      return credential.user;
    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        print("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        print("Incorrect password.");
      } else if (e.code == 'invalid-email') {
        print("Invalid email address.");
      } else {
        print("An unknown error occurred: ${e.message}");
      }
    } catch (e) {

      print("An error occurred: $e");
    }

    return null;
  }

  Future<void> sendPasswordResetEmail(String email) async{
    await _auth.sendPasswordResetEmail(email: email);
  }
}

