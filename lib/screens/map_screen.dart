import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/errors.dart';
import '../services/location_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

const List<double> _grayscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _location = const LocationService();
  final _game = GameState.instance;
  late Future<Position> _future;

  @override
  void initState() {
    super.initState();
    _future = _location.currentPosition();
  }

  void _retry() => setState(() => _future = _location.currentPosition());

  double get _distanceMeters => _game.muriloDistanceMeters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        foregroundColor: AppTheme.ink,
        centerTitle: true,
        title: Text('ONDE ELE ESTÁ', style: AppTheme.marker(22)),
      ),
      body: FutureBuilder<Position>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.ink),
            );
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is AppError
                ? (snapshot.error as AppError).message
                : 'Erro ao obter a localização.';
            return _ErrorView(message: msg, onRetry: _retry);
          }
          final pos = snapshot.data!;
          final me = LatLng(pos.latitude, pos.longitude);
          final him = LatLng(
            pos.latitude + _distanceMeters / 111320.0,
            pos.longitude,
          );
          return _buildMap(me, him);
        },
      ),
    );
  }

  Widget _buildMap(LatLng me, LatLng him) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([me, him]),
              padding: const EdgeInsets.all(70),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.murilo.murilo_game',
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
                child: tileWidget,
              ),
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [me, him],
                  strokeWidth: 3,
                  color: AppTheme.blood,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: me,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                Marker(
                  point: him,
                  width: 56,
                  height: 56,
                  child: ClipOval(
                    child: Image.asset(
                      _game.currentSkin.asset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_game.finalPhase)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: AppTheme.blood.withValues(alpha: 0.15)),
            ),
          ),
        Positioned(top: 12, left: 12, right: 12, child: _caption()),
      ],
    );
  }

  Widget _caption() {
    final text = _game.finalPhase
        ? 'ELE ESTÁ QUASE AQUI.'
        : 'ele está a ~${_distanceMeters.round()} m de você.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.blood, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.hand(18, color: AppTheme.blood),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.hand(20),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('Tentar de novo', style: AppTheme.hand(18)),
            ),
          ],
        ),
      ),
    );
  }
}
