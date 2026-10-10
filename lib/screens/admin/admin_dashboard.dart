import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import 'manage_buses_screen.dart';
import 'manage_routes_screen.dart';
import 'view_reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _busCount = 0, _routeCount = 0, _reportCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final buses = await DBHelper.instance.getBuses();
    final routes = await DBHelper.instance.getRoutes();
    final reports = await DBHelper.instance.getReports();
    setState(() {
      _busCount = buses.length;
      _routeCount = routes.length;
      _reportCount = reports.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  _stat('Buses', _busCount),
                  _divider(),
                  _stat('Routes', _routeCount),
                  _divider(),
                  _stat('Reports', _reportCount),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SoftCard(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ManageBusesScreen()))
                  .then((_) => _load()),
              child: const _AdminTile(
                icon: Icons.directions_bus_filled_rounded,
                title: 'Manage Buses',
                subtitle: 'Add, edit, or remove buses',
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ManageRoutesScreen()))
                  .then((_) => _load()),
              child: const _AdminTile(
                icon: Icons.alt_route_rounded,
                title: 'Manage Routes',
                subtitle: 'Create and edit bus routes',
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ViewReportsScreen()))
                  .then((_) => _load()),
              child: const _AdminTile(
                icon: Icons.report_gmailerrorred_rounded,
                title: 'Passenger Reports',
                subtitle: 'Review and manage submitted issues',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 40, width: 1, color: Colors.white24);

  Widget _stat(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AdminTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ],
    );
  }
}
