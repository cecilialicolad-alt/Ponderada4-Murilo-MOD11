import 'package:geolocator/geolocator.dart';

import '../domain/errors.dart';

class LocationService {
  const LocationService();

  Future<Position> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationUnavailableError(
        'Ative a localização do aparelho pra continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableError('Permissão de localização negada.');
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      throw const LocationUnavailableError();
    }
  }
}
