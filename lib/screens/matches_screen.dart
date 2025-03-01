import 'package:flutter/material.dart';
import 'package:simple_dating_app/models/user_model.dart';
import 'package:simple_dating_app/services/auth_service.dart';
import 'package:simple_dating_app/services/database_service.dart';
import 'package:simple_dating_app/screens/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  List<UserModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final String? userId = _authService.currentUser?.uid;
    if (userId == null) {
      debugPrint('No user logged in');
      return;
    }
    _databaseService.getMatches().listen((matches) async {
      final List<UserModel> userMatches = [];
      for (final match in matches) {
        // À ajuster selon la structure réelle de MatchModel et DatabaseService
        // Hypothèse temporaire : match contient un ID utilisateur
        final user = await _databaseService.getUser(match.matchedUserId); // Remplace matchedUserId par le bon champ
        if (user != null) {
          userMatches.add(user);
        }
      }
      setState(() {
        _matches = userMatches;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: _matches.isEmpty
          ? const Center(child: Text('No matches yet'))
          : ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return ListTile(
                  title: Text(match.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen()),
                    );
                  },
                );
              },
            ),
    );
  }
}