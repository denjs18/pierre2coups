import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements d'état d'authentification
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((User? firebaseUser) {
      return firebaseUser != null ? _appUserFromFirebase(firebaseUser) : null;
    });
  }

  // Utilisateur actuellement connecté
  AppUser? get currentUser {
    final User? firebaseUser = _auth.currentUser;
    return firebaseUser != null ? _appUserFromFirebase(firebaseUser) : null;
  }

  // Conversion User Firebase -> AppUser
  AppUser _appUserFromFirebase(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      firstName: null, // Ces infos viendront de Firestore
      lastName: null,
      department: '', // Ces infos viendront de Firestore
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  // Inscription avec email et mot de passe
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Échec de la création du compte');
      }

      return _appUserFromFirebase(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion avec email et mot de passe
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Échec de la connexion');
      }

      return _appUserFromFirebase(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  // Supprimer le compte
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  // Recharger les informations utilisateur
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Ignorer les erreurs de rechargement
    }
  }

  // Gestion des erreurs Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'requires-recent-login':
        return 'Cette opération nécessite une connexion récente. Veuillez vous reconnecter.';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      default:
        return 'Erreur d\'authentification: ${e.message ?? e.code}';
    }
  }

  // Vérifier si l'email est vérifié
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email: $e');
    }
  }

  // Mettre à jour l'email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'email: $e');
    }
  }

  // Mettre à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  // Ré-authentifier l'utilisateur (nécessaire pour certaines opérations sensibles)
  Future<void> reauthenticate(String email, String password) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la ré-authentification: $e');
    }
  }
}
