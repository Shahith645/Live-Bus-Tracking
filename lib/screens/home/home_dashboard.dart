import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';
import 'search_bus_screen.dart';
import 'bus_tracking_screen.dart';
import 'nearby_stops_screen.dart';
import 'report_issue_screen.dart';
import 'trip_history_screen.dart';
import 'profile_screen.dart';
import '../admin/admin_dashboard.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<Bus> _buses = [];
  List<BusRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final buses = await DBHelper.instance.getBuses();
    final routes = await DBHelper.instance.getRoutes();
    if (!mounted) return;
    setState(() {
      _buses = buses;
      _routes = routes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live Buses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (user?.isAdmin ?? false)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboard())),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                      label: const Text('Admin'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buses.isEmpty
                      ? const EmptyState(
                          icon: Icons.directions_bus_filled_outlined,
                          title: 'No buses yet',
                          subtitle: 'Buses added by the admin will appear here.',
                        )
                      : Column(children: _buses.map((b) => _busTile(context, b)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppUser? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?.name.split(' ').first ?? 'Passenger'} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Where would you like to go today?',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchBusScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        SizedBox(width: 10),
                        Text('Search bus, route or stop', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'P',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _Action('Track Bus', Icons.location_on_rounded, AppColors.cardGradient,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusTrackingScreen()))),
      _Action('Nearby Stops', Icons.pin_drop_rounded, AppColors.amberGradient,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyStopsScreen()))),
      _Action('Report Issue', Icons.report_gmailerrorred_rounded,
          const LinearGradient(colors: [Color(0xFFFF5A6E), Color(0xFFFF8A65)]),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
      _Action('Trip History', Icons.history_rounded,
          const LinearGradient(colors: [Color(0xFF00C2A8), Color(0xFF3A5AFF)]),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripHistoryScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: actions
          .map((a) => SoftCard(
                onTap: a.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBadge(icon: a.icon, gradient: a.gradient, size: 44),
                    const Spacer(),
                    Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _busTile(BuildContext context, Bus bus) {
    final route = _routes.where((r) => r.id == bus.routeId);
    final routeLabel = route.isNotEmpty ? '${route.first.source} → ${route.first.destination}' : 'Unassigned route';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => BusTrackingScreen(initialBus: bus))),
        child: Row(
          children: [
            const IconBadge(icon: Icons.directions_bus_filled_rounded, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${bus.busNumber} · ${bus.busName}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(routeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const StatusChip(label: 'Live', color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  _Action(this.label, this.icon, this.gradient, this.onTap);
}
