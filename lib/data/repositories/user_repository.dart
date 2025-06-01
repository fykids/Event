import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tubes/data/models/user_models.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'users';

  CollectionReference get _usersCollection => _firestore.collection(_collection);

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('UserRepository: Error getting user by ID: $e');
      return null;
    }
  }

  // Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      
      // Firestore 'in' query has a limit of 10 items
      List<UserModel> allUsers = [];
      
      // Split into chunks of 10
      for (int i = 0; i < userIds.length; i += 10) {
        int end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        List<String> chunk = userIds.sublist(i, end);
        
        QuerySnapshot query = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
            
        List<UserModel> chunkUsers = query.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
            
        allUsers.addAll(chunkUsers);
      }
      
      return allUsers;
    } catch (e) {
      debugPrint('UserRepository: Error getting users by IDs: $e');
      return [];
    }
  }

  // Create or update user profile
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserRepository: Error creating/updating user: $e');
    }
  }

  // Get current user
  UserModel? getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }
}