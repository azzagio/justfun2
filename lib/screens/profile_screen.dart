import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_dating_app/models/user_model.dart';
import 'package:simple_dating_app/services/auth_service.dart';
import 'package:simple_dating_app/services/database_service.dart';
import 'package:simple_dating_app/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = true;
  List<String> _photos = [];
  String _gender = 'male';
  String _lookingFor = 'female';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      _user = await _databaseService.getCurrentUser();
      _nameController.text = _user!.name;
      _ageController.text = _user!.age.toString();
      _bioController.text = _user!.bio;
      _photos = List.from(_user!.photos);
      _gender = _user!.gender;
      _lookingFor = _user!.lookingFor;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      
      try {
        String imageUrl = await _storageService.uploadProfileImage(File(pickedFile.path));
        setState(() {
          _photos.add(imageUrl);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() => _isLoading = true);
    
    try {
      await _storageService.deleteProfileImage(_photos[index]);
      setState(() {
        _photos.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      UserModel updatedUser = UserModel(
        id: _user!.id,
        name: _nameController.text,
        email: _user!.email,
        age: int.parse(_ageController.text),
        gender: _gender,
        lookingFor: _lookingFor,
        bio: _bioController.text,
        photos: _photos,
        // Keep the existing values for other fields
        location: _user!.location,
        interests: _user!.interests,
        likes: _user!.likes,
        dislikes: _user!.dislikes,
        matches: _user!.matches,
      );
      
      await _databaseService.updateUserProfile(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Photos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length + 1, // +1 for the add button
                        itemBuilder: (context, index) {
                          if (index == _photos.length) {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(_photos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        int? age = int.tryParse(value);
                        if (age == null || age < 18) {
                          return 'You must be at least 18 years old';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('I am a:'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'male',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Male'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'female',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Female'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Looking for:'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'male',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Male'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'female',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Female'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'both',
                          groupValue: _lookingFor,
                          onChanged: (value) => setState(() => _lookingFor = value!),
                        ),
                        const Text('Both'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'About Me',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
