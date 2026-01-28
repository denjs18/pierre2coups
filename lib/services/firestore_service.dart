import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/club.dart';
import '../models/weapon.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================

  /// Créer un profil utilisateur dans Firestore
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  /// Récupérer un utilisateur par son ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Mettre à jour un utilisateur
  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Supprimer un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du profil: $e');
    }
  }

  /// Stream pour écouter les changements du profil utilisateur
  Stream<AppUser?> userStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    });
  }

  // ==================== CLUBS ====================

  /// Rechercher des clubs
  Future<List<Club>> searchClubs(String query, {String? department}) async {
    try {
      Query<Map<String, dynamic>> clubsQuery = _firestore.collection('clubs');

      if (department != null && department.isNotEmpty) {
        clubsQuery = clubsQuery.where('department', isEqualTo: department);
      }

      final snapshot = await clubsQuery.limit(50).get();

      List<Club> clubs = snapshot.docs
          .map((doc) => Club.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrage côté client pour la recherche textuelle
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        clubs = clubs.where((club) {
          return club.name.toLowerCase().contains(lowerQuery) ||
              club.city.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return clubs;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de clubs: $e');
    }
  }

  /// Créer un nouveau club
  Future<Club> createClub({
    required String name,
    required String city,
    required String department,
    required String createdBy,
  }) async {
    try {
      final docRef = _firestore.collection('clubs').doc();
      final club = Club(
        id: docRef.id,
        name: name,
        city: city,
        department: department,
        memberCount: 1,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await docRef.set(club.toFirestore());
      return club;
    } catch (e) {
      throw Exception('Erreur lors de la création du club: $e');
    }
  }

  /// Récupérer un club par son ID
  Future<Club?> getClub(String clubId) async {
    try {
      final doc = await _firestore.collection('clubs').doc(clubId).get();
      if (!doc.exists) return null;
      return Club.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du club: $e');
    }
  }

  /// Rejoindre un club
  Future<void> joinClub(String userId, String clubId) async {
    try {
      // Mettre à jour l'utilisateur
      await _firestore.collection('users').doc(userId).update({
        'club': clubId,
      });

      // Incrémenter le compteur de membres du club
      await _firestore.collection('clubs').doc(clubId).update({
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'adhésion au club: $e');
    }
  }

  /// Quitter un club
  Future<void> leaveClub(String userId, String clubId) async {
    try {
      // Mettre à jour l'utilisateur
      await _firestore.collection('users').doc(userId).update({
        'club': FieldValue.delete(),
      });

      // Décrémenter le compteur de membres du club
      await _firestore.collection('clubs').doc(clubId).update({
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Erreur lors de la sortie du club: $e');
    }
  }

  // ==================== WEAPONS ====================

  /// Rechercher des armes
  Future<List<Weapon>> searchWeapons(
    String query, {
    String? manufacturer,
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> weaponsQuery = _firestore.collection('weapons');

      if (category != null && category.isNotEmpty) {
        weaponsQuery = weaponsQuery.where('category', isEqualTo: category);
      }

      weaponsQuery = weaponsQuery.orderBy('usageCount', descending: true).limit(50);

      final snapshot = await weaponsQuery.get();

      List<Weapon> weapons = snapshot.docs
          .map((doc) => Weapon.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrage côté client pour la recherche textuelle
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        weapons = weapons.where((weapon) {
          return weapon.name.toLowerCase().contains(lowerQuery) ||
              weapon.manufacturer.toLowerCase().contains(lowerQuery) ||
              weapon.model.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      if (manufacturer != null && manufacturer.isNotEmpty) {
        final lowerManufacturer = manufacturer.toLowerCase();
        weapons = weapons.where((weapon) {
          return weapon.manufacturer.toLowerCase().contains(lowerManufacturer);
        }).toList();
      }

      return weapons;
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'armes: $e');
    }
  }

  /// Créer une nouvelle arme
  Future<Weapon> createWeapon({
    required String name,
    required String manufacturer,
    required String model,
    required String caliber,
    required String category,
    required String createdBy,
  }) async {
    try {
      final docRef = _firestore.collection('weapons').doc();
      final weapon = Weapon(
        id: docRef.id,
        name: name,
        manufacturer: manufacturer,
        model: model,
        caliber: caliber,
        category: category,
        usageCount: 0,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await docRef.set(weapon.toFirestore());
      return weapon;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'arme: $e');
    }
  }

  /// Récupérer une arme par son ID
  Future<Weapon?> getWeapon(String weaponId) async {
    try {
      final doc = await _firestore.collection('weapons').doc(weaponId).get();
      if (!doc.exists) return null;
      return Weapon.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'arme: $e');
    }
  }

  /// Incrémenter le compteur d'utilisation d'une arme
  Future<void> incrementWeaponUsage(String weaponId) async {
    try {
      await _firestore.collection('weapons').doc(weaponId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Ignorer les erreurs d'incrémentation
    }
  }

  // ==================== UTILITY ====================

  /// Vérifier si Firestore est disponible
  Future<bool> isAvailable() async {
    try {
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
