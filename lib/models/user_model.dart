import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? bio;
  final int? age;
  final String? gender;
  final List<String>? interestedIn;
  final List<String> photos;
  final GeoPoint? location;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    this.bio,
    this.age,
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
      bio: data['bio'],
      age: data['age'],
      gender: data['gender'],
      interestedIn: data['interestedIn'] != null 
          ? List<String>.from(data['interestedIn']) 
          : null,
      photos: data['photos'] != null 
          ? List<String>.from(data['photos']) 
          : [],
      location: data['location'],
      preferences: data['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'age': age,
      'gender': gender,
      'interestedIn': interestedIn,
      'photos': photos,
      'location': location,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? name,
    String? bio,
    int? age,
    String? gender,
    List<String>? interestedIn,
    List<String>? photos,
    GeoPoint? location,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
    );
  }
}
