import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// Importez correctement vos services et modèles
import 'package:simple_dating_app/models/user_model.dart';
import 'package:simple_dating_app/screens/matches_screen.dart';
import 'package:simple_dating_app/screens/profile_screen.dart';
import 'package:simple_dating_app/services/database_service.dart'; // Assurez-vous que ce chemin est correct
import 'package:simple_dating_app/services/location_service.dart'; // Assurez-vous que ce chemin est correct
import 'package:simple_dating_app/widgets/profile_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  // Instanciez vos services avec le mot-clé final
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final CardSwiperController _cardController = CardSwiperController();
  
  bool _isLoading = true;
  List<UserModel> _potentialMatches = [];
  bool _isMatched = false;
  UserModel? _matchedUser;
  double _maxDistance = 50.0; // Distance maximale en km (paramètre par défaut)

  @override
  void initState() {
    super.initState();
    _updateLocationAndLoadMatches();
  }

  // Mise à jour de la localisation et chargement des matchs potentiels
  Future<void> _updateLocationAndLoadMatches() async {
    await _locationService.updateUserLocation();
    _loadPotentialMatches();
  }

  // Chargement des matchs potentiels
  Future<void> _loadPotentialMatches() async {
    setState(() => _isLoading = true);
    
    _databaseService.getPotentialMatches().listen((users) {
      _filterMatchesByDistance(users).then((filteredUsers) {
        setState(() {
          _potentialMatches = filteredUsers;
          _isLoading = false;
        });
      });
    });
  }

  // Filtrage des matchs selon la distance
  Future<List<UserModel>> _filterMatchesByDistance(List<UserModel> users) async {
    // Si distance maximale est 0 ou négative, pas de filtrage
    if (_maxDistance <= 0) return users;
    
    // Obtenir l'utilisateur actuel avec sa localisation
    final currentUser = await _databaseService.getCurrentUser();
    
    // Vérifier si la localisation existe, pas besoin de vérifier null car Map ne peut pas être null
    if (currentUser.location.isEmpty) {
      return users;
    }
    
    // Récupérer les coordonnées de l'utilisateur courant
    final currentLat = currentUser.location['latitude'] as double?;
    final currentLong = currentUser.location['longitude'] as double?;
    
    // Si les coordonnées ne sont pas disponibles, retourner tous les utilisateurs
    if (currentLat == null || currentLong == null) {
      return users;
    }
    
    // Filtrer les utilisateurs par distance
    return users.where((user) {
      // Vérifier si l'autre utilisateur a une localisation valide
      if (user.location.isEmpty) {
        return false;
      }
      
      // Récupérer les coordonnées de l'utilisateur
      final userLat = user.location['latitude'] as double?;
      final userLong = user.location['longitude'] as double?;
      
      // Si les coordonnées ne sont pas disponibles, exclure cet utilisateur
      if (userLat == null || userLong == null) {
        return false;
      }
      
      // Calculer la distance entre les deux utilisateurs
      double distance = _locationService.calculateDistance(
        currentLat, 
        currentLong,
        userLat,
        userLong
      );
      
      // Conserver l'utilisateur s'il est dans le rayon défini
      return distance <= _maxDistance;
    }).toList();
  }

  // Gestion du swipe manuel
  void _handleSwipe(CardSwiperDirection direction) {
    // Vérifier qu'il y a des profils à traiter
    if (_potentialMatches.isEmpty) return;
    
    UserModel swipedUser = _potentialMatches[0];
    
    if (direction == CardSwiperDirection.right) {
      // Like l'utilisateur et vérifier s'il y a match
      _databaseService.likeUser(swipedUser.id).then((isMatch) {
        if (isMatch) {
          setState(() {
            _isMatched = true;
            _matchedUser = swipedUser;
          });
        }
      });
    } else if (direction == CardSwiperDirection.left) {
      // Dislike l'utilisateur
      _databaseService.dislikeUser(swipedUser.id);
    }
    
    // Passer à la carte suivante
    _cardController.swipe();
  }

  // Fermeture de la boîte de dialogue de match
  void _closeMatchDialog() {
    setState(() {
      _isMatched = false;
      _matchedUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Matches'),
        actions: [
          // Bouton pour rafraîchir la localisation
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _updateLocationAndLoadMatches,
            tooltip: 'Update location',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchesScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Affichage des profils ou message de chargement/vide
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _potentialMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No more profiles to show!',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateLocationAndLoadMatches,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CardSwiper(
                        controller: _cardController,
                        cardsCount: _potentialMatches.length,
                        numberOfCardsDisplayed: 1,
                        cardBuilder: (context, index) {
                          return ProfileCard(user: _potentialMatches[index]);
                        },
                      ),
                    ),
                    
          // Dialog de match
          if (_isMatched && _matchedUser != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'It\'s a Match!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: _matchedUser!.photos.isNotEmpty
                              ? CachedNetworkImageProvider(_matchedUser!.photos.first)
                              : null,
                          child: _matchedUser!.photos.isEmpty
                              ? const Icon(Icons.person, size: 70)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You and ${_matchedUser!.name} have liked each other!',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _closeMatchDialog();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MatchesScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Send Message'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _closeMatchDialog,
                                child: const Text('Keep Swiping'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Section pour ajuster la distance maximale
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Max Distance:'),
                Text('${_maxDistance.toInt()} km'),
              ],
            ),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _maxDistance = value;
                });
              },
              onChangeEnd: (_) => _loadPotentialMatches(),
            ),
          ],
        ),
      ),
      // Boutons de swipe
      bottomNavigationBar: !_isLoading && _potentialMatches.isNotEmpty
          ? Container(
              padding: const EdgeInsets.only(
                left: 32.0, 
                right: 32.0, 
                bottom: 16.0, 
                top: 60.0  // Espace pour le bottomSheet
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: 'dislike',
                    onPressed: () => _handleSwipe(CardSwiperDirection.left),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.close, color: Colors.red, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'like',
                    onPressed: () => _handleSwipe(CardSwiperDirection.right),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                  ),
                ],
              ),
            )
          : const SizedBox(height: 80), // Hauteur réservée quand pas de boutons
    );
  }
}
