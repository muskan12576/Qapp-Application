import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String mapsUrl;
  final String locationName;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.mapsUrl,
    this.locationName = "Current Location",
  });
}

class LocationHelperService {
  LocationHelperService._();
  static final LocationHelperService instance = LocationHelperService._();

  /// Check GPS service enabled and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ [LOCATION] Location services are disabled on device');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ [LOCATION] Location permission denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ [LOCATION] Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get actual device GPS coordinates with high accuracy
  Future<LocationResult?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = "https://www.google.com/maps?q=$lat,$lng";

      debugPrint('📍 [LOCATION] Coordinates fetched: $lat, $lng');
      return LocationResult(
        latitude: lat,
        longitude: lng,
        mapsUrl: mapsUrl,
      );
    } catch (e) {
      debugPrint('⚠️ [LOCATION] Error getting current position: $e');
      return null;
    }
  }
}
