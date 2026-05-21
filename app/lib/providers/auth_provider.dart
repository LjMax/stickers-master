import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Streams the currently-signed-in [User] (or `null` if signed out).
///
/// Used by the rest of the app to react to auth state. Anonymous users are
/// real `User`s — `isAnonymous == true` is the way to tell them apart from
/// Google / email / phone accounts.
///
/// **Uses `userChanges()` rather than `authStateChanges()`** so we get
/// notified when an anonymous account is *linked* to a Google account —
/// in that case the `User` instance is the same (same uid) but its
/// `isAnonymous`, `email`, and `displayName` change. `authStateChanges`
/// only fires on full sign-in/sign-out, which would miss the link event.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

/// Convenience: the current user, or `null` while the stream is still loading.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Side-effecting auth methods. Use `ref.read(authServiceProvider)` to call.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  /// Sign in anonymously if no user is currently signed in. Safe to call
  /// multiple times — does nothing if a user is already present.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Trigger Google account picker. If the user is currently anonymous, the
  /// anonymous account is **linked** to the Google credential — the uid is
  /// preserved, so any locally-saved collection data stays put.
  ///
  /// Returns the resulting [User], or `null` if the user cancelled.
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled the picker

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      // Upgrade the anonymous account in place.
      try {
        result = await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // If the Google account is already linked to a different existing
        // account, we can't link — fall back to sign-in with that account.
        // The anonymous uid will be orphaned; collection merge is a Phase
        // 2.5 task once Firestore sync lands.
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          result = await _auth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      result = await _auth.signInWithCredential(credential);
    }

    // Firebase Auth doesn't automatically copy displayName / photoURL from
    // the Google credential into the User profile when you call
    // linkWithCredential on an anonymous account (and sometimes not even
    // on a plain signInWithCredential). The fields stay null on the User
    // object even though GoogleSignInAccount has them. Push them in
    // explicitly so the rest of the app (avatar widgets, the
    // public_profile auto-sync in SwapRepository.watchMyProfile, etc.)
    // can read them off `FirebaseAuth.instance.currentUser`.
    final user = result.user;
    if (user != null) {
      final futures = <Future<void>>[];
      final googleName = googleUser.displayName;
      final googlePhoto = googleUser.photoUrl;
      if (googleName != null &&
          googleName.isNotEmpty &&
          user.displayName != googleName) {
        futures.add(user.updateDisplayName(googleName));
      }
      if (googlePhoto != null &&
          googlePhoto.isNotEmpty &&
          user.photoURL != googlePhoto) {
        futures.add(user.updatePhotoURL(googlePhoto));
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
        await user.reload();
      }
    }

    final fresh = _auth.currentUser;

    if (kDebugMode) {
      debugPrint('Google sign-in completed:');
      debugPrint('  uid: ${fresh?.uid}');
      debugPrint('  displayName: ${fresh?.displayName}');
      debugPrint('  email: ${fresh?.email}');
      debugPrint('  photoURL: ${fresh?.photoURL}');
      debugPrint('  google account photoUrl: ${googleUser.photoUrl}');
    }

    return fresh ?? result.user;
  }

  /// Sign out of Firebase and clear the cached Google account.
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Best-effort — Google sign-out can fail without affecting Firebase.
    }
  }

  /// Permanently delete the current user's account and all of their data.
  ///
  /// Invokes the `deleteAccount` Cloud Function, which erases the user's
  /// Firestore data across every collection and then deletes their Firebase
  /// Auth account. The function is pinned to europe-west3 (the Firestore
  /// region), so the client must target that region explicitly.
  ///
  /// Once the server has deleted the Auth user, the local session is stale.
  /// We sign out and start a fresh anonymous session so the app stays
  /// usable as a guest without needing a restart. Throws on failure — the
  /// caller should surface an error and leave the account intact.
  Future<void> deleteAccount() async {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
    await functions.httpsCallable('deleteAccount').call();

    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Best-effort.
    }
    await _auth.signInAnonymously();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});
