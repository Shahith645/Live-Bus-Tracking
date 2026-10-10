import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';
import '../../models/models.dart';
import '../../providers/session_provider.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});
  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<TripHistory> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<SessionProvider>().currentUser;
    if (user == null) return;
    final trips = await DBHelper.instance.getTripsByUser(user.id!);
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No trips yet',
                  subtitle: 'Your completed bus trips will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = _trips[i];
                    return SoftCard(
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.directions_bus_filled_rounded,
                              gradient: LinearGradient(colors: [Color(0xFF00C2A8), Color(0xFF3A5AFF)])),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bus ${t.busNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(t.route, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(t.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(t.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
