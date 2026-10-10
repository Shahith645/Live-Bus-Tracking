import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';

/// Live tracking screen. Since there is no real driver-side GPS feed,
/// the bus location is simulated by stepping along the route polyline
/// on a timer — this satisfies "Simulate real-time bus movement".
class BusTrackingScreen extends StatefulWidget {
  final Bus? initialBus;
  const BusTrackingScreen({super.key, this.initialBus});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  List<Bus> _buses = [];
  List<BusRoute> _routes = [];
  Bus? _selected;
  BusRoute? _selectedRoute;
  ll.LatLng? _userLocation;
  Timer? _simTimer;
  int _simStep = 0;
  List<ll.LatLng> _path = [];
  final MapController _mapController = MapController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final buses = await DBHelper.instance.getBuses();
    final routes = await DBHelper.instance.getRoutes();
    Bus? selected = widget.initialBus ?? (buses.isNotEmpty ? buses.first : null);
    setState(() {
      _buses = buses;
      _routes = routes;
      _selected = selected;
      _loading = false;
    });
    if (selected != null) _selectBus(selected);
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _userLocation = ll.LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Location unavailable (emulator/permission denied) — safe to ignore, map still works.
    }
  }

  void _selectBus(Bus bus) {
    _simTimer?.cancel();
    final route = _routes.where((r) => r.id == bus.routeId);
    final r = route.isEmpty ? null : route.first;
    setState(() {
      _selected = bus;
      _selectedRoute = r;
      _simStep = 0;
    });
    _buildSimulatedPath(bus, r);
    _startSimulation();
  }

  void _buildSimulatedPath(Bus bus, BusRoute? route) {
    // Build a synthetic path across a handful of waypoints for a smooth
    // simulated route, starting from the bus's last known location.
    final rnd = Random(bus.id ?? 1);
    final start = ll.LatLng(bus.lastLat, bus.lastLng);
    final stopCount = route?.stopList.length ?? 4;
    final points = <ll.LatLng>[start];
    double lat = start.latitude;
    double lng = start.longitude;
    for (int i = 0; i < max(stopCount, 4); i++) {
      lat += (rnd.nextDouble() - 0.3) * 0.02;
      lng += (rnd.nextDouble() - 0.3) * 0.02;
      points.add(ll.LatLng(lat, lng));
    }
    _path = points;
  }

  void _startSimulation() {
    _simTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_path.length < 2 || _selected == null) return;
      setState(() {
        _simStep = (_simStep + 1) % (_path.length - 1);
      });
      final current = _path[_simStep];
      await DBHelper.instance.updateBusLocation(_selected!.id!, current.latitude, current.longitude);
    });
  }

  double get _etaMinutes {
    if (_selectedRoute == null) return 0;
    // crude ETA: remaining fraction of path * (distance/avg speed 25kmph)
    final remainingFraction = _path.isEmpty ? 0 : 1 - (_simStep / _path.length);
    final hours = (_selectedRoute!.distanceKm * remainingFraction) / 25;
    return (hours * 60).clamp(2, 90);
  }

  double get _distanceRemaining {
    if (_selectedRoute == null) return 0;
    final remainingFraction = _path.isEmpty ? 0 : 1 - (_simStep / _path.length);
    return _selectedRoute!.distanceKm * remainingFraction;
  }

  @override
  Widget build(BuildContext context) {
    final busPoint = _path.isNotEmpty ? _path[_simStep] : const ll.LatLng(13.0827, 80.2707);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: busPoint, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smart_bus_tracker',
                    ),
                    if (_path.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(points: _path, strokeWidth: 5, color: AppColors.primary.withOpacity(0.7)),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: busPoint,
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.amberGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.soft,
                          ),
                          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
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
                    ]),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _busSelector(),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _infoCard(),
                ),
              ],
            ),
    );
  }

  Widget _busSelector() {
    if (_buses.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _buses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final b = _buses[i];
          final active = b.id == _selected?.id;
          return ChoiceChip(
            label: Text(b.busNumber),
            selected: active,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700),
            backgroundColor: Colors.white,
            onSelected: (_) => _selectBus(b),
          );
        },
      ),
    );
  }

  Widget _infoCard() {
    if (_selected == null) {
      return const SoftCard(
        child: EmptyState(icon: Icons.directions_bus_outlined, title: 'No bus selected', subtitle: 'Choose a bus above.'),
      );
    }
    return SoftCard(
      child: Row(
        children: [
          const IconBadge(icon: Icons.directions_bus_filled_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selected!.busNumber} · ${_selected!.busName}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  _selectedRoute != null
                      ? '${_selectedRoute!.source} → ${_selectedRoute!.destination}'
                      : 'Route not assigned',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_etaMinutes.toStringAsFixed(0)} min', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('${_distanceRemaining.toStringAsFixed(1)} km left',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
