import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'utilisateur actuellement connecté
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Créer un nouvel utilisateur dans Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint("Error creating user: $e");
      rethrow;
    }
  }

  // Obtenir les données de l'utilisateur actuel
  Future<UserModel> getCurrentUser() async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User not found");
      }

      return UserModel.fromDocument(userDoc);
    } catch (e) {
      debugPrint("Error getting current user: $e");
      rethrow;
    }
  }

  // Mettre à jour les informations de l'utilisateur
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update(userData);
    } catch (e) {
      debugPrint("Error updating user data: $e");
      rethrow;
    }
  }

  // Mettre à jour la localisation de l'utilisateur
  Future<void> updateUserLocation(double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'location': GeoPoint(latitude, longitude),
      });
    } catch (e) {
      debugPrint("Error updating location: $e");
      rethrow;
    }
  }

  // Obtenir les matchs potentiels
  Stream<List<UserModel>> getPotentialMatches() {
    // On récupère les utilisateurs avec qui l'utilisateur actuel a déjà interagi
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('swipes')
        .snapshots()
        .asyncMap((swipesSnapshot) async {
          // Extraire les IDs des utilisateurs déjà swipés
          List<String> swipedUserIds = swipesSnapshot.docs.map((doc) => doc.id).toList();

          // Ajouter l'ID de l'utilisateur actuel pour l'exclure aussi
          swipedUserIds.add(currentUserId);

          // Récupérer les filtres de l'utilisateur actuel (genre recherché, tranche d'âge...)
          DocumentSnapshot currentUserDoc = await _firestore
              .collection('users')
              .doc(currentUserId)
              .get();

          UserModel currentUser = UserModel.fromDocument(currentUserDoc);

          // Créer la requête pour obtenir les utilisateurs potentiels
          Query query = _firestore.collection('users');

          // Filtrer par genre si spécifié
          if (currentUser.interestedIn != null && currentUser.interestedIn!.isNotEmpty) {
            query = query.where('gender', whereIn: currentUser.interestedIn);
          }

          // Exclure les utilisateurs déjà swipés si la liste n'est pas vide
          if (swipedUserIds.isNotEmpty) {
            // Firestore ne permet pas de faire whereNotIn avec une liste vide
            query = query.where(FieldPath.documentId, whereNotIn: swipedUserIds);
          }

          // Exécuter la requête
          QuerySnapshot potentialMatchesSnapshot = await query.get();

          // Convertir les documents en objets UserModel
          return potentialMatchesSnapshot.docs
              .map((doc) => UserModel.fromDocument(doc))
              .toList();
        });
  }

  // Liker un utilisateur
  Future<bool> likeUser(String likedUserId) async {
    try {
      // Ajouter le like dans la collection swipes
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('swipes')
          .doc(likedUserId)
          .set({'liked': true, 'timestamp': FieldValue.serverTimestamp()});

      // Vérifier si l'utilisateur liké a aussi liké l'utilisateur courant
      DocumentSnapshot otherUserSwipe = await _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('swipes')
          .doc(currentUserId)
          .get();

      // Si match (l'autre utilisateur a aussi liké l'utilisateur courant)
      if (otherUserSwipe.exists && otherUserSwipe.get('liked') == true) {
        // Créer le match dans la collection matches de l'utilisateur courant
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('matches')
            .doc(likedUserId)
            .set({
          'matchedUserId': likedUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'lastMessageRead': true,
        });

        // Créer le match dans la collection matches de l'autre utilisateur
        await _firestore
            .collection('users')
            .doc(likedUserId)
            .collection('matches')
            .doc(currentUserId)
            .set({
          'matchedUserId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'lastMessageRead': true,
        });

        // Créer la collection messages pour ce match
        String chatId = _getChatId(currentUserId, likedUserId);
        await _firestore
            .collection('chats')
            .doc(chatId)
            .set({
          'participants': [currentUserId, likedUserId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true; // C'est un match
      }

      return false; // Pas de match pour l'instant
    } catch (e) {
      debugPrint('Error liking user: $e');
      rethrow;
    }
  }

  // Disliker un utilisateur
  Future<void> dislikeUser(String dislikedUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('swipes')
          .doc(dislikedUserId)
          .set({'liked': false, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error disliking user: $e');
      rethrow;
    }
  }

  // Obtenir les matchs
  Stream<List<MatchModel>> getMatches() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('matches')
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((matchesSnapshot) async {
          List<MatchModel> matches = [];

          for (var doc in matchesSnapshot.docs) {
            String matchedUserId = doc.data()['matchedUserId'];

            // Obtener les informations de l'utilisateur matché
            DocumentSnapshot userDoc = await _firestore
                .collection('users')
                .doc(matchedUserId)
                .get();

            if (userDoc.exists) {
              UserModel matchedUser = UserModel.fromDocument(userDoc);

              // Créer le modèle de match
              matches.add(MatchModel(
                id: doc.id,
                user: matchedUser,
                lastMessage: doc.data()['lastMessage'],
                lastMessageTimestamp: doc.data()['lastMessageTimestamp'] != null
                    ? (doc.data()['lastMessageTimestamp'] as Timestamp).toDate()
                    : null,
                lastMessageRead: doc.get('lastMessageRead') ?? true,
              ));
            }
          }

          return matches;
        });
  }

  // Obtenir les matchs de l'utilisateur (pour MatchesScreen)
  Stream<List<UserModel>> getUserMatches() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('matches')
        .snapshots()
        .asyncMap((matchesSnapshot) async {
      List<UserModel> matches = [];
      for (var doc in matchesSnapshot.docs) {
        String matchedUserId = doc.data()['matchedUserId'] as String;
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(matchedUserId)
            .get();
        if (userDoc.exists) {
          matches.add(UserModel.fromDocument(userDoc));
        }
      }
      return matches;
    });
  }

  // Envoyer un message
  Future<void> sendMessage(String recipientId, String content) async {
    try {
      String chatId = _getChatId(currentUserId, recipientId);

      // Ajouter le message à la collection messages du chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Mettre à jour le dernier message dans les collections matches
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('matches')
          .doc(recipientId)
          .update({
        'lastMessage': content,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageRead': true,
      });

      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('matches')
          .doc(currentUserId)
          .update({
        'lastMessage': content,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageRead': false,
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String chatPartnerId) async {
    try {
      String chatId = _getChatId(currentUserId, chatPartnerId);

      // Obtenir les messages non lus de l'autre utilisateur
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: chatPartnerId)
          .where('read', isEqualTo: false)
          .get();

      // Mettre à jour chaque message
      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }

      // Mettre à jour le statut de lecture dans la collection matches
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('matches')
          .doc(chatPartnerId)
          .update({'lastMessageRead': true});
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
      rethrow;
    }
  }

  // Obtenir les messages d'un chat
  Stream<List<MessageModel>> getMessages(String chatPartnerId) {
    String chatId = _getChatId(currentUserId, chatPartnerId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .toList());
  }

  // Générer un ID de chat unique pour deux utilisateurs
  String _getChatId(String userId1, String userId2) {
    // Trier les IDs pour avoir toujours le même chatId quel que soit l'ordre des utilisateurs
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Supprimer un match
  Future<void> unmatchUser(String matchedUserId) async {
    try {
      // Supprimer de la collection matches de l'utilisateur courant
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('matches')
          .doc(matchedUserId)
          .delete();

      // Supprimer de la collection matches de l'autre utilisateur
      await _firestore
          .collection('users')
          .doc(matchedUserId)
          .collection('matches')
          .doc(currentUserId)
          .delete();

      // Garder les entrées dans la collection swipes pour éviter de remontrer ces profils

      // Supprimer le chat associé
      String chatId = _getChatId(currentUserId, matchedUserId);

      // D'abord supprimer tous les messages
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Puis supprimer le document du chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      debugPrint('Error unmatching user: $e');
      rethrow;
    }
  }
}