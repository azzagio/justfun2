// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final int? age;
  final String? bio;
  final String? gender;
  final List<String>? interestedIn;
  final List<String> photos;
  final GeoPoint? location;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    this.age,
    this.bio,
    this.gender,
    this.interestedIn,
    required this.photos,
    this.location,
    this.preferences,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      age: data['age'] as int?,
      bio: data['bio'] as String?,
      gender: data['gender'] as String?,
      interestedIn: (data['interestedIn'] as List<dynamic>?)?.map((e) => e as String).toList(),
      photos: (data['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      location: data['location'] as GeoPoint?,
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'gender': gender,
      'interestedIn': interestedIn,
      'photos': photos,
      'location': location,
      'preferences': preferences,
    };
  }
}