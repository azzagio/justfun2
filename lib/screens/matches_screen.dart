import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simple_dating_app/models/user_model.dart';
import 'package:simple_dating_app/screens/chat_screen.dart';
import 'package:simple_dating_app/services/auth_service.dart';
import 'package:simple_dating_app/services/database_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
    final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _databaseService.getUserMatches(userId: _authService.getCurrentUserId()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No matches yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep swiping to find your match!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Swiping'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              UserModel match = snapshot.data![index];
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: match.photos.isNotEmpty
                        ? CachedNetworkImageProvider(match.photos.first)
                        : null,
                    child: match.photos.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(match.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${match.age} years old'),
                  trailing: const Icon(Icons.message),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(match: match),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
