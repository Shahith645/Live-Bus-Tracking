import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';

class NearbyStopsScreen extends StatefulWidget {
  const NearbyStopsScreen({super.key});
  @override
  State<NearbyStopsScreen> createState() => _NearbyStopsScreenState();
}

class _NearbyStopsScreenState extends State<NearbyStopsScreen> {
  Position? _position;
  List<BusStop> _stops = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition();

      // Derive nearby stops from all route stop lists (demo data).
      final routes = await DBHelper.instance.getRoutes();
      final rand = pos.latitude + pos.longitude;
      final stops = <BusStop>[];
      int seed = 0;
      for (final r in routes) {
        for (final s in r.stopList) {
          seed++;
          stops.add(BusStop(
            name: s,
            lat: pos.latitude + ((seed % 5) - 2) * 0.004 + (rand * 0),
            lng: pos.longitude + ((seed % 7) - 3) * 0.004,
          ));
        }
      }
      stops.sort((a, b) => Geolocator.distanceBetween(pos.latitude, pos.longitude, a.lat, a.lng)
          .compareTo(Geolocator.distanceBetween(pos.latitude, pos.longitude, b.lat, b.lng)));

      setState(() {
        _position = pos;
        _stops = stops;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Bus Stops'), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.location_off_rounded, title: 'Location unavailable', subtitle: _error!)
              : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: ll.LatLng(_position!.latitude, _position!.longitude),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.smart_bus_tracker',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                              point: ll.LatLng(_position!.latitude, _position!.longitude),
                              width: 26,
                              height: 26,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                            ..._stops.take(10).map((s) => Marker(
                                  point: ll.LatLng(s.lat, s.lng),
                                  width: 34,
                                  height: 34,
                                  child: const Icon(Icons.pin_drop_rounded, color: AppColors.accent, size: 32),
                                )),
                          ]),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _stops.isEmpty
                          ? const EmptyState(
                              icon: Icons.pin_drop_outlined, title: 'No stops found', subtitle: 'No bus stops nearby yet.')
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _stops.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final s = _stops[i];
                                final dist = Geolocator.distanceBetween(
                                        _position!.latitude, _position!.longitude, s.lat, s.lng) /
                                    1000;
                                return SoftCard(
                                  child: Row(
                                    children: [
                                      const IconBadge(icon: Icons.pin_drop_rounded, gradient: AppColors.amberGradient, size: 42),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text('${dist.toStringAsFixed(2)} km away',
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.directions_rounded, color: AppColors.primary),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
