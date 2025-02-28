import 'dart:math';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint

// Importez votre service de base de données - Ajustez le chemin si nécessaire
import 'package:simple_dating_app/services/database_service.dart';

class LocationService {
  final Location _location = Location();
  final DatabaseService _databaseService = DatabaseService();
  
  // Demander les permissions de localisation
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }
    
    return true;
  }

  // Mettre à jour la localisation de l'utilisateur
  Future<bool> updateUserLocation() async {
    try {
      bool permissionsGranted = await requestLocationPermission();
      if (!permissionsGranted) {
        return false;
      }

      LocationData locationData = await _location.getLocation();
      
      // Mettre à jour la localisation dans la base de données
      await _databaseService.updateUserLocation(
        locationData.latitude ?? 0.0,
        locationData.longitude ?? 0.0,
      );
      
      return true;
    } catch (e) {
      // Utiliser debugPrint au lieu de print pour le débogage
      debugPrint('Error updating location: $e');
      return false;
    }
  }
  
  // Calculer la distance entre deux points (formule haversine)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    // Conversion en radians
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    // Formule haversine
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance; // Distance en kilomètres
  }
  
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
  
  // Pour obtenir des mises à jour en temps réel
  Stream<LocationData> getLocationUpdates() {
    _location.changeSettings(
      accuracy: LocationAccuracy.high, 
      interval: 10000, // 10 secondes
    );
    return _location.onLocationChanged;
  }
}
