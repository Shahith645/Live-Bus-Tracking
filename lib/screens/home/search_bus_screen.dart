import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';
import 'bus_tracking_screen.dart';

class SearchBusScreen extends StatefulWidget {
  const SearchBusScreen({super.key});
  @override
  State<SearchBusScreen> createState() => _SearchBusScreenState();
}

class _SearchBusScreenState extends State<SearchBusScreen> {
  final _controller = TextEditingController();
  List<Bus> _all = [];
  List<BusRoute> _routes = [];
  List<Bus> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final buses = await DBHelper.instance.getBuses();
    final routes = await DBHelper.instance.getRoutes();
    setState(() {
      _all = buses;
      _routes = routes;
      _filtered = buses;
      _loading = false;
    });
  }

  BusRoute? _routeFor(Bus b) {
    final match = _routes.where((r) => r.id == b.routeId);
    return match.isEmpty ? null : match.first;
  }

  void _search(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _all.where((b) {
        final route = _routeFor(b);
        return b.busNumber.toLowerCase().contains(q) ||
            b.busName.toLowerCase().contains(q) ||
            (route?.source.toLowerCase().contains(q) ?? false) ||
            (route?.destination.toLowerCase().contains(q) ?? false) ||
            (route?.stops.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Bus')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Search by bus number, name, route or stop',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No buses found',
                          subtitle: 'Try a different bus number, route or stop name.',
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final bus = _filtered[i];
                            final route = _routeFor(bus);
                            return SoftCard(
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => BusTrackingScreen(initialBus: bus))),
                              child: Row(
                                children: [
                                  const IconBadge(icon: Icons.directions_bus_filled_rounded, size: 48),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${bus.busNumber} · ${bus.busName}',
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(
                                          route != null ? '${route.source} → ${route.destination}' : 'No route assigned',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                        if (route != null) ...[
                                          const SizedBox(height: 2),
                                          Text('${route.distanceKm.toStringAsFixed(1)} km · Driver: ${bus.driverName}',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
